
CREATE OR REPLACE FUNCTION public.get_posts()
RETURNS "text/html" AS $$
DECLARE
  posts_html text;
  token_user_id uuid;
BEGIN
  token_user_id := auth.uid();

  -- Get all posts with their corresponding user details
  SELECT
    COALESCE(
      string_agg(
        CASE
          WHEN p.user_id = token_user_id THEN public.users_post_template(p, u)
          ELSE public.public_post_template(p, u)
        END,
        E'\n'
        ORDER BY p.created_at DESC
      ),
      '<div class="no-posts">No posts found</div>'
    ) INTO posts_html
  FROM public.posts p
  LEFT JOIN public.profiles u ON p.user_id = u.id;

  RETURN posts_html;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.get_post_id(post_id text)
RETURNS "text/html" AS $$
DECLARE
  post_html text;
  post public.posts;
  profile public.profiles;
  uuid_post_id uuid;
  token_user_id uuid;
BEGIN
  token_user_id := auth.uid();

  -- Check for null/empty post_id
  IF post_id IS NULL OR post_id = '' THEN
    RETURN '<div>Post not found</div>';
  END IF;

  -- Try to convert text to UUID
  BEGIN
    uuid_post_id := post_id::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RETURN '<div>Post not found</div>';
  END;

  -- Get the post with the corresponding user details
  SELECT * INTO post FROM public.posts WHERE id = uuid_post_id;

  -- Check if post exists
  IF post IS NULL THEN
    RETURN '<div>Post not found</div>';
  END IF;

  SELECT * INTO profile FROM public.profiles WHERE id = post.user_id;

  -- Check if the post belongs to the current user
  IF post.user_id = token_user_id THEN
    -- Use users_post_template for the user's own posts
    SELECT public.users_post_template(post, profile) INTO post_html;
  ELSE
    -- Use public_post_template for other users' posts
    SELECT public.public_post_template(post, profile) INTO post_html;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.delete_post(post_id uuid)
RETURNS "text/html" AS $$
BEGIN
  -- Delete the post
  DELETE FROM public.posts WHERE posts.id = post_id;

  RETURN format($html$
    <div class="post-deleted" data-auto-remove="1000">
      <h2>Post deleted</h2>
      <script>
        setTimeout(() => {
          document.querySelector('[data-auto-remove="1000"]').remove();
        }, 1000);
      </script>
    </div>
  $html$);
END;
$$ LANGUAGE plpgsql;

create or replace function public.get_edit_post(post_id uuid)
returns "text/html" as $$
declare
  post public.posts;
  profile public.profiles;
begin
  select * into post from public.posts where id = post_id;
  select * into profile from public.profiles where id = post.user_id;
  return public.edit_post_template(post, profile);
end;
$$ language plpgsql;

create or replace function public.edit_post(post_id uuid, post_title text, post_body text)
returns "text/html" as $$
declare
  post public.posts;
  profile public.profiles;
begin
  update public.posts
  set title = post_title, body = post_body
  where id = post_id;

  select * into post from public.posts where id = post_id;
  select * into profile from public.profiles where id = post.user_id;
  return public.users_post_template(post, profile);
end;
$$ language plpgsql;

create or replace function public.get_create_post()
returns "text/html" as $$
declare
  user_id uuid := auth.uid ();
  profile public.profiles;
begin
  if user_id is null then
    return '<p>You must be logged in to create a post</p>';
  end if;
  select * into profile from public.profiles where id = user_id;
  return public.create_post_template (profile);
end;
$$ language plpgsql;

create or replace function public.create_post(author_user_id uuid, post_title text, post_body text)
returns "text/html" as $$
begin
  insert into public.posts (user_id, title, body)
  values (author_user_id, post_title, post_body);

  return format($html$
    <div class="post-created" data-auto-remove="1000">
      <h2>Post created</h2>
      <script>
        htmx.trigger(htmx.find('#post-list'), 'refresh');
        setTimeout(() => {
          document.querySelector('[data-auto-remove="1000"]').remove();
        }, 1000);
      </script>
    </div>
  $html$);

end;
$$ language plpgsql;


create or replace function public.public_get_userid_posts(profile_id text)
returns "text/html" as $$
declare
  profile public.profiles;
  posts_html text;
  token_user_id uuid;
  uuid_profile_id uuid;
begin
  token_user_id := auth.uid();

  -- Try to convert profile_id to UUID
  BEGIN
    uuid_profile_id := profile_id::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RETURN '<div>Profile not found</div>';
  END;

  select * into profile from public.profiles where id = uuid_profile_id;

  SELECT
    COALESCE(
      string_agg(
        CASE
          WHEN token_user_id = uuid_profile_id THEN public.users_post_template(p, u)
          ELSE public.public_post_template(p, u)
        END,
        E'\n'
        ORDER BY p.created_at DESC
      ),
      '<div class="no-posts">No posts found</div>'
    ) INTO posts_html
  FROM public.posts p
  LEFT JOIN public.profiles u ON p.user_id = u.id
  WHERE p.user_id = uuid_profile_id;

  return posts_html;
end;
$$ language plpgsql;
