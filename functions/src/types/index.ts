// Type definitions for Weftly Firebase Functions

export interface Message {
  id: string;
  text: string;
  senderId: string;
  senderName?: string;
  timestamp: FirebaseFirestore.Timestamp | Date;
  conversationId: string;
  status?: "pending" | "sent" | "delivered" | "read";
  imageUrl?: string;
  replyTo?: string;
}

export interface Conversation {
  id: string;
  participants: string[];
  participantNames?: Record<string, string>;
  type: "direct" | "group";
  groupName?: string;
  lastMessage?: string;
  lastMessageTimestamp?: FirebaseFirestore.Timestamp | Date;
  unreadCount?: Record<string, number>;
}

export interface User {
  id: string;
  email: string;
  displayName: string;
  phoneNumber?: string;
  photoURL?: string;
  fcmToken?: string;
  about?: string;
  status?: "online" | "offline";
  lastSeen?: FirebaseFirestore.Timestamp | Date;
}

export interface ExtractedEvent {
  id: string;
  conversationId: string;
  messageId: string;
  title: string;
  date: Date | string; // ISO8601 string
  time?: string; // ISO8601 string
  location?: string;
  confidence: number; // 0-1
  addedToCalendar: boolean;
  extractedAt: Date | string;
}

export interface RSVPParticipantResponse {
  status: "yes" | "no" | "maybe" | "no_reply";
  numberOfGuests?: number;
  note?: string;
  respondedAt?: Date | string;
}

export interface RSVPResponse {
  id: string; // eventId
  conversationId: string;
  eventTitle: string;
  eventDate: Date | string;
  responses: Record<string, RSVPParticipantResponse>; // userId: response
  totalParticipants: number;
  lastUpdated: Date | string;
  messageId: string;
}

export interface Deadline {
  id: string;
  userId: string;
  task: string;
  dueDate: Date | string;
  priority: "high" | "medium" | "low";
  conversationId: string;
  messageId: string;
  completed: boolean;
  confidence: number;
  createdAt: Date | string;
  reminderSent: boolean;
}

export interface AIDecision {
  id: string;
  conversationId: string;
  topic: string;
  decision: string;
  participants: string[]; // User IDs who agreed
  confidence: number;
  timestamp: Date | string;
  messageIds: string[];
  extractedAt: Date | string;
}

export interface Priority {
  level: "urgent" | "important" | "normal";
  confidence: number;
  reason: string;
}

// OpenAI Response Types

export interface CalendarEventExtraction {
  events: Array<{
    title: string;
    date: string; // ISO8601
    time?: string; // ISO8601
    location?: string;
    confidence: number;
  }>;
}

export interface PriorityDetectionResponse {
  priority: "urgent" | "important" | "normal";
  confidence: number;
  reason: string;
  keywords?: string[];
}

export interface DeadlineExtractionResponse {
  deadlines: Array<{
    task: string;
    dueDate: string; // ISO8601
    priority: "high" | "medium" | "low";
    confidence: number;
    assignedTo?: string; // user ID if mentioned
  }>;
}

// Function Request/Response Types

export interface CalendarExtractionRequest {
  messageText: string;
  conversationId: string;
  messageId: string;
}

export interface PriorityDetectionRequest {
  messageText: string;
}

export interface DeadlineExtractionRequest {
  messageText: string;
  conversationId: string;
  messageId: string;
}

export interface RSVPTrackingRequest {
  conversationId: string;
  eventId?: string;
}

export interface DecisionSummarizationRequest {
  conversationId: string;
  query?: string;
}

export interface AIChatRequest {
  query: string;
  chatId: string;
  history: Array<{
    role: "user" | "assistant";
    content: string;
  }>;
}

