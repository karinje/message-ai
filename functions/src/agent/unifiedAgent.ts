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

NEW MESSAGE to analyze:
- From: ${state.newMessage?.senderName} (ID: ${state.newMessage?.senderId})
- Text: "${state.newMessage?.text}"
- Message ID: ${state.newMessage?.id}
- Timestamp: ${state.newMessage?.timestamp}

Context:
- User ID: ${state.userId}
- Conversation ID: ${state.conversationId}
- Recent conversation history: ${state.messages.length} messages
- Current user digest state: ${JSON.stringify(state.currentDigest)}
- Upcoming calendar events (${state.calendarContext?.length || 0}): ${JSON.stringify(state.calendarContext ?? [])}

Tools available:
- create_calendar_event: Create NEW events (check currentDigest to avoid duplicates!)
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

CRITICAL - Conflict Detection & Resolution:
- ONLY check for conflicts if there are BOTH:
  1. A new event being proposed with a specific time
  2. Existing events either in currentDigest.events OR in the user's device calendar (calendarContext)
- A conflict exists ONLY if two events have OVERLAPPING TIME RANGES (same hour or overlapping intervals).
- Use calendarContext events as authoritative device calendar data. Do NOT assume conflicts if no overlap exists.
- Steps:
  1. Gather all relevant existing events (currentDigest.events + calendarContext) occurring on the same day.
  2. Convert times to the same timezone (ISO strings already include offsets). Compare start/end ranges precisely.
  3. If an overlap exists, call detect_conflicts with the proposed event and the conflicting ones, including source information.
  4. If detect_conflicts reports hasConflicts, call suggest_resolution with 3 open slots based on actual gaps around the conflicting times. Prefer suggestions that avoid other calendarContext events and respect typical hours (8am-8pm).
  5. Only create ONE suggestion per conflicting proposed event.
  6. If detect_conflicts returns hasConflicts=false, DO NOT create a suggestion.
- DO NOT call detect_conflicts or suggest_resolution if there is no real overlap.

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
  
  for (const toolCall of state.toolCalls || []) {
    const tool = tools.find(t => (t as any).name === toolCall.name);
    if (!tool) continue;
    try {
      const result = await (tool as any).invoke(toolCall.args);
      toolMessages.push(
        new ToolMessage({
          content: typeof result === 'string' ? result : JSON.stringify(result),
          tool_call_id: toolCall.id,
        })
      );
    } catch (error) {
      console.error(`Tool execution error (${toolCall.name}):`, error);
      toolMessages.push(
        new ToolMessage({
          content: `Error: ${(error as Error).message}`,
          tool_call_id: toolCall.id,
        })
      );
    }
  }
  
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

