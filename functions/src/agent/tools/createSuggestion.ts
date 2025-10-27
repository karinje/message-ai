import { tool } from "@langchain/core/tools";
import z from "zod";
import { getFirestore } from 'firebase-admin/firestore';

export const createSuggestionTool = tool(
  async ({ userId, type, priority, description, options }) => {
    const db = getFirestore();
    const suggestionId = `sug_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    const optionsJSON = JSON.stringify(options ?? []);
    console.log(`📝 Creating suggestion with ${options?.length || 0} options`);
    console.log(`   Options array: ${JSON.stringify(options)}`);
    console.log(`   optionsJSON string: ${optionsJSON}`);
    await db.collection('users').doc(userId)
      .collection('digest').doc('suggestions')
      .collection('items').doc(suggestionId)
      .set({
        type,
        priority,
        suggestionDescription: description,
        optionsJSON: optionsJSON,
        status: 'pending',
        createdAt: new Date(),
      });
    console.log(`✅ Created suggestion: ${description}`);
    return `Created suggestion: ${description}`;
  },
  {
    name: "create_suggestion",
    description: "Create a proactive suggestion for the user.",
    schema: z.object({
      userId: z.string(),
      type: z.enum(['conflict_resolution', 'reminder', 'proactive']),
      priority: z.enum(['high', 'medium', 'low']),
      description: z.string(),
      options: z.array(z.string()).default([]),
    }),
  }
);

