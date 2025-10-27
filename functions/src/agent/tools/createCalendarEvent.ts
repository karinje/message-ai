import { tool } from "@langchain/core/tools";
import z from "zod";
import { getFirestore } from 'firebase-admin/firestore';

export const createCalendarEventTool = tool(
  async ({ userId, title, date, time, location, conversationId, messageId, confidence }) => {
    try {
      const db = getFirestore();
      const eventId = `evt_${Date.now()}_${Math.random().toString(36).substring(7)}`;
      const path = `users/${userId}/digest/events/items/${eventId}`;
      
      console.log(`📝 Writing event to Firestore: ${path}`);
      
      // Combine date and time into a proper ISO timestamp
      // The LLM provides either:
      // 1. Full ISO timestamp with timezone in 'date' field (e.g., "2025-10-28T22:00:00-07:00")
      // 2. ISO timestamp WITHOUT timezone (e.g., "2025-10-28T22:00:00") - treat as Pacific
      // 3. Separate 'date' (YYYY-MM-DD) and 'time' (HH:MM) fields
      let eventDate: Date;
      
      // Check if date already includes a timezone offset (+ or -)
      if (date.includes('+') || (date.includes('-') && date.lastIndexOf('-') > 10)) {
        // Already has timezone, use it directly
        eventDate = new Date(date);
      } else if (date.includes('T')) {
        // ISO format but no timezone - assume Pacific Time
        const dateTimeStr = `${date}-07:00`;
        eventDate = new Date(dateTimeStr);
      } else if (time) {
        // Separate date and time - combine with Pacific timezone
        const dateTimeStr = `${date}T${time}:00-07:00`;
        eventDate = new Date(dateTimeStr);
      } else {
        // Date only, set to noon Pacific Time
        const dateTimeStr = `${date}T12:00:00-07:00`;
        eventDate = new Date(dateTimeStr);
      }
      
      console.log(`📅 Event date parsed: ${eventDate.toISOString()} (input: date="${date}", time="${time || 'none'}")`);
      
      await db.collection('users').doc(userId)
        .collection('digest').doc('events')
        .collection('items').doc(eventId)
        .set({
          title,
          date: eventDate,
          time: time ?? null,
          location: location ?? null,
          conversationId,
          messageId,
          confidence,
          status: 'pending',
          addedToCalendar: false,
          createdAt: new Date(),
          lastMentionedAt: new Date(),
        });
      
      console.log(`✅ Created calendar event "${title}" with ID ${eventId} at ${path}`);
      return `Created calendar event "${title}" with ID ${eventId}`;
    } catch (error) {
      console.error(`❌ Error creating calendar event:`, error);
      throw error;
    }
  },
  {
    name: "create_calendar_event",
    description: "Create a new calendar event in the user's digest. IMPORTANT: For the 'date' field, provide a full ISO 8601 timestamp with timezone offset (e.g., '2025-10-28T22:00:00-07:00' for 10 PM Pacific Time). If you only have a date like '2025-10-28', and a time like '22:00', combine them as '2025-10-28T22:00:00' and assume the user's local timezone.",
    schema: z.object({
      userId: z.string(),
      title: z.string(),
      date: z.string().describe("ISO 8601 timestamp with timezone (e.g., '2025-10-28T22:00:00-07:00')"),
      time: z.string().nullable().describe("Time in HH:MM format (for display purposes only, actual time should be in 'date' field)"),
      location: z.string().nullable(),
      conversationId: z.string(),
      messageId: z.string(),
      confidence: z.number().min(0).max(1),
    }),
  }
);

