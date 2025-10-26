# Weftly AI Implementation Plan v2 - Unified Agent Architecture
**Complete implementation plan incorporating the final agent architecture**

---

## 📋 Executive Summary

**Purpose:** This plan supersedes `weftly_ai_implementation_plan_comprehensive.md` with a new unified agent architecture.

**Key Architectural Changes:**
1. ✅ **SwiftData as single source of truth** - No messages in Firestore
2. ✅ **Unified LangGraph agent** - Single agent for all features, not separate functions
3. ✅ **Pinecone for RAG only** - Semantic search, not storage
4. ✅ **User-specific digest** - All AI features write to `users/{userId}/digest/`
5. ✅ **LLM-driven decisions** - No hardcoded rules (e.g., agent infers RSVP host)

**Timeline:** 5-7 days (PR #25-32)

**Rubric Target:** 28-30/30 points (Required AI: 15/15, Advanced AI: 10/10, Persona Fit: 5/5)

---

## 🔄 Migration Plan Overview

### **Phase 1: Reverse Old Implementation (PR #25-26)**
Remove Firestore messages storage and separate feature functions that conflict with new architecture.

### **Phase 2: New Infrastructure (PR #27-28)**
Set up Pinecone for RAG, unified agent framework, and new data models.

### **Phase 3: Unified Agent Implementation (PR #29-31)**
Build single LangGraph agent with all tools, digest management, and AI chat.

### **Phase 4: iOS Integration (PR #32)**
Connect iOS app to new backend, implement Digest tab with real-time updates.

---

## 📊 What's Changing

### **Old Architecture (To Be Removed)**

```
❌ conversations/{conversationId}/messages/{messageId}/ - Firestore messages
❌ Separate Firebase Functions for each feature:
   - calendarExtractionFunction
   - priorityDetectionFunction
   - rsvpTrackingFunction
   - decisionSummarizationFunction
   - deadlineExtractionFunction
❌ Features run independently on message triggers
❌ AI data stored in conversation subcollections
```

### **New Architecture (To Be Implemented)**

```
✅ Messages only in SwiftData (iOS) and Pinecone (embeddings for RAG)
✅ Single unified LangGraph agent with multiple tools
✅ Agent modes: 'background_processing' | 'ai_chat'
✅ All AI features write to users/{userId}/digest/
   - events/
   - deadlines/
   - priorityMessages/
   - rsvps/
   - suggestions/
✅ iOS provides messages from SwiftData when calling agent
```

---

## 🗂️ New Project Structure

```
Weftly/                                     # iOS App (existing)
├── Weftly/
│   ├── Models/
│   │   ├── Message.swift                   # ✅ existing
│   │   ├── Conversation.swift              # ✅ existing
│   │   ├── LocalConversationState.swift    # 🆕 AI indexing toggle per conversation
│   │   ├── DigestEvent.swift               # 🆕 calendar events
│   │   ├── DigestDeadline.swift            # 🆕 deadlines
│   │   ├── DigestPriorityMessage.swift     # 🆕 priority messages
│   │   ├── DigestRSVP.swift                # 🆕 RSVP tracking
│   │   └── DigestSuggestion.swift          # 🆕 proactive suggestions
│   │
│   ├── Services/
│   │   ├── AIService.swift                 # 🆕 coordinator for AI features
│   │   ├── DigestService.swift             # 🆕 Firestore digest listeners
│   │   └── CalendarService.swift           # 🆕 iOS EventKit integration
│   │
│   ├── ViewModels/
│   │   ├── ChatDetailViewModel.swift       # ✅ existing - MODIFY for AI indexing
│   │   ├── DigestViewModel.swift           # 🆕 Digest tab coordinator
│   │   ├── AssistantViewModel.swift        # 🆕 AI Chat interface
│   │   └── CalendarViewModel.swift         # 🆕 calendar management
│   │
│   └── Views/
│       ├── Digest/                         # 🆕 NEW TAB (replaces "Updates")
│       │   ├── DigestView.swift            # Main Digest tab
│       │   ├── EventsListView.swift        # Calendar events section
│       │   ├── DeadlinesListView.swift     # Deadlines section
│       │   ├── PriorityMessagesView.swift  # Important messages
│       │   ├── RSVPListView.swift          # RSVP tracking
│       │   └── SuggestionsView.swift       # Proactive suggestions
│       │
│       ├── Assistant/                      # 🆕 NEW TAB (replaces "AI")
│       │   ├── AssistantChatView.swift     # AI chat interface
│       │   └── QuickActionsView.swift      # Quick action buttons
│       │
│       └── Chat/
│           ├── ConversationSettingsView.swift  # 🆕 AI indexing toggle per thread
│           └── ChatDetailView.swift        # ✅ existing - ADD settings button

functions/                                  # 🆕 NEW Firebase Functions (TypeScript)
├── src/
│   ├── index.ts                            # Main exports
│   │
│   ├── agent/
│   │   ├── unifiedAgent.ts                 # LangGraph agent (single agent)
│   │   ├── tools/                          # Agent tools
│   │   │   ├── createCalendarEvent.ts      # Create event in digest
│   │   │   ├── updateCalendarEvent.ts      # Update existing event
│   │   │   ├── createDeadline.ts           # Create deadline
│   │   │   ├── updateDeadline.ts           # Update deadline
│   │   │   ├── createPriorityMessage.ts    # Mark message as priority
│   │   │   ├── createRSVP.ts               # Create RSVP event
│   │   │   ├── updateRSVPResponses.ts      # Update RSVP responses
│   │   │   ├── detectConflicts.ts          # Find scheduling conflicts
│   │   │   ├── suggestResolution.ts        # Suggest conflict resolution
│   │   │   └── decisionSummarize.ts        # Summarize group decisions (AI chat only)
│   │   └── agentState.ts                   # LangGraph state definition
│   │
│   ├── functions/
│   │   ├── processMessage.ts               # Background: new message → agent
│   │   └── aiChatQuery.ts                  # AI Chat: user query → agent
│   │
│   ├── utils/
│   │   ├── pinecone.ts                     # Pinecone client (RAG only)
│   │   ├── openai.ts                       # OpenAI client
│   │   ├── embeddings.ts                   # Generate embeddings
│   │   ├── contextPreparation.ts           # Combine recent + semantic messages
│   │   └── firestore.ts                    # Firestore helpers
│   │
│   └── types/
│       ├── index.ts                        # Shared TypeScript types
│       └── digest.ts                       # Digest item types
│
├── package.json
├── tsconfig.json
└── .env.example
```

---

## 📦 PR Breakdown

---

### **PR #25: Remove Old Firestore Messages Schema** 🔴 REVERSAL
**Branch:** `refactor/remove-firestore-messages`  
**Estimated Time:** 2-3 hours  
**Purpose:** Remove Firestore messages collection, keep only SwiftData

**Tasks:**

**1. Remove Firestore messages writes:**
- [ ] Identify all places in iOS code that write messages to Firestore
- [ ] Comment out or remove these writes:
  - `ChatService.sendMessage()` → Remove Firestore write
  - `GroupChatService.sendGroupMessage()` → Remove Firestore write
- [ ] Keep only SwiftData persistence for messages
- [ ] Update message status tracking (no Firestore dependency)

**2. Remove message listeners:**
- [ ] Remove Firestore message listeners in `ChatDetailViewModel`
- [ ] Remove any snapshot listeners for `conversations/{id}/messages`
- [ ] Keep only local SwiftData queries for message display

**3. Update conversation model:**
- [ ] Keep `conversations/{conversationId}` document (participants, name, type)
- [ ] Remove any references to message subcollection
- [ ] Update documentation

**4. Data migration notice:**
- [ ] Add migration function (optional) to:
  - Export existing Firestore messages to local SwiftData
  - Or simply start fresh (messages stay in SwiftData only)

**Why this matters:** The new architecture uses SwiftData as the single source of truth. Firestore is only used for digest items under `users/{userId}/digest/`.

**Verification:**
- [ ] Send message → saves to SwiftData only
- [ ] Check Firestore Console → no messages written to `conversations/{id}/messages`
- [ ] Messages still display correctly from SwiftData
- [ ] No errors in console about missing Firestore paths

---

### **PR #26: Remove Old Separate Feature Functions** 🔴 REVERSAL
**Branch:** `refactor/remove-old-functions`  
**Estimated Time:** 1-2 hours  
**Purpose:** Remove old separate functions (if any were implemented) that will be replaced by unified agent

**Tasks:**

**1. Audit what was implemented from old plan:**
- [ ] Check `functions/` directory for any existing code
- [ ] List all Firebase Functions currently deployed
- [ ] Identify functions to be removed:
  - `calendarExtractionFunction`
  - `priorityDetectionFunction`
  - `rsvpTrackingFunction`
  - `decisionSummarizationFunction`
  - `deadlineExtractionFunction`

**2. Remove or archive old code:**
- [ ] If functions exist, move to `functions/archive/` folder
- [ ] Remove from `functions/src/index.ts` exports
- [ ] Document what was removed and why

**3. Clean up iOS calls:**
- [ ] Remove any iOS code calling old separate functions
- [ ] Remove old models specific to separate features
- [ ] Keep only models we'll reuse (basic Message, Conversation)

**Why this matters:** The new architecture uses a single unified agent instead of separate functions for each feature.

**Verification:**
- [ ] `firebase functions:list` shows no old AI feature functions
- [ ] iOS project has no calls to removed functions
- [ ] Code compiles without errors

---

### **PR #27: New Infrastructure - Pinecone + Agent Framework** 🆕
**Branch:** `feature/new-agent-infrastructure`  
**Estimated Time:** 4-5 hours  
**Purpose:** Set up Pinecone for RAG, install LangGraph, create basic agent structure

**Tasks:**

**1. Set up Pinecone:**
- [ ] Create Pinecone account (free tier: 100K vectors)
- [ ] Create index: `weftly-messages`
  - Dimensions: 1536 (OpenAI `text-embedding-3-small`)
  - Metric: cosine similarity
- [ ] Get API key and environment
- [ ] Document Pinecone setup in README

**2. Initialize Firebase Functions project:**
```bash
cd functions
npm init -y
npm install --save \
  firebase-functions@latest \
  firebase-admin \
  @langchain/core \
  @langchain/langgraph \
  @langchain/openai \
  @pinecone-database/pinecone \
  openai \
  dotenv

npm install --save-dev \
  typescript \
  @types/node \
  ts-node
```

**3. Create environment configuration:**
```typescript
// functions/.env.example
OPENAI_API_KEY=sk-...
PINECONE_API_KEY=...
PINECONE_ENVIRONMENT=us-west1-gcp-free
PINECONE_INDEX=weftly-messages
```

**4. Create basic agent structure:**

```typescript
// functions/src/agent/unifiedAgent.ts
import { StateGraph } from "@langchain/langgraph";
import { ChatOpenAI } from "@langchain/openai";

interface AgentState {
  mode: 'background_processing' | 'ai_chat';
  userId: string;
  conversationId?: string;
  messages: any[];
  currentDigest: any;
  agentMessages: any[];
  toolCalls: any[];
  output: any;
}

const llm = new ChatOpenAI({
  modelName: "gpt-4o",
  temperature: 0.2,
});

// Agent workflow will be built in PR #29
export const createUnifiedAgent = () => {
  const workflow = new StateGraph<AgentState>({
    channels: {
      mode: null,
      userId: null,
      conversationId: null,
      messages: null,
      currentDigest: null,
      agentMessages: null,
      toolCalls: null,
      output: null,
    }
  });
  
  // Nodes will be added in PR #29
  
  return workflow.compile();
};
```

**5. Create Pinecone utility:**

```typescript
// functions/src/utils/pinecone.ts
import { Pinecone } from '@pinecone-database/pinecone';

let pineconeClient: Pinecone | null = null;

export const getPineconeClient = async () => {
  if (!pineconeClient) {
    pineconeClient = new Pinecone({
      apiKey: process.env.PINECONE_API_KEY!,
    });
  }
  return pineconeClient;
};

export const getIndex = async () => {
  const client = await getPineconeClient();
  return client.index(process.env.PINECONE_INDEX || 'weftly-messages');
};

// Embed and upsert message
export const embedMessage = async (message: {
  id: string;
  text: string;
  conversationId: string;
  senderId: string;
  senderName: string;
  timestamp: number;
}) => {
  const index = await getIndex();
  const { generateEmbedding } = await import('./embeddings');
  
  const embedding = await generateEmbedding(message.text);
  
  await index.upsert([{
    id: message.id,
    values: embedding,
    metadata: {
      conversationId: message.conversationId,
      text: message.text,
      senderId: message.senderId,
      senderName: message.senderName,
      timestamp: message.timestamp,
      deletedBy: [], // Array of user IDs who deleted this
    }
  }]);
};

// Semantic search (returns message IDs only)
export const semanticSearch = async (
  query: string,
  conversationId: string,
  userId: string,
  topK: number = 20
) => {
  const index = await getIndex();
  const { generateEmbedding } = await import('./embeddings');
  
  const embedding = await generateEmbedding(query);
  
  const results = await index.query({
    vector: embedding,
    topK,
    filter: {
      conversationId: { $eq: conversationId },
      deletedBy: { $nin: [userId] } // Exclude messages user deleted
    },
    includeMetadata: true,
  });
  
  return results.matches || [];
};
```

**6. Create embeddings utility:**

```typescript
// functions/src/utils/embeddings.ts
import { OpenAI } from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY!,
});

export const generateEmbedding = async (text: string): Promise<number[]> => {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: text,
  });
  
  return response.data[0].embedding;
};
```

**Files Created:**
- `functions/src/agent/unifiedAgent.ts`
- `functions/src/agent/agentState.ts`
- `functions/src/utils/pinecone.ts`
- `functions/src/utils/embeddings.ts`
- `functions/src/utils/openai.ts`
- `functions/src/types/index.ts`
- `functions/.env.example`
- `functions/package.json`
- `functions/tsconfig.json`

**Verification:**
- [ ] `npm run build` compiles without errors
- [ ] Can connect to Pinecone (test with simple script)
- [ ] Can generate embeddings (test with sample text)
- [ ] Environment variables load correctly

---

### **PR #28: iOS Models + SwiftData Extensions** 🆕
**Branch:** `feature/ios-digest-models`  
**Estimated Time:** 3-4 hours  
**Purpose:** Create iOS models for digest items, add AI indexing toggle

**Tasks:**

**1. Create LocalConversationState model:**

```swift
// Models/LocalConversationState.swift
import SwiftData
import Foundation

@Model
class LocalConversationState {
    @Attribute(.unique) var conversationId: String
    var aiIndexingEnabled: Bool
    var lastProcessedMessageId: String?
    var lastProcessedAt: Date?
    
    init(conversationId: String, aiIndexingEnabled: Bool = false) {
        self.conversationId = conversationId
        self.aiIndexingEnabled = aiIndexingEnabled
    }
}
```

**2. Create Digest models:**

```swift
// Models/DigestEvent.swift
import SwiftData
import Foundation

@Model
class DigestEvent {
    @Attribute(.unique) var id: String
    var title: String
    var date: Date
    var time: String?
    var location: String?
    var conversationId: String
    var messageId: String
    var confidence: Double
    var status: String // "pending" | "accepted" | "dismissed"
    var addedToCalendar: Bool
    var createdAt: Date
    var lastMentionedAt: Date
    
    init(id: String, title: String, date: Date, conversationId: String, messageId: String) {
        self.id = id
        self.title = title
        self.date = date
        self.conversationId = conversationId
        self.messageId = messageId
        self.confidence = 0.0
        self.status = "pending"
        self.addedToCalendar = false
        self.createdAt = Date()
        self.lastMentionedAt = Date()
    }
}

// Models/DigestDeadline.swift
@Model
class DigestDeadline {
    @Attribute(.unique) var id: String
    var task: String
    var dueDate: Date
    var priority: String // "high" | "medium" | "low"
    var assignedTo: String // user ID
    var conversationId: String
    var messageId: String
    var confidence: Double
    var status: String // "pending" | "completed" | "dismissed"
    var completed: Bool
    
    init(id: String, task: String, dueDate: Date, assignedTo: String, conversationId: String, messageId: String) {
        self.id = id
        self.task = task
        self.dueDate = dueDate
        self.assignedTo = assignedTo
        self.conversationId = conversationId
        self.messageId = messageId
        self.priority = "medium"
        self.confidence = 0.0
        self.status = "pending"
        self.completed = false
    }
}

// Models/DigestPriorityMessage.swift
@Model
class DigestPriorityMessage {
    @Attribute(.unique) var id: String // Same as message ID
    var messageText: String
    var priority: String // "urgent" | "important"
    var reason: String
    var requiresAction: Bool
    var conversationId: String
    var senderId: String
    var senderName: String
    var timestamp: Date
    var status: String // "pending" | "dismissed"
    
    init(id: String, messageText: String, priority: String, reason: String, conversationId: String, senderId: String, senderName: String, timestamp: Date) {
        self.id = id
        self.messageText = messageText
        self.priority = priority
        self.reason = reason
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.timestamp = timestamp
        self.requiresAction = false
        self.status = "pending"
    }
}

// Models/DigestRSVP.swift
@Model
class DigestRSVP {
    @Attribute(.unique) var id: String
    var eventId: String // Reference to DigestEvent
    var eventTitle: String
    var eventDate: Date
    var conversationId: String
    var messageId: String
    var isHost: Bool // Current user is organizer
    var responsesJSON: String // JSON string of responses map
    var totalInvited: Int
    var createdAt: Date
    
    init(id: String, eventId: String, eventTitle: String, eventDate: Date, conversationId: String, messageId: String, isHost: Bool) {
        self.id = id
        self.eventId = eventId
        self.eventTitle = eventTitle
        self.eventDate = eventDate
        self.conversationId = conversationId
        self.messageId = messageId
        self.isHost = isHost
        self.responsesJSON = "{}"
        self.totalInvited = 0
        self.createdAt = Date()
    }
    
    var responses: [String: RSVPResponse] {
        get {
            guard let data = responsesJSON.data(using: .utf8) else { return [:] }
            return (try? JSONDecoder().decode([String: RSVPResponse].self, from: data)) ?? [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                responsesJSON = json
            }
        }
    }
}

struct RSVPResponse: Codable {
    let response: String // "yes" | "no" | "maybe"
    let guestCount: Int?
    let note: String?
    let timestamp: Date
}

// Models/DigestSuggestion.swift
@Model
class DigestSuggestion {
    @Attribute(.unique) var id: String
    var type: String // "conflict_resolution" | "reminder" | "proactive"
    var priority: String // "high" | "medium" | "low"
    var suggestionDescription: String
    var optionsJSON: String // JSON string of options array
    var status: String // "pending" | "accepted" | "dismissed"
    var createdAt: Date
    
    init(id: String, type: String, priority: String, description: String) {
        self.id = id
        self.type = type
        self.priority = priority
        self.suggestionDescription = description
        self.optionsJSON = "[]"
        self.status = "pending"
        self.createdAt = Date()
    }
}
```

**3. Update SwiftData schema:**

```swift
// WeftlyApp.swift
import SwiftUI
import SwiftData

@main
struct WeftlyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Existing
            Message.self,
            Conversation.self,
            // New
            LocalConversationState.self,
            DigestEvent.self,
            DigestDeadline.self,
            DigestPriorityMessage.self,
            DigestRSVP.self,
            DigestSuggestion.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Files Created:**
- `Models/LocalConversationState.swift`
- `Models/DigestEvent.swift`
- `Models/DigestDeadline.swift`
- `Models/DigestPriorityMessage.swift`
- `Models/DigestRSVP.swift`
- `Models/DigestSuggestion.swift`

**Files Modified:**
- `WeftlyApp.swift` (add new models to schema)

**Verification:**
- [ ] App compiles without errors
- [ ] SwiftData preview works
- [ ] Can create and save test digest items
- [ ] No migration issues

---

### **PR #29: Unified Agent Implementation** 🆕
**Branch:** `feature/unified-agent`  
**Estimated Time:** 6-8 hours  
**Purpose:** Build complete LangGraph agent with all tools

**Tasks:**

**1. Define agent tools:**

```typescript
// functions/src/agent/tools/createCalendarEvent.ts
import { tool } from "@langchain/core/tools";
import { z } from "zod";
import { getFirestore } from 'firebase-admin/firestore';

export const createCalendarEventTool = tool(
  async ({ userId, title, date, time, location, conversationId, messageId, confidence }) => {
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
    
    return `Created calendar event "${title}" with ID ${eventId}`;
  },
  {
    name: "create_calendar_event",
    description: "Create a new calendar event in the user's digest. Use this when you detect a new event (meeting, appointment, etc.) in the messages.",
    schema: z.object({
      userId: z.string(),
      title: z.string(),
      date: z.string().describe("ISO date string"),
      time: z.string().optional(),
      location: z.string().optional(),
      conversationId: z.string(),
      messageId: z.string(),
      confidence: z.number().min(0).max(1),
    }),
  }
);

// functions/src/agent/tools/updateCalendarEvent.ts
export const updateCalendarEventTool = tool(
  async ({ userId, eventId, updates }) => {
    const db = getFirestore();
    
    await db.collection('users').doc(userId)
      .collection('digest').doc('events')
      .collection('items').doc(eventId)
      .update({
        ...updates,
        lastMentionedAt: new Date(),
      });
    
    return `Updated event ${eventId}`;
  },
  {
    name: "update_calendar_event",
    description: "Update an existing calendar event. Use when the time, location, or other details change.",
    schema: z.object({
      userId: z.string(),
      eventId: z.string(),
      updates: z.object({
        title: z.string().optional(),
        date: z.string().optional(),
        time: z.string().optional(),
        location: z.string().optional(),
      }),
    }),
  }
);

// Similar tools for:
// - createDeadline
// - updateDeadline
// - createPriorityMessage
// - updatePriorityMessage
// - createRSVP
// - updateRSVPResponses
// - detectConflicts
// - suggestResolution
// - decisionSummarize (AI chat only)
```

**2. Build agent workflow:**

```typescript
// functions/src/agent/unifiedAgent.ts
import { StateGraph, END } from "@langchain/langgraph";
import { ChatOpenAI } from "@langchain/openai";
import { createCalendarEventTool } from "./tools/createCalendarEvent";
import { updateCalendarEventTool } from "./tools/updateCalendarEvent";
// ... import all other tools

interface AgentState {
  mode: 'background_processing' | 'ai_chat';
  userId: string;
  conversationId?: string;
  newMessage?: any;
  query?: string;
  messages: any[]; // Recent + semantic matches
  currentDigest: any; // Existing digest state
  agentMessages: any[];
  toolCalls: any[];
  output: any;
}

const llm = new ChatOpenAI({
  modelName: "gpt-4o",
  temperature: 0.2,
}).bind({
  tools: [
    createCalendarEventTool,
    updateCalendarEventTool,
    // ... all other tools
  ],
});

// Node: Prepare system prompt
async function preparePrompt(state: AgentState) {
  const systemPrompt = state.mode === 'background_processing'
    ? `You are an AI assistant analyzing a new message in a conversation.
Your job is to extract calendar events, deadlines, priority markers, RSVP events, and detect conflicts.

Context:
- New message: "${state.newMessage?.text}"
- Recent conversation history: ${state.messages.length} messages
- Current user digest state: ${JSON.stringify(state.currentDigest)}

Tools available:
- create_calendar_event: Create new events
- update_calendar_event: Update existing events (avoid duplicates!)
- create_deadline: Create deadlines/tasks
- create_priority_message: Mark urgent/important messages
- create_rsvp: Track RSVP events
- update_rsvp_responses: Update RSVP responses
- detect_conflicts: Find scheduling conflicts
- suggest_resolution: Suggest conflict resolutions

Guidelines:
- Check currentDigest before creating duplicates
- Update existing items if details changed
- Set confidence scores honestly (0-1)
- Infer context (e.g., who is the RSVP host based on who sent invitation)
- Only extract clear, actionable information
`
    : `You are an AI assistant helping the user query their message history.

User query: "${state.query}"

You have access to:
- Recent messages from relevant conversations
- User's current digest (events, deadlines, RSVPs, etc.)
- Tools to create/update digest items
- decision_summarize tool to summarize group decisions

Answer the user's question naturally and use tools when appropriate.
`;

  return {
    ...state,
    agentMessages: [
      { role: 'system', content: systemPrompt },
      ...state.messages.map(m => ({
        role: 'user',
        content: `[${m.senderName} at ${new Date(m.timestamp).toLocaleString()}]: ${m.text}`
      }))
    ]
  };
}

// Node: Invoke LLM
async function callLLM(state: AgentState) {
  const response = await llm.invoke(state.agentMessages);
  
  return {
    ...state,
    agentMessages: [...state.agentMessages, response],
    toolCalls: response.tool_calls || [],
  };
}

// Node: Execute tools
async function executeTools(state: AgentState) {
  if (!state.toolCalls || state.toolCalls.length === 0) {
    return state;
  }
  
  const toolResults = [];
  
  for (const toolCall of state.toolCalls) {
    const tool = [
      createCalendarEventTool,
      updateCalendarEventTool,
      // ... all tools
    ].find(t => t.name === toolCall.name);
    
    if (tool) {
      const result = await tool.invoke(toolCall.args);
      toolResults.push({
        tool: toolCall.name,
        result,
      });
    }
  }
  
  return {
    ...state,
    agentMessages: [
      ...state.agentMessages,
      {
        role: 'function',
        content: JSON.stringify(toolResults),
      }
    ],
    toolCalls: [],
  };
}

// Node: Determine if done
function shouldContinue(state: AgentState): string {
  if (state.toolCalls && state.toolCalls.length > 0) {
    return "executeTools";
  }
  
  if (state.mode === 'ai_chat') {
    return "formatOutput";
  }
  
  return END;
}

// Node: Format output (for AI chat)
async function formatOutput(state: AgentState) {
  const lastMessage = state.agentMessages[state.agentMessages.length - 1];
  
  return {
    ...state,
    output: {
      response: lastMessage.content,
      toolsUsed: state.agentMessages.filter(m => m.role === 'function').length,
    }
  };
}

// Build workflow
export const createUnifiedAgent = () => {
  const workflow = new StateGraph<AgentState>({
    channels: {
      mode: null,
      userId: null,
      conversationId: null,
      newMessage: null,
      query: null,
      messages: null,
      currentDigest: null,
      agentMessages: null,
      toolCalls: null,
      output: null,
    }
  });
  
  workflow.addNode("preparePrompt", preparePrompt);
  workflow.addNode("callLLM", callLLM);
  workflow.addNode("executeTools", executeTools);
  workflow.addNode("formatOutput", formatOutput);
  
  workflow.setEntryPoint("preparePrompt");
  workflow.addEdge("preparePrompt", "callLLM");
  workflow.addConditionalEdges("callLLM", shouldContinue, {
    executeTools: "executeTools",
    formatOutput: "formatOutput",
    [END]: END,
  });
  workflow.addEdge("executeTools", "callLLM"); // Loop back for multi-step reasoning
  workflow.addEdge("formatOutput", END);
  
  return workflow.compile();
};
```

**3. Create context preparation utility:**

```typescript
// functions/src/utils/contextPreparation.ts
import { semanticSearch } from './pinecone';
import { getFirestore } from 'firebase-admin/firestore';

export const prepareAgentContext = async (
  mode: 'background_processing' | 'ai_chat',
  userId: string,
  params: {
    conversationId?: string;
    newMessage?: any;
    recentMessages?: any[]; // Provided by iOS from SwiftData
    query?: string;
  }
) => {
  // 1. Get recent messages (provided by iOS)
  const recentMessages = params.recentMessages || [];
  
  // 2. If background processing, do semantic search
  let semanticMatches: any[] = [];
  
  if (mode === 'background_processing' && params.newMessage) {
    const matches = await semanticSearch(
      params.newMessage.text,
      params.conversationId!,
      userId,
      20 // top K
    );
    
    // iOS needs to expand these IDs with context window
    semanticMatches = matches.map(m => m.id);
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
  
  // 4. Deduplicate messages
  const messageIds = new Set();
  const allMessages = [];
  
  for (const msg of [...recentMessages, ...semanticMatches]) {
    if (!messageIds.has(msg.id)) {
      messageIds.add(msg.id);
      allMessages.push(msg);
    }
  }
  
  // Sort by timestamp
  allMessages.sort((a, b) => a.timestamp - b.timestamp);
  
  return {
    messages: allMessages,
    currentDigest,
    semanticMatchIds: semanticMatches.map(m => m.id), // Return IDs for iOS to expand
  };
};
```

**Files Created:**
- `functions/src/agent/unifiedAgent.ts`
- `functions/src/agent/tools/createCalendarEvent.ts`
- `functions/src/agent/tools/updateCalendarEvent.ts`
- `functions/src/agent/tools/createDeadline.ts`
- `functions/src/agent/tools/updateDeadline.ts`
- `functions/src/agent/tools/createPriorityMessage.ts`
- `functions/src/agent/tools/createRSVP.ts`
- `functions/src/agent/tools/updateRSVPResponses.ts`
- `functions/src/agent/tools/detectConflicts.ts`
- `functions/src/agent/tools/suggestResolution.ts`
- `functions/src/agent/tools/decisionSummarize.ts`
- `functions/src/utils/contextPreparation.ts`

**Verification:**
- [ ] Agent compiles without errors
- [ ] Can invoke agent with test state
- [ ] Tools execute correctly (test with mock data)
- [ ] Agent makes appropriate tool calls

---

### **PR #30: Firebase Functions - Message Processing & AI Chat** 🆕
**Branch:** `feature/firebase-functions`  
**Estimated Time:** 4-5 hours  
**Purpose:** Create callable functions for iOS to invoke agent

**Tasks:**

**1. Create processMessage function:**

```typescript
// functions/src/functions/processMessage.ts
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { createUnifiedAgent } from '../agent/unifiedAgent';
import { embedMessage } from '../utils/pinecone';
import { prepareAgentContext } from '../utils/contextPreparation';

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

export const processMessage = onCall<ProcessMessageRequest>(
  async (request) => {
    const { userId, conversationId, newMessage, recentMessages } = request.data;
    
    // 1. Validate
    if (!userId || !conversationId || !newMessage) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }
    
    // 2. Embed new message to Pinecone
    await embedMessage(newMessage);
    
    // 3. Prepare context
    const context = await prepareAgentContext('background_processing', userId, {
      conversationId,
      newMessage,
      recentMessages,
    });
    
    // 4. Invoke agent
    const agent = createUnifiedAgent();
    
    const result = await agent.invoke({
      mode: 'background_processing',
      userId,
      conversationId,
      newMessage,
      messages: context.messages,
      currentDigest: context.currentDigest,
      agentMessages: [],
      toolCalls: [],
      output: null,
    });
    
    return {
      success: true,
      semanticMatchIds: context.semanticMatchIds,
      toolCallsExecuted: result.agentMessages.filter(m => m.role === 'function').length,
    };
  }
);
```

**2. Create aiChatQuery function:**

```typescript
// functions/src/functions/aiChatQuery.ts
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { createUnifiedAgent } from '../agent/unifiedAgent';
import { prepareAgentContext } from '../utils/contextPreparation';

interface AIChatQueryRequest {
  userId: string;
  query: string;
  enabledThreadIds: string[];
  recentMessagesByThread: Record<string, any[]>; // iOS provides recent messages per thread
}

export const aiChatQuery = onCall<AIChatQueryRequest>(
  async (request) => {
    const { userId, query, enabledThreadIds, recentMessagesByThread } = request.data;
    
    // 1. Validate
    if (!userId || !query) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }
    
    // 2. Prepare cross-thread context
    const allMessages = [];
    for (const threadId of enabledThreadIds) {
      const threadMessages = recentMessagesByThread[threadId] || [];
      allMessages.push(...threadMessages);
    }
    
    // 3. Get digest state
    const context = await prepareAgentContext('ai_chat', userId, {
      recentMessages: allMessages,
      query,
    });
    
    // 4. Invoke agent
    const agent = createUnifiedAgent();
    
    const result = await agent.invoke({
      mode: 'ai_chat',
      userId,
      query,
      messages: context.messages,
      currentDigest: context.currentDigest,
      agentMessages: [],
      toolCalls: [],
      output: null,
    });
    
    return {
      response: result.output?.response || "I couldn't process that query.",
      toolsUsed: result.output?.toolsUsed || 0,
    };
  }
);
```

**3. Export functions:**

```typescript
// functions/src/index.ts
export { processMessage } from './functions/processMessage';
export { aiChatQuery } from './functions/aiChatQuery';
```

**4. Deploy functions:**

```bash
cd functions
npm run build
firebase deploy --only functions
```

**Files Created:**
- `functions/src/functions/processMessage.ts`
- `functions/src/functions/aiChatQuery.ts`
- `functions/src/index.ts`

**Verification:**
- [ ] Functions deploy successfully
- [ ] Can call `processMessage` from iOS (test with curl or Postman)
- [ ] Can call `aiChatQuery` from iOS
- [ ] Functions execute without errors
- [ ] Check Firebase Console logs for output

---

### **PR #31: iOS Services - AI & Digest Integration** 🆕
**Branch:** `feature/ios-ai-services`  
**Estimated Time:** 5-6 hours  
**Purpose:** Create iOS services to call Firebase Functions and listen to digest updates

**Tasks:**

**1. Create AIService:**

```swift
// Services/AIService.swift
import Foundation
import FirebaseFunctions
import SwiftData

