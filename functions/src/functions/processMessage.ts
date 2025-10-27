import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { createSimpleAgent } from '../agent/simpleAgent';
import { embedMessage } from '../utils_new/pinecone';
import { getFirestore } from 'firebase-admin/firestore';

interface ProcessMessageRequest {
  userId: string;
  conversationId: string;
  newMessage: {
    id: string;
    text: string;
    senderId: string;
    senderName: string;
    timestamp: number;
  };
  recentMessages: any[]; // From SwiftData (last 50)
}

/**
 * Process new message through unified agent (background processing mode)
 * Called by iOS when AI indexing is enabled for a conversation
 */
const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');
const PINECONE_API_KEY = defineSecret('PINECONE_API_KEY');

export const processMessage = onCall<ProcessMessageRequest>({
  secrets: [OPENAI_API_KEY, PINECONE_API_KEY],
},
  async (request) => {
    const { userId, conversationId, newMessage, recentMessages } = request.data;
    
    // 1. Validate
    if (!userId || !conversationId || !newMessage) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }
    
    console.log(`🤖 Processing message ${newMessage.id} for user ${userId}`);
    
    // 2. Embed new message to Pinecone for RAG
    try {
      await embedMessage({
        ...newMessage,
        conversationId,
      });
    } catch (error) {
      console.error('Error embedding message:', error);
      // Continue even if embedding fails
    }
    
    // 3. Get current digest state
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
        mode: 'background_processing',
        userId,
        conversationId,
        newMessage,
        messages: recentMessages,
        currentDigest,
        agentMessages: [],
        toolCalls: [],
        output: null,
      });
      
      console.log(`✅ Agent processed message with ${result.agentMessages.filter((m: any) => m.role === 'function').length} tool calls`);
      
      return {
        success: true,
        toolCallsExecuted: result.agentMessages.filter((m: any) => m.role === 'function').length,
      };
    } catch (error) {
      console.error('Agent execution error:', error);
      throw new HttpsError('internal', `Agent failed: ${(error as Error).message}`);
    }
  }
);

