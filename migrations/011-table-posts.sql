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


/*
SQL Function to Get Posts with User Details - for general usage - in frontend im sticking with the string coalesce since its more efficient.
*/
CREATE OR REPLACE FUNCTION public.fetch_posts_with_users()
RETURNS TABLE (
    post public.posts,
    user_profile public.profiles
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.*, u.*
    FROM public.posts p
    LEFT JOIN public.profiles u ON p.user_id = u.id
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

/*
SQL Function to get post by ID
*/
create or replace function public.get_post_by_id(post_id uuid)
returns public.posts as $$
declare
  post public.posts;
begin
  select * into post from public.posts where id = post_id;
  return post;
end;
$$ language plpgsql;

/*
SQL Function to get posts by user ID
*/
create or replace function public.get_posts_by_user_id(user_id uuid)
returns setof public.posts as $$
declare
  posts public.posts;
begin
  select * into posts from public.posts where user_id = user_id;
  return posts;
end;
$$ language plpgsql;

/*
SQL Function to update post
*/
create or replace function public.update_post(post_id uuid, post_title text, post_body text)
returns public.posts as $$
declare
sanitized_title text;
sanitized_body text;
begin
   sanitized_title := public.sanitize_input(post_title);
   sanitized_body := public.sanitize_input(post_body);

  update public.posts
  set title = sanitized_title, body = sanitized_body
  where id = post_id;

  return public.get_post_by_id(post_id);
end;
$$ language plpgsql;

/*
SQL Function to delete post
*/
create or replace function public.delete_post(post_id uuid)
returns public.posts as $$
begin
  -- Delete the post
  delete from public.posts where posts.id = post_id;

  return public.get_post_by_id(post_id);
end;
$$ language plpgsql;

/*
SQL Function to create post
*/
create or replace function public.create_post(author_user_id uuid, post_title text, post_body text)
returns public.posts as $$
declare
sanitized_title text;
sanitized_body text;
begin
  sanitized_title := public.sanitize_input(post_title);
  sanitized_body := public.sanitize_input(post_body);

  insert into public.posts (user_id, title, body)
  values (author_user_id, sanitized_title, sanitized_body);

  return public.get_post_by_id(public.get_last_insert_id());
end;
$$ language plpgsql;