class AIService {
    static let shared = AIService()
    private let functions = Functions.functions()
    
    private init() {}
    
    // Process new message through agent
    func processNewMessage(_ message: Message, conversation: Conversation, context: ModelContext) async throws {
        // 1. Check if AI indexing enabled for this conversation
        let descriptor = FetchDescriptor<LocalConversationState>(
            predicate: #Predicate { $0.conversationId == conversation.id }
        )
        guard let state = try context.fetch(descriptor).first,
              state.aiIndexingEnabled else {
            return // AI not enabled for this thread
        }
        
        // 2. Get recent messages from SwiftData
        let recentDescriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.conversationId == conversation.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 50
        
        let recentMessages = try context.fetch(recentDescriptor).reversed()
        
        // 3. Call Firebase Function
        let callable = functions.httpsCallable("processMessage")
        
        let requestData: [String: Any] = [
            "userId": AuthService.shared.currentUserId ?? "",
            "conversationId": conversation.id,
            "newMessage": [
                "id": message.id,
                "text": message.text,
                "senderId": message.senderId,
                "senderName": message.senderName,
                "timestamp": Int(message.timestamp.timeIntervalSince1970 * 1000)
            ],
            "recentMessages": recentMessages.map { [
                "id": $0.id,
                "text": $0.text,
                "senderId": $0.senderId,
                "senderName": $0.senderName,
                "timestamp": Int($0.timestamp.timeIntervalSince1970 * 1000)
            ]}
        ]
        
        let result = try await callable.call(requestData)
        
        // 4. Update last processed
        state.lastProcessedMessageId = message.id
        state.lastProcessedAt = Date()
        try context.save()
        
        print("✅ Message processed by agent")
    }
    
