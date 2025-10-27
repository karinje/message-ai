import { getFirestore } from 'firebase-admin/firestore';

export async function createCalendarEvent(args: any) {
  const { userId, title, date, time, location, conversationId, messageId, confidence } = args || {};
  const db = getFirestore();
  const eventId = `evt_${Date.now()}_${Math.random().toString(36).substring(7)}`;
  await db.collection('users').doc(userId)
    .collection('digest').doc('events')
    .collection('items').doc(eventId)
    .set({
      title,
      date: new Date(date),
      time,
      location,
      conversationId,
      messageId,
      confidence,
      status: 'pending',
      addedToCalendar: false,
      createdAt: new Date(),
      lastMentionedAt: new Date(),
    });
  console.log(`✅ Created calendar event "${title}" with ID ${eventId}`);
  return { eventId };
}

