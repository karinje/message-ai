import { getFirestore } from 'firebase-admin/firestore';

export async function createDeadline(args: any) {
  const { userId, task, dueDate, priority, assignedTo, conversationId, messageId, confidence } = args || {};
  const db = getFirestore();
  const deadlineId = `dl_${Date.now()}_${Math.random().toString(36).substring(7)}`;
  await db.collection('users').doc(userId)
    .collection('digest').doc('deadlines')
    .collection('items').doc(deadlineId)
    .set({
      task,
      dueDate: new Date(dueDate),
      priority: priority || 'medium',
      assignedTo: assignedTo || userId,
      conversationId,
      messageId,
      confidence,
      status: 'pending',
      completed: false,
      createdAt: new Date(),
    });
  console.log(`✅ Created deadline "${task}" with ID ${deadlineId}`);
  return { deadlineId };
}

