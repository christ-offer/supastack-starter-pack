CREATE OR REPLACE FUNCTION get_api_url()
RETURNS text AS $$
BEGIN
    RETURN 'https://your-supabase-project-id.supabase.co/rest/v1/rpc';
END;
$$ LANGUAGE plpgsql;
