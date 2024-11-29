create or replace function public.dashboard_template()
returns "text/html" as $$
declare
url text;
begin
url := public.get_api_url();
return format($html$
<header
  hx-get="%1$s/get_header"
  hx-trigger="load"
></header>
<main>
  <div
    class="profile-editor"
    hx-get="%1$s/public_get_profile"
    hx-trigger="load"
  ></div>
  <div
    id="profile-upload"
    hx-get="%1$s/get_profile_upload"
    hx-trigger="load, customTrigger"
  ></div>
</main>
$html$,
url);
end;
$$ language plpgsql;

create or replace function public.get_dashboard()
returns "text/html" as $$
declare
  user_id uuid := auth.uid ();
begin
  if user_id is null then
    return '<script>window.location.href = "/auth/login.html";</script>';
  end if;
  return public.dashboard_template();
end;
$$ language plpgsql;
