// LangGraph + OpenAI via dynamic imports to avoid tsc OOM
import type { AgentState } from "./agentState";
import { createCalendarEventTool } from "./tools/createCalendarEvent";
import { updateCalendarEventTool } from "./tools/updateCalendarEvent";
import { createDeadlineTool } from "./tools/createDeadline";
import { updateDeadlineTool } from "./tools/updateDeadline";
import { createPriorityMessageTool } from "./tools/createPriorityMessage";
import { createRSVPTool } from "./tools/createRSVP";
import { updateRSVPResponsesTool } from "./tools/updateRSVPResponses";
import { createSuggestionTool } from "./tools/createSuggestion";
import { detectConflictsTool } from "./tools/detectConflicts";
import { suggestResolutionTool } from "./tools/suggestResolution";

/**
 * Create unified LangGraph agent
 * PR #29: Complete implementation with tools and workflow
 */

// Node: Prepare system prompt
async function preparePrompt(state: any) {
  const systemPrompt = state.mode === 'background_processing'
    ? `You are an AI assistant analyzing a new message in a conversation for a busy parent.
Your job is to extract calendar events, deadlines, priority markers, RSVP events, and detect conflicts.

⏰ CRITICAL - TIMEZONE HANDLING:
- The user is in Pacific Time (PST/PDT, UTC-8/-7)
- ALL dates you generate MUST include Pacific timezone: "-07:00" or "-08:00"
- When parsing times like "3pm", "tomorrow at 2pm", "next Tuesday at 10am":
  * Convert to 24-hour format
  * Add Pacific timezone offset
  * Example: "tomorrow at 3pm" → "2025-10-28T15:00:00-07:00"
- Never use UTC or assume UTC - ALWAYS use Pacific timezone
- For date-only (no time): use noon Pacific (T12:00:00-07:00)
- For deadlines end of day: use 11:59pm Pacific (T23:59:59-07:00)

NEW MESSAGE to analyze:
- From: ${state.newMessage?.senderName} (ID: ${state.newMessage?.senderId})
- Text: "${state.newMessage?.text}"
- Message ID: ${state.newMessage?.id}
- Timestamp: ${state.newMessage?.timestamp}
- Current time: ${new Date().toLocaleString('en-US', { timeZone: 'America/Los_Angeles' })} Pacific Time

Context:
- User ID: ${state.userId}
- Conversation ID: ${state.conversationId}
- Recent conversation history: ${state.messages.length} messages
- Current user digest state: ${JSON.stringify(state.currentDigest)}
- Upcoming calendar events (${state.calendarContext?.length || 0}): ${JSON.stringify(state.calendarContext ?? [])}

Tools available:
- create_calendar_event: Create NEW events (check currentDigest.events to avoid creating duplicates, but DON'T use it for conflict detection)
- update_calendar_event: UPDATE existing events (when time/date/location changes)
- create_deadline: Create deadlines/tasks
- update_deadline: UPDATE existing deadlines
- create_priority_message: Mark urgent/important messages (look for keywords like URGENT, ASAP, important, critical, etc.)
- create_rsvp: Track RSVP events (look for invitations requesting responses)
- update_rsvp_responses: Update who responded yes/no/maybe to an RSVP
- create_suggestion: Suggest conflict resolutions or proactive actions
- detect_conflicts: Check if a proposed time conflicts with existing events
- suggest_resolution: Suggest alternative times for conflicting events

Guidelines:
- **ALWAYS use "${state.userId}" as the userId parameter when calling tools**
- **ALWAYS use "${state.conversationId}" as the conversationId parameter**
- **ALWAYS use "${state.newMessage?.id}" as the messageId parameter**
- **For priority messages, use senderId="${state.newMessage?.senderId}" and senderName="${state.newMessage?.senderName}"**

CRITICAL - Handling Updates:
- Read the recent conversation history to understand context
- If the new message modifies a previous event/deadline (e.g. "actually let's do 4pm instead"), use UPDATE tools, not CREATE
- Check currentDigest for existing events that match the conversation topic
- If similar event exists in currentDigest AND new message suggests a change, use update_calendar_event with the existing eventId
- Only create NEW items if there's no existing match

CRITICAL - RSVP Response Tracking:
- When someone RESPONDS to an invitation with phrases like:
  * YES: "I'm in", "count me in", "I'll be there", "yes", "sure", "sounds good"
  * NO: "can't make it", "sorry no", "I'm busy", "not available"
  * MAYBE: "maybe", "not sure", "depends", "I'll try"
- DO NOT create a new RSVP - find the existing one in currentDigest.rsvps
- Look at the RSVP's responsesJSON field to see who already responded
- Add the NEW person (use their senderName from newMessage) to the responses
- Call update_rsvp_responses with:
  * rsvpId: from currentDigest
  * responses: MERGE existing responses + new person's response
  
STEP BY STEP:
1. Check if RSVP exists in currentDigest.rsvps for this conversationId
2. Parse existing responsesJSON (might be empty "{}" or have existing responses)
3. Create new entry: "SenderName": {"response": "yes", "guestCount": 1, "note": null, "timestamp": "now"}
4. Merge with existing responses
5. Call update_rsvp_responses with complete merged object

Example: Existing RSVP has responsesJSON='{"Alice":{"response":"yes","guestCount":1,"note":null,"timestamp":"..."}}'
Bob says "I'm in!" → Call update_rsvp_responses with:
responses: {
  "Alice": {"response":"yes","guestCount":1,"note":null,"timestamp":"..."},
  "Bob": {"response":"yes","guestCount":1,"note":null,"timestamp":"2025-10-27T..."}
}

CRITICAL - Priority Detection:
- Treat ANY message that sounds urgent, time-sensitive, or safety-related as high priority even if wording is imperfect.
- Look for cues: all caps, exclamation points, words like "urgent", "emergency", "asap", "now", "immediately", "pick up", "need you", "doctor", "school nurse", etc.
- Handle misspellings or partial matches (e.g. "MERGENCY", "URGANT", "immediatly"). Use common sense.
- Call create_priority_message alongside any other tool calls when the message requires immediate attention. Provide a short reason like "Emergency pickup request".

CRITICAL - Conflict Detection & Resolution:
⚠️ ONLY check conflicts against DEVICE CALENDAR (calendarContext), NOT digest events!

Rules:
1. Ignore currentDigest.events for conflict detection - they are just suggestions, not real calendar events
2. ONLY check calendarContext for conflicts
3. If calendarContext is EMPTY or has NO events on the same day/time → NO CONFLICT, do NOT call detect_conflicts
4. If calendarContext HAS events with overlapping times → call detect_conflicts with ONLY:
   - The new proposed event
   - The conflicting calendarContext events (source: "device_calendar")
5. NEVER pass currentDigest.events to detect_conflicts - they don't exist on the calendar yet!

Steps when someone proposes a new event time:
1. Check calendarContext for events on the same day
2. If NO calendarContext events overlap → create the event, NO conflict
3. If calendarContext events DO overlap → call detect_conflicts, then create_suggestion with alternatives
4. NEVER create a conflict suggestion if the only "conflict" is with currentDigest.events

⏰ CRITICAL - Alternative Times for Conflicts:
- Alternatives MUST be on the SAME DAY as the proposed event (unless impossible)
- Look at calendarContext to find free slots on that same day
- Suggest times BEFORE and AFTER the conflicting time
- If no slots available on same day, suggest next available day
- Format: "October 28th at 2:00 PM" (include full date + time)

Example:
- calendarContext = [{"title": "Soccer Practice", "startDateTime": "2025-10-28T16:00:00-07:00", "endDateTime": "2025-10-28T17:00:00-07:00", "source": "device_calendar"}]
- New message: "Meeting at 4:30pm tomorrow" (tomorrow = Oct 28th)
- Proposed time: Oct 28 at 4:30pm overlaps with Soccer Practice (4pm-5pm)
- Call detect_conflicts with ONLY [proposed event, Soccer Practice]
- Create suggestion with alternatives ON OCT 28TH: ["October 28th at 2:00 PM", "October 28th at 3:00 PM", "October 28th at 5:30 PM"]

Counter-example (DO NOT DO THIS):
- currentDigest.events = [{"title": "Meeting proposal", "date": "2025-10-28T15:00:00-07:00"}]
- calendarContext = [] (empty)
- New message: "Another meeting at 3pm"
- NO CONFLICT! currentDigest events don't count! Do NOT call detect_conflicts!

Other Guidelines:
- Set confidence scores honestly (0-1)
- Infer context (e.g., who is the RSVP host based on who sent invitation)
- Only extract clear, actionable information
- For priority: urgent = needs immediate action (URGENT, ASAP, emergency), important = needs attention today
- Be aggressive about detecting priority - any time-sensitive request should be flagged
`
    : `You are an AI assistant helping a busy parent query their message history.

User query: "${state.query}"

You have access to:
- Recent messages from relevant conversations
- User's current digest (events, deadlines, RSVPs, etc.)
- Tools to create/update digest items

Answer naturally and use tools when appropriate.
`;

  const agentMessages = [
    { role: 'system', content: systemPrompt },
    ...state.messages.map((m: any) => ({
      role: 'user',
      content: `[${m.senderName} at ${new Date(m.timestamp).toLocaleString()}]: ${m.text}`
    }))
  ];
  
  console.log(`🔍 Prepared prompt for LLM:
    Mode: ${state.mode}
    New Message: "${state.newMessage?.text}"
    From: ${state.newMessage?.senderName} (${state.newMessage?.senderId})
    Message ID: ${state.newMessage?.id}
    Timestamp: ${state.newMessage?.timestamp}
    Context messages: ${state.messages.length}
    Current digest events: ${state.currentDigest?.events?.length || 0}
    Current digest priority: ${state.currentDigest?.priorityMessages?.length || 0}
    Calendar context events: ${state.calendarContext?.length || 0}
  `);
  
  if (state.calendarContext && state.calendarContext.length > 0) {
    console.log(`📅 Calendar events for conflict checking:`);
    state.calendarContext.forEach((evt: any) => {
      console.log(`  - "${evt.title}" from ${evt.startDateTime} to ${evt.endDateTime} (source: ${evt.source || 'unknown'})`);
    });
  } else {
    console.log(`📅 No calendar events in context (calendarContext is empty)`);
  }
  
  return {
    ...state,
    agentMessages
  };
}

