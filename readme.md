# Supastack Starter Pack

## What is this?

This is a "fully functional" CRUD starter pack using:

- HTML/HTMX for the frontend
- Supabase for the backend
- A tiny bit of javascript glue to handle auth and storage
- Can be hosted on github pages

It is purposefully basic and not very fancy to provide a decent enough starting point to build from.

It comes with two tables, profiles and posts.

The profile table automatically creates a row when a user signs up.
Profiles can be edited by the owner and are public to read.
Posts can be created, edited and delted by the user who created them. And read by anyone.

There is also a file storage bucket for files. Users are allowed to upload files to a folder that is named after their profile id. Anyone can read/download files.

## How it works:

- The entire backend runs on Supabase (postgres / postgrest API).
- Any logic is handled by postgres functions and triggers. (including input sanitization)
- Postgres functions returns chunks of html (templates/components) to the front on requests.

### Auth:

Authentication is handled clientside by the supabase client.

Upon successful login or signup, a token is automatically stored as a browser cookie.

This token is then used to authenticate subsequent requests to the postgREST API.

### File Uploads / Storage:

File upload is similarly handled clientside by the supabase client - as the storage api is only available through the client (or https calls ofc).

### Routes/Protected routes

Routing is mainly handled by the static html files - with queries for individual pages happening through a search-string parameter.

Examples:

- localhost:8080/post?id=post_id
- localhost:8080/profile?id=profile_id

Protected routes are handled by postgrest and postgres functions (function checks auth.uid() and if no uid redirects to login page)

## How to use:

1. Clone this repo
2. Create a supabase project
3. Add in the url and anon key where needed in the code
4. Simples way to add migrations is just to use the supabase dashboard SQL editor. Do it in the order the files are listed in.
5. For auth and everything to work - you have to run the html files as a server - i use `npx http-server` --cors to handle this - but any server will do.
6. Build away!

## Some further ideas as to what can be done:

- Realtime updates for posts using the supabase client realtime api to listen for updates and update the ui with x new updates and a refresh button.
- Regular/Vector search for posts (or whatever tables you want)
- Pagination/infinite scrolling for posts
- And much much much more.

## Notes:

I have purposefully not included any css. This is a starter pack after all.

There are some classes and id's added in to the HTML, but mostly for htmx functionality.

## Screenshots:

### Front page when logged in

Note that the edit and delete buttons only appear on your own posts - and only when logged in (obviously)

Edit posts replaces the post content with inputs and lets you edit in place
Delete posts replaces it with a "post has been deleted" div that dissappears after a second.

<img width="400" src="/screenshots/authed-front-page.png" alt="auth-front-page" style="max-width: 400px;">

### Post page for other user (not your own post)

<img width="400" src="/screenshots/post-page.png" alt="auth-front-page" style="max-width: 400px;">

### Profile page for other user

Lists all the posts from this user

<img width="400" src="/screenshots/profile-page.png" alt="auth-front-page" style="max-width: 400px;">

### Dashboard page

<img width="400" src="/screenshots/dashboard.png" alt="auth-front-page" style="max-width: 400px;">
