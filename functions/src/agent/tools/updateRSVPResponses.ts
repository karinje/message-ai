import { tool } from "@langchain/core/tools";
import z from "zod";
import { getFirestore } from 'firebase-admin/firestore';

const individualResponseSchema = z.object({
  response: z.enum(['yes','no','maybe']),
  guestCount: z.number().nullable(),
  note: z.string().nullable(),
  timestamp: z.string()
});

const responsesSchema = z.record(individualResponseSchema);

interface IndividualResponse {
  response: 'yes' | 'no' | 'maybe';
  guestCount: number | null;
  note: string | null;
  timestamp: string;
}

type ResponsesRecord = Record<string, IndividualResponse>;

export const updateRSVPResponsesTool = tool(
  async ({ userId, rsvpId, responses }) => {
    console.log(`📝 Updating RSVP ${rsvpId} with ${Object.keys(responses).length} responses`);
    
    const db = getFirestore();
    const parsed: ResponsesRecord = responsesSchema.parse(responses);

    const normalized: ResponsesRecord = {};
    for (const [key, value] of Object.entries(parsed)) {
      normalized[key] = {
        response: value.response,
        guestCount: value.guestCount ?? null,
        note: value.note ?? null,
        timestamp: value.timestamp
      };
      console.log(`  - ${key}: ${value.response}${value.guestCount ? ` (+${value.guestCount - 1})` : ''}`);
    }

    await db.collection('users').doc(userId)
      .collection('digest').doc('rsvps')
      .collection('items').doc(rsvpId)
      .update({
        responsesJSON: JSON.stringify(normalized),
        totalInvited: Object.keys(normalized).length
      });
    
    console.log(`✅ Updated RSVP ${rsvpId} with ${Object.keys(normalized).length} total responses`);
    return `Updated RSVP ${rsvpId} with ${Object.keys(normalized).length} responses`;
  },
  {
    name: "update_rsvp_responses",
    description: `Update RSVP responses when people respond to an invitation.

WHEN TO USE:
- Someone says "yes", "I'm in", "count me in", "I'll be there"
- Someone says "no", "can't make it", "sorry I can't"  
- Someone says "maybe", "not sure", "depends"

HOW TO USE:
1. Find the RSVP in currentDigest.rsvps that matches this conversationId
2. Look at the existing responsesJSON to see who already responded
3. Add the NEW person who just responded (use their senderName)
4. Pass the COMPLETE responses object (old responses + new response)

EXAMPLE:
If currentDigest has RSVP with responsesJSON: {"Alice": {"response": "yes", ...}}
And Bob says "I'm in!"
Call with responses: {
  "Alice": {"response": "yes", "guestCount": 1, "note": null, "timestamp": "2025-10-27T..."},
  "Bob": {"response": "yes", "guestCount": 1, "note": null, "timestamp": "2025-10-27T..."}
}`,
    schema: z.object({
      userId: z.string(),
      rsvpId: z.string().describe("ID of the existing RSVP from currentDigest.rsvps"),
      responses: responsesSchema.describe("COMPLETE map with ALL responses (existing + new): { 'PersonName': { response: 'yes'|'no'|'maybe', guestCount: number|null, note: string|null, timestamp: ISO string } }")
    })
  }
);



