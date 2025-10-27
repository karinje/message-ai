import { tool } from "@langchain/core/tools";
import z from "zod";
import { getFirestore } from 'firebase-admin/firestore';

export const createPriorityMessageTool = tool(
  async ({ userId, messageId, messageText, priority, reason, conversationId, senderId, senderName, timestamp }) => {
    const db = getFirestore();
    
    // Handle timestamp parsing - accept string, number, or date
    let parsedTimestamp: Date;
    try {
      if (typeof timestamp === 'number') {
        parsedTimestamp = new Date(timestamp);
      } else if (typeof timestamp === 'string') {
        parsedTimestamp = new Date(timestamp);
      } else {
        parsedTimestamp = new Date();
      }
      // Validate the date
      if (isNaN(parsedTimestamp.getTime())) {
        parsedTimestamp = new Date();
      }
    } catch (e) {
      console.error('Error parsing timestamp:', e);
      parsedTimestamp = new Date();
    }
    
    const data = {
      messageText,
      priority,
      reason,
      conversationId,
      senderId,
      senderName,
      timestamp: parsedTimestamp,
      requiresAction: priority === 'urgent',
      status: 'pending',
    };
    
    console.log(`📝 Writing priority message to Firestore: users/${userId}/digest/priorityMessages/items/${messageId}`);
    console.log(`   Data:`, JSON.stringify(data, null, 2));
    
    await db.collection('users').doc(userId)
      .collection('digest').doc('priorityMessages')
      .collection('items').doc(messageId)
      .set(data);
      
    console.log(`✅ Marked message ${messageId} as ${priority} priority`);
    return `Marked message as ${priority} priority: "${messageText.substring(0, 50)}..."`;
  },
  {
    name: "create_priority_message",
    description: "Mark a message as urgent or important. Use for any time-sensitive requests (emergencies, ASAP, pickup/dropoff, health issues, etc.).",
    schema: z.object({
      userId: z.string(),
      messageId: z.string(),
      messageText: z.string(),
      priority: z.enum(['urgent', 'important']),
      reason: z.string(),
      conversationId: z.string(),
      senderId: z.string(),
      senderName: z.string(),
      timestamp: z.union([z.string(), z.number()]).describe("ISO timestamp string or Unix ms"),
    }),
  }
);

