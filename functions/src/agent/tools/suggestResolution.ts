import { tool } from "@langchain/core/tools";
import z from "zod";
import { getFirestore } from 'firebase-admin/firestore';

export const suggestResolutionTool = tool(
  async ({ userId, conflictingEventId, conflictingEventTitle, originalDateTime, alternativeSlots }) => {
    const db = getFirestore();
    const suggestionId = `sug_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    
    const description = `Conflict detected for "${conflictingEventTitle}". Here are alternative times:`;
    
    await db.collection('users').doc(userId)
      .collection('digest').doc('suggestions')
      .collection('items').doc(suggestionId)
      .set({
        type: 'conflict_resolution',
        priority: 'high',
        suggestionDescription: description,
        optionsJSON: JSON.stringify(alternativeSlots),
        relatedEventId: conflictingEventId,
        originalDateTime: originalDateTime,
        status: 'pending',
        createdAt: new Date(),
      });
    
    console.log(`✅ Created conflict resolution suggestion for "${conflictingEventTitle}" with ${alternativeSlots.length} options`);
    return `Created suggestion with ${alternativeSlots.length} alternative time slots`;
  },
  {
    name: "suggest_resolution",
    description: "Create a conflict resolution suggestion with alternative time slots. Use this when a proposed meeting truly conflicts with existing events. Provide 3 alternative slots that do NOT overlap with other events.",
    schema: z.object({
      userId: z.string(),
      conflictingEventId: z.string().describe("ID of the event that has a conflict"),
      conflictingEventTitle: z.string().describe("Title of the conflicting event"),
      originalDateTime: z.string().describe("Original proposed date/time in ISO format"),
      alternativeSlots: z.array(z.object({
        startDateTime: z.string().describe("ISO start time for the alternative"),
        endDateTime: z.string().describe("ISO end time for the alternative"),
        label: z.string().describe("Human readable label (e.g. 'Tomorrow at 3pm')"),
      })).min(1).max(5).describe("Alternative date/time slots to suggest"),
    })
  }
);



