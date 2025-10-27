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
    suggestions: any[];
  };
  calendarContext?: Array<{
    id: string;
    title: string;
    startDateTime: string;
    endDateTime: string;
    location?: string;
    calendarTitle?: string;
    source?: string;
  }>;
  agentMessages: any[];
  toolCalls: any[];
  output: any;
}

