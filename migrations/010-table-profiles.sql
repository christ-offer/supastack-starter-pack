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

/*
SQL Function to Get User Profile
*/
create or replace function public.get_user_profile(user_id uuid)
returns public.profiles as $$
declare
  user_profile public.profiles;
begin
  select * into user_profile from public.profiles where id = user_id;
  return user_profile;
end;
$$ language plpgsql;

/*
SQL Function to Update User Profile
*/
create or replace function public.update_user_profile(user_id uuid, profile_name text)
returns public.profiles as $$
declare
user_profile public.profiles;
begin
update public.profiles
set name = profile_name
where id = user_id;
select * into user_profile from public.profiles where id = user_id;
return user_profile;
end;
$$ language plpgsql;
