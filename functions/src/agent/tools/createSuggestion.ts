import { getFirestore } from 'firebase-admin/firestore';

export async function createSuggestion(args: any) {
  const { userId, type, priority, description, options } = args || {};
  const db = getFirestore();
  const suggestionId = `sug_${Date.now()}_${Math.random().toString(36).substring(7)}`;
  await db.collection('users').doc(userId)
    .collection('digest').doc('suggestions')
    .collection('items').doc(suggestionId)
    .set({
      type,
      priority,
      suggestionDescription: description,
      optionsJSON: JSON.stringify(options || []),
      status: 'pending',
      createdAt: new Date(),
    });
  console.log(`✅ Created suggestion: ${description}`);
  return { suggestionId };
}

