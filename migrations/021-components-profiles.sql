/*
PUBLIC PROFILE COMPONENT
*/
create or replace function public.public_profile_template(p public.profiles)
returns "text/html" as $$
begin
return format($html$
  <div>
    <div>
      <h1>Profile</h1>
      <p>
        <strong>Username:</strong> %2$s
      </p>
      <p>
        <strong>Created at:</strong> %3$s
      </p>
      <p>
        <strong>Updated at:</strong> %4$s
      </p>
    </div>
  </div>
$html$,
    p.id,
    p.name,
    p.created_at,
    p.updated_at
  );
end;
$$ language plpgsql;

/*
EDIT PROFILE COMPONENT
*/
create or replace function public.edit_profile_template(p public.profiles)
returns "text/html" as $$
declare
url text;
begin
url := public.get_api_url();
return format($html$
    <div>
      <h1>Edit Profile</h1>
      <form hx-post="%5$s/update_profile" hx-target=".profile-editor">
        <p>
          <label for="username">Username:</label>
          <input type="text" id="profile_name" name="profile_name" value="%2$s" />
        </p>
        <p>
          <strong>Created at:</strong> %3$s
        </p>
        <p>
          <strong>Updated at:</strong> %4$s
        </p>
        <button type="submit">Save Changes</button>
      </form>
    </div>
$html$,
    p.id,
    p.name,
    p.created_at,
    p.updated_at,
    url
  );
end;
$$ language plpgsql;

/*
GET - PROFILE ROUTE (PROTECTED)
*/
create or replace function public.public_get_profile()
returns "text/html" as $$
declare
  user_id uuid := auth.uid ();
  user_profile public.profiles;
begin
  if user_id is null then
    return '<script>window.location.href = "/auth.html";</script>';
  end if;
  select * into user_profile from public.profiles where id = user_id;
  return public.edit_profile_template (user_profile);
end;
$$ language plpgsql;

/*
POST - UPDATE PROFILE ROUTE (PROTECTED)
*/
create or replace function public.update_profile(profile_name text)
returns "text/html" as $$
declare
  user_id uuid := auth.uid ();
  user_profile public.profiles;
begin
  if user_id is null then
    return '<p>unauth access </p>';
  end if;
  update public.profiles
  set name = profile_name
  where id = user_id;

  select * into user_profile from public.profiles where id = user_id;
  return public.edit_profile_template (user_profile);
end;
$$ language plpgsql;

/*
GET - PROFILE BY ID ROUTE
*/
create or replace function public.get_profile_id(profile_id text)
returns "text/html" as $$
declare
  profile public.profiles;
  uuid_profile_id uuid;
begin

  uuid_profile_id := auth.uid();
  -- Check for null/empty profile_id
  if profile_id is null or profile_id = '' then
    return '<div>Profile not found</div>';
  end if;

  -- Try to convert text to UUID
  begin
    uuid_profile_id := profile_id::uuid;
  exception when invalid_text_representation then
    return '<div>Profile not found</div>';
  end;

  -- Get the profile with the corresponding user details
  select * into profile from public.profiles where id = uuid_profile_id;

  -- Check if profile exists
  if profile is null then
    return '<div>Profile not found</div>';
  end if;

  return public.public_profile_template(profile);
end;
$$ language plpgsql;


/*
UPLOAD PROFILE IMAGE COMPONENT
*/
create or replace function public.upload_profile_img_template(p public.profiles)
returns "text/html" as $$
begin
return format($html$
  <div class="profile-img-upload">
    <img width="400" src="%1$s" />
    <h1>Upload Profile Image</h1>
    <input type="file" id="fileInput" />
    <button onclick="uploadFile()">Upload</button>
    <div id="status"></div>
  </div>

$html$,
p.avatar_url
);
end;
$$ language plpgsql;

/*
POST - PROFILE IMAGE UPLOAD ROUTE (PROTECTED)
*/
create or replace function public.get_profile_upload()
returns "text/html" as $$
declare
token_user_id uuid;
profile public.profiles;
begin
token_user_id := auth.uid();

-- get matching profile to token user id
select * into profile from public.profiles where id = token_user_id;

return public.upload_profile_img_template(profile);
end;
$$ language plpgsql;
