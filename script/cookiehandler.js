const supabaseKey =
  "your-anon-key";

// Function to get cookie value by name
function getCookie(name) {
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) {
    const cookieValue = parts.pop().split(";").shift();
    try {
      // Try to parse it as JSON first
      const parsed = JSON.parse(cookieValue);
      return parsed.access_token || parsed;
    } catch {
      // If it's not JSON, return as is
      return cookieValue;
    }
  }
  return null;
}

// Add the auth token to htmx headers on every request
document.addEventListener("htmx:configRequest", (event) => {
  const accessToken = getCookie("sb-access-token");
  event.detail.headers = {
    ...event.detail.headers,
    Accept: "text/html",
    apikey: supabaseKey,
  };
  if (accessToken) {
    event.detail.headers.Authorization = `Bearer ${accessToken}`;
  }
});
