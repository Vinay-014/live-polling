#!/bin/bash

# Supabase Database Setup Script
# This script creates the required tables in your Supabase project

echo "🚀 Supabase Database Setup"
echo "=================================="

# Check if SUPABASE_URL is set
if [ -z "$SUPABASE_URL" ]; then
    echo "❌ Error: SUPABASE_URL not set in .env"
    exit 1
fi

if [ -z "$SUPABASE_KEY" ]; then
    echo "❌ Error: SUPABASE_KEY not set in .env"
    exit 1
fi

echo "✓ Credentials loaded from .env"
echo ""
echo "Creating tables in Supabase..."
echo ""

# Create tables using curl (requires authentication)
# Note: You may need to use the Supabase dashboard to create these tables manually
# or use the Supabase CLI (supabase-cli) if this script doesn't work

echo "📋 SQL to execute in Supabase SQL Editor:"
echo ""
cat << 'EOF'
-- Create polls table
CREATE TABLE IF NOT EXISTS public.polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  duration INT NOT NULL,
  status TEXT DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create options table
CREATE TABLE IF NOT EXISTS public.options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create votes table
CREATE TABLE IF NOT EXISTS public.votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  option_id UUID NOT NULL REFERENCES public.options(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(poll_id, student_name)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_polls_status ON public.polls(status);
CREATE INDEX IF NOT EXISTS idx_options_poll_id ON public.options(poll_id);
CREATE INDEX IF NOT EXISTS idx_votes_poll_id ON public.votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_votes_option_id ON public.votes(option_id);

-- Enable Row Level Security (optional, for security)
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;

-- Create policies for anonymous access (for development only!)
CREATE POLICY "Allow all selects for polls" ON public.polls
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow all inserts for polls" ON public.polls
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow all updates for polls" ON public.polls
  FOR UPDATE TO anon USING (true);

CREATE POLICY "Allow all deletes for polls" ON public.polls
  FOR DELETE TO anon USING (true);

CREATE POLICY "Allow all operations on options" ON public.options
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on votes" ON public.votes
  FOR ALL TO anon USING (true) WITH CHECK (true);

EOF

echo ""
echo "=================================="
echo "✓ Manual Steps Required:"
echo "1. Go to your Supabase project: https://supabase.com/dashboard"
echo "2. Navigate to SQL Editor"
echo "3. Copy and paste the SQL above"
echo "4. Execute the query"
echo "5. Verify tables are created"
echo ""
echo "✓ After setup, test with:"
echo "   curl http://localhost:3000/health/detailed"
echo ""
