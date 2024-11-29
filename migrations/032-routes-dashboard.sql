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
