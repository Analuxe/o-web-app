-- Create dummy users in auth.users so that DummyDataService can insert into profiles.
DO $$ 
DECLARE
    i INT;
    user_id UUID;
BEGIN
    FOR i IN 1..15 LOOP
        -- Generate the exact dummy UUIDs we need: d0000000-0000-0000-0000-000000000001 to 015
        user_id := ('d0000000-0000-0000-0000-' || lpad(i::text, 12, '0'))::UUID;
        
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, 
            last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, 
            confirmation_token, email_change, email_change_token_new, recovery_token
        )
        VALUES (
            user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 
            'dummy' || i || '@test.com', '', now(), now(), 
            '{"provider":"email","providers":["email"]}', '{}', now(), now(), 
            '', '', '', ''
        )
        ON CONFLICT (id) DO NOTHING;
    END LOOP;
END $$;
