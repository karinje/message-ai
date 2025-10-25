# MessageAI/Weftly - AI Features Implementation Plan
**Comprehensive Architecture for PR #17-24 (AI Phase)**

---

## 📋 Executive Summary

**Goal:** Implement all 5 required AI features + 1 advanced AI capability to score 28-30/30 points on rubric

**Technology Stack:**
- **Backend:** Firebase Functions v2 (Node.js 20, TypeScript)
- **AI Framework:** LangGraph for multi-step agents
- **Vector Store:** Pinecone (free tier: 100K vectors)
- **Embeddings:** OpenAI `text-embedding-3-small` ($0.02/1M tokens)
- **LLM:** GPT-4o-mini (fast features) + GPT-4o (AI chat)
- **iOS Calendar:** Native EventKit (no external API)
- **Deployment:** Firebase Functions, Firebase Firestore (existing)

**Timeline:** 4 days (PR #17-24)

---

## 🏗️ Project Structure Updates

### **New Directory Structure**

```
Weftly/                                    # iOS App (existing)
├── Weftly/
│   ├── Models/
│   │   ├── User.swift                     # ✅ existing
│   │   ├── Message.swift                  # ✅ existing
│   │   ├── Conversation.swift             # ✅ existing
│   │   ├── MessageStatus.swift            # ✅ existing
│   │   ├── ExtractedEvent.swift           # 🆕 calendar event model
│   │   ├── RSVPResponse.swift             # 🆕 RSVP tracking model
│   │   ├── Deadline.swift                 # 🆕 deadline/reminder model
│   │   ├── AIDecision.swift               # 🆕 decision summary model
│   │   └── AIChatMessage.swift            # 🆕 AI assistant chat model
│   │
│   ├── Services/
│   │   ├── FirebaseManager.swift          # ✅ existing
│   │   ├── AuthService.swift              # ✅ existing
│   │   ├── UserService.swift              # ✅ existing
│   │   ├── ChatService.swift              # ✅ existing
│   │   ├── StorageService.swift           # ✅ existing
│   │   ├── NotificationService.swift      # ✅ existing
│   │   ├── NetworkMonitor.swift           # ✅ existing
│   │   ├── AIService.swift                # 🆕 AI features coordinator
│   │   ├── CalendarService.swift          # 🆕 iOS EventKit integration
│   │   └── FunctionsService.swift         # 🆕 Firebase Functions client
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift            # ✅ existing
│   │   ├── ChatListViewModel.swift        # ✅ existing
│   │   ├── ChatDetailViewModel.swift      # ✅ existing - MODIFY for AI features
│   │   ├── ProfileViewModel.swift         # ✅ existing
│   │   ├── GroupChatViewModel.swift       # ✅ existing
│   │   ├── AssistantViewModel.swift       # 🆕 AI assistant chat
│   │   ├── DigestViewModel.swift          # 🆕 Digest tab coordinator
│   │   ├── CalendarViewModel.swift        # 🆕 calendar management
│   │   ├── RSVPViewModel.swift            # 🆕 RSVP tracking
│   │   └── DeadlineViewModel.swift        # 🆕 deadline management
│   │
│   ├── Views/
│   │   ├── Assistant/                     # 🆕 ASSISTANT TAB (pure chat)
│   │   │   ├── AssistantChatView.swift    # 🆕 AI chat interface with quick actions
│   │   │   └── QuickActionsView.swift     # 🆕 quick action buttons
│   │   │
│   │   ├── Digest/                        # 🆕 DIGEST TAB (auto-extracted insights)
│   │   │   ├── DigestView.swift           # 🆕 main Digest tab container
│   │   │   ├── CalendarEventsSection.swift # 🆕 upcoming events section
│   │   │   ├── RSVPSection.swift          # 🆕 RSVP tracking section
│   │   │   ├── DeadlinesSection.swift     # 🆕 deadlines section
│   │   │   └── DecisionsSection.swift     # 🆕 group decisions section
│   │   │
│   │   ├── Chat/
│   │   │   ├── ChatListView.swift         # ✅ existing - MODIFY for priority badges
│   │   │   ├── ChatDetailView.swift       # ✅ existing - MODIFY for AI features
│   │   │   ├── MessageRow.swift           # ✅ existing - MODIFY for priority highlighting
│   │   │   ├── MessageInputView.swift     # ✅ existing
│   │   │   ├── TypingIndicatorView.swift  # ✅ existing
│   │   │   ├── NewChatView.swift          # ✅ existing
│   │   │   ├── PriorityBadgeView.swift    # 🆕 urgent/important badge
│   │   │   └── AIFeaturesBannerView.swift # 🆕 inline AI suggestions
│   │   │
│   │   ├── Components/
│   │   │   ├── UserAvatarView.swift       # ✅ existing
│   │   │   ├── OnlineStatusView.swift     # ✅ existing
│   │   │   ├── ImagePickerView.swift      # ✅ existing
│   │   │   ├── LoadingView.swift          # ✅ existing
│   │   │   ├── EventCardView.swift        # 🆕 calendar event card
│   │   │   ├── RSVPResponseView.swift     # 🆕 RSVP status display
│   │   │   └── DeadlineCardView.swift     # 🆕 deadline card
│   │   │
│   │   └── [other existing views...]
│   │
│   └── Persistence/
│       ├── MessageAIDataModel.xcdatamodeld  # ✅ existing - ADD new entities
│       └── PersistenceController.swift      # ✅ existing - MODIFY for AI data
│
│
functions/                                   # 🆕 NEW FIREBASE FUNCTIONS PROJECT
├── src/
│   ├── index.ts                            # Main function exports
│   │
│   ├── agents/
│   │   ├── aiChatAgent.ts                  # LangGraph multi-tool agent
│   │   └── decisionAgent.ts                # Decision summarization agent
│   │
│   ├── tools/
│   │   ├── messageSearchTool.ts            # Pinecone RAG search
│   │   ├── translateTool.ts                # Translation tool
│   │   ├── calendarTool.ts                 # Calendar operations
│   │   ├── rsvpTool.ts                     # RSVP operations
│   │   ├── deadlineTool.ts                 # Deadline operations
│   │   └── proactiveTool.ts                # Proactive suggestions
│   │
│   ├── features/
│   │   ├── calendarExtraction.ts           # Smart calendar extraction
│   │   ├── priorityDetection.ts            # Priority message highlighting
│   │   ├── rsvpTracking.ts                 # RSVP tracking
│   │   ├── decisionSummarization.ts        # Group decision summary
│   │   └── deadlineExtraction.ts           # Deadline extraction
│   │
│   ├── utils/
│   │   ├── pinecone.ts                     # Pinecone client singleton
│   │   ├── openai.ts                       # OpenAI client singleton
│   │   ├── firestore.ts                    # Firestore helpers
│   │   └── embeddings.ts                   # Message embedding logic
│   │
│   └── types/
│       ├── index.ts                        # TypeScript interfaces
│       ├── messages.ts                     # Message-related types
│       ├── events.ts                       # Event-related types
│       └── agent.ts                        # Agent-related types
│
├── package.json                            # Dependencies
├── tsconfig.json                           # TypeScript config
└── .env.example                            # Environment variables template
```

---

## 🔄 Firestore Data Model Extensions

### **New Collections & Documents**

```
conversations/{conversationId}/
├── messages/{messageId}/                   # ✅ existing
│   ├── text: string                        # ✅ existing
│   ├── senderId: string                    # ✅ existing
│   ├── timestamp: timestamp                # ✅ existing
│   ├── status: string                      # ✅ existing
│   ├── priority: string                    # 🆕 "urgent" | "important" | "normal"
│   ├── priorityReason: string              # 🆕 AI explanation
│   ├── priorityConfidence: number          # 🆕 0-1 score
│   └── embedded: boolean                   # 🆕 true if sent to Pinecone
│
├── extractedEvents/{eventId}/              # 🆕 NEW SUBCOLLECTION
│   ├── title: string                       # "Soccer practice"
│   ├── date: timestamp                     # Event date/time
│   ├── location: string?                   # Optional location
│   ├── messageId: string                   # Source message reference
│   ├── confidence: number                  # 0-1 extraction confidence
│   ├── addedToCalendar: boolean            # iOS EventKit status
│   ├── extractedAt: timestamp              # When AI processed it
│   └── notified: boolean                   # Push notification sent
│
├── rsvps/{eventId}/                        # 🆕 NEW SUBCOLLECTION
│   ├── eventTitle: string                  # "Birthday party"
│   ├── eventDate: timestamp                # Event date
│   ├── responses: map                      # { userId: response }
│   │   └── {userId}: {
│   │       status: "yes" | "no" | "maybe" | "no_reply"
│   │       numberOfGuests: number?
│   │       note: string?
│   │       respondedAt: timestamp?
│   │   }
│   ├── totalParticipants: number           # Group size
│   ├── lastUpdated: timestamp              # Last RSVP change
│   └── messageId: string                   # Source message
│
└── decisions/{decisionId}/                 # 🆕 NEW SUBCOLLECTION
    ├── topic: string                       # "Where to have party"
    ├── decision: string                    # "Pizza place on Friday"
    ├── participants: [string]              # User IDs who agreed
    ├── confidence: number                  # 0-1 AI confidence
    ├── timestamp: timestamp                # When decided
    ├── messageIds: [string]                # Thread leading to decision
    └── extractedAt: timestamp              # When AI processed it

users/{userId}/
├── email: string                           # ✅ existing
├── displayName: string                     # ✅ existing
├── profilePictureUrl: string               # ✅ existing
├── lastSeen: timestamp                     # ✅ existing
├── fcmToken: string                        # ✅ existing
├── isOnline: boolean                       # ✅ existing
├── aiPreferences: map                      # 🆕 NEW FIELD
│   ├── enablePriorityDetection: boolean    # Default: true
│   ├── enableCalendarExtraction: boolean   # Default: true
│   ├── enableRSVPTracking: boolean         # Default: true
│   ├── enableDeadlineReminders: boolean    # Default: true
│   └── proactiveSuggestionsEnabled: boolean # Default: true
│
└── deadlines/{deadlineId}/                 # 🆕 NEW SUBCOLLECTION
    ├── task: string                        # "Bring cupcakes"
    ├── dueDate: timestamp                  # Deadline date
    ├── priority: "high" | "medium" | "low" # AI-determined
    ├── conversationId: string              # Source conversation
    ├── messageId: string                   # Source message
    ├── completed: boolean                  # User-marked status
    ├── confidence: number                  # 0-1 AI confidence
    ├── createdAt: timestamp                # When extracted
    └── reminderSent: boolean               # Push notification sent

aiChats/{chatId}/                           # 🆕 NEW ROOT COLLECTION
├── userId: string                          # Owner of this chat
├── messages: [                             # Chat history
│   {
│       role: "user" | "assistant"
│       content: string
│       timestamp: timestamp
│       toolsUsed?: [string]                # Which tools agent called
│   }
│ ]
├── createdAt: timestamp
└── updatedAt: timestamp
```

---

## 📱 iOS App Tab Structure (Redesigned for Busy Parents)

### **Tab Organization:**

**Tab 1 (Leftmost): Assistant** 🤖
- Pure conversational AI chat interface
- Chat about ANY message thread or conversation
- Quick action buttons (search, translate, summarize, etc.)
- Uses LangGraph multi-tool agent backend

**Tab 2: Digest** 📊
- Auto-extracted AI insights at a glance
- Sections: Upcoming Events, Pending RSVPs, Deadlines, Recent Decisions
- Sorted by urgency and time
- Tap any item to navigate to source conversation

**Tab 3: Chats** 💬
- Main messaging interface (existing)

**Tab 4 (Rightmost): Settings** ⚙️
- Account, Privacy, Lists, Broadcasts (existing)

---

## 📱 iOS App Changes (PR #17-18)

### **PR #17: AI Infrastructure Setup**
**Branch:** `feature/ai-infrastructure`  
**Estimated Time:** 4-6 hours  
**Description:** Set up AI services, Firebase Functions client, data models, and SwiftData extensions

#### **Tasks:**

**1. Create New Swift Models**

**Files to Create:**
- `Models/ExtractedEvent.swift`
  - Properties: id, title, date, location?, confidence, addedToCalendar, messageId
  - SwiftData model + Codable for Firestore sync
  
- `Models/RSVPResponse.swift`
  - Properties: eventId, eventTitle, eventDate, responses (dictionary), totalParticipants
  - Methods: percentageResponded(), needsReminderUsers()
  
- `Models/Deadline.swift`
  - Properties: id, task, dueDate, priority, conversationId, messageId, completed
  - Methods: isDueToday(), isDueTomorrow(), isOverdue()
  
- `Models/AIDecision.swift`
  - Properties: id, topic, decision, participants, confidence, timestamp
  - Methods: participantNames(from: UserService)
  
- `Models/AIChatMessage.swift`
  - Properties: id, role (user/assistant), content, timestamp, toolsUsed?
  - Enum: AIChatRole { case user, assistant }

**2. Create iOS AI Services**

**Files to Create:**
- `Services/FunctionsService.swift`
  - Purpose: Wrapper for Firebase Functions calls
  - Methods:
    - `callFunction<T>(_ name: String, data: [String: Any]) async throws -> T`
    - `extractCalendarEvents(messageText: String, conversationId: String) async throws -> [ExtractedEvent]`
    - `trackRSVP(conversationId: String, eventId: String) async throws -> RSVPResponse`
    - `summarizeDecisions(conversationId: String) async throws -> [AIDecision]`
    - `detectPriority(messageText: String) async throws -> MessagePriority`
    - `extractDeadlines(messageText: String) async throws -> [Deadline]`
    - `sendAIChatMessage(message: String, chatId: String, history: [AIChatMessage]) async throws -> String`
  - Error handling: NetworkError enum with retry logic
  
- `Services/CalendarService.swift`
  - Purpose: iOS EventKit integration for native calendar
  - Methods:
    - `requestCalendarAccess() async throws -> Bool`
    - `addEvent(_ event: ExtractedEvent) async throws`
    - `getUpcomingEvents(days: Int) async throws -> [EKEvent]`
    - `removeEvent(eventId: String) async throws`
  - Properties: `eventStore: EKEventStore`
  
- `Services/AIService.swift`
  - Purpose: Coordinator for all AI features, caching, background processing
  - Methods:
    - `processNewMessage(_ message: Message) async` // Triggers all AI analysis
    - `getExtractedEvents(for conversationId: String) -> [ExtractedEvent]`
    - `getRSVPs(for conversationId: String) -> [RSVPResponse]`
    - `getDecisions(for conversationId: String) -> [AIDecision]`
    - `getUserDeadlines() -> [Deadline]`
    - `togglePriorityDetection(enabled: Bool) async`
  - Caching: In-memory cache with 5-minute TTL
  - Background: Queue for batch processing

**3. Extend SwiftData Schema**

**Files to Modify:**
- `Persistence/MessageAIDataModel.xcdatamodeld`
  - Add entities: ExtractedEvent, Deadline (for offline caching)
  - Add attributes to Message entity:
    - priority: String? (optional: "urgent", "important")
    - priorityReason: String?
  - Create relationships as needed

**4. Firebase Functions Client Setup**

**Files to Modify:**
- `Services/FirebaseManager.swift`
  - Add Firebase Functions initialization:
    ```swift
    import FirebaseFunctions
    
    static let functions = Functions.functions()
    ```

**5. Update Main Tab View**

**Files to Modify:**
- `Views/Main/MainTabView.swift`
  - Ensure AI tab is properly wired
  - Add `.badge()` to AI tab icon (show pending items count)

#### **Verification Checklist:**
- [ ] All new models compile
- [ ] FunctionsService can call Firebase Functions (test with simple echo function)
- [ ] CalendarService requests permission correctly
- [ ] AIService initializes without errors
- [ ] SwiftData schema migrates successfully

---

### **PR #18: AI Chat Interface + Digest Tab (Advanced AI Feature)**
**Branch:** `feature/ai-assistant-and-digest`  
**Estimated Time:** 6-8 hours  
**Description:** Implement Assistant tab (AI chat) and Digest tab (auto-extracted insights)

#### **Tasks:**

**1. Create Assistant Tab Views (Pure Chat Interface)**

**Files to Create:**
- `Views/Assistant/AssistantChatView.swift` (replaces AITabView)
  - Pure conversational AI chat interface
  - Message bubbles for user/assistant (similar to ChatDetailView style)
  - Input field with "Ask anything..." placeholder
  - Quick action buttons above input (horizontal scroll):
    - "📅 Show Calendar"
    - "✅ Pending RSVPs"
    - "⏰ Deadlines"
    - "🔍 Search Messages"
    - "🌐 Translate"
  - Loading indicator while AI responds
  - Typing indicator animation
  - Auto-scroll to bottom on new message
  - No navigation - this IS the tab content
  
- `Views/Assistant/QuickActionsView.swift`
  - Horizontal scrollable row of action chips
  - Each chip triggers pre-filled query to AI
  - Icons + labels

**2. Create Digest Tab Views (Auto-Extracted Insights)**

**Files to Create:**
- `Views/Digest/DigestView.swift`
  - Main container for Digest tab
  - Scrollable list of collapsible sections:
    - Upcoming Events (sorted by date)
    - Pending RSVPs (needs attention)
    - Deadlines (sorted by urgency)
    - Recent Decisions (last 7 days)
  - Each section shows count badge
  - Empty state: "No insights yet - start chatting!"
  - Pull to refresh to re-scan conversations
  
- `Views/Digest/CalendarEventsSection.swift`
  - Collapsible section for extracted calendar events
  - Group by: Today, This Week, Later
  - Each card shows:
    - Event title
    - Date/time
    - Location (if any)
    - "Add to Calendar" button
    - Tap card → navigate to source conversation
  - Empty state: "No upcoming events found"
  
- `Views/Digest/RSVPSection.swift`
  - Collapsible section for active RSVP tracking
  - Each card shows:
    - Event title + date
    - Visual summary: 8 Yes / 2 Maybe / 1 No / 3 No Reply
    - Progress bar
    - "Remind No Replies" button
    - Tap card → navigate to source conversation
  - Empty state: "No active RSVPs"
  
- `Views/Digest/DeadlinesSection.swift`
  - Collapsible section for user's deadlines
  - Group by: Overdue, Today, This Week, Later
  - Each card shows:
    - Task description
    - Due date
    - Priority badge (high/medium/low)
    - Checkbox to mark complete
    - Tap card → navigate to source conversation
  - Swipe to complete
  - Empty state: "No deadlines found"
  
- `Views/Digest/DecisionsSection.swift`
  - Collapsible section for group decisions
  - Each card shows:
    - Decision topic
    - Final decision
    - Participants (with avatars)
    - Timestamp
    - Tap card → navigate to source conversation
  - Empty state: "No group decisions yet"

**3. Create UI Components (Shared)**

**Files to Create:**
- `Views/Components/EventCardView.swift`
  - Reusable card for calendar events
  - Shows: icon, title, datetime, location, confidence indicator
  
- `Views/Components/RSVPResponseView.swift`
  - Visual display of RSVP status
  - Color-coded badges: green (yes), orange (maybe), red (no), gray (no reply)
  
- `Views/Components/DeadlineCardView.swift`
  - Card with priority color strip
  - Checkbox, task text, due date
  - Urgency indicator (e.g., "Due in 2 hours")

**4. Create ViewModels**

**Files to Create:**
- `ViewModels/AssistantViewModel.swift` (renamed from AIChatViewModel)
  - Properties:
    - `messages: [AIChatMessage]`
    - `currentChatId: String?`
    - `isLoading: Bool`
    - `errorMessage: String?`
  - Methods:
    - `sendMessage(_ text: String) async`
    - `loadChatHistory() async`
    - `handleQuickAction(_ action: QuickAction) async`
  - Uses FunctionsService to call AI agent
  
- `ViewModels/CalendarViewModel.swift`
  - Properties:
    - `extractedEvents: [ExtractedEvent]`
    - `isLoading: Bool`
  - Methods:
    - `loadEvents() async`
    - `addToCalendar(_ event: ExtractedEvent) async`
    - `deleteEvent(_ event: ExtractedEvent) async`
  - Listens to Firestore subcollection: `conversations/{id}/extractedEvents`
  
- `ViewModels/RSVPViewModel.swift`
  - Properties:
    - `activeRSVPs: [RSVPResponse]`
    - `isLoading: Bool`
  - Methods:
    - `loadRSVPs() async`
    - `sendReminders(for eventId: String) async`
    - `refreshRSVP(_ eventId: String) async`
  - Listens to Firestore subcollection: `conversations/{id}/rsvps`
  
- `ViewModels/DeadlineViewModel.swift`
  - Properties:
    - `deadlines: [Deadline]`
    - `isLoading: Bool`
  - Methods:
    - `loadDeadlines() async`
    - `markComplete(_ deadline: Deadline) async`
    - `deleteDeadline(_ deadline: Deadline) async`
  - Computed properties: `overdueDeadlines`, `todayDeadlines`, `upcomingDeadlines`
  - Listens to Firestore subcollection: `users/{uid}/deadlines`

- `ViewModels/DigestViewModel.swift` (NEW)
  - Properties:
    - `@Published var events: [ExtractedEvent] = []`
    - `@Published var rsvps: [RSVPResponse] = []`
    - `@Published var deadlines: [Deadline] = []`
    - `@Published var decisions: [AIDecision] = []`
    - `@Published var isLoading = false`
    - `@Published var lastRefreshed: Date?`
  - Methods:
    - `loadAllInsights() async` - load all 4 sections
    - `refresh() async` - manual refresh
  - Computed properties:
    - `upcomingEventCount: Int`
    - `pendingRSVPCount: Int`
    - `overdueDeadlineCount: Int`
    - `recentDecisionCount: Int`

**5. Integrate into Main App**

**Files to Modify:**
- `Views/Main/MainTabView.swift`
  - Tab 1: AssistantChatView (rename from AIView)
  - Tab 2: DigestView (rename from UpdatesView)
  - Tab 3: ChatListView (unchanged)
  - Tab 4: SettingsView (unchanged)
  - Update tab labels and icons:
    - "Assistant" with sparkles icon
    - "Digest" with chart.bar.doc.horizontal icon (or similar)
  - Add badge to Digest tab showing total pending items

#### **Verification Checklist:**
- [ ] Assistant tab renders correctly (pure chat interface)
- [ ] Can send message to AI and get response
- [ ] Quick action buttons trigger appropriate queries
- [ ] Digest tab shows all 4 sections (Events, RSVPs, Deadlines, Decisions)
- [ ] Calendar events section shows extracted events grouped by time
- [ ] "Add to Calendar" adds event to iOS Calendar
- [ ] RSVP section shows correct counts and progress bars
- [ ] Deadlines section shows tasks grouped by urgency
- [ ] Decisions section shows recent group decisions
- [ ] Tapping any card navigates to source conversation
- [ ] Pull to refresh works on Digest tab
- [ ] All sections have proper empty states
- [ ] Badge on Digest tab shows total pending items count

---

## ☁️ Firebase Functions Implementation (PR #19-24)

### **PR #19: Functions Infrastructure + Calendar Extraction**
**Branch:** `feature/functions-infrastructure`  
**Estimated Time:** 6-8 hours  
**Description:** Set up Firebase Functions project, Pinecone, OpenAI clients, implement calendar extraction

#### **Project Setup:**

**1. Initialize Functions Project**
```bash
cd Weftly/  # project root
firebase init functions
# Select TypeScript
# Install dependencies: Yes
# ESLint: Yes
```

**2. Install Dependencies**
```bash
cd functions
npm install @langchain/langgraph @langchain/openai @langchain/core
npm install @pinecone-database/pinecone openai zod
npm install --save-dev @types/node
```

**3. Configure Environment**
```bash
firebase functions:config:set \
  openai.key="YOUR_OPENAI_API_KEY" \
  pinecone.key="YOUR_PINECONE_API_KEY" \
  pinecone.environment="gcp-starter" \
  pinecone.index="weftly-messages"
```

**4. Create Pinecone Index**
- Go to https://app.pinecone.io
- Create account (free tier)
- Create index:
  - Name: `weftly-messages`
  - Dimensions: 1536 (for text-embedding-3-small)
  - Metric: cosine
  - Environment: gcp-starter (free)

#### **Files to Create:**

**Core Utilities:**

1. `functions/src/utils/openai.ts`
   - Purpose: OpenAI client singleton
   - Exports:
     - `getOpenAIClient(): OpenAI`
     - `createEmbedding(text: string): Promise<number[]>`
     - `createStructuredCompletion<T>(system: string, user: string, model): Promise<T>`
   - Features: JSON mode for structured outputs, error handling, retry logic

2. `functions/src/utils/pinecone.ts`
   - Purpose: Pinecone client singleton
   - Exports:
     - `getPineconeIndex(): Index`
     - `upsertMessage(message: MessageData): Promise<void>`
     - `queryMessages(query: string, filters: Record<string, any>, topK: number): Promise<Match[]>`
     - `deleteConversationMessages(conversationId: string): Promise<void>`
   - Features: Batch upserts, metadata filtering, error handling

3. `functions/src/utils/firestore.ts`
   - Purpose: Firestore helper functions
   - Exports:
     - `getConversation(conversationId: string): Promise<Conversation>`
     - `getMessages(conversationId: string, limit: number): Promise<Message[]>`
     - `getUserProfile(userId: string): Promise<User>`
     - `updateMessagePriority(messageId: string, priority: Priority): Promise<void>`
   - Features: Type-safe queries, error handling

4. `functions/src/types/index.ts`
   - Purpose: TypeScript types/interfaces
   - Types to define:
     - `Message`, `Conversation`, `User`, `ExtractedEvent`, `RSVPResponse`
     - `Priority`, `CalendarEvent`, `Deadline`, `Decision`
     - `AIRequest`, `AIResponse`, `ToolResult`

**Calendar Extraction Feature:**

5. `functions/src/features/calendarExtraction.ts`
   - Purpose: Extract calendar events from messages
   - Main function: `extractCalendarEvents(data: { messageText: string, conversationId: string, messageId: string }): Promise<ExtractedEvent[]>`
   - Process:
     1. Use GPT-4o-mini with JSON mode
     2. System prompt: Extract structured calendar events
     3. Return: array of events with confidence scores
     4. Store in Firestore: `conversations/{id}/extractedEvents`
     5. Only store if confidence > 0.7
   - Response format:
     ```typescript
     {
       events: [
         {
           title: string,
           date: ISO8601,
           time?: ISO8601,
           location?: string,
           confidence: 0-1
         }
       ]
     }
     ```

6. `functions/src/index.ts`
   - Export calendar extraction function:
     ```typescript
     export const extractCalendarEvents = onCall(async (request) => {
       const { messageText, conversationId, messageId } = request.data;
       // Call feature implementation
       // Return result
     });
     ```
   - Also export background trigger for automatic extraction:
     ```typescript
     export const onMessageCreated = onDocumentCreated(
       'conversations/{convId}/messages/{msgId}',
       async (event) => {
         // Auto-extract calendar events from new messages
       }
     );
     ```

#### **Implementation Notes (Completed):**

**✅ Timezone Handling (Critical Fix):**
- **Problem:** OpenAI was interpreting "tomorrow at 2pm" as UTC time, causing events to appear in the past for PST users
- **Solution 1 - OpenAI Prompt Enhancement:**
  - Added explicit timezone context to system prompt in `calendarExtraction.ts`
  - Instructed AI to interpret times as Pacific Time and convert to UTC
  - Example: "2pm PT" → "21:00 UTC" (during PDT) or "22:00 UTC" (during PST)
  - Included current date/time in PT format for relative date calculations ("tomorrow", "next week")
- **Solution 2 - Firestore Timestamp Storage:**
  - Modified `utils/firestore.ts` `storeExtractedEvents()` function
  - Convert ISO string dates to `admin.firestore.Timestamp.fromDate()` before storage
  - Ensures proper date serialization/deserialization across platforms
- **Solution 3 - iOS Date Decoding:**
  - Updated `ExtractedEvent.swift` Codable implementation
  - Handle both Firestore Timestamps and ISO8601 strings for backward compatibility
  - Added debug logging in `FirestoreService.swift` for troubleshooting
- **Result:** Events now correctly stored and displayed in user's local timezone

**⚠️ Known Issue - `addedToCalendar` Tracking:**
- **Current:** Single `addedToCalendar: Bool` on event (shared across all participants)
- **Problem:** If User A adds event to calendar, button shows "Added" for ALL users
- **Proper Fix:** Change to `addedByUsers: [String]` (array of user IDs)
- **Status:** Deferred to future polish pass (not blocking for MVP)

**📦 Simplified Implementation (Pinecone Deferred):**
- Pinecone integration NOT implemented in PR #19 (will be added in PR #23/24 for RAG search)
- Focus: Core calendar extraction + background processing only
- Dependencies: OpenAI API only (GPT-4o-mini for extraction)

#### **Verification Checklist:**
- [x] Functions project compiles: `npm run build`
- [x] Can deploy: `firebase deploy --only functions`
- [x] OpenAI client works (timezone-aware completions)
- [x] Calendar extraction returns structured events with correct dates/times
- [x] Events stored in Firestore as Timestamps (not ISO strings)
- [x] iOS app displays events correctly in Digest tab
- [x] Background trigger (`onMessageCreated`) auto-extracts events
- [x] "Add to Calendar" button integrates with iOS EventKit
- [x] Timezone conversion handles PST/PDT correctly

**Status: ✅ COMPLETE**

---

### **PR #20: Priority Detection (Background Processing)**
**Branch:** `feature/priority-detection`  
**Estimated Time:** 4-5 hours  
**Description:** Real-time priority analysis for incoming messages

**Status: ✅ COMPLETE**

#### **Files to Create:**

1. `functions/src/features/priorityDetection.ts`
   - Purpose: Classify message urgency for busy parents
   - Main function: `detectMessagePriority(messageText: string): Promise<PriorityResult>`
   - Process:
     1. Use GPT-4o-mini with JSON mode
     2. System prompt: Classify urgency for busy parent persona
     3. Categories:
        - **urgent**: Needs immediate action (pickup, emergency, deadline <2h)
        - **important**: Needs attention today (schedule change, RSVP needed)
        - **normal**: General information
     4. Return: priority level, reason, confidence score
   - Keywords to boost priority:
     - "emergency", "ASAP", "urgent", "now", "immediately"
     - "pick up", "forgot", "deadline", "due today"
     - Time-sensitive: "in 30 minutes", "at 3pm today"
   - Response format:
     ```typescript
     {
       priority: "urgent" | "important" | "normal",
       reason: string,
       confidence: 0-1
     }
     ```

2. Update `functions/src/index.ts`
   - Export background trigger:
     ```typescript
     export const analyzePriority = onDocumentCreated(
       'conversations/{convId}/messages/{msgId}',
       async (event) => {
         const message = event.data?.data();
         if (!message) return;
         
         const result = await detectMessagePriority(message.text);
         
         // Only update if confidence > 0.75
         if (result.confidence > 0.75) {
           await event.data.ref.update({
             priority: result.priority,
             priorityReason: result.reason,
             priorityConfidence: result.confidence
           });
           
           // Send urgent push notification
           if (result.priority === 'urgent') {
             await sendUrgentNotification(message);
           }
         }
       }
     );
     ```
   - Helper: `sendUrgentNotification(message: Message)` sends special push with 🚨 icon

#### **iOS Changes:**

**Files to Modify:**
1. `Views/Chat/MessageRow.swift`
   - Add priority badge visual:
     - Urgent: red exclamation triangle, red tinted background
     - Important: orange star, orange tinted background
     - Normal: no badge
   - Layout: badge on left side of message bubble
   
2. `Views/Chat/ChatListView.swift`
   - Add priority badge to conversation preview
   - Badge appears if last message is urgent/important
   - Badge count: number of unread priority messages
   
3. `Views/Components/PriorityBadgeView.swift` (NEW)
   - Reusable component for priority display
   - Props: `priority: String`, `size: BadgeSize`
   - Renders appropriate icon + color

4. `ViewModels/ChatDetailViewModel.swift`
   - Listen for priority updates on messages
   - Update UI when priority field changes

#### **Verification Checklist:**
- [ ] Background function triggers on new message
- [ ] Priority correctly classified for test messages
- [ ] Message document updated with priority field
- [ ] Urgent messages send push notification
- [ ] iOS displays priority badges correctly
- [ ] Badge colors match urgency level

---

### **PR #21: RSVP Tracking**
**Branch:** `feature/rsvp-tracking`  
**Estimated Time:** 5-6 hours  
**Description:** Extract and track RSVP responses in group chats

#### **Files to Create:**

1. `functions/src/features/rsvpTracking.ts`
   - Purpose: Extract RSVP responses from group chat messages
   - Main function: `trackRSVP(data: { conversationId: string, eventId?: string }): Promise<RSVPResponse>`
   - Process:
     1. Retrieve last 100 messages from conversation
     2. Identify event mention (if eventId provided, find that event, else detect latest event discussion)
     3. Use GPT-4o-mini to extract RSVP responses
     4. System prompt: Parse RSVP responses from group chat
     5. Match responses to user IDs
     6. Count: yes/no/maybe/no_reply
   - Response format:
     ```typescript
     {
       eventId: string,
       eventTitle: string,
       eventDate: Date,
       rsvps: {
         [userId: string]: {
           status: "yes" | "no" | "maybe" | "no_reply",
           numberOfGuests?: number,
           note?: string,
           respondedAt?: Date
         }
       },
       totalParticipants: number,
       lastUpdated: Date
     }
     ```
   - Store result in: `conversations/{id}/rsvps/{eventId}`

2. `functions/src/tools/rsvpTool.ts`
   - Purpose: LangGraph tool for RSVP operations
   - Exports: `createRSVPTool()`
   - Operations:
     - "list": Get all active RSVPs for a conversation
     - "track": Analyze conversation for RSVP responses
     - "remind": Trigger reminder notifications
   - Used by AI chat agent

3. Update `functions/src/index.ts`
   - Export callable function:
     ```typescript
     export const trackRSVP = onCall(async (request) => {
       const { conversationId, eventId } = request.data;
       return await rsvpTracking.trackRSVP({ conversationId, eventId });
     });
     
     export const sendRSVPReminders = onCall(async (request) => {
       const { eventId, conversationId } = request.data;
       // Get no_reply users
       // Send broadcast message or push notifications
     });
     ```

#### **iOS Changes:**

**Files to Modify:**
1. `Views/AI/RSVPDashboardView.swift`
   - Load RSVPs from Firestore listener
   - Display visual summary (progress bars, counts)
   - "Remind No Replies" button calls `sendRSVPReminders` function
   
2. `ViewModels/RSVPViewModel.swift`
   - Properties:
     - `@Published var activeRSVPs: [RSVPResponse] = []`
     - `@Published var isLoading = false`
   - Methods:
     - `loadRSVPs() async` - queries Firestore collectionGroup
     - `refreshRSVP(eventId: String, conversationId: String) async` - calls Firebase Function
     - `sendReminders(eventId: String) async` - calls Firebase Function
   - Firestore listener: listen to all `rsvps` subcollections across conversations

#### **Verification Checklist:**
- [ ] RSVP extraction correctly identifies responses
- [ ] Matches user IDs to responses
- [ ] Handles "maybe" and guest counts
- [ ] Stores results in Firestore correctly
- [ ] iOS displays RSVP dashboard
- [ ] "Remind" button sends notifications
- [ ] Real-time updates when responses change

---

### **PR #22: Decision Summarization**
**Branch:** `feature/decision-summarization`  
**Estimated Time:** 5-6 hours  
**Description:** Summarize group chat decisions using LangGraph agent

#### **Files to Create:**

1. `functions/src/agents/decisionAgent.ts`
   - Purpose: Multi-step agent for analyzing group decisions
   - Uses: LangGraph StateGraph
   - Tools: message retrieval, participant lookup, confidence scoring
   - Process:
     1. Query Pinecone for relevant messages about topic
     2. Use GPT-4o-mini to identify decision points
     3. Track who agreed/disagreed
     4. Determine final consensus
     5. Extract timestamp of decision
   - Response format:
     ```typescript
     {
       decisions: [
         {
           topic: string,
           decision: string,
           participants: string[],  // user IDs who agreed
           confidence: 0-1,
           timestamp: Date,
           messageIds: string[]  // thread leading to decision
         }
       ]
     }
     ```

2. `functions/src/features/decisionSummarization.ts`
   - Purpose: Wrapper for decision agent
   - Main function: `summarizeDecisions(data: { conversationId: string, query?: string }): Promise<Decision[]>`
   - If query provided: find decisions about that topic
   - Else: find all recent decisions (last 7 days)
   - Store results in: `conversations/{id}/decisions/{decisionId}`

3. Update `functions/src/index.ts`
   - Export callable function:
     ```typescript
     export const summarizeDecisions = onCall(async (request) => {
       const { conversationId, query } = request.data;
       return await decisionSummarization.summarizeDecisions({ conversationId, query });
     });
     ```
   - Export scheduled function (daily summary):
     ```typescript
     export const dailyDecisionSummary = onSchedule(
       { schedule: 'every day 20:00', timeZone: 'America/Los_Angeles' },
       async (event) => {
         // For each active conversation
         // Generate decision summary
         // Store in Firestore
       }
     );
     ```

#### **iOS Changes:**

**Files to Modify:**
1. `Views/AI/DecisionSummaryView.swift`
   - Load decisions from Firestore
   - Display cards with topic, decision, participants
   - "View Thread" button navigates to original messages
   
2. `Views/Chat/GroupDetailView.swift` (existing file)
   - Add "Decisions" section
   - Shows extracted decisions for this group
   - "See All Decisions" navigates to AI tab

#### **Verification Checklist:**
- [ ] Agent correctly identifies group decisions
- [ ] Tracks participant agreement
- [ ] Handles ambiguous discussions (doesn't falsely detect decisions)
- [ ] Stores decisions in Firestore
- [ ] iOS displays decisions correctly
- [ ] "View Thread" navigates to source messages
- [ ] Daily summary runs successfully

---

### **PR #23: Deadline Extraction**
**Branch:** `feature/deadline-extraction`  
**Estimated Time:** 4-5 hours  
**Description:** Extract deadlines and commitments from messages, send reminders

**Status: ✅ COMPLETE**

#### **Files to Create:**

1. `functions/src/features/deadlineExtraction.ts`
   - Purpose: Extract deadlines and commitments
   - Main function: `extractDeadlines(data: { messageText: string, conversationId: string, messageId: string }): Promise<Deadline[]>`
   - Process:
     1. Use GPT-4o-mini with JSON mode
     2. System prompt: Extract deadlines, commitments, action items
     3. Determine priority based on urgency
     4. Return structured deadlines
   - Response format:
     ```typescript
     {
       deadlines: [
         {
           task: string,
           dueDate: Date,
           assignedTo?: string,  // user ID if mentioned
           priority: "high" | "medium" | "low",
           confidence: 0-1
         }
       ]
     }
     ```
   - Store in: `users/{userId}/deadlines/{deadlineId}`
   - If assignedTo present, store in that user's deadlines, else store for message recipient

2. `functions/src/utils/embeddings.ts`
   - Purpose: Message embedding for Pinecone
   - Main function: `embedMessage(message: Message): Promise<void>`
   - Process:
     1. Generate embedding using OpenAI text-embedding-3-small
     2. Upsert to Pinecone with metadata
   - Called by: background trigger on new messages

3. Update `functions/src/index.ts`
   - Export callable function:
     ```typescript
     export const extractDeadlines = onCall(async (request) => {
       const { messageText, conversationId, messageId } = request.data;
       return await deadlineExtraction.extractDeadlines({ messageText, conversationId, messageId });
     });
     ```
   - Export background triggers:
     ```typescript
     export const onMessageCreatedEmbedding = onDocumentCreated(
       'conversations/{convId}/messages/{msgId}',
       async (event) => {
         const message = event.data?.data();
         await embedMessage(message);  // Store in Pinecone
       }
     );
     
     export const sendDeadlineReminders = onSchedule(
       { schedule: 'every day 08:00', timeZone: 'America/Los_Angeles' },
       async (event) => {
         // Find deadlines due tomorrow
         // Send push notifications
       }
     );
     ```

#### **iOS Changes:**

**Files to Modify:**
1. `Views/AI/DeadlinesView.swift`
   - Load deadlines from Firestore listener
   - Group by: Overdue, Today, This Week, Later
   - Swipe to mark complete
   - Tap to see source message
   
2. `ViewModels/DeadlineViewModel.swift`
   - Listen to `users/{uid}/deadlines` collection
   - Computed properties for grouping
   - Methods:
     - `markComplete(_ deadline: Deadline) async`
     - `deleteDeadline(_ deadline: Deadline) async`

#### **Verification Checklist:**
- [ ] Deadline extraction identifies commitments correctly
- [ ] Priority classification makes sense
- [ ] Deadlines stored in user's subcollection
- [ ] iOS displays deadlines grouped by date
- [ ] Swipe to complete works
- [ ] Daily reminder notifications sent
- [ ] Messages embedded to Pinecone successfully

---

### **PR #24: AI Chat Agent (Advanced Feature)**
**Branch:** `feature/ai-chat-agent`  
**Estimated Time:** 8-10 hours  
**Description:** LangGraph multi-tool agent for conversational AI assistant

#### **Files to Create:**

**Tools:**

1. `functions/src/tools/messageSearchTool.ts`
   - Purpose: Search through conversation history using Pinecone RAG
   - Schema: `{ query: string, conversationId: string, topK?: number }`
   - Process:
     1. Generate embedding for query
     2. Query Pinecone with conversationId filter
     3. Return top matches with metadata
   - Used for: "Find messages about...", "When did we discuss..."

2. `functions/src/tools/translateTool.ts`
   - Purpose: Translate messages to different languages
   - Schema: `{ messageId: string, targetLanguage: string }`
   - Process:
     1. Fetch message from Firestore
     2. Use GPT-4o-mini to translate
     3. Return translated text
   - Used for: "Translate my last message to Spanish"

3. `functions/src/tools/calendarTool.ts`
   - Purpose: Calendar operations (list, add, remove events)
   - Schema: `{ conversationId: string, action: "list" | "add" | "remove", eventId?: string }`
   - Operations:
     - list: Get extracted events for conversation
     - add: Trigger calendar extraction
     - remove: Delete extracted event
   - Used for: "Show me upcoming events", "What's on my calendar?"

4. `functions/src/tools/deadlineTool.ts`
   - Purpose: Deadline operations (list, complete, add)
   - Schema: `{ userId: string, action: "list" | "complete" | "add", deadlineId?: string }`
   - Operations:
     - list: Get user's deadlines
     - complete: Mark deadline as done
     - add: Manually create deadline
   - Used for: "What are my deadlines?", "Mark task as complete"

5. `functions/src/tools/proactiveTool.ts`
   - Purpose: Generate proactive suggestions based on conversation analysis
   - Schema: `{ conversationId: string, analysisType?: "conflicts" | "rsvps" | "deadlines" }`
   - Process:
     1. Retrieve recent messages (last 100)
     2. Use GPT-4o to analyze for:
        - Scheduling conflicts (overlapping events)
        - Pending RSVPs needing response
        - Approaching deadlines without confirmation
        - Important messages needing reply
     3. Return prioritized suggestions
   - Response format:
     ```typescript
     {
       suggestions: [
         {
           type: "conflict" | "rsvp" | "deadline" | "response",
           priority: "high" | "medium" | "low",
           description: string,
           action: string,
           relatedMessageIds?: string[]
         }
       ]
     }
     ```
   - Used for: Proactive assistant feature (auto-triggers)

**Agent:**

6. `functions/src/agents/aiChatAgent.ts`
   - Purpose: Main LangGraph agent with multi-tool support
   - Framework: LangGraph StateGraph
   - Tools: All 5 tools above
   - Model: GPT-4o (for best reasoning)
   - State: Maintains conversation history, tool results
   - Process:
     1. Receive user query + chat history
     2. Agent decides which tool(s) to use
     3. Execute tools in sequence or parallel
     4. Synthesize results into natural response
     5. Return response + metadata (which tools used)
   - Features:
     - Context awareness (remembers conversation)
     - Multi-step reasoning (can chain tools)
     - Error recovery (retries failed tools)
     - Response streaming (optional for real-time updates)

7. Update `functions/src/index.ts`
   - Export callable function:
     ```typescript
     export const aiChatAgent = onCall(async (request) => {
       const { query, chatId, history } = request.data;
       const userId = request.auth?.uid;
       
       if (!userId) {
         throw new HttpsError('unauthenticated', 'User must be authenticated');
       }
       
       const agent = createAIChatAgent();
       const result = await agent.invoke({
         messages: [
           ...history.map(m => ({ role: m.role, content: m.content })),
           { role: 'user', content: query }
         ],
         userId,
         conversationId: chatId
       });
       
       // Store chat message
       await firestore().collection('aiChats').doc(chatId).update({
         messages: FieldValue.arrayUnion({
           role: 'user',
           content: query,
           timestamp: FieldValue.serverTimestamp()
         }, {
           role: 'assistant',
           content: result.response,
           timestamp: FieldValue.serverTimestamp(),
           toolsUsed: result.toolsUsed
         }),
         updatedAt: FieldValue.serverTimestamp()
       });
       
       return {
         response: result.response,
         toolsUsed: result.toolsUsed
       };
     });
     
     // Proactive suggestions (runs periodically)
     export const generateProactiveSuggestions = onSchedule(
       { schedule: 'every 6 hours', timeZone: 'America/Los_Angeles' },
       async (event) => {
         // For each user with active conversations
         // Generate proactive suggestions
         // Send notification if high-priority suggestions found
       }
     );
     ```

#### **iOS Changes:**

**Files Already Created in PR #18:**
- `Views/AI/AIChatView.swift` - UI already implemented
- `ViewModels/AIChatViewModel.swift` - ViewModel already implemented

**Files to Modify:**
1. `ViewModels/AIChatViewModel.swift`
   - Connect `sendMessage()` to Firebase Function
   - Parse tool usage from response
   - Display "AI used: Search, Calendar" badges

2. `Views/AI/AIChatView.swift`
   - Add tool usage indicators
   - Show "Searching messages..." while tool runs
   - Display rich results (e.g., show event cards if calendar tool used)

#### **Verification Checklist:**
- [ ] Agent can use all 5 tools correctly
- [ ] Multi-step queries work ("Find messages about soccer and add events to calendar")
- [ ] Context maintained across conversation
- [ ] Response quality is high (uses GPT-4o)
- [ ] iOS displays responses correctly
- [ ] Tool usage shown to user
- [ ] Proactive suggestions generate correctly
- [ ] Performance acceptable (<15s for complex queries)

---

## 🧪 Testing Strategy

### **Unit Tests (Functions)**

**Files to Create:**
- `functions/src/__tests__/calendarExtraction.test.ts`
- `functions/src/__tests__/priorityDetection.test.ts`
- `functions/src/__tests__/rsvpTracking.test.ts`
- `functions/src/__tests__/decisionSummarization.test.ts`
- `functions/src/__tests__/deadlineExtraction.test.ts`
- `functions/src/__tests__/aiChatAgent.test.ts`

**Test Cases (per feature):**
1. Correct extraction from clear message
2. Confidence scoring works
3. Edge cases handled (ambiguous dates, missing info)
4. Error handling (malformed input)
5. Performance benchmarks (<2s target)

**Run Tests:**
```bash
cd functions
npm test
```

### **Integration Tests (iOS + Functions)**

**Test Scenarios:**
1. **Calendar Flow:**
   - Send message: "Soccer practice Tuesday 4pm"
   - Verify: Event appears in AI tab
   - Action: Add to calendar
   - Verify: Event in iOS Calendar app

2. **Priority Flow:**
   - Send urgent message: "Emergency! Pick up Sam NOW"
   - Verify: Message marked urgent (red badge)
   - Verify: Push notification sent with 🚨

3. **RSVP Flow:**
   - Group chat with event
   - Multiple members respond
   - Verify: RSVP dashboard shows correct counts
   - Action: Send reminders
   - Verify: Non-responders get notification

4. **Decision Flow:**
   - Group discusses: "Should we have pizza party Friday?"
   - Members agree
   - Action: Trigger decision summary
   - Verify: Decision card appears with consensus

5. **Deadline Flow:**
   - Send message: "Bring cupcakes by Friday"
   - Verify: Deadline appears in AI tab
   - Action: Mark complete
   - Verify: Deadline removed from list

6. **AI Chat Flow:**
   - Open AI chat
   - Query: "What RSVPs am I missing?"
   - Verify: Agent uses RSVP tool
   - Verify: Response shows pending RSVPs
   - Query: "Remind them"
   - Verify: Reminders sent

### **Performance Benchmarks**

**Targets:**
- Calendar extraction: <2s
- Priority detection: <1.5s (background)
- RSVP tracking: <3s
- Decision summarization: <4s
- Deadline extraction: <2s
- AI chat response: <15s (complex queries), <5s (simple)

**Monitoring:**
- Use Firebase Performance Monitoring
- Log execution times in functions
- Alert if p95 exceeds targets

---

## 📊 Cost Optimization

### **Monthly Cost Estimates (1000 users)**

**OpenAI:**
- Embeddings (100K messages): $1.00
- GPT-4o-mini (required features, 50K calls): $3.00
- GPT-4o (AI chat only, 5K calls): $62.50
- **Total OpenAI: $66.50/month**

**Pinecone:**
- Free tier: 100K vectors, 1 index
- **Total Pinecone: $0/month**

**Firebase Functions:**
- Free tier: 2M invocations/month
- Estimated usage: 500K invocations
- **Total Functions: $0/month**

**Grand Total: ~$67/month** for 1000 active users

### **Cost Reduction Strategies:**

1. **Use GPT-4o-mini for everything except AI chat**
   - Saves ~$60/month
   - Trade-off: Slightly lower quality on complex reasoning

2. **Cache common queries in Firestore**
   - Cache decision summaries for 24h
   - Cache RSVP status for 1h
   - Reduces redundant LLM calls

3. **Batch process where possible**
   - Embed messages in batches of 10
   - Daily decision summaries instead of on-demand

4. **Implement rate limits**
   - AI chat: 50 messages/user/day
   - Calendar extraction: Auto-trigger only, no manual calls
   - Prevents abuse

---

## 🎯 Rubric Alignment Summary

### **Required AI Features (15 points) → Target: 14-15**

| Feature | Accuracy Target | Response Time | UI Integration | Points |
|---------|----------------|---------------|----------------|--------|
| Calendar Extraction | 90%+ | <2s | Banner + AI tab | 3/3 |
| Priority Detection | 88%+ | <1.5s | Badge + filtered list | 3/3 |
| RSVP Tracking | 92%+ | <3s | Dashboard + reminders | 3/3 |
| Decision Summarization | 85%+ | <4s | Cards + thread links | 3/3 |
| Deadline Extraction | 85%+ | <2s | List + notifications | 3/3 |

**Total: 15/15** ✅

### **Advanced AI Capability (10 points) → Target: 9-10**

**AI Chat Interface with LangGraph Agent:**
- ✅ Multi-step agent (5+ tools)
- ✅ Context awareness across conversation
- ✅ Proactive suggestions (conflict detection)
- ✅ Response time <15s for complex queries
- ✅ Seamless integration with other features

**Total: 9-10/10** ✅

### **Persona Fit (5 points) → Target: 5**

Every feature directly addresses Busy Parent pain points:
- ✅ Calendar: "Missing appointments buried in chats"
- ✅ Priority: "Information overload"
- ✅ RSVP: "Coordinating multiple schedules"
- ✅ Decisions: "Decision fatigue in group chats"
- ✅ Deadlines: "Missing commitments"

**Total: 5/5** ✅

### **Grand Total: 29-30 / 30** 🎉

---

## 📅 Implementation Timeline

### **Week 1: Infrastructure + Basic Features**
- **Day 1 (Mon):**
  - PR #17: iOS infrastructure (models, services, views structure)
  - Functions project setup (dependencies, config, utils)
  - **Deliverable:** Can call test Firebase Function from iOS

- **Day 2 (Tue):**
  - PR #19: Calendar extraction feature (complete)
  - iOS calendar integration (EventKit)
  - **Deliverable:** Extract events, add to iOS calendar

- **Day 3 (Wed):**
  - PR #20: Priority detection (complete)
  - iOS priority badges in chat
  - **Deliverable:** Messages auto-tagged with priority

### **Week 2: Advanced Features + AI Chat**
- **Day 4 (Thu):**
  - PR #21: RSVP tracking (complete)
  - PR #22: Decision summarization (complete)
  - **Deliverable:** RSVP dashboard, decision cards

- **Day 5 (Fri):**
  - PR #23: Deadline extraction (complete)
  - Message embedding to Pinecone
  - **Deliverable:** Deadlines list, reminders

- **Day 6 (Sat):**
  - PR #18: AI Chat UI (complete)
  - PR #24: LangGraph agent (tools + agent logic)
  - **Deliverable:** AI assistant can answer queries

- **Day 7 (Sun):**
  - PR #24: Proactive suggestions (complete)
  - Testing & bug fixes
  - **Deliverable:** All AI features working

### **Week 3: Polish & Demo**
- **Day 8 (Mon):**
  - Integration testing
  - Performance optimization
  - **Deliverable:** All features pass test scenarios

- **Day 9 (Tue):**
  - UI polish (animations, empty states)
  - Edge case handling
  - **Deliverable:** Production-ready code

- **Day 10 (Wed):**
  - Record demo video
  - Write persona brainlift
  - Deploy to TestFlight
  - **Deliverable:** All deliverables submitted

---

## 🚀 Deployment Checklist

### **Firebase Functions Deployment**
- [ ] All environment variables configured
- [ ] Functions compile without errors: `npm run build`
- [ ] Deploy to Firebase: `firebase deploy --only functions`
- [ ] Test each function with sample data
- [ ] Verify Pinecone index has data
- [ ] Check Firebase console for errors

### **iOS App Deployment**
- [ ] All AI views render correctly
- [ ] No console errors or warnings
- [ ] Performance acceptable on real device
- [ ] Push notifications work
- [ ] TestFlight build uploaded
- [ ] Internal testers can access

### **Documentation**
- [ ] README updated with AI features
- [ ] Architecture diagram created
- [ ] API documentation for Functions
- [ ] User guide for AI features

---

## 📚 References & Resources

### **LangGraph**
- Docs: https://langchain-ai.github.io/langgraph/
- Examples: https://github.com/langchain-ai/langgraph/tree/main/examples

### **Pinecone**
- Docs: https://docs.pinecone.io/
- Node SDK: https://docs.pinecone.io/docs/node-client
- Free tier: https://www.pinecone.io/pricing/

### **OpenAI**
- API Reference: https://platform.openai.com/docs/api-reference
- Embeddings: https://platform.openai.com/docs/guides/embeddings
- JSON mode: https://platform.openai.com/docs/guides/text-generation/json-mode

### **Firebase Functions**
- Get Started: https://firebase.google.com/docs/functions/get-started
- Callable Functions: https://firebase.google.com/docs/functions/callable
- Scheduled Functions: https://firebase.google.com/docs/functions/schedule-functions

### **iOS EventKit**
- Apple Docs: https://developer.apple.com/documentation/eventkit
- Calendar Access: https://developer.apple.com/documentation/eventkit/accessing_the_event_store

---

## ✅ Success Criteria

### **Functionality**
- [ ] All 5 required AI features working
- [ ] AI chat agent responds appropriately
- [ ] Proactive suggestions generate correctly
- [ ] All features accessible from iOS app

### **Performance**
- [ ] Response times meet targets (see benchmarks)
- [ ] No lag in UI
- [ ] Background processing doesn't drain battery

### **Accuracy**
- [ ] Calendar extraction: 90%+ accuracy
- [ ] Priority detection: 88%+ accuracy
- [ ] RSVP tracking: 92%+ accuracy
- [ ] Decision summarization: 85%+ accuracy
- [ ] Deadline extraction: 85%+ accuracy

### **User Experience**
- [ ] Intuitive UI for all AI features
- [ ] Clear loading states
- [ ] Proper error handling
- [ ] Empty states guide user

### **Rubric Score**
- [ ] Required AI: 14-15/15 points
- [ ] Advanced AI: 9-10/10 points
- [ ] Persona Fit: 5/5 points
- [ ] **Total: 28-30/30 points** 🎯

---

**This plan is ready for implementation. Each PR is clearly defined with file structure, key functions, and verification steps. The AI coding agent can follow this plan sequentially to build all features. Good luck! 🚀**
