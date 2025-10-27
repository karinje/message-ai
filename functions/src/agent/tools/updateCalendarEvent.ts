import { tool } from "@langchain/core/tools";
import z from "zod";
import { getFirestore } from 'firebase-admin/firestore';

export const updateCalendarEventTool = tool(
  async ({ userId, eventId, updates }) => {
    const db = getFirestore();
    const payload: Record<string, unknown> = { lastMentionedAt: new Date() };

    if (updates.title !== undefined) payload.title = updates.title;
    if (updates.date !== undefined) payload.date = updates.date ? new Date(updates.date) : null;
    if (updates.time !== undefined) payload.time = updates.time;
    if (updates.location !== undefined) payload.location = updates.location;
    if (updates.confidence !== undefined) payload.confidence = updates.confidence;
    if (updates.status !== undefined) payload.status = updates.status;

    await db.collection('users').doc(userId)
      .collection('digest').doc('events')
      .collection('items').doc(eventId)
      .update(payload);
    return `Updated event ${eventId}`;
  },
  {
    name: "update_calendar_event",
    description: "Update an existing calendar event details.",
    schema: z.object({
      userId: z.string(),
      eventId: z.string(),
      updates: z.object({
        title: z.string().nullable(),
        date: z.string().nullable(),
        time: z.string().nullable(),
        location: z.string().nullable(),
        confidence: z.number().min(0).max(1).nullable(),
        status: z.enum(['pending','accepted','dismissed']).nullable(),
      })
    })
  }
);



