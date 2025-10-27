import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { createSimpleAgent } from '../agent/simpleAgent';
import { getFirestore } from 'firebase-admin/firestore';

interface AIChatQueryRequest {
  userId: string;
  query: string;
  enabledThreadIds: string[];
  recentMessagesByThread: Record<string, any[]>; // iOS provides recent messages per thread
}

/**
 * Query AI assistant (ai_chat mode)
 * Called by iOS from AI Chat interface
 */
const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');

export const aiChatQuery = onCall<AIChatQueryRequest>({
  secrets: [OPENAI_API_KEY],
},
  async (request) => {
    const { userId, query, enabledThreadIds, recentMessagesByThread } = request.data;
    
    // 1. Validate
    if (!userId || !query) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }
    
    console.log(`💬 AI Chat query from user ${userId}: "${query}"`);
    
    // 2. Prepare cross-thread context
    const allMessages: any[] = [];
    for (const threadId of enabledThreadIds) {
      const threadMessages = recentMessagesByThread[threadId] || [];
      allMessages.push(...threadMessages);
    }
    
    // Sort by timestamp
    allMessages.sort((a, b) => a.timestamp - b.timestamp);
    
    // 3. Get digest state
    const db = getFirestore();
    const digestRef = db.collection('users').doc(userId).collection('digest');
    
    const [eventsSnap, deadlinesSnap, prioritySnap, rsvpsSnap] = await Promise.all([
      digestRef.doc('events').collection('items').get(),
      digestRef.doc('deadlines').collection('items').get(),
      digestRef.doc('priorityMessages').collection('items').get(),
      digestRef.doc('rsvps').collection('items').get(),
    ]);
    
    const currentDigest = {
      events: eventsSnap.docs.map(d => ({ id: d.id, ...d.data() })),
      deadlines: deadlinesSnap.docs.map(d => ({ id: d.id, ...d.data() })),
      priorityMessages: prioritySnap.docs.map(d => ({ id: d.id, ...d.data() })),
      rsvps: rsvpsSnap.docs.map(d => ({ id: d.id, ...d.data() })),
    };
    
    // 4. Invoke simple agent
    const agent = createSimpleAgent();
    
    try {
      const result = await agent.invoke({
        mode: 'ai_chat',
        userId,
        query,
        messages: allMessages,
        currentDigest,
        agentMessages: [],
        toolCalls: [],
        output: null,
      });
      
      console.log(`✅ AI Chat responded with ${result.output?.toolsUsed || 0} tool calls`);
      
      return {
        response: result.output?.response || "I couldn't process that query.",
        toolsUsed: result.output?.toolsUsed || 0,
      };
    } catch (error) {
      console.error('Agent execution error:', error);
      throw new HttpsError('internal', `Agent failed: ${(error as Error).message}`);
    }
  }
);

