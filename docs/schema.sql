create table public.thoughts_meta (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  duration_ms bigint,
  title text,
  tags text[],
  transcript_path text,
  audio_path text,
  sha256 text,
  local_thought_id text
);