// Node: Invoke LLM with tool binding (dynamic import to avoid tsc OOM)
async function callLLM(state: any) {
  const { ChatOpenAI } = await import("@langchain/openai");
  const llm = new ChatOpenAI({
    modelName: "gpt-4o",
    temperature: 0.2,
  }).bind({
    tools: [
      createCalendarEventTool,
      updateCalendarEventTool,
      createDeadlineTool,
      updateDeadlineTool,
      createPriorityMessageTool,
      createRSVPTool,
      updateRSVPResponsesTool,
      createSuggestionTool,
      detectConflictsTool,
      suggestResolutionTool,
      // decisionSummarizeTool (bind during ai_chat mode only later if needed)
    ],
  });

  const response = await llm.invoke(state.agentMessages);
  const toolCalls = (response as any).tool_calls || [];
  
  console.log(`🤖 LLM Response:
    Tool calls detected: ${toolCalls.length}
    ${toolCalls.map((tc: any, i: number) => `
      ${i + 1}. ${tc.name} with args: ${JSON.stringify(tc.args)}`).join('')}
  `);
  
  return {
    ...state,
    agentMessages: [...state.agentMessages, response],
    toolCalls,
  };
}

// Node: Execute tools
async function executeTools(state: any) {
  if (!state.toolCalls || state.toolCalls.length === 0) {
    console.log('⚠️ No tool calls to execute');
    return state;
  }
  
  const tools = [
    createCalendarEventTool,
    updateCalendarEventTool,
    createDeadlineTool,
    updateDeadlineTool,
    createPriorityMessageTool,
    createRSVPTool,
    updateRSVPResponsesTool,
    createSuggestionTool,
    detectConflictsTool,
    suggestResolutionTool,
  ];

  const { ToolMessage } = await import("@langchain/core/messages");
  const toolMessages: any[] = [];
  
  console.log(`\n🔧 Executing ${state.toolCalls.length} tool(s)...`);
  
  for (const toolCall of state.toolCalls || []) {
    const tool = tools.find(t => (t as any).name === toolCall.name);
    if (!tool) {
      console.error(`❌ Tool not found: ${toolCall.name}`);
      continue;
    }
    
    console.log(`  → ${toolCall.name}(${JSON.stringify(toolCall.args).substring(0, 100)}...)`);
    
    try {
      const result = await (tool as any).invoke(toolCall.args);
      console.log(`  ✅ ${toolCall.name} succeeded: ${result}`);
      toolMessages.push(
        new ToolMessage({
          content: typeof result === 'string' ? result : JSON.stringify(result),
          tool_call_id: toolCall.id,
        })
      );
    } catch (error) {
      const errMsg = (error as Error).message;
      console.error(`  ❌ ${toolCall.name} failed: ${errMsg}`);
      console.error(`  Error details:`, error);
      toolMessages.push(
        new ToolMessage({
          content: `Error: ${errMsg}`,
          tool_call_id: toolCall.id,
        })
      );
    }
  }
  
  console.log(`✅ Tool execution complete\n`);
  
  return {
    ...state,
    agentMessages: [...state.agentMessages, ...toolMessages],
    toolCalls: [],
  };
}

