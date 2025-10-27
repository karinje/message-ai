// @ts-nocheck
import { StateGraph, END } from "@langchain/langgraph";
import OpenAI from "openai";
import type { AgentState } from "./agentState";
import { createCalendarEvent } from "./tools/createCalendarEvent";
import { createDeadline } from "./tools/createDeadline";
import { createPriorityMessage } from "./tools/createPriorityMessage";
import { createRSVP } from "./tools/createRSVP";
import { createSuggestion } from "./tools/createSuggestion";

/**
 * Create unified LangGraph agent
 * PR #29: Complete implementation with tools and workflow
 */

// Node: Prepare system prompt
async function preparePrompt(state: any) {
  const systemPrompt = state.mode === 'background_processing'
    ? `You are an AI assistant analyzing a new message in a conversation for a busy parent.
Your job is to extract calendar events, deadlines, priority markers, RSVP events, and detect conflicts.

Context:
- New message: "${state.newMessage?.text}"
- Recent conversation history: ${state.messages.length} messages
- Current user digest state: ${JSON.stringify(state.currentDigest)}

Tools available:
- create_calendar_event: Create new events (avoid duplicates by checking currentDigest!)
- create_deadline: Create deadlines/tasks
- create_priority_message: Mark urgent/important messages
- create_rsvp: Track RSVP events
- create_suggestion: Suggest conflict resolutions or proactive actions

Guidelines:
- Check currentDigest before creating duplicates
- Set confidence scores honestly (0-1)
- Infer context (e.g., who is the RSVP host based on who sent invitation)
- Only extract clear, actionable information
- For priority: urgent = needs immediate action, important = needs attention today
`
    : `You are an AI assistant helping a busy parent query their message history.

User query: "${state.query}"

You have access to:
- Recent messages from relevant conversations
- User's current digest (events, deadlines, RSVPs, etc.)
- Tools to create/update digest items

Answer naturally and use tools when appropriate.
`;

  return {
    ...state,
    agentMessages: [
      { role: 'system', content: systemPrompt },
      ...state.messages.map(m => ({
        role: 'user',
        content: `[${m.senderName} at ${new Date(m.timestamp).toLocaleString()}]: ${m.text}`
      }))
    ]
  };
}

// Node: Invoke LLM (JSON tool plan)
async function callLLM(state: any) {
  const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });
  const response = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0.2,
    messages: state.agentMessages,
    response_format: { type: "json_object" },
  });

  const raw = response.choices[0]?.message?.content || "{}";
  let parsed: any = {};
  try { parsed = JSON.parse(raw); } catch {}
  const tools = Array.isArray(parsed.tools) ? parsed.tools : [];

  return {
    ...state,
    agentMessages: [...state.agentMessages, { role: 'assistant', content: raw }],
    toolCalls: tools,
    output: parsed.response ? { response: parsed.response } : state.output,
  };
}

// Node: Execute tools
async function executeTools(state: any) {
  if (!state.toolCalls || state.toolCalls.length === 0) {
    return state;
  }
  
  const toolResults: any[] = [];
  for (const call of state.toolCalls || []) {
    try {
      let result: any = null;
      switch (call.name) {
        case 'create_calendar_event':
          result = await createCalendarEvent(call.args);
          break;
        case 'create_deadline':
          result = await createDeadline(call.args);
          break;
        case 'create_priority_message':
          result = await createPriorityMessage(call.args);
          break;
        case 'create_rsvp':
          result = await createRSVP(call.args);
          break;
        case 'create_suggestion':
          result = await createSuggestion(call.args);
          break;
      }
      toolResults.push({ tool: call.name, result });
    } catch (error) {
      console.error(`Tool execution error (${call.name}):`, error);
      toolResults.push({ tool: call.name, result: `Error: ${(error as Error).message}` });
    }
  }
  
  return {
    ...state,
    agentMessages: [
      ...state.agentMessages,
      {
        role: 'function',
        content: JSON.stringify(toolResults),
      }
    ],
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
  
  return END;
}

// Node: Format output (for AI chat)
async function formatOutput(state: any) {
  const lastMessage = state.agentMessages[state.agentMessages.length - 1];
  
  return {
    ...state,
    output: {
      response: lastMessage.content,
      toolsUsed: state.agentMessages.filter(m => m.role === 'function').length,
    }
  };
}

// Build workflow
export const createUnifiedAgent = () => {
  const workflow = new StateGraph<any>({
    channels: {
      mode: null,
      userId: null,
      conversationId: null,
      newMessage: null,
      query: null,
      messages: null,
      currentDigest: null,
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
    [END]: END,
  });
  workflow.addEdge("executeTools", "callLLM"); // Loop back for multi-step reasoning
  workflow.addEdge("formatOutput", END);
  
  return workflow.compile();
};

