const BUCKET_NAME = "user_files";
const sbClient = supabase.createClient(
  "https://your-supabase-project-id.supabase.co",
  "your-anon-key",
);

async function uploadFile() {
  console.log("Starting upload process");

  const fileInput = document.getElementById("fileInput");
  const statusDiv = document.getElementById("status");

  // Get current user
  const {
    data: { user },
    error: userError,
  } = await sbClient.auth.getUser();

  if (userError || !user) {
    console.error("Authentication error:", userError);
    statusDiv.innerHTML = "User not authenticated";
    return;
  }

  console.log("User authenticated:", user.id);

  // Check if file is selected
  if (!fileInput.files || fileInput.files.length === 0) {
    console.log("No file selected");
    statusDiv.innerHTML = "Please select a file";
    return;
  }

  const file = fileInput.files[0];
  console.log("File selected:", file.name);

  // Create a safe filename
  const fileExt = file.name.split(".").pop();
  const fileName = `${user.id}/${Date.now()}.${fileExt}`;
  console.log("Generated filename:", fileName);

  try {
    statusDiv.innerHTML = "Uploading...";
    console.log("Starting file upload to bucket");

    // Upload file to Supabase Storage
    const { data, error: uploadError } = await sbClient.storage
      .from(BUCKET_NAME)
      .upload(fileName, file);

    if (uploadError) {
      console.error("Upload error:", uploadError);
      throw uploadError;
    }

    console.log("File uploaded successfully");

    // Get public URL for the uploaded file
    const {
      data: { publicUrl },
    } = sbClient.storage.from(BUCKET_NAME).getPublicUrl(fileName);

    console.log("Public URL generated:", publicUrl);

    // Store URL in profiles table
    const { error: dbError } = await sbClient
      .from("profiles")
      .update({ avatar_url: publicUrl })
      .eq("id", user.id);

    if (dbError) {
      console.error("Database error:", dbError);
      throw dbError;
    }

    console.log("Profile updated successfully");

    statusDiv.innerHTML = `Upload successful! URL: ${publicUrl}`;
    htmx.trigger("#profile-upload", "customTrigger");
  } catch (error) {
    console.error("Error in upload process:", error);
    statusDiv.innerHTML = `Error: ${error.message}`;
  }
}
