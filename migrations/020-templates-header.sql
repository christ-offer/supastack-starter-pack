create or replace function public.get_unauth_header()
returns "text/html" as $$
begin
return format($html$
  <a href="/">
    <h1>Welcome</h1>
  </a>
  <nav>
    <menu>
      <li>
        <a href="auth/login.html">Sign In</a>
      </li>
    </menu>
  </nav>
$html$);
end;
$$ language plpgsql;

create or replace function public.get_auth_header()
returns "text/html" as $$
begin
return format($html$
  <a href="/">
    <h1>Welcome</h1>
  </a>
  <nav>
    <menu>
      <li>
        <button onclick="logOut()">Log Out</button>
      </li>
      <li>
        <a href="dashboard.html">Dashboard</a>
      </li>
    </menu>
    <script>
      const logOut = () => {
        console.log('logging out');
        document.cookie = 'sb-access-token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/';
        document.cookie = 'sb-refresh-token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/';
      }
    </script>
  </nav>
$html$);
end;
$$ language plpgsql;


create or replace function public.get_header()
returns "text/html" as $$
declare
  user_id uuid := auth.uid ();
  user_profile public.profiles;
begin
  if user_id is null then
    return public.get_unauth_header();
  end if;
  select * into user_profile from public.profiles where id = user_id;
  return public.get_auth_header();
end;
$$ language plpgsql;
