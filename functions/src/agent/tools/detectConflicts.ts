import { tool } from "@langchain/core/tools";
import z from "zod";

const conflictEventSchema = z.object({
  id: z.string(),
  title: z.string(),
  startDateTime: z.string().describe("ISO8601 start timestamp with timezone"),
  endDateTime: z.string().describe("ISO8601 end timestamp with timezone"),
  location: z.string().nullable().optional(),
  source: z.string().nullable().optional(),
});

export const detectConflictsTool = tool(
  async ({ events }) => {
    console.log(`🔍 Checking ${events.length} events for conflicts`);
    
    const conflicts: Array<{ eventA: any; eventB: any; reason: string }> = [];
    
    interface EventRange {
      event: any;
      start: Date;
      end: Date;
    }
    
    const eventRanges: EventRange[] = events
      .map((event: any) => {
        try {
          const start = new Date(event.startDateTime);
          const end = new Date(event.endDateTime);
          if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
            throw new Error(`Invalid dates for event ${event.id}`);
          }
          console.log(`  Event: "${event.title || event.id}" from ${start.toISOString()} to ${end.toISOString()} (source: ${event.source || 'unknown'})`);
          return { event, start, end };
        } catch (err) {
          console.error(`  ⚠️ Failed to parse event ${event.id}:`, err);
          return null;
        }
      })
      .filter((e: EventRange | null): e is EventRange => e !== null);
    
    for (let i = 0; i < eventRanges.length; i++) {
      for (let j = i + 1; j < eventRanges.length; j++) {
        const rangeA = eventRanges[i];
        const rangeB = eventRanges[j];
        const overlaps = rangeA.start < rangeB.end && rangeA.end > rangeB.start;
        if (overlaps) {
          const conflict = { 
            eventA: rangeA.event, 
            eventB: rangeB.event, 
            reason: `Events overlap: ${rangeA.event.title || 'Event'} (${rangeA.start.toLocaleString()} - ${rangeA.end.toLocaleString()}) conflicts with ${rangeB.event.title || 'Event'} (${rangeB.start.toLocaleString()} - ${rangeB.end.toLocaleString()})`
          };
          conflicts.push(conflict);
          console.log(`  ⚠️ CONFLICT: ${conflict.reason}`);
        }
      }
    }

    const result = { 
      conflicts,
      hasConflicts: conflicts.length > 0,
      message: conflicts.length > 0 
        ? `Found ${conflicts.length} scheduling conflict(s)` 
        : 'No conflicts detected'
    };
    
    console.log(`✅ Conflict check complete: ${result.message}`);
    return result;
  },
  {
    name: "detect_conflicts",
    description: "Detect actual TIME OVERLAPS between events. Pass in the proposed event plus existing device calendar events (from calendarContext ONLY - do NOT use currentDigest.events). Requires ISO startDateTime/endDateTime values.",
    schema: z.object({
      events: z.array(conflictEventSchema).min(2).describe("Array of events to check for conflicts: the new proposed event + existing device calendar events from calendarContext."),
    })
  }
);



