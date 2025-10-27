import { tool } from "@langchain/core/tools";
import z from "zod";
import { getFirestore } from 'firebase-admin/firestore';

export const createRSVPTool = tool(
  async ({ userId, eventId, eventTitle, eventDate, conversationId, messageId, isHost }) => {
    const db = getFirestore();
    const rsvpId = `rsvp_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    
    // Handle timezone for RSVP event dates - always Pacific Time
    let parsedEventDate: Date;
    try {
      // Check if date already includes a timezone offset (+ or -)
      if (eventDate.includes('+') || (eventDate.includes('-') && eventDate.lastIndexOf('-') > 10)) {
        // Already has timezone, use it directly
        parsedEventDate = new Date(eventDate);
      } else if (eventDate.includes('T')) {
        // ISO format but no timezone - assume Pacific Time
        const dateTimeStr = `${eventDate}-07:00`;
        parsedEventDate = new Date(dateTimeStr);
      } else {
        // Date only, set to noon Pacific Time
        parsedEventDate = new Date(`${eventDate}T12:00:00-07:00`);
      }
      
      if (isNaN(parsedEventDate.getTime())) {
        throw new Error('Invalid date');
      }
      
      console.log(`⏰ RSVP date parsed: ${parsedEventDate.toISOString()} (input: "${eventDate}")`);
    } catch (e) {
      console.error('Error parsing RSVP eventDate:', e);
      parsedEventDate = new Date();
    }
    
    const data = {
      eventId,
      eventTitle,
      eventDate: parsedEventDate,
      conversationId,
      messageId,
      isHost,
      responsesJSON: "{}",
      totalInvited: 0,
      status: 'pending',
      createdAt: new Date(),
    };
    
    console.log(`📝 Writing RSVP to Firestore: users/${userId}/digest/rsvps/items/${rsvpId}`);
    console.log(`   Data:`, JSON.stringify(data, null, 2));
    
    await db.collection('users').doc(userId)
      .collection('digest').doc('rsvps')
      .collection('items').doc(rsvpId)
      .set(data);
      
    console.log(`✅ Created RSVP tracking for "${eventTitle}" with ID ${rsvpId}`);
    return `Created RSVP tracking for "${eventTitle}" with ID ${rsvpId}`;
  },
  {
    name: "create_rsvp",
    description: "Create RSVP tracking for an event that requires responses. Use this when:\n- Someone is inviting people to an event and asking for responses (RSVP, 'let me know', 'can you come')\n- Set isHost=true if the current user is sending the invitation\n- Set isHost=false if the current user is receiving the invitation\n- The eventId should be a unique identifier (you can use the messageId or generate one)\nIMPORTANT: For 'eventDate', provide ISO 8601 timestamp with Pacific timezone (e.g., '2025-10-28T19:00:00-07:00').",
    schema: z.object({
      userId: z.string(),
      eventId: z.string().describe("Unique ID for the event (can use messageId)"),
      eventTitle: z.string().describe("Short title for the event"),
      eventDate: z.string().describe("ISO 8601 timestamp with Pacific timezone (e.g., '2025-10-28T19:00:00-07:00')"),
      conversationId: z.string(),
      messageId: z.string(),
      isHost: z.boolean().describe("True if the current user is hosting/sending the invitation, false if receiving"),
    }),
  }
);

