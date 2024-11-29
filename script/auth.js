const sbClient = supabase.createClient(
  "https://your-supabase-project-id.supabase.co",
  "your-anon-key",
);

async function handleAuthResponse(event) {
  event.preventDefault();
  const formData = new FormData(event.target);
  const action = event.submitter.value;
  let result;

  if (action === "login") {
    result = await sbClient.auth.signInWithPassword({
      email: formData.get("email"),
      password: formData.get("password"),
    });
  } else if (action === "signup") {
    result = await sbClient.auth.signUp({
      email: formData.get("email"),
      password: formData.get("password"),
    });
  }

  const { data, error } = result;

  if (error) {
    document.querySelector('.response').innerHTML = `
      <h1>Error</h1>
      <p>${error.message}</p>`
    return;
  }

  if (data.session) {
    // Keep original Supabase cookie names
    document.cookie = `sb-access-token=${data.session.access_token}; path=/; max-age=${data.session.expires_in}`;
    document.cookie = `sb-refresh-token=${data.session.refresh_token}; path=/; max-age=${data.session.expires_in}`;
  }

  if (action === "login" && data.session) {
    window.location.href = "/"
  }

  if (action === "signup" && !error) {
    document.querySelector('.response').innerHTML = `
      <h1>Success!</h1>
      <p>Check your email for a confirmation link</p>`
  }
}
