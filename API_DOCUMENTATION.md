# API Documentation - Supabase Integration

## Health Check Endpoints

### 1. Basic Health Check
**Endpoint:** `GET /health`

**Description:** Quick health check for server status

**Response:**
```json
{
  "status": "ok"
}
```

**Status Code:** 200

---

### 2. Detailed Health Check (NEW)
**Endpoint:** `GET /health/detailed`

**Description:** Extended health check including database connection status for both PostgreSQL and Supabase

**Response:**
```json
{
  "status": "ok",
  "postgresql": "connected",
  "supabase": "connected",
  "timestamp": "2026-01-09T10:30:45.123Z"
}
```

**Possible Supabase Status Values:**
- `"connected"` - Successfully connected to Supabase
- `"disconnected"` - Supabase is unreachable
- `"error"` - Error during connection test

**Status Code:** 200

**Notes:**
- This endpoint is useful for monitoring
- Supabase connection issues will not affect the response status code
- Server continues to function even if Supabase is unavailable

---

## Existing Endpoints (Unchanged)

All existing endpoints continue to work as before:

### Poll Endpoints
- `POST /api/polls` - Create new poll
- `GET /api/polls/current` - Get active poll
- `GET /api/polls/history` - Get poll history

### Vote Endpoints
- `POST /api/votes` - Submit vote

### Socket Events
- `poll:created` - New poll available
- `vote:update` - Vote submitted
- `student:kicked` - Student removed
- `participants:update` - Participant list updated
- `chat:send` / `chat:receive` - Chat messages

---

## Internal Services (Backend Only)

### SupabasePollService
Location: `server/src/services/SupabaseService.ts`

**Methods:**
```typescript
// Create poll in Supabase
createPoll(data: {
  question: string;
  duration: number;
  options: { text: string; isCorrect?: boolean }[];
}): Promise<SupabasePoll | null>

// Get active poll from Supabase
getActivePoll(): Promise<SupabasePoll | null>

// Get poll history from Supabase
getPollHistory(): Promise<SupabasePoll[]>

// Get options with vote counts
getOptionsWithVotes(pollId: string): Promise<any[]>
```

### SupabaseVoteService
Location: `server/src/services/SupabaseService.ts`

**Methods:**
```typescript
// Submit vote to Supabase
submitVote(data: {
  pollId: string;
  studentName: string;
  optionId: string;
}): Promise<SupabaseVote | null>

// Get vote count for option
getOptionVoteCount(optionId: string): Promise<number>
```

### DatabaseSyncService
Location: `server/src/services/DatabaseSyncService.ts`

**Methods:**
```typescript
// Sync poll from Prisma to Supabase
static syncPollToSupabase(pollData): Promise<void>

// Sync vote from Prisma to Supabase
static syncVoteToSupabase(voteData): Promise<void>

// Verify data consistency between databases
static verifyDataConsistency(): Promise<{
  supabasePolls: number;
  supabaseVotes: number;
  status: string;
}>
```

---

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    Client Application                        │
└────────────────────────────┬─────────────────────────────────┘
                             │ HTTP Requests
                             ▼
┌──────────────────────────────────────────────────────────────┐
│              Express Server (port 3000)                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Routes (index.ts)                                          │
│    ├─ POST /api/polls ──────────────────┐                   │
│    ├─ GET /api/polls/current            │                   │
│    ├─ GET /api/polls/history            │                   │
│    ├─ POST /api/votes ─────────────────┐│                   │
│    └─ GET /health/detailed              ││                   │
│                                          │▼                   │
│  Controllers                       Services                   │
│    ├─ PollController ───────────► PollService ──┐            │
│    └─ VoteController ───────────► VoteService ──┤            │
│                                                  ▼            │
│                            DatabaseSyncService               │
│                                 │                            │
│                                 ▼                            │
│                         (Async Sync)                         │
│                                 │                            │
│        ┌────────────────────────┼────────────────────┐      │
│        ▼                        ▼                     ▼      │
│   ┌─────────────┐          ┌──────────────┐  ┌─────────────┐ │
│   │   Prisma    │          │  Supabase    │  │   Supabase  │ │
│   │   ORM       │          │   Service    │  │   Client    │ │
│   └─────────────┘          └──────────────┘  └─────────────┘ │
│        │                                             │        │
└────────┼─────────────────────────────────────────────┼────────┘
         │                                             │
         ▼                                             ▼
   ┌──────────────┐                          ┌──────────────────┐
   │ PostgreSQL   │                          │ Supabase         │
   │ (Primary)    │                          │ (Parallel Sync)  │
   └──────────────┘                          └──────────────────┘
