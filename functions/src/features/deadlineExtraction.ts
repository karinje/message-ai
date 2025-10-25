import { createStructuredCompletion } from "../utils/openai";
import { storeDeadlines } from "../utils/firestore";
import { DeadlineExtractionResponse, Deadline } from "../types";

const DEADLINE_EXTRACTION_SYSTEM_PROMPT = `You are an AI assistant that extracts FUTURE deadlines and commitments from conversational messages.

CRITICAL: Only extract items that are:
1. **Action items** that can be completed over time (bring, submit, pay, send, etc.)
2. **Have a future due date** (not immediate/right now)
3. **Not urgent emergencies** (skip "EMERGENCY", "NOW", "ASAP", "immediately")

DO NOT extract:
- Immediate pickup requests ("pick up now", "come get me")
- Emergency situations (these are priority messages, not deadlines)
- Vague invitations without commitment ("want to attend?", "interested?")
- Questions about attendance (these are RSVPs, not deadlines)

Examples of VALID deadlines:
- "Bring cupcakes by Friday" → ✅ deadline (future, actionable)
- "Need to submit forms by tomorrow" → ✅ deadline (future due date)
- "Payment due next Monday" → ✅ deadline (specific future date)
- "Send me the document by end of week" → ✅ deadline (clear action + date)

Examples of INVALID (skip these):
- "EMERGENCY! Pick up Sam NOW" → ❌ urgent priority, not a deadline
- "Can you come get me?" → ❌ immediate request, not a deadline
- "Do you want to attend tomorrow?" → ❌ RSVP question, not a deadline
- "Need help ASAP" → ❌ urgent request, not a deadline

Guidelines:
- Extract ONLY explicit commitments or requests
- Include time-sensitive action items
- Assign priority based on urgency:
  * high: Due today or tomorrow, urgent language
  * medium: Due this week
  * low: Due later or no specific date
- If no specific date, estimate based on context ("soon" → 2 days, "next week" → 7 days)
- Confidence scoring:
  * 0.9-1.0: Explicit deadline with date
  * 0.7-0.9: Clear action item, date may be implied
  * 0.5-0.7: Vague commitment
  * < 0.5: Too uncertain

Current date for reference: ${new Date().toLocaleString("en-US", { 
  timeZone: "America/Los_Angeles", 
  dateStyle: "full", 
  timeStyle: "short" 
})}

IMPORTANT: You MUST respond with valid JSON matching this exact schema:
{
  "deadlines": [
    {
      "task": "string (what needs to be done)",
      "dueDate": "YYYY-MM-DD" (ISO8601 date),
      "priority": "high" | "medium" | "low",
      "confidence": number (0-1),
      "assignedTo": "string (optional, if a specific person is mentioned)"
    }
  ]
}

If NO deadlines found, return: {"deadlines": []}
`;

/**
 * Extract deadlines and action items from message text
 * @param data Contains messageText, conversationId, messageId
 * @returns Array of extracted deadlines
 */
export async function extractDeadlines(data: {
  messageText: string;
  conversationId: string;
  messageId: string;
  userId: string;
}): Promise<Deadline[]> {
  const { messageText, conversationId, messageId, userId } = data;

  if (!messageText || messageText.trim().length < 10) {
    console.log("Message too short for deadline extraction");
    return [];
  }

  try {
    const aiResponse = await createStructuredCompletion<DeadlineExtractionResponse>(
      DEADLINE_EXTRACTION_SYSTEM_PROMPT,
      messageText,
      "gpt-4o-mini"
    );

    console.log(`📋 OpenAI extracted ${aiResponse.deadlines.length} deadline(s):`, JSON.stringify(aiResponse.deadlines, null, 2));

    if (!aiResponse.deadlines || aiResponse.deadlines.length === 0) {
      return [];
    }

    // Convert to Deadline format
    const deadlines: Deadline[] = aiResponse.deadlines
      .filter(d => d.confidence >= 0.7) // Only store high-confidence deadlines
      .map(d => ({
        id: `${conversationId}_${messageId}_${Date.now()}`,
        userId: d.assignedTo || userId, // Assign to mentioned person or message sender
        task: d.task,
        dueDate: d.dueDate,
        priority: d.priority,
        conversationId,
        messageId,
        completed: false,
        confidence: d.confidence,
        createdAt: new Date().toISOString(),
        reminderSent: false,
        dismissedBy: [], // Initialize empty array for dismissal tracking
      }));

    if (deadlines.length > 0) {
      console.log(`✅ Storing ${deadlines.length} deadlines`);
      await storeDeadlines(deadlines);
    }

    return deadlines;
  } catch (error) {
    console.error("❌ Deadline extraction failed:", error);
    throw error;
  }
}

