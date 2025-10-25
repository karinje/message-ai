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

    const eventWithId: ExtractedEvent = {
      ...event,
      id: docRef.id,
      extractedAt: new Date().toISOString(),
    };

    batch.set(docRef, eventWithId);
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

