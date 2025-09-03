-- Schema changes for Phase 10

-- Ensure table has user_id and e2ee
alter table if exists public.thoughts_meta
  add column if not exists user_id uuid references auth.users(id),
  add column if not exists embedding vector(1536),
  add column if not exists e2ee boolean default false,
  add column if not exists updated_at timestamptz default now();

-- Add index for user_id and updated_at for better query performance
create index if not exists thoughts_meta_user_id_updated_at_idx
  on public.thoughts_meta (user_id, updated_at);

-- Row Level Security (RLS) for user data isolation
alter table public.thoughts_meta enable row level security;

-- Policies for thoughts_meta
create policy "Users can read their own thoughts"
  on public.thoughts_meta for select
  using (auth.uid() = user_id);

create policy "Users can insert their own thoughts"
  on public.thoughts_meta for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own thoughts"
  on public.thoughts_meta for update
  using (auth.uid() = user_id);

create policy "Users can delete their own thoughts"
  on public.thoughts_meta for delete
  using (auth.uid() = user_id);

-- Anonymous users can read/write null user_id thoughts (for migration)
create policy "Anonymous users can access unassigned thoughts"
  on public.thoughts_meta
  using (user_id is null);

-- Add trigger to automatically update updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

create trigger set_thoughts_meta_updated_at
before update on public.thoughts_meta
for each row
execute procedure public.handle_updated_at();
CREATE INDEX IF NOT EXISTS idx_thoughts_meta_user_updated
ON thoughts_meta (user_id, updated_at DESC);

-- Create IVFFlat index on embedding if pgvector is available
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
        -- Create index on embedding for semantic search
        CREATE INDEX IF NOT EXISTS idx_thoughts_meta_embedding
        ON thoughts_meta
        USING ivfflat (embedding vector_l2_ops)
        WITH (lists = 100);
    END IF;
END
$$;

-- Create a devices table to track linked devices
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    name TEXT NOT NULL,
    last_active TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    metadata JSONB
);

-- Create index on user_id for devices
CREATE INDEX IF NOT EXISTS idx_devices_user_id
ON devices (user_id);

-- Create a table for storing encryption metadata
CREATE TABLE IF NOT EXISTS encryption_metadata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    thought_id UUID REFERENCES thoughts_meta(id) NOT NULL,
    metadata JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create a unique index on user_id and thought_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_encryption_metadata_user_thought
ON encryption_metadata (user_id, thought_id);

-- Create a function to check if pgvector is available
CREATE OR REPLACE FUNCTION check_pgvector_available()
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'vector'
    );
END;
$$;

-- Create a function for semantic search
CREATE OR REPLACE FUNCTION semantic_search(
    user_id UUID,
    query_embedding vector(1536),
    match_count INT DEFAULT 5
)
RETURNS TABLE (
    id UUID,
    local_thought_id TEXT,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
        RAISE EXCEPTION 'pgvector extension is not available';
    END IF;

    RETURN QUERY
    SELECT
        thoughts_meta.id,
        thoughts_meta.local_thought_id,
        1 - (thoughts_meta.embedding <=> query_embedding) AS similarity
    FROM
        thoughts_meta
    WHERE
        thoughts_meta.user_id = semantic_search.user_id
        AND thoughts_meta.embedding IS NOT NULL
    ORDER BY
        thoughts_meta.embedding <=> query_embedding
    LIMIT
        match_count;
END;
$$;
