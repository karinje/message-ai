import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { createUnifiedAgent } from '../agent/unifiedAgent';
import { embedMessage } from '../utils_new/pinecone';
import { prepareAgentContext } from '../utils_new/contextPreparation';
// import { getFirestore } from 'firebase-admin/firestore';

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
  recentMessages: any[];
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
    const { userId, conversationId, newMessage, recentMessages, calendarEvents = [] } = request.data;
    
    // 1. Validate
    if (!userId || !conversationId || !newMessage) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }
    
    console.log(`🤖 Processing message ${newMessage.id} for user ${userId}
      Sender: ${newMessage.senderName} (${newMessage.senderId})
      Text: "${newMessage.text}"
      Timestamp: ${newMessage.timestamp}
      Recent messages count: ${recentMessages?.length || 0}
      Calendar events provided: ${calendarEvents.length}
    `);
    
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
    
    // 3. Prepare context with semantic RAG
    const ctx = await prepareAgentContext('background_processing', userId, {
      conversationId,
      newMessage,
      recentMessages,
      calendarEvents,
    });
    
    // 4. Invoke unified LangGraph agent
    const agent = createUnifiedAgent();
    
    try {
      const result = await agent.invoke({
        mode: 'background_processing',
        userId,
        conversationId,
        newMessage,
        messages: ctx.messages,
        currentDigest: ctx.currentDigest,
        calendarContext: ctx.calendarContext,
        agentMessages: [],
        toolCalls: [],
        output: null,
      });
      
      console.log(`✅ Agent processed message with ${result.agentMessages.filter((m: any) => m.role === 'function').length} tool calls`);
      
      return {
        success: true,
        semanticMatchIds: ctx.semanticMatchIds,
        toolCallsExecuted: result.agentMessages.filter((m: any) => m.role === 'function').length,
      };
    } catch (error) {
      console.error('Agent execution error:', error);
      throw new HttpsError('internal', `Agent failed: ${(error as Error).message}`);
    }
  }
);

