# Supabase Integration Guide

## Overview
This document explains the Supabase integration into the Live Polling System. Supabase is integrated as a **parallel database layer** alongside the existing PostgreSQL/Prisma setup.

## Architecture

### Dual Database Setup
```
┌─────────────────────┐
│   Client (React)    │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│  Express Server     │
└──────┬──────────────┘
       │
   ┌───┴───────────────────────┐
   │                           │
┌──▼────────────┐    ┌────────▼──────┐
│ Prisma ORM    │    │   Supabase    │
│ PostgreSQL    │    │   Parallel    │
│ (Primary)     │    │   (Sync)      │
└───────────────┘    └───────────────┘
```

### How It Works

1. **Write Operations**: 
   - Data is written to PostgreSQL via Prisma (primary database)
   - Automatically synced to Supabase (parallel layer)
   - Sync is non-blocking (async, fire-and-forget)

2. **Read Operations**: 
   - Continues to use PostgreSQL/Prisma (existing logic unchanged)
   - Supabase can be queried independently for analytics or backup

3. **Data Consistency**:
   - PostgreSQL is the single source of truth
   - Supabase is a read replica for redundancy
   - Sync failures are logged but don't break the application

---

## Files Added/Modified

### New Files

1. **`server/.env`**
   - Stores Supabase credentials
   - PostgreSQL and Supabase URLs

2. **`server/src/supabaseClient.ts`**
   - Initializes Supabase client
   - Provides connection testing

3. **`server/src/services/SupabaseService.ts`**
   - `SupabasePollService`: Poll CRUD operations on Supabase
   - `SupabaseVoteService`: Vote CRUD operations on Supabase
   - Methods return null on errors (graceful degradation)

4. **`server/src/services/DatabaseSyncService.ts`**
   - Synchronizes Prisma operations to Supabase
   - Methods are non-blocking (async)
   - Logs sync status for monitoring

### Modified Files

1. **`server/package.json`**
   - Added: `@supabase/supabase-js` dependency

2. **`server/src/index.ts`**
   - Added `/health/detailed` endpoint for database status
   - Tests Supabase connection on startup
   - Logs connection status

3. **`server/src/services/PollService.ts`**
   - Added sync call after poll creation (async, non-blocking)

4. **`server/src/services/VoteService.ts`**
   - Added sync call after vote submission (async, non-blocking)

---

## Configuration

### Environment Variables
```env
# PostgreSQL (Existing)
DATABASE_URL="file:./dev.db"

# Supabase (New)
SUPABASE_URL=https://buhmyduesbhylnmlbigp.supabase.co
SUPABASE_KEY=sb_publishable_7FeoBYaEwKXJK5d33t8gpw_ToMjWLQ

# Server
PORT=3000
NODE_ENV=development
```

---

## Supabase Database Schema

The Supabase database should mirror the Prisma schema:

### polls table
```sql
CREATE TABLE polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  duration INT NOT NULL,
  status TEXT DEFAULT 'OPEN',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### options table
```sql
CREATE TABLE options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now()
);
```

### votes table
```sql
CREATE TABLE votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  option_id UUID NOT NULL REFERENCES options(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(poll_id, student_name)
);
```

---

## Usage Examples

### Checking Connection Status
```bash
curl http://localhost:3000/health/detailed
```

Response:
```json
{
  "status": "ok",
  "postgresql": "connected",
  "supabase": "connected",
  "timestamp": "2026-01-09T00:00:00.000Z"
}
```

### Automatic Sync Flow

**When a teacher creates a poll:**
1. Prisma creates poll in PostgreSQL ✓
2. Sync service async calls Supabase ✓
3. Supabase poll created (logged, no blocking)
4. Client receives response from PostgreSQL

**When a student votes:**
1. Prisma creates vote in PostgreSQL ✓
2. Sync service async calls Supabase ✓
3. Supabase vote created (logged, no blocking)
4. Poll updated in PostgreSQL, broadcasted to clients

---

## Error Handling

### Graceful Degradation
- If Supabase is down, the application continues normally
- Sync failures are logged as warnings
- Primary database (PostgreSQL) is unaffected
- Frontend users experience no disruption

### Logging
All sync operations are logged:
```
[Sync] Poll synced to Supabase: <poll-id>
[Sync] Vote synced to Supabase: <vote-id>
[Sync] Failed to sync poll to Supabase
Supabase: Error fetching active poll: <error>
```

---

## Performance Considerations

1. **Non-blocking Sync**: All Supabase writes are fire-and-forget (async)
2. **No Latency Added**: Response times unaffected
3. **No Database Locks**: Separate transactions
4. **Read-only Supabase**: Secondary queries don't impact primary DB

---

## Future Enhancements

1. **Read from Supabase**: 
   - Implement read fallback if PostgreSQL is down
   - Implement read-from-replica for analytics

2. **Conflict Resolution**:
   - Implement version control for data consistency
   - Add retry logic with exponential backoff

3. **Audit Trail**:
   - Track all sync operations
   - Implement rollback capability

4. **Real-time Subscriptions**:
   - Use Supabase Realtime for bidirectional sync
   - Enable multi-region deployment

---

## Troubleshooting

### Supabase Not Connecting
- Check `.env` file has correct `SUPABASE_URL` and `SUPABASE_KEY`
- Verify Supabase project is running
- Check network connectivity

### Data Not Syncing
- Check server logs for sync errors
- Verify Supabase schema matches Prisma schema
- Ensure tables have correct permissions

### Performance Issues
- Monitor sync operation duration
- Check Supabase API rate limits
- Consider batching operations if volume increases

---

## Deployment Checklist

- [ ] `.env` file configured with Supabase credentials
- [ ] Supabase project created with correct schema
- [ ] `npm install` executed to install `@supabase/supabase-js`
- [ ] Tested `/health/detailed` endpoint
- [ ] Verified sync logs in server output
- [ ] Confirmed PostgreSQL still works as primary DB
- [ ] Tested poll creation (should sync to both DBs)
- [ ] Tested vote submission (should sync to both DBs)

---