```

---

## Error Handling & Resilience

### PostgreSQL (Primary Database)
- **Behavior on Error:** Application responds with error, request fails
- **Priority:** Critical - affects all users
- **Fallback:** None (is the primary database)

### Supabase (Parallel Sync Layer)
- **Behavior on Error:** Logged as warning, application continues normally
- **Priority:** Non-critical - monitoring only
- **Fallback:** Automatic retry on next write operation

### Example Error Scenarios

**Scenario 1: PostgreSQL Down**
```
User Action: Create Poll
Result: ❌ 500 Error - Cannot connect to database
Client Sees: Error message
```

**Scenario 2: Supabase Down**
```
User Action: Create Poll
PostgreSQL Result: ✅ Poll created
Supabase Result: ⚠️ Sync failed (logged as warning)
Client Sees: Poll created successfully
Note: Supabase tables remain empty until sync succeeds
```

**Scenario 3: Both Databases Down**
```
User Action: Create Poll
Result: ❌ 500 Error - Cannot connect to PostgreSQL
Client Sees: Error message
Note: Supabase error is irrelevant as primary DB is unavailable
```

---

## Monitoring & Observability

### Health Check Examples

**Both databases healthy:**
```bash
$ curl http://localhost:3000/health/detailed
{
  "status": "ok",
  "postgresql": "connected",
  "supabase": "connected",
  "timestamp": "2026-01-09T10:30:45.123Z"
}
```

**Supabase unavailable:**
```bash
$ curl http://localhost:3000/health/detailed
{
  "status": "ok",
  "postgresql": "connected",
  "supabase": "disconnected",
  "timestamp": "2026-01-09T10:30:45.123Z"
}
```

### Log Monitoring

Watch server logs for sync operations:

**Successful sync:**
```
[Sync] Poll synced to Supabase: 12345678-1234-1234-1234-123456789012
[Sync] Vote synced to Supabase: 87654321-4321-4321-4321-210987654321
```

**Failed sync:**
```
Supabase: Error creating poll: {"message": "connection refused"}
[Sync] Failed to sync poll to Supabase
```

---

## Performance Metrics

### Write Operations (Poll/Vote Creation)

**PostgreSQL (Blocking):**
- Expected latency: 10-50ms
- Affects response time

**Supabase Sync (Async):**
- Expected latency: 50-200ms (non-blocking)
- Does NOT affect response time
- Runs in background after primary write completes

**Total User Response Time:**
- Unchanged from before (only PostgreSQL blocks)
- Supabase sync is fire-and-forget

---

## Environment Configuration

### Required Environment Variables
```env
DATABASE_URL="file:./dev.db"
SUPABASE_URL=https://buhmyduesbhylnmlbigp.supabase.co
SUPABASE_KEY=sb_publishable_7FeoBYaEwKXJK5d33t8gpw_ToMjWLQ
PORT=3000
NODE_ENV=development
```

### Optional (for future use)
```env
SUPABASE_SYNC_ENABLED=true    # Enable/disable Supabase sync
SUPABASE_SYNC_TIMEOUT=5000    # Sync timeout in ms
LOG_LEVEL=debug                # Logging level
```

---

## Backward Compatibility

✅ **All existing functionality preserved**
- All existing API endpoints work unchanged
- All existing socket events work unchanged
- All existing client code works unchanged
- PostgreSQL remains the primary database

✅ **No breaking changes**
- Existing routes unmodified
- Controllers unmodified (only added sync calls)
- Services unmodified (only added sync calls)
- Database schema (Prisma) unmodified

---

## Testing Checklist

- [ ] Server starts without errors
- [ ] Health endpoint works
- [ ] Health/detailed endpoint returns database status
- [ ] Create poll → both databases get data
- [ ] Submit vote → both databases get data
- [ ] Existing endpoints still work
- [ ] Supabase down → system still functions
- [ ] PostgreSQL down → expected error
- [ ] Student can vote and see results
- [ ] Teacher can create and view poll results

---
