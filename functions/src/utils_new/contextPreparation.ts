import { getFirestore } from 'firebase-admin/firestore';
import { semanticSearch } from './pinecone';

export const prepareAgentContext = async (
  mode: 'background_processing' | 'ai_chat',
  userId: string,
  params: {
    conversationId?: string;
    newMessage?: any;
    recentMessages?: any[];
    query?: string;
    calendarEvents?: Array<{
      id: string;
      title: string;
      startDateTime: string;
      endDateTime: string;
      location?: string;
      calendarTitle?: string;
      source?: string;
    }>;
  }
) => {
  const recentMessages = params.recentMessages || [];
  const calendarEvents = params.calendarEvents || [];

  // Semantic matches only when processing a new message with a conversation
  let semanticMatches: any[] = [];
  if (mode === 'background_processing' && params.newMessage && params.conversationId) {
    try {
      const matches = await semanticSearch(
        params.newMessage.text,
        params.conversationId,
        userId,
        20
      );
      // Include matched messages as minimal context lines using metadata stored in index
      semanticMatches = matches
        .filter((m: any) => m?.metadata)
        .map((m: any) => ({
          id: m.id,
          text: m.metadata.text,
          conversationId: m.metadata.conversationId,
          senderId: m.metadata.senderId,
          senderName: m.metadata.senderName,
          timestamp: m.metadata.timestamp,
        }));
    } catch (e) {
      console.warn('semanticSearch failed, continuing without RAG', (e as Error).message);
    }
  }

  // Digest state - NO events (conflict detection uses calendarContext only)
  const db = getFirestore();
  const digestRef = db.collection('users').doc(userId).collection('digest');
  const [deadlinesSnap, prioritySnap, rsvpsSnap, suggestionsSnap] = await Promise.all([
    digestRef.doc('deadlines').collection('items').get(),
    digestRef.doc('priorityMessages').collection('items').get(),
    digestRef.doc('rsvps').collection('items').get(),
    digestRef.doc('suggestions').collection('items').get(),
  ]);

  // Filter items by status - only pending items
  // NO EVENTS in digest context - conflicts should ONLY use calendarContext (device calendar)
  const currentDigest = {
    events: [], // Empty - conflict detection uses calendarContext ONLY
    deadlines: deadlinesSnap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter((d: any) => d.status === 'pending'),
    priorityMessages: prioritySnap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter((p: any) => p.status === 'pending'),
    rsvps: rsvpsSnap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter((r: any) => r.status === 'pending'),
    suggestions: suggestionsSnap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter((s: any) => s.status === 'pending'),
  };

  // Merge, dedupe, sort
  const byId = new Map<string, any>();
  for (const m of [...recentMessages, ...semanticMatches]) {
    if (!m?.id) continue;
    if (!byId.has(m.id)) byId.set(m.id, m);
  }
  const messages = Array.from(byId.values()).sort((a, b) => a.timestamp - b.timestamp);

  const now = new Date();
  const calendarContext = calendarEvents
    .map(event => {
      try {
        const start = new Date(event.startDateTime);
        const end = new Date(event.endDateTime);
        return { ...event, start, end };
      } catch {
        return null;
      }
    })
    .filter((e): e is typeof calendarEvents[number] & { start: Date; end: Date } => !!e)
    .filter(e => e.end > now)
    .sort((a, b) => a.start.getTime() - b.start.getTime())
    .slice(0, 50)
    .map(({ start, end, ...rest }) => ({ ...rest, startDateTime: start.toISOString(), endDateTime: end.toISOString() }));

  return {
    messages,
    currentDigest,
    semanticMatchIds: semanticMatches.map(m => m.id),
    calendarContext,
  };
};



