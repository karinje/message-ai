import * as admin from "firebase-admin";
import {
  Message,
  Conversation,
  User,
  ExtractedEvent,
  Priority,
} from "../types";

/**
 * Get Firestore instance
 */
export function getFirestore(): FirebaseFirestore.Firestore {
  return admin.firestore();
}

/**
 * Get a conversation by ID
 */
export async function getConversation(conversationId: string): Promise<Conversation | null> {
  const db = getFirestore();
  const doc = await db.collection("conversations").doc(conversationId).get();

  if (!doc.exists) {
    return null;
  }

  return {
    id: doc.id,
    ...doc.data(),
  } as Conversation;
}

/**
 * Get messages from a conversation
 */
export async function getMessages(
  conversationId: string,
  limit: number = 50
): Promise<Message[]> {
  const db = getFirestore();
  const snapshot = await db
    .collection("conversations")
    .doc(conversationId)
    .collection("messages")
    .orderBy("timestamp", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  })) as Message[];
}

/**
 * Get a user profile
 */
export async function getUserProfile(userId: string): Promise<User | null> {
  const db = getFirestore();
  const doc = await db.collection("users").doc(userId).get();

  if (!doc.exists) {
    return null;
  }

  return {
    id: doc.id,
    ...doc.data(),
  } as User;
}

/**
 * Update message priority
 */
export async function updateMessagePriority(
  messageId: string,
  conversationId: string,
  priority: Priority
): Promise<void> {
  const db = getFirestore();
  await db
    .collection("conversations")
    .doc(conversationId)
    .collection("messages")
    .doc(messageId)
    .update({
      priority: priority.level,
      priorityReason: priority.reason,
      priorityConfidence: priority.confidence,
      priorityDetectedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * Store extracted calendar events
 */
export async function storeExtractedEvents(
  conversationId: string,
  events: Omit<ExtractedEvent, "id">[]
): Promise<ExtractedEvent[]> {
  const db = getFirestore();
  const batch = db.batch();
  const storedEvents: ExtractedEvent[] = [];

  for (const event of events) {
    // Only store if confidence is high enough
    if (event.confidence < 0.7) {
      console.log(`Skipping low-confidence event: ${event.title} (${event.confidence})`);
      continue;
    }

    const docRef = db
      .collection("conversations")
      .doc(conversationId)
      .collection("extractedEvents")
      .doc();

    // Convert ISO string dates to Firestore Timestamps
    const eventData: any = {
      ...event,
      id: docRef.id,
      date: admin.firestore.Timestamp.fromDate(new Date(event.date)),
      extractedAt: admin.firestore.Timestamp.now(),
    };

    // Remove undefined values (Firestore doesn't accept them)
    const cleanedEvent = Object.fromEntries(
      Object.entries(eventData).filter(([_, value]) => value !== undefined)
    );

    batch.set(docRef, cleanedEvent);
    
    // For return value, keep ISO strings
    const eventWithId: ExtractedEvent = {
      ...event,
      id: docRef.id,
      extractedAt: new Date().toISOString(),
    };
    storedEvents.push(eventWithId);
  }

  await batch.commit();
  console.log(`✅ Stored ${storedEvents.length} calendar events for conversation ${conversationId}`);

  return storedEvents;
}

/**
 * Get extracted events for a conversation
 */
export async function getExtractedEvents(
  conversationId: string
): Promise<ExtractedEvent[]> {
  const db = getFirestore();
  const snapshot = await db
    .collection("conversations")
    .doc(conversationId)
    .collection("extractedEvents")
    .orderBy("date", "asc")
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  })) as ExtractedEvent[];
}

/**
 * Store extracted deadlines in Firestore
 * Deadlines are stored in users/{userId}/deadlines collection
 */
export async function storeDeadlines(
  deadlines: import("../types").Deadline[]
): Promise<void> {
  const db = getFirestore();
  const batch = db.batch();

  for (const deadline of deadlines) {
    const docRef = db
      .collection("users")
      .doc(deadline.userId)
      .collection("deadlines")
      .doc(deadline.id);

    // Convert date string to Firestore Timestamp
    const deadlineData = {
      ...deadline,
      dueDate: admin.firestore.Timestamp.fromDate(new Date(deadline.dueDate)),
      createdAt: admin.firestore.Timestamp.now(),
    };

    // Remove undefined values
    const cleanedDeadline = Object.fromEntries(
      Object.entries(deadlineData).filter(([_, value]) => value !== undefined)
    );

    batch.set(docRef, cleanedDeadline);
  }

  await batch.commit();
  console.log(`✅ Stored ${deadlines.length} deadlines`);
}

