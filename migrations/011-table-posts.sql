create table if not exists public.posts (
  id uuid primary key default gen_random_uuid (),
  user_id uuid references public.profiles (id) not null,
  title text not null,
  body text not null,
  created_at timestamptz not null default now (),
  updated_at timestamptz not null default now ()
);

alter table public.posts enable row level security;

create policy "Posts can be read by anyone" on public.posts for
select
  using (true);

create policy "Posts can be updated by users" on public.posts for
update using (auth.uid () = user_id);

create policy "Posts can be deleted by users" on public.posts for delete using (auth.uid () = user_id);

create policy "Posts can be created by authenticated users" on public.posts for insert
with
  check (auth.uid () = user_id);