    // Query AI assistant
    func queryChatAssistant(_ query: String, context: ModelContext) async throws -> String {
        guard let userId = AuthService.shared.currentUserId else {
            throw NSError(domain: "AIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        // 1. Get all enabled threads
        let descriptor = FetchDescriptor<LocalConversationState>(
            predicate: #Predicate { $0.aiIndexingEnabled == true }
        )
        let enabledStates = try context.fetch(descriptor)
        let enabledThreadIds = enabledStates.map { $0.conversationId }
        
        // 2. Get recent messages per thread
        var recentMessagesByThread: [String: [[String: Any]]] = [:]
        
        for threadId in enabledThreadIds {
            let msgDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate { $0.conversationId == threadId },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            msgDescriptor.fetchLimit = 30
            
            let messages = try context.fetch(msgDescriptor).reversed()
            
            recentMessagesByThread[threadId] = messages.map { [
                "id": $0.id,
                "text": $0.text,
                "senderId": $0.senderId,
                "senderName": $0.senderName,
                "timestamp": Int($0.timestamp.timeIntervalSince1970 * 1000)
            ]}
        }
        
        // 3. Call Firebase Function
        let callable = functions.httpsCallable("aiChatQuery")
        
        let requestData: [String: Any] = [
            "userId": userId,
            "query": query,
            "enabledThreadIds": enabledThreadIds,
            "recentMessagesByThread": recentMessagesByThread
        ]
        
        let result = try await callable.call(requestData)
        
        guard let data = result.data as? [String: Any],
              let response = data["response"] as? String else {
            throw NSError(domain: "AIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        return response
    }
}
```

**2. Create DigestService:**

```swift
// Services/DigestService.swift
import Foundation
import FirebaseFirestore
import SwiftData

class DigestService: ObservableObject {
    static let shared = DigestService()
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    private init() {}
    
    // Start listening to all digest subcollections
    func startListening(userId: String, context: ModelContext) {
        stopListening()
        
        // Listen to events
        let eventsListener = db.collection("users").document(userId)
            .collection("digest").document("events")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.syncEvents(documents, context: context)
            }
        
        // Listen to deadlines
        let deadlinesListener = db.collection("users").document(userId)
            .collection("digest").document("deadlines")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.syncDeadlines(documents, context: context)
            }
        
        // Listen to priority messages
        let priorityListener = db.collection("users").document(userId)
            .collection("digest").document("priorityMessages")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.syncPriorityMessages(documents, context: context)
            }
        
        // Listen to RSVPs
        let rsvpsListener = db.collection("users").document(userId)
            .collection("digest").document("rsvps")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.syncRSVPs(documents, context: context)
            }
        
        // Listen to suggestions
        let suggestionsListener = db.collection("users").document(userId)
            .collection("digest").document("suggestions")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.syncSuggestions(documents, context: context)
            }
        
