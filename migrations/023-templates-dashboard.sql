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
