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
