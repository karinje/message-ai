import { tool } from "@langchain/core/tools";
import z from "zod";

export const decisionSummarizeTool = tool(
  async ({ conversationId, messages }) => {
    // TODO: Implement actual decision summarization logic
    return `Summarized ${messages.length} messages for conversation ${conversationId}.`;
  },
  {
    name: "decision_summarize",
    description: "Summarize decisions made in a conversation using provided messages.",
    schema: z.object({
      conversationId: z.string(),
      messages: z.array(z.object({ id: z.string().nullable(), text: z.string() }))
    })
  }
);



