-- Storage policies for Phase 10

-- Enable Row Level Security on all tables
ALTER TABLE thoughts_meta ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE encryption_metadata ENABLE ROW LEVEL SECURITY;

-- Create policies for thoughts_meta
CREATE POLICY "Users can view their own thoughts"
ON thoughts_meta FOR SELECT
USING (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users can create their own thoughts"
ON thoughts_meta FOR INSERT
WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users can update their own thoughts"
ON thoughts_meta FOR UPDATE
USING (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users can delete their own thoughts"
ON thoughts_meta FOR DELETE
USING (user_id = auth.uid() OR user_id IS NULL);

-- Storage policies (bucket 'thoughts')
-- Ensure the 'thoughts' bucket exists.
-- Owner policy: user may read/write objects they uploaded.
-- If you namespace by user_id, ensure the path starts with the user_id

-- Create the storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('thoughts', 'thoughts', false)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS on the thoughts bucket
UPDATE storage.buckets
SET public = false
WHERE id = 'thoughts';

-- Allow users to read their own thoughts
CREATE POLICY "Users can read their own thought files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'thoughts' AND
  (
    -- Legacy non-namespaced files (will be migrated)
    auth.uid() IS NULL OR
    -- Files namespaced with user_id (format: thoughts/{user_id}/*)
    storage.foldername(name)[1] = auth.uid()::text
  )
);

-- Allow users to insert their own thoughts
CREATE POLICY "Users can insert their own thought files"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'thoughts' AND
  (
    -- Legacy non-namespaced files (for anonymous users)
    auth.uid() IS NULL OR
    -- Files namespaced with user_id (format: thoughts/{user_id}/*)
    storage.foldername(name)[1] = auth.uid()::text
  )
);

-- Allow users to update their own thoughts
CREATE POLICY "Users can update their own thought files"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'thoughts' AND
  (
    -- Legacy non-namespaced files (will be migrated)
    auth.uid() IS NULL OR
    -- Files namespaced with user_id (format: thoughts/{user_id}/*)
    storage.foldername(name)[1] = auth.uid()::text
  )
);

-- Allow users to delete their own thoughts
CREATE POLICY "Users can delete their own thought files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'thoughts' AND
  (
    -- Legacy non-namespaced files (will be migrated)
    auth.uid() IS NULL OR
    -- Files namespaced with user_id (format: thoughts/{user_id}/*)
    storage.foldername(name)[1] = auth.uid()::text
  )
);
ON thoughts_meta
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own thoughts"
ON thoughts_meta
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own thoughts"
ON thoughts_meta
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own thoughts"
ON thoughts_meta
FOR DELETE
USING (user_id = auth.uid());

-- Create policies for devices
CREATE POLICY "Users can view their own devices"
ON devices
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own devices"
ON devices
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own devices"
ON devices
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own devices"
ON devices
FOR DELETE
USING (user_id = auth.uid());

-- Create policies for encryption_metadata
CREATE POLICY "Users can view their own encryption metadata"
ON encryption_metadata
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own encryption metadata"
ON encryption_metadata
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own encryption metadata"
ON encryption_metadata
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own encryption metadata"
ON encryption_metadata
FOR DELETE
USING (user_id = auth.uid());

-- Storage bucket policies for thoughts
-- Assumes a bucket named 'thoughts' exists

-- Create a policy to allow users to read their own files
BEGIN;
  INSERT INTO storage.policies (name, definition)
  VALUES (
    'Users can read their own thoughts',
    '(bucket_id = ''thoughts''::text AND auth.uid() = (storage.foldername(name))[1]::uuid)'
  )
  ON CONFLICT (name) DO UPDATE SET definition = EXCLUDED.definition;
COMMIT;

-- Create a policy to allow users to insert their own files
BEGIN;
  INSERT INTO storage.policies (name, definition)
  VALUES (
    'Users can upload their own thoughts',
    '(bucket_id = ''thoughts''::text AND auth.uid() = (storage.foldername(name))[1]::uuid)'
  )
  ON CONFLICT (name) DO UPDATE SET definition = EXCLUDED.definition;
COMMIT;

-- Create a policy to allow users to update their own files
BEGIN;
  INSERT INTO storage.policies (name, definition)
  VALUES (
    'Users can update their own thoughts',
    '(bucket_id = ''thoughts''::text AND auth.uid() = (storage.foldername(name))[1]::uuid)'
  )
  ON CONFLICT (name) DO UPDATE SET definition = EXCLUDED.definition;
COMMIT;

-- Create a policy to allow users to delete their own files
BEGIN;
  INSERT INTO storage.policies (name, definition)
  VALUES (
    'Users can delete their own thoughts',
    '(bucket_id = ''thoughts''::text AND auth.uid() = (storage.foldername(name))[1]::uuid)'
  )
  ON CONFLICT (name) DO UPDATE SET definition = EXCLUDED.definition;
COMMIT;
