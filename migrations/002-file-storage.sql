-- Storage bucket setup:
-- create supabase images bucket
insert into storage.buckets
  (id, name, public)
values
  ('user_files', 'user_files', true);

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Allow public read access to the bucket
CREATE POLICY "Allow public file listing" ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'user_files');

-- Create policy for inserting objects
CREATE POLICY "Users can upload their own files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user_files'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Create policy for updating objects
CREATE POLICY "Users can update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'user_files' AND (storage.foldername(name))[1] = auth.uid()::text)
WITH CHECK (bucket_id = 'user_files' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Create policy for deleting objects
CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'user_files' AND (storage.foldername(name))[1] = auth.uid()::text);
