import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { createUnifiedAgent } from '../agent/unifiedAgent';
// import { getFirestore } from 'firebase-admin/firestore';
import { prepareAgentContext } from '../utils_new/contextPreparation';

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
    
    // 3. Prepare context with recent messages
    const ctx = await prepareAgentContext('ai_chat', userId, {
      recentMessages: allMessages,
      query,
    });
    
    // 4. Invoke unified LangGraph agent
    const agent = createUnifiedAgent();
    
    try {
      const result = await agent.invoke({
        mode: 'ai_chat',
        userId,
        query,
        messages: ctx.messages,
        currentDigest: ctx.currentDigest,
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

