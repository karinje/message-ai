import { getFirestore } from 'firebase-admin/firestore';

export async function createPriorityMessage(args: any) {
  const { userId, messageId, messageText, priority, reason, conversationId, senderId, senderName, timestamp } = args || {};
  const db = getFirestore();
  await db.collection('users').doc(userId)
    .collection('digest').doc('priorityMessages')
    .collection('items').doc(messageId)
    .set({
      messageText,
      priority,
      reason,
      conversationId,
      senderId,
      senderName,
      timestamp: new Date(timestamp),
      requiresAction: priority === 'urgent',
      status: 'pending',
    });
  console.log(`✅ Marked message as ${priority} priority`);
  return { messageId };
}

