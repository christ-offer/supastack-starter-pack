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