        listeners = [eventsListener, deadlinesListener, priorityListener, rsvpsListener, suggestionsListener]
        
        print("✅ Started listening to digest updates")
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // Sync Firestore → SwiftData
    private func syncEvents(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        for doc in documents {
            let data = doc.data()
            let id = doc.documentID
            
            // Check if exists
            let descriptor = FetchDescriptor<DigestEvent>(
                predicate: #Predicate { $0.id == id }
            )
            
            let existingEvent = try? context.fetch(descriptor).first
            
            if let event = existingEvent {
                // Update
                event.title = data["title"] as? String ?? event.title
                event.date = (data["date"] as? Timestamp)?.dateValue() ?? event.date
                event.status = data["status"] as? String ?? event.status
                // ... update other fields
            } else {
                // Create
                let newEvent = DigestEvent(
                    id: id,
                    title: data["title"] as? String ?? "",
                    date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                    conversationId: data["conversationId"] as? String ?? "",
                    messageId: data["messageId"] as? String ?? ""
                )
                context.insert(newEvent)
            }
        }
        
        try? context.save()
    }
    
    // Similar sync methods for deadlines, priority messages, RSVPs, suggestions
    private func syncDeadlines(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        // Similar logic
    }
    
    private func syncPriorityMessages(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        // Similar logic
    }
    
