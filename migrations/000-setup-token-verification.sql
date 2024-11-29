CREATE OR REPLACE FUNCTION public.check_auth()
RETURNS record AS $$
DECLARE
    token_payload record;
BEGIN
    token_payload := auth.uid();
    IF token_payload IS NOT NULL THEN
        RETURN token_payload;
    ELSE
        RETURN NULL::record;
    END IF;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.check_auth() SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION public.check_auth() TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_auth() TO anon;