// Node: Determine if done
function shouldContinue(state: any): string {
  if (state.toolCalls && state.toolCalls.length > 0) {
    return "executeTools";
  }
  
  if (state.mode === 'ai_chat') {
    return "formatOutput";
  }
  
  return "END";
}

// Node: Format output (for AI chat)
async function formatOutput(state: any) {
  const lastMessage = state.agentMessages[state.agentMessages.length - 1];
  
  return {
    ...state,
    output: {
      response: lastMessage.content,
      toolsUsed: state.agentMessages.filter((m: any) => m.role === 'function').length,
    }
  };
}

// Build workflow
export const createUnifiedAgent = () => {
  const workflowFactory = async () => {
    const { StateGraph, END } = await import("@langchain/langgraph");
    const workflow = new (StateGraph as any)({
    channels: {
      mode: null,
      userId: null,
      conversationId: null,
      newMessage: null,
      query: null,
      messages: null,
      currentDigest: null,
      calendarContext: null,
      agentMessages: null,
      toolCalls: null,
      output: null,
    }
    });
    
    workflow.addNode("preparePrompt", preparePrompt);
    workflow.addNode("callLLM", callLLM);
    workflow.addNode("executeTools", executeTools);
    workflow.addNode("formatOutput", formatOutput);
    
    workflow.setEntryPoint("preparePrompt");
    workflow.addEdge("preparePrompt", "callLLM");
    workflow.addConditionalEdges("callLLM", shouldContinue, {
      executeTools: "executeTools",
      formatOutput: "formatOutput",
      END: END,
    });
    workflow.addEdge("executeTools", "callLLM"); // Loop back for multi-step reasoning
    workflow.addEdge("formatOutput", END);
    
    return workflow.compile();
  };

  // Return a proxy that compiles workflow on first invoke
  let app: any = null;
  return {
    invoke: async (state: AgentState) => {
      if (!app) app = await workflowFactory();
      return app.invoke(state as any);
    }
  } as any;
};