    private func syncRSVPs(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        // Similar logic
    }
    
    private func syncSuggestions(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        // Similar logic
    }
    
    // Accept/Dismiss actions
    func acceptEvent(_ eventId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("digest").document("events")
            .collection("items").document(eventId)
            .updateData(["status": "accepted"])
    }
    
    func dismissEvent(_ eventId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("digest").document("events")
            .collection("items").document(eventId)
            .updateData(["status": "dismissed"])
    }
    
    // Similar methods for other digest types
}
```

**3. Create CalendarService:**

```swift
// Services/CalendarService.swift
import Foundation
import EventKit

class CalendarService {
    static let shared = CalendarService()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    func requestAccess() async throws -> Bool {
        return try await eventStore.requestAccess(to: .event)
    }
    
    func addEventToCalendar(_ event: DigestEvent) async throws {
        let granted = try await requestAccess()
        guard granted else {
            throw NSError(domain: "CalendarService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied"])
        }
        
        let calendarEvent = EKEvent(eventStore: eventStore)
        calendarEvent.title = event.title
        calendarEvent.startDate = event.date
        calendarEvent.endDate = event.date.addingTimeInterval(3600) // 1 hour default
        calendarEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        if let location = event.location {
            calendarEvent.location = location
        }
        
        try eventStore.save(calendarEvent, span: .thisEvent)
        
