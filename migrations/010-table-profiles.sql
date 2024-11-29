create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  name text default null,
  avatar_url text default null,
  bio text default null,
  location text default null,
  website text default null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- RLS
create policy "Public profiles can be read by anyone" on public.profiles for select using (true);
create policy "Users can insert their own profiles" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update their own profiles" on public.profiles for update using (auth.uid() = id);
create policy "Users can delete their own profiles" on public.profiles for delete using (auth.uid() = id);

-- Create a trigger to automatically update the updated_at column
create or replace function public.set_timestamp_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_timestamp_updated_at
  before update on public.profiles
  for each row
  execute procedure public.set_timestamp_updated_at();

-- Trigger to automatically create a profile row when a user is created
create or replace function public.create_profile() returns trigger as $$
begin
  insert into public.profiles (id)
  values (new.id);
  return new;
end;
$$ language plpgsql security definer;  -- Add security definer

create trigger create_profile
  after insert on auth.users
  for each row
  execute procedure public.create_profile();


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
