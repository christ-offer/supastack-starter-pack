/*
PUBLIC POST COMPONENT
*/
create or replace function public.public_post_template(p public.posts, u public.profiles)
returns "text/html" as $$
begin
return format($html$
  <div>
    <div>
      <a href="/post.html?id=%4$s">
        <p>
          <strong>Title:</strong> %1$s
        </p>
      </a>
      <p>
        <strong>Body:</strong> %2$s
      </p>
      <p>
        <a href="/profile?id=%7$s">
          <strong>Author:</strong> %3$s
        </a>
      </p>
      <small>
        <strong>Created at:</strong> %5$s
      </small>
      <small>
        <strong>Last update:</strong> %6$s
      </small>
    </div>
  </div>
$html$,
  p.title,
  p.body,
  u.name,
  p.id,
  p.created_at,
  p.updated_at,
  u.id);
end;
$$ language plpgsql;

/*
PRIVATE POST COMPONENT
*/
create or replace function public.users_post_template(p public.posts, u public.profiles)
returns "text/html" as $$
declare
url text;
begin
url := public.get_api_url();
return format($html$
  <div class="post-%5$s">
    <div>
      <a href="/post.html?id=%5$s">
        <p>
          <strong>Title:</strong> %1$s
        </p>
      </a>
      <p>
        <strong>Body:</strong> %2$s
      </p>
      <p>
        <a href="/profile?id=%8$s">
        <strong>Author:</strong> %3$s
        </a>
      </p>
      <button hx-post="%4$s/delete_post" hx-vals='{"post_id": "%5$s"}' hx-target=".post-%5$s" hx-swap="outerHTML">Delete Post</button>
      <button hx-post="%4$s/get_edit_post" hx-vals='{"post_id": "%5$s"}' hx-target=".post-%5$s" hx-swap="outerHTML">Edit Post</button>
    </div>
    <small>
      <strong>Created at:</strong> %6$s
    </small>
    <small>
      <strong>Last update:</strong> %7$s
    </small>
  </div>
$html$,
  p.title,
  p.body,
  u.name,
  url,
  p.id,
  p.created_at,
  p.updated_at,
  u.id);
end;
$$ language plpgsql;

/*
GET - PUBLIC POST ROUTE
*/
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

/*
GET - PUBLIC POST BY POST ID ROUTE
*/
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
  post := public.get_post_by_id(uuid_post_id);

  -- Check if post exists
  IF post IS NULL THEN
    RETURN '<div>Post not found</div>';
  END IF;

  profile := public.get_user_profile(post.user_id);

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

/*
GET - PUBLIC POSTS BY USER ROUTE
*/
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

  profile := public.get_user_profile(uuid_profile_id);

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

/*
DELETE - PRIVATE DELETE POST ROUTE
*/
CREATE OR REPLACE FUNCTION public.delete_post(post_id uuid)
RETURNS "text/html" AS $$
BEGIN
  -- Delete the post
  public.delete_post(post_id);

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


/*
EDIT POST COMPONENT
*/
create or replace function public.edit_post_template(p public.posts, u public.profiles)
returns "text/html" as $$
declare
url text;
begin
url := public.get_api_url();
return format($html$
  <div class="post-%5$s">
    <div>
      <form hx-post="%4$s/edit_post" hx-target=".post-%5$s" hx-swap="outerHTML">
        <input type="hidden" id="id" name="post_id" value="%5$s" />
        <p>
          <label for="title">Title:</label>
          <input type="text" id="title" name="post_title" value="%1$s" />
        </p>
        <p>
          <label for="body">Body:</label>
          <textarea id="body" name="post_body">%2$s</textarea>
        </p>
        <p>
          <strong>Author:</strong> %3$s
        </p>
        <button type="submit">Save Changes</button>
      </form>
    </div>
  </div>
$html$,
  p.title,
  p.body,
  u.name,
  url,
  p.id);
end;
$$ language plpgsql;

/*
CREATE POST COMPONENT
*/
create or replace function public.create_post_template(p public.profiles)
returns "text/html" as $$
declare
url text;
begin
url := public.get_api_url();
return format($html$
  <div class="post-creator">
    <div>
      <h1>Create Post</h1>
      <form hx-post="%1$s/create_post" hx-target=".post-creation-message" hx-swap="innerHTML" hx-on::after-request="this.reset()">
        <input type="hidden" id="user_id" name="author_user_id" value="%2$s" />
        <p>
          <label for="title">Title:</label>
          <input type="text" id="title" name="post_title" />
        </p>
        <p>
          <label for="body">Body:</label>
          <textarea id="body" name="post_body"></textarea>
        </p>
        <button type="submit">Create Post</button>
      </form>
    </div>
  </div>
$html$,
  url,
  p.id
);
end;
$$ language plpgsql;

/*
GET - EDIT POST COMPONENT ROUTE
*/
create or replace function public.get_edit_post(post_id uuid)
returns "text/html" as $$
declare
  post public.posts;
  profile public.profiles;
begin
  post := public.get_post_by_id(post_id);
  profile := public.get_user_profile(post.user_id);
  return public.edit_post_template(post, profile);
end;
$$ language plpgsql;

/*
POST - UPDATE POST ROUTE
*/
create or replace function public.edit_post(post_id uuid, post_title text, post_body text)
returns "text/html" as $$
declare
  post public.posts;
  profile public.profiles;
  update_post public.posts;
begin
  update_post := public.update_post(post_id, post_title, post_body);

  post := public.get_post_by_id(update_post.id);
  profile := public.get_user_profile(post.user_id);

  return public.users_post_template(post, profile);
end;
$$ language plpgsql;

/*
GET - CREATE POST COMPONENT ROUTE
*/
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

/*
POST - CREATE POST ROUTE
*/
create or replace function public.create_post(author_user_id uuid, post_title text, post_body text)
returns "text/html" as $$
declare
sanitized_title text;
sanitized_body text;
begin
  public.create_post(author_user_id, post_title, post_body);

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
