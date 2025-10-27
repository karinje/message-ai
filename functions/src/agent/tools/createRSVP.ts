import { getFirestore } from 'firebase-admin/firestore';

export async function createRSVP(args: any) {
  const { userId, eventId, eventTitle, eventDate, conversationId, messageId, isHost } = args || {};
  const db = getFirestore();
  const rsvpId = `rsvp_${Date.now()}_${Math.random().toString(36).substring(7)}`;
  await db.collection('users').doc(userId)
    .collection('digest').doc('rsvps')
    .collection('items').doc(rsvpId)
    .set({
      eventId,
      eventTitle,
      eventDate: new Date(eventDate),
      conversationId,
      messageId,
      isHost,
      responsesJSON: "{}",
      totalInvited: 0,
      createdAt: new Date(),
    });
  console.log(`✅ Created RSVP tracking for "${eventTitle}"`);
  return { rsvpId };
}

