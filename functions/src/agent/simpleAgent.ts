import OpenAI from "openai";
import { AgentState } from "./agentState";
import { createCalendarEvent, createDeadline, createPriorityMessage, createRSVP, createSuggestion } from "./tools/tools";

/**
 * Simple agent without LangGraph (to avoid memory issues during compilation)
 * This is a lightweight version that works immediately
 */

export const createSimpleAgent = () => {
  return {
    invoke: async (state: AgentState) => {
      const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });

      // Prepare system prompt
      const systemPrompt = state.mode === 'background_processing'
        ? `You are an AI assistant analyzing a new message for a busy parent.
Extract calendar events, deadlines, priority markers, RSVP events.

New message: "${state.newMessage?.text}"
Current digest: ${JSON.stringify(state.currentDigest)}

Guidelines:
- Check currentDigest to avoid duplicates
- Set confidence scores (0-1)
- Only extract clear, actionable information`
        : `You are an AI assistant helping a busy parent query their messages.

Query: "${state.query}"
Digest: ${JSON.stringify(state.currentDigest)}

Answer naturally and use tools when appropriate.`;

      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        temperature: 0.2,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: state.messages.map(m => `[${m.senderName}]: ${m.text}`).join("\n") }
        ],
        response_format: { type: "json_object" },
      });

      // Expect JSON with tools array
      const raw = response.choices[0]?.message?.content || "{}";
      let parsed: any = {};
      try { parsed = JSON.parse(raw); } catch {}
      const tools = Array.isArray(parsed.tools) ? parsed.tools : [];

      for (const call of tools) {
        try {
          switch (call.name) {
            case "create_calendar_event":
              await createCalendarEvent(call.args);
              break;
            case "create_deadline":
              await createDeadline(call.args);
              break;
            case "create_priority_message":
              await createPriorityMessage(call.args);
              break;
            case "create_rsvp":
              await createRSVP(call.args);
              break;
            case "create_suggestion":
              await createSuggestion(call.args);
              break;
          }
        } catch (e) {
          console.error("Tool exec error", e);
        }
      }

      return {
        ...state,
        output: {
          response: parsed.response || "Processed",
          toolsUsed: tools.length,
        }
      };
    }
  };
};

