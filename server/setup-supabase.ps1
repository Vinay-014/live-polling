# Supabase Database Setup Script (Windows PowerShell)
# This script displays the SQL needed to set up Supabase

Write-Host "🚀 Supabase Database Setup (Windows)" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""

# Check environment variables
if (-not $env:SUPABASE_URL) {
    Write-Host "❌ Error: SUPABASE_URL not found in .env" -ForegroundColor Red
    exit 1
}

if (-not $env:SUPABASE_KEY) {
    Write-Host "❌ Error: SUPABASE_KEY not found in .env" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Credentials loaded from .env" -ForegroundColor Green
Write-Host ""
Write-Host "📋 SQL to execute in Supabase SQL Editor:" -ForegroundColor Yellow
Write-Host ""

$sql = @"
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
"@

Write-Host $sql -ForegroundColor Cyan
Write-Host ""
Write-Host "=================================" -ForegroundColor Green
Write-Host "✓ Manual Steps Required:" -ForegroundColor Yellow
Write-Host "  1. Go to: https://supabase.com/dashboard" -ForegroundColor White
Write-Host "  2. Select your project" -ForegroundColor White
Write-Host "  3. Navigate to SQL Editor tab" -ForegroundColor White
Write-Host "  4. Click 'New Query'" -ForegroundColor White
Write-Host "  5. Paste the SQL above" -ForegroundColor White
Write-Host "  6. Click 'Run'" -ForegroundColor White
Write-Host "  7. Verify tables are created" -ForegroundColor White
Write-Host ""
Write-Host "✓ After setup, test with:" -ForegroundColor Yellow
Write-Host "  curl http://localhost:3000/health/detailed" -ForegroundColor Cyan
Write-Host ""
