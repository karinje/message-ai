import { createStructuredCompletion } from "../utils/openai";
import { storeExtractedEvents } from "../utils/firestore";
import {
  CalendarEventExtraction,
  CalendarExtractionRequest,
  ExtractedEvent,
} from "../types";

const CALENDAR_EXTRACTION_SYSTEM_PROMPT = `You are an AI assistant that extracts calendar events from conversational text messages.

Your task:
1. Identify ANY mentions of events, appointments, meetings, deadlines, or time-specific commitments
2. Extract structured information: title, date, time (if mentioned), location (if mentioned)
3. Assign a confidence score (0-1) based on how explicit the event details are
4. Return ONLY valid JSON in the specified format

Guidelines:
- Be generous in interpretation - extract even casual mentions like "let's meet tomorrow"
- For relative dates (tomorrow, next week, etc.), calculate the actual date
- If no time is mentioned, omit the time field
- If location is mentioned (even informally like "at my place"), include it
- Confidence scoring:
  * 0.9-1.0: Explicit event with date/time
  * 0.7-0.9: Clear event but some details missing
  * 0.5-0.7: Implied or casual mention
  * < 0.5: Very vague or uncertain

Current date for reference: ${new Date().toISOString().split("T")[0]}

IMPORTANT: You MUST respond with valid JSON matching this exact schema:
{
  "events": [
    {
      "title": "string",
      "date": "YYYY-MM-DD",
      "time": "HH:MM" (optional),
      "location": "string" (optional),
      "confidence": number (0-1)
    }
  ]
}

If NO events are found, return: {"events": []}`;

/**
 * Extract calendar events from a message
 */
export async function extractCalendarEvents(
  request: CalendarExtractionRequest
): Promise<ExtractedEvent[]> {
  const { messageText, conversationId, messageId } = request;

  console.log(`📅 Extracting calendar events from message: ${messageId}`);

  try {
    // Call OpenAI to extract events
    const extraction = await createStructuredCompletion<CalendarEventExtraction>(
      CALENDAR_EXTRACTION_SYSTEM_PROMPT,
      messageText
    );

    if (!extraction.events || extraction.events.length === 0) {
      console.log("No calendar events found in message");
      return [];
    }

    // Convert to ExtractedEvent format
    const extractedEvents: Omit<ExtractedEvent, "id">[] = extraction.events.map((event) => {
      // Combine date and time into ISO string
      let dateTime: string;
      if (event.time) {
        dateTime = new Date(`${event.date}T${event.time}:00`).toISOString();
      } else {
        dateTime = new Date(`${event.date}T12:00:00`).toISOString(); // Default to noon
      }

      return {
        conversationId,
        messageId,
        title: event.title,
        date: dateTime,
        location: event.location,
        confidence: event.confidence,
        addedToCalendar: false,
        extractedAt: new Date().toISOString(),
      };
    });

    // Store in Firestore (only events with confidence >= 0.7)
    const storedEvents = await storeExtractedEvents(conversationId, extractedEvents);

    console.log(`✅ Successfully extracted and stored ${storedEvents.length} events`);

    return storedEvents;
  } catch (error) {
    console.error("❌ Calendar extraction failed:", error);
    throw new Error(`Calendar extraction failed: ${(error as Error).message}`);
  }
}

