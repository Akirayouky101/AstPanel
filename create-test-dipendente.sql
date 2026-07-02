-- =====================================================
-- CREA UTENTE TEST DIPENDENTE
-- Email:    dipendente.test@zgimpianti.it
-- Password: Test1234!
-- =====================================================

DO $$
DECLARE
    v_auth_id UUID := gen_random_uuid();
    v_user_id UUID := gen_random_uuid();
BEGIN

    -- Rimuovi eventuale utente test precedente
    DELETE FROM public.users WHERE email = 'dipendente.test@zgimpianti.it';
    DELETE FROM auth.identities WHERE email = 'dipendente.test@zgimpianti.it';
    DELETE FROM auth.users WHERE email = 'dipendente.test@zgimpianti.it';

    -- 1. Crea utente in auth.users
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        confirmation_token,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        v_auth_id,
        'authenticated',
        'authenticated',
        'dipendente.test@zgimpianti.it',
        crypt('Test1234!', gen_salt('bf')),
        NOW(),
        NOW(),
        NOW(),
        '{"provider":"email","providers":["email"]}',
        '{"nome":"Marco","cognome":"Rossi"}',
        false,
        '',
        ''
    );

    -- 2. Crea identity (OBBLIGATORIA per login email/password)
    INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        v_auth_id,
        jsonb_build_object('sub', v_auth_id::text, 'email', 'dipendente.test@zgimpianti.it'),
        'email',
        v_auth_id::text,
        NOW(),
        NOW(),
        NOW()
    );

    -- 2. Crea record in public.users
    INSERT INTO public.users (
        id,
        auth_id,
        email,
        nome,
        cognome,
        ruolo,
        stato
    ) VALUES (
        v_user_id,
        v_auth_id,
        'dipendente.test@zgimpianti.it',
        'Marco',
        'Rossi',
        'dipendente',
        'attivo'
    );

    RAISE NOTICE '✅ Utente creato!';
    RAISE NOTICE '   auth_id : %', v_auth_id;
    RAISE NOTICE '   user_id : %', v_user_id;
    RAISE NOTICE '   Email   : dipendente.test@zgimpianti.it';
    RAISE NOTICE '   Password: Test1234!';

END $$;
