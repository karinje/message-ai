import { createStructuredCompletion } from "../utils/openai";
import { Priority } from "../types";

const PRIORITY_DETECTION_SYSTEM_PROMPT = `You are an AI assistant that classifies message urgency for busy parents.

Your task: Analyze the message and determine if it requires immediate attention, needs attention today, or is just general information.

Priority Categories:
- **urgent**: Needs IMMEDIATE action (pickup, emergency, deadline <2h, safety issue)
  * Keywords: "emergency", "ASAP", "urgent", "now", "immediately", "forgot", "pick up"
  * Time-sensitive: "in 30 minutes", "at 3pm today", "right now"
  * School/safety: "hurt", "sick", "nurse", "accident"
  
- **important**: Needs attention TODAY (schedule change, RSVP needed, decision required)
  * Keywords: "deadline today", "need your input", "RSVP by tonight", "respond asap"
  * Schedule: "changed to", "moved to", "cancelled", "rescheduled"
  * Action items: "can you", "please confirm", "need to know"
  
- **normal**: General information (casual chat, FYI, future planning)
  * Casual conversation, social plans, general updates
  * No time pressure or action required

Context: Busy parent persona with limited time, needs clear urgency signals.

IMPORTANT: You MUST respond with valid JSON matching this exact schema:
{
  "priority": "urgent" | "important" | "normal",
  "reason": "Brief explanation of why this priority was assigned",
  "confidence": number (0-1, how certain you are about this classification)
}

If the message is ambiguous, default to "normal" with lower confidence.
`;

/**
 * Detect message priority for busy parents
 * @param messageText The message content to analyze
 * @returns Priority classification with reason and confidence
 */
export async function detectMessagePriority(
  messageText: string
): Promise<Priority> {
  if (!messageText || messageText.trim().length < 5) {
    return {
      level: "normal",
      reason: "Message too short to determine priority",
      confidence: 1.0,
    };
  }

  try {
    const result = await createStructuredCompletion<Priority>(
      PRIORITY_DETECTION_SYSTEM_PROMPT,
      messageText,
      "gpt-4o-mini"
    );

    console.log(`🚦 Priority detected: ${result.level} (confidence: ${result.confidence})`);
    console.log(`📝 Reason: ${result.reason}`);

    return result;
  } catch (error) {
    console.error("❌ Priority detection failed:", error);
    // Default to normal on error
    return {
      level: "normal",
      reason: "Error analyzing priority",
      confidence: 0.0,
    };
  }
}

