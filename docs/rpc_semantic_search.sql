-- SQL function for semantic search with PostgreSQL pgvector extension
-- This allows efficient similarity search over thought embeddings

-- Create the function if pgvector is available
CREATE OR REPLACE FUNCTION semantic_search(
    user_id UUID,
    query_embedding vector(1536),
    match_count INT DEFAULT 5
)
RETURNS TABLE (
    id UUID,
    local_thought_id TEXT,
    title TEXT,
    transcript TEXT,
    created_at TIMESTAMPTZ,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if pgvector extension is available
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
        RAISE EXCEPTION 'pgvector extension is not available';
    END IF;

    -- Return matching thoughts sorted by similarity
    RETURN QUERY
    SELECT
        t.id,
        t.local_thought_id,
        t.title,
        t.transcript,
        t.created_at,
        1 - (t.embedding <=> query_embedding) AS similarity
    FROM
        thoughts_meta t
    WHERE
        t.user_id = semantic_search.user_id
        AND t.embedding IS NOT NULL
    ORDER BY
        t.embedding <=> query_embedding
    LIMIT
        match_count;
END;
$$;

-- Example usage:
-- SELECT * FROM semantic_search(
--     '123e4567-e89b-12d3-a456-426614174000', -- user_id
--     '[0.1, 0.2, ..., 0.5]'::vector, -- query_embedding (1536 dimensions)
--     5 -- match_count
-- );

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