        print("✅ Added event to iOS calendar: \(event.title)")
    }
}
```

**4. Modify ChatDetailViewModel:**

```swift
// ViewModels/ChatDetailViewModel.swift
// Add AI processing call after sending message

func sendMessage(_ text: String) async {
    // ... existing send logic
    
    // Process message with AI (if enabled)
    Task {
        try? await AIService.shared.processNewMessage(
            newMessage,
            conversation: conversation,
            context: modelContext
        )
    }
}
```

**Files Created:**
- `Services/AIService.swift`
- `Services/DigestService.swift`
- `Services/CalendarService.swift`

**Files Modified:**
- `ViewModels/ChatDetailViewModel.swift`

**Verification:**
- [ ] Send message → AIService.processNewMessage called
- [ ] Check Firebase Console → function invoked
- [ ] Digest items appear in Firestore
- [ ] DigestService listeners sync to SwiftData
- [ ] No crashes or errors

---

### **PR #32: Digest Tab UI + AI Chat Interface** 🆕
**Branch:** `feature/digest-ui`  
**Estimated Time:** 6-8 hours  
**Purpose:** Build complete Digest tab and AI Chat interface

**Tasks:**

**1. Create Digest tab structure:**

```swift
// Views/Digest/DigestView.swift
import SwiftUI
import SwiftData

