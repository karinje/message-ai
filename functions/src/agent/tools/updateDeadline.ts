import { tool } from "@langchain/core/tools";
import z from "zod";
import { getFirestore } from 'firebase-admin/firestore';

export const updateDeadlineTool = tool(
  async ({ userId, deadlineId, updates }) => {
    const db = getFirestore();
    const payload: Record<string, unknown> = {};

    if (updates.task !== undefined) payload.task = updates.task;
    if (updates.dueDate !== undefined) payload.dueDate = updates.dueDate ? new Date(updates.dueDate) : null;
    if (updates.priority !== undefined) payload.priority = updates.priority;
    if (updates.assignedTo !== undefined) payload.assignedTo = updates.assignedTo;
    if (updates.status !== undefined) payload.status = updates.status;
    if (updates.completed !== undefined) payload.completed = updates.completed;
    if (updates.confidence !== undefined) payload.confidence = updates.confidence;

    await db.collection('users').doc(userId)
      .collection('digest').doc('deadlines')
      .collection('items').doc(deadlineId)
      .update(payload);
    return `Updated deadline ${deadlineId}`;
  },
  {
    name: "update_deadline",
    description: "Update an existing deadline/task.",
    schema: z.object({
      userId: z.string(),
      deadlineId: z.string(),
      updates: z.object({
        task: z.string().nullable(),
        dueDate: z.string().nullable(),
        priority: z.enum(['high','medium','low']).nullable(),
        assignedTo: z.string().nullable(),
        status: z.enum(['pending','completed','dismissed']).nullable(),
        completed: z.boolean().nullable(),
        confidence: z.number().min(0).max(1).nullable(),
      })
    })
  }
);



