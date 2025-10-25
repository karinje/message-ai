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

TIMEZONE CONTEXT:
- User timezone: America/Los_Angeles (Pacific Time, UTC-8 during PST / UTC-7 during PDT)
- Current date/time in PT: ${new Date().toLocaleString("en-US", { timeZone: "America/Los_Angeles", dateStyle: "full", timeStyle: "long" })}
- IMPORTANT: When the user says "tomorrow", "next week", etc., calculate relative to Pacific Time, NOT UTC
  * Example: If it's 10pm PT on Thursday Oct 24, "tomorrow" = Friday Oct 25 (even though it's already Friday in UTC)
- When extracting times, interpret them as Pacific Time
- CRITICAL: Convert all times to UTC before returning. Pacific Time → UTC conversion:
  * During PST (Nov-Mar): Add 8 hours (e.g., 2pm PT = 22:00 UTC)
  * During PDT (Mar-Nov): Add 7 hours (e.g., 2pm PT = 21:00 UTC)
- Current month is October, so we're in PDT (UTC-7)
- NOTE: After UTC conversion, the date might shift to the next day if the time is late (e.g., 10pm PT Oct 24 = 5am UTC Oct 25)

IMPORTANT: You MUST respond with valid JSON matching this exact schema:
{
  "events": [
    {
      "title": "string",
      "date": "YYYY-MM-DD",
      "time": "HH:MM" (24-hour format in UTC - already converted from PT),
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

    console.log(`🤖 OpenAI extracted ${extraction.events.length} event(s):`, JSON.stringify(extraction.events, null, 2));

    // Convert to ExtractedEvent format
    const extractedEvents: Omit<ExtractedEvent, "id">[] = extraction.events.map((event) => {
      // Combine date and time into ISO string
      let dateTime: string;
      if (event.time) {
        dateTime = new Date(`${event.date}T${event.time}:00`).toISOString();
      } else {
        dateTime = new Date(`${event.date}T12:00:00`).toISOString(); // Default to noon
      }

      console.log(`📅 Event "${event.title}": Raw date=${event.date}, time=${event.time || "none"} → ISO=${dateTime}`);

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