struct DigestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DigestEvent.date) private var events: [DigestEvent]
    @Query(sort: \DigestDeadline.dueDate) private var deadlines: [DigestDeadline]
    @Query(sort: \DigestPriorityMessage.timestamp, order: .reverse) private var priorityMessages: [DigestPriorityMessage]
    @Query(sort: \DigestRSVP.eventDate) private var rsvps: [DigestRSVP]
    @Query(sort: \DigestSuggestion.createdAt, order: .reverse) private var suggestions: [DigestSuggestion]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Proactive suggestions (top)
                    if !suggestions.filter({ $0.status == "pending" }).isEmpty {
                        SuggestionsView(suggestions: suggestions.filter { $0.status == "pending" })
                    }
                    
                    // Calendar events
                    if !events.filter({ $0.status == "pending" }).isEmpty {
                        EventsListView(events: events.filter { $0.status == "pending" })
                    }
                    
                    // Deadlines
                    if !deadlines.filter({ $0.status == "pending" }).isEmpty {
                        DeadlinesListView(deadlines: deadlines.filter { $0.status == "pending" })
                    }
                    
                    // Priority messages
                    if !priorityMessages.filter({ $0.status == "pending" }).isEmpty {
                        PriorityMessagesView(messages: priorityMessages.filter { $0.status == "pending" })
                    }
                    
                    // RSVPs
                    if !rsvps.isEmpty {
                        RSVPListView(rsvps: rsvps)
                    }
                    
                    // Empty state
                    if events.isEmpty && deadlines.isEmpty && priorityMessages.isEmpty && rsvps.isEmpty {
                        ContentUnavailableView(
                            "No insights yet",
                            systemImage: "sparkles",
                            description: Text("Enable AI for conversations to start seeing events, deadlines, and important messages here.")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Digest")
        }
        .onAppear {
            if let userId = AuthService.shared.currentUserId {
                DigestService.shared.startListening(userId: userId, context: modelContext)
            }
        }
    }
}
```

**2. Create section views:**

```swift
// Views/Digest/EventsListView.swift
struct EventsListView: View {
    let events: [DigestEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 Upcoming Events")
                .font(.headline)
            
            ForEach(events) { event in
                EventCardView(event: event)
            }
        }
    }
}

