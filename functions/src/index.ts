import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { extractCalendarEvents as extractCalendarEventsFeature } from "./features/calendarExtraction";
import { detectMessagePriority } from "./features/priorityDetection";
import type {
  CalendarExtractionRequest,
  Message,
  Conversation,
} from "./types";

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Callable Function: Extract Calendar Events
 * Called from the iOS app when a user wants to extract calendar events from a message
 */
export const extractCalendarEvents = functions.https.onCall(
  async (data: CalendarExtractionRequest, context) => {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to use this function"
      );
    }

    const { messageText, conversationId, messageId } = data;

    // Validation
    if (!messageText || !conversationId || !messageId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: messageText, conversationId, messageId"
      );
    }

    try {
      const events = await extractCalendarEventsFeature({
        messageText,
        conversationId,
        messageId,
      });

      return { events };
    } catch (error) {
      console.error("Calendar extraction error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to extract calendar events: ${(error as Error).message}`
      );
    }
  }
);

/**
 * Background Trigger: Handle new messages
 * - Send push notifications to participants
 * - Auto-extract calendar events from message text
 * Original function name maintained for backward compatibility
 */
export const onMessageCreated = functions.firestore
  .document("conversations/{conversationId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data() as Message;
    const conversationId = context.params.conversationId;
    const messageId = context.params.messageId;
    const db = admin.firestore();

    // Run AI features in background (don't block push notifications)
    if (message.text && message.text.trim().length >= 10) {
      // Calendar extraction
      extractCalendarEventsFeature({
        messageText: message.text,
        conversationId,
        messageId,
      }).catch((error) => {
        console.error("Auto calendar extraction failed:", error);
      });

      // Priority detection
      detectMessagePriority(message.text)
        .then(async (priority) => {
          // Only update if confidence is high
          if (priority.confidence > 0.75) {
            console.log(`🚦 Updating message priority: ${priority.level} (${priority.confidence})`);
            await snapshot.ref.update({
              priority: priority.level,
              priorityReason: priority.reason,
              priorityConfidence: priority.confidence,
            });
          }
        })
        .catch((error) => {
          console.error("Auto priority detection failed:", error);
        });
    }

    // Continue with push notification logic
    if (!message || !message.senderId || !conversationId) {
      console.warn("Skipping push, incomplete message payload", message);
      return null;
    }

    // Get conversation
    const conversationSnap = await db
      .collection("conversations")
      .doc(conversationId)
      .get();

    if (!conversationSnap.exists) {
      console.warn("Conversation not found for push", conversationId);
      return null;
    }

    const conversation = conversationSnap.data() as Conversation;
    const participantIds = conversation.participants || [];
    const senderId = message.senderId;

    // Get recipient IDs (all participants except sender)
    const recipientIds = participantIds.filter((id: string) => id !== senderId);
    if (recipientIds.length === 0) {
      console.info("No recipients for push", conversationId);
      return null;
    }

    // Fetch FCM tokens
    const tokenResults = await Promise.all(
      recipientIds.map(async (userId: string) => {
        try {
          const doc = await db.collection("users").doc(userId).get();
          if (!doc.exists) {
            console.warn("Recipient user doc missing", userId);
            return null;
          }
          const data = doc.data();
          if (data?.fcmToken) {
            return { userId, token: data.fcmToken };
          }
          console.warn("Recipient missing fcmToken", userId);
          return null;
        } catch (error) {
          console.error("Error fetching recipient", userId, error);
          return null;
        }
      })
    );

    const tokens = tokenResults
      .filter((result): result is { userId: string; token: string } => result?.token !== undefined)
      .map((result) => result.token);

    if (tokens.length === 0) {
      console.info("No valid FCM tokens for recipients", recipientIds);
      return null;
    }

    // Prepare notification
    const senderName = message.senderName ||
      conversation.participantNames?.[senderId] ||
      "Someone";
    const title = conversation.type === "group" ?
      (conversation.groupName || "Group Chat") :
      senderName;
    const body = message.text || "Sent a message";

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title,
          body,
        },
        data: {
          conversationId,
          senderId,
          messageId: context.params.messageId,
          type: conversation.type || "direct",
        },
      });

      const failures = response.responses.filter((r) => !r.success);
      if (failures.length) {
        console.warn(
          "Push failures",
          failures.map((f) => ({ error: f.error?.message }))
        );
      }
      return null;
    } catch (error) {
      console.error("Error sending push", error);
      return null;
    }
  });

