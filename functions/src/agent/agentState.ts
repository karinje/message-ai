/**
 * Agent State for LangGraph
 */
export interface AgentState {
  mode: 'background_processing' | 'ai_chat';
  userId: string;
  conversationId?: string;
  newMessage?: any;
  query?: string;
  messages: any[]; // Recent + semantic matches
  currentDigest: {
    events: any[];
    deadlines: any[];
    priorityMessages: any[];
    rsvps: any[];
  };
  agentMessages: any[];
  toolCalls: any[];
  output: any;
}