// Views/Components/EventCardView.swift
struct EventCardView: View {
    let event: DigestEvent
    @State private var isProcessing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(event.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let time = event.time {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let location = event.location {
                        Label(location, systemImage: "mappin.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Confidence badge
                Text("\(Int(event.confidence * 100))%")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await addToCalendar()
                    }
                }) {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .disabled(event.addedToCalendar || isProcessing)
                
                Button(action: {
                    Task {
                        await dismissEvent()
                    }
                }) {
                    Text("Dismiss")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    func addToCalendar() async {
        isProcessing = true
        
        do {
            try await CalendarService.shared.addEventToCalendar(event)
            
            if let userId = AuthService.shared.currentUserId {
                try await DigestService.shared.acceptEvent(event.id, userId: userId)
            }
        } catch {
            print("❌ Error adding to calendar: \(error)")
        }
        
        isProcessing = false
    }
    
    func dismissEvent() async {
        if let userId = AuthService.shared.currentUserId {
            try? await DigestService.shared.dismissEvent(event.id, userId: userId)
        }
    }
}

// Similar views for:
// - DeadlinesListView / DeadlineCardView
// - PriorityMessagesView / PriorityMessageCard
// - RSVPListView / RSVPCardView
// - SuggestionsView / SuggestionCardView
```

**3. Create AI Chat interface:**

```swift
// Views/Assistant/AssistantChatView.swift
import SwiftUI

struct AssistantChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isProcessing {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input
                HStack(spacing: 12) {
                    TextField("Ask anything about your messages...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(inputText.isEmpty ? .gray : .blue)
                    }
                    .disabled(inputText.isEmpty || isProcessing)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { /* Show enabled threads */ }) {
                            Label("Enabled Conversations", systemImage: "list.bullet")
                        }
                        
                        Button(action: { /* Clear chat */ }) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            // Load chat history (optional)
        }
    }
    
    func sendMessage() {
        let userMessage = ChatMessage(role: .user, content: inputText)
        messages.append(userMessage)
        
        let query = inputText
        inputText = ""
        isProcessing = true
        
        Task {
            do {
                let response = try await AIService.shared.queryChatAssistant(query, context: modelContext)
                
                let aiMessage = ChatMessage(role: .assistant, content: response)
                messages.append(aiMessage)
            } catch {
                let errorMessage = ChatMessage(role: .assistant, content: "Sorry, I couldn't process that. Please try again.")
                messages.append(errorMessage)
            }
            
            isProcessing = false
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()
    
    enum Role {
        case user
        case assistant
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.role == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .opacity(dotCount >= index ? 1.0 : 0.3)
                }
            }
            .padding(12)
            .background(Color(.systemGray5))
            .cornerRadius(18)
            
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}
```

**4. Add conversation settings (AI toggle):**

```swift
// Views/Chat/ConversationSettingsView.swift
import SwiftUI
import SwiftData

struct ConversationSettingsView: View {
    let conversation: Conversation
    @Environment(\.modelContext) private var modelContext
    @State private var aiIndexingEnabled = false
    
    var body: some View {
        Form {
            Section("AI Features") {
                Toggle("Enable AI Digest", isOn: $aiIndexingEnabled)
                    .onChange(of: aiIndexingEnabled) { _, newValue in
                        Task {
                            await updateAIIndexing(enabled: newValue)
                        }
                    }
                
                if aiIndexingEnabled {
                    Text("This conversation's messages will be analyzed for events, deadlines, and important messages.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentState()
        }
    }
    
    func loadCurrentState() {
        let descriptor = FetchDescriptor<LocalConversationState>(
            predicate: #Predicate { $0.conversationId == conversation.id }
        )
        
        if let state = try? modelContext.fetch(descriptor).first {
            aiIndexingEnabled = state.aiIndexingEnabled
        }
    }
    
    func updateAIIndexing(enabled: Bool) async {
        // Get or create state
        let descriptor = FetchDescriptor<LocalConversationState>(
            predicate: #Predicate { $0.conversationId == conversation.id }
        )
        
        let state: LocalConversationState
        
        if let existing = try? modelContext.fetch(descriptor).first {
            state = existing
        } else {
            state = LocalConversationState(conversationId: conversation.id)
            modelContext.insert(state)
        }
        
        state.aiIndexingEnabled = enabled
        try? modelContext.save()
        
        // Update Firestore user preferences
        guard let userId = AuthService.shared.currentUserId else { return }
        
        let db = Firestore.firestore()
        
        if enabled {
            try? await db.collection("users").document(userId).updateData([
                "aiPreferences.enabledThreadIds": FieldValue.arrayUnion([conversation.id])
            ])
        } else {
            try? await db.collection("users").document(userId).updateData([
                "aiPreferences.enabledThreadIds": FieldValue.arrayRemove([conversation.id])
            ])
        }
    }
}
```

**5. Update MainTabView:**

```swift
// Views/Main/MainTabView.swift
TabView(selection: $selectedTab) {
    AssistantChatView()
        .tabItem {
            Label("Assistant", systemImage: "sparkles")
        }
        .tag(0)
    
    DigestView()
        .tabItem {
            Label("Digest", systemImage: "tray.full")
        }
        .tag(1)
    
    ChatListView()
        .tabItem {
            Label("Chats", systemImage: "message")
        }
        .tag(2)
    
    SettingsView()
        .tabItem {
            Label("Settings", systemImage: "gearshape")
        }
        .tag(3)
}
```

**Files Created:**
- `Views/Digest/DigestView.swift`
- `Views/Digest/EventsListView.swift`
- `Views/Digest/DeadlinesListView.swift`
- `Views/Digest/PriorityMessagesView.swift`
- `Views/Digest/RSVPListView.swift`
- `Views/Digest/SuggestionsView.swift`
- `Views/Components/EventCardView.swift`
- `Views/Components/DeadlineCardView.swift`
- `Views/Components/PriorityMessageCard.swift`
- `Views/Components/RSVPCardView.swift`
- `Views/Components/SuggestionCardView.swift`
- `Views/Assistant/AssistantChatView.swift`
- `Views/Chat/ConversationSettingsView.swift`

**Files Modified:**
- `Views/Main/MainTabView.swift`
- `Views/Chat/ChatDetailView.swift` (add settings button)

**Verification:**
- [ ] Digest tab displays all sections correctly
- [ ] Can accept/dismiss events
- [ ] Can add events to iOS calendar
- [ ] AI Chat interface works
- [ ] Can send queries and receive responses
- [ ] Conversation settings toggle works
- [ ] Real-time updates work (send message → digest updates)

---

## 📊 Testing Strategy

### **Unit Tests (Firebase Functions)**

```typescript
// Test context preparation
describe('prepareAgentContext', () => {
  it('should deduplicate messages', async () => {
    const context = await prepareAgentContext('background_processing', userId, {
      conversationId: 'conv1',
      recentMessages: [msg1, msg2, msg3],
      newMessage: msg4,
    });
    
    // Should not have duplicates
    const ids = context.messages.map(m => m.id);
    expect(new Set(ids).size).toBe(ids.length);
  });
});

// Test tool execution
describe('Agent tools', () => {
  it('should not create duplicate events', async () => {
    const agent = createUnifiedAgent();
    
    const state = {
      mode: 'background_processing',
      userId: 'user1',
      currentDigest: {
        events: [{ id: 'evt1', title: 'Soccer practice', date: '2025-11-05' }]
      },
      messages: [{ text: 'Soccer practice is at 5pm' }],
      // ... other state
    };
    
    await agent.invoke(state);
    
    // Should call update, not create
    // Check Firestore for single event
  });
});
```

### **Integration Tests (iOS)**

```swift
func testEndToEndEventExtraction() async throws {
    // 1. Enable AI indexing
    let conversation = Conversation(id: "test_conv", type: "direct", participants: ["user1", "user2"])
    let state = LocalConversationState(conversationId: conversation.id, aiIndexingEnabled: true)
    modelContext.insert(state)
    
    // 2. Send message with event
    let message = Message(
        id: "msg1",
        text: "Team meeting tomorrow at 3pm in conference room A",
        senderId: "user2",
        senderName: "Alice",
        conversationId: conversation.id
    )
    modelContext.insert(message)
    try modelContext.save()
    
    // 3. Process message
    try await AIService.shared.processNewMessage(message, conversation: conversation, context: modelContext)
    
    // 4. Wait for digest update
    try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
    
    // 5. Check digest
    let descriptor = FetchDescriptor<DigestEvent>(
        predicate: #Predicate { $0.conversationId == "test_conv" }
    )
    let events = try modelContext.fetch(descriptor)
    
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Team meeting")
    XCTAssertTrue(events[0].date > Date())
}
```

---

## 📈 Success Criteria

### **Functionality (Required)**
- [ ] Messages only stored in SwiftData (no Firestore messages)
- [ ] Pinecone used only for RAG, not storage
- [ ] Single unified agent handles all features
- [ ] Agent can operate in both modes (background_processing, ai_chat)
- [ ] Digest items write to `users/{userId}/digest/`
- [ ] Real-time digest updates via Firestore listeners
- [ ] Per-conversation AI toggle works
- [ ] Calendar integration works
- [ ] AI Chat interface functional

### **Performance Targets**
- [ ] Message processing: <3s (background)
- [ ] AI Chat response: <5s (simple queries)
- [ ] AI Chat response: <15s (complex queries)
- [ ] Digest tab updates: Real-time (<1s after Firestore write)
- [ ] No UI lag when scrolling

### **Accuracy Targets (Rubric)**
- [ ] Calendar extraction: 90%+ accuracy
- [ ] Priority detection: 88%+ accuracy
- [ ] RSVP tracking: 92%+ accuracy
- [ ] Decision summarization: 85%+ accuracy
- [ ] Deadline extraction: 85%+ accuracy

### **Rubric Score**
- [ ] Required AI Features: 14-15/15 points
- [ ] Advanced AI Capability: 9-10/10 points
- [ ] Persona Fit: 5/5 points
- [ ] **Total: 28-30/30 points** 🎯

---

## 💰 Cost Estimates

**For demo/development (1 user, 50 messages/day):**

| Service | Usage | Cost/Month |
|---------|-------|------------|
| Pinecone (free tier) | <100K vectors | $0 |
| OpenAI Embeddings | 1.5K embeds × 500 tokens | $0.02 |
| OpenAI GPT-4o | 200 calls × 2K tokens | $8.00 |
| Firebase Functions | 1.5K invocations | $0 (free tier) |
| Firestore | Minimal ops | $0 (free tier) |
| **Total** | | **~$8/month** |

**For production (1000 users, 100 messages/day average):**

| Service | Usage | Cost/Month |
|---------|-------|------------|
| Pinecone (free tier) | 100K vectors | $0 |
| OpenAI Embeddings | 100K embeds × 500 tokens | $1.00 |
| OpenAI GPT-4o (agent) | 50K calls × 2K tokens avg | $200 |
| Firebase Functions | 500K invocations | $0 (free tier) |
| Firestore Reads/Writes | Digest operations | ~$50 |
| **Total** | | **~$251/month** |

---

## 🚀 Deployment Checklist

### **Backend**
- [ ] Create Pinecone account and index
- [ ] Set up Firebase Functions environment variables
- [ ] Deploy functions: `firebase deploy --only functions`
- [ ] Test functions with curl/Postman
- [ ] Monitor Firebase Console logs

### **iOS**
- [ ] All models compile without errors
- [ ] Services initialize correctly
- [ ] UI renders on simulator and device
- [ ] Real-time updates work
- [ ] Calendar integration works
- [ ] Test on multiple devices

### **Final Verification**
- [ ] Complete end-to-end test (message → digest → calendar)
- [ ] AI Chat responds correctly
- [ ] No memory leaks or crashes
- [ ] Performance acceptable
- [ ] All rubric criteria met

---

## 📚 Implementation Timeline

| Week | PRs | Focus | Deliverables |
|------|-----|-------|--------------|
| **Week 1** | #25-26 | Remove old implementation | Clean slate |
| **Week 2** | #27-28 | New infrastructure | Pinecone, agent framework, iOS models |
| **Week 3** | #29-30 | Agent + Functions | Unified agent, Firebase Functions |
| **Week 4** | #31-32 | iOS Integration | Services, Digest tab, AI Chat |
| **Week 5** | Testing | Polish | Integration tests, bug fixes, demo |

---

## 🎉 Final Notes

This plan **completely replaces** the old implementation with a unified agent architecture that:

1. ✅ Uses SwiftData as single source of truth
2. ✅ Leverages Pinecone purely for RAG
3. ✅ Consolidates all AI features into a single LangGraph agent
4. ✅ Provides user-specific, context-aware intelligence
5. ✅ Meets all rubric criteria for 28-30/30 points

**Key architectural improvements:**
- **Simpler:** One agent instead of 5+ separate functions
- **Smarter:** LLM-driven decisions instead of hardcoded rules
- **Faster:** Local SwiftData reads, efficient RAG search
- **Scalable:** User-specific agents, no shared state
- **Cost-effective:** Minimal Firestore writes, efficient embeddings

**Ready to implement!** Follow PRs sequentially for clean migration. 🚀
