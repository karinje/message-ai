# Weftly Firebase Functions

AI-powered backend for Weftly messaging app with calendar extraction, priority detection, and more.

## Setup

### Prerequisites
- Node.js 20+
- Firebase CLI: `npm install -g firebase-tools`
- OpenAI API key

### Installation

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables for local development:
```bash
# Create .env file (not committed to git)
echo "OPENAI_API_KEY=your_openai_api_key_here" > .env
```

3. Configure Firebase Functions environment:
```bash
# Set OpenAI API key in Firebase
firebase functions:config:set openai.api_key="your_openai_api_key_here"
```

4. Build TypeScript:
```bash
npm run build
```

## Development

### Local Testing
```bash
# Start Firebase emulators
npm run serve

# In another terminal, test functions
npm run shell
```

### Building
```bash
npm run build
```

### Deployment
```bash
# Deploy all functions
npm run deploy

# Deploy specific function
firebase deploy --only functions:extractCalendarEvents
```

## Functions

### Callable Functions (iOS App)

#### `extractCalendarEvents`
Extracts calendar events from message text using GPT-4o-mini.

**Request:**
```typescript
{
  messageText: string;
  conversationId: string;
  messageId: string;
}
```

**Response:**
```typescript
{
  events: ExtractedEvent[];
}
```

### Background Triggers

#### `onMessageCreatedForCalendar`
Automatically extracts calendar events when a new message is created.

**Trigger:** `conversations/{conversationId}/messages/{messageId}` onCreate

#### `onMessageCreatedForPush`
Sends push notifications to conversation participants when a new message is created.

**Trigger:** `conversations/{conversationId}/messages/{messageId}` onCreate

## Project Structure

```
functions/
├── src/
│   ├── features/
│   │   └── calendarExtraction.ts    # Calendar event extraction logic
│   ├── utils/
│   │   ├── openai.ts                # OpenAI client & helpers
│   │   └── firestore.ts             # Firestore helpers
│   ├── types/
│   │   └── index.ts                 # TypeScript type definitions
│   └── index.ts                     # Function exports
├── lib/                             # Compiled JavaScript (generated)
├── package.json
├── tsconfig.json
└── README.md
```

## Environment Variables

### Required
- `OPENAI_API_KEY` - OpenAI API key for GPT models

Set in Firebase:
```bash
firebase functions:config:set openai.api_key="sk-..."
```

Access in code:
```typescript
process.env.OPENAI_API_KEY
```

## Testing

### Manual Testing with Firebase Shell
```bash
npm run shell

# Test extractCalendarEvents
extractCalendarEvents({
  messageText: "Let's meet tomorrow at 2pm for coffee",
  conversationId: "test-conv-id",
  messageId: "test-msg-id"
})
```

### View Logs
```bash
# Real-time logs
npm run logs

# Or via Firebase console
firebase functions:log
```

## Troubleshooting

### Build Errors
```bash
# Clean build
rm -rf lib/ && npm run build
```

### Environment Variable Issues
```bash
# Check current config
firebase functions:config:get

# Update config
firebase functions:config:set openai.api_key="new_key"

# Deploy to apply changes
firebase deploy --only functions
```

### Emulator Issues
```bash
# Clear emulator data
firebase emulators:start --only functions --project demo-weftly
```

## Future Features (Upcoming PRs)

- **PR #20:** Priority Detection
- **PR #21:** RSVP Tracking
- **PR #22:** AI Chat Agent (LangGraph)
- **PR #23:** Deadline Extraction
- **PR #24:** Decision Summarization

## License

Private - Weftly Inc.

