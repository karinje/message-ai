import { tool } from "@langchain/core/tools";
import z from "zod";
import { getFirestore } from 'firebase-admin/firestore';

export const createDeadlineTool = tool(
  async ({ userId, task, dueDate, priority, assignedTo, conversationId, messageId, confidence }) => {
    const db = getFirestore();
    const deadlineId = `dl_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    
    // Handle timezone for deadline dates - always Pacific Time
    let parsedDueDate: Date;
    try {
      // Check if date already includes a timezone offset (+ or -)
      if (dueDate.includes('+') || (dueDate.includes('-') && dueDate.lastIndexOf('-') > 10)) {
        // Already has timezone, use it directly
        parsedDueDate = new Date(dueDate);
      } else if (dueDate.includes('T')) {
        // ISO format but no timezone - assume Pacific Time
        const dateTimeStr = `${dueDate}-07:00`;
        parsedDueDate = new Date(dateTimeStr);
      } else {
        // Date only, set to end of day Pacific Time
        parsedDueDate = new Date(`${dueDate}T23:59:59-07:00`);
      }
      
      if (isNaN(parsedDueDate.getTime())) {
        throw new Error('Invalid date');
      }
      
      console.log(`⏰ Deadline parsed: ${parsedDueDate.toISOString()} (input: "${dueDate}")`);
    } catch (e) {
      console.error('Error parsing deadline dueDate:', e);
      parsedDueDate = new Date();
    }
    
    const data = {
      task,
      dueDate: parsedDueDate,
      priority: priority ?? 'medium',
      assignedTo: assignedTo ?? userId,
      conversationId,
      messageId,
      confidence,
      status: 'pending',
      completed: false,
      createdAt: new Date(),
    };
    
    console.log(`📝 Writing deadline to Firestore: users/${userId}/digest/deadlines/items/${deadlineId}`);
    console.log(`   Data:`, JSON.stringify(data, null, 2));
    
    await db.collection('users').doc(userId)
      .collection('digest').doc('deadlines')
      .collection('items').doc(deadlineId)
      .set(data);
      
    console.log(`✅ Created deadline "${task}" with ID ${deadlineId}`);
    return `Created deadline "${task}" with ID ${deadlineId}`;
  },
  {
    name: "create_deadline",
    description: "Create a new deadline/task in the user's digest. IMPORTANT: For 'dueDate', provide ISO 8601 timestamp with Pacific timezone (e.g., '2025-10-28T23:59:59-07:00'). If only a date is known, use end of day Pacific time.",
    schema: z.object({
      userId: z.string(),
      task: z.string(),
      dueDate: z.string().describe("ISO 8601 timestamp with Pacific timezone (e.g., '2025-10-28T23:59:59-07:00')"),
      priority: z.enum(['high', 'medium', 'low']).default('medium'),
      assignedTo: z.string().nullable(),
      conversationId: z.string(),
      messageId: z.string(),
      confidence: z.number().min(0).max(1),
    }),
  }
);

