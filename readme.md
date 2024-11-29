# HTMX Supabase Starter (WIP)

HTMX - Postgrest usage - no server in the middle - all squeel.

-- Uses supabase-js for two things - auth and the supabase storage api.

Besides this - its all postgres functions and triggers. With template functions returning html from htmx ajax requests.

Auth:
Supabase-js - manually setting cookies instead of local storage so we can send these as headers in requests to postgrest.

Storage:
Supabase-js - supabase storage api - needs the client to be able to upload files (and the cookies/auth to be able to insert file url into db)

Everything else:
HTMX requests directly to posgrest functions and return html.
