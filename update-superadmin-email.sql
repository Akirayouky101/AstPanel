-- =====================================================
-- AGGIORNA EMAIL SUPER ADMIN IN SUPABASE AUTH
-- =====================================================
-- Questo script aggiorna l'email del super admin in auth.users
-- per farla corrispondere con quella in public.users
-- =====================================================

-- 1. Verifica stato attuale
SELECT 
    'PRIMA DELLA MODIFICA' as fase,
    au.id,
    au.email as email_auth,
    pu.email as email_users,
    CASE 
        WHEN au.email = pu.email THEN '✅ Corrispondono'
        ELSE '❌ NON corrispondono'
    END as status
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.auth_id
WHERE au.id = '0536c4f6-e377-4e81-ab81-95e14a2214d7';

-- 2. Aggiorna email in auth.users per farla corrispondere
UPDATE auth.users
SET 
    email = 'diegomarruchi@outlook.it',
    raw_user_meta_data = jsonb_set(
        raw_user_meta_data,
        '{email}',
        '"diegomarruchi@outlook.it"'
    )
WHERE id = '0536c4f6-e377-4e81-ab81-95e14a2214d7';

-- 3. Verifica dopo la modifica
SELECT 
    'DOPO LA MODIFICA' as fase,
    au.id,
    au.email as email_auth,
    pu.email as email_users,
    CASE 
        WHEN au.email = pu.email THEN '✅ Corrispondono'
        ELSE '❌ NON corrispondono'
    END as status
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.auth_id
WHERE au.id = '0536c4f6-e377-4e81-ab81-95e14a2214d7';

-- 4. Mostra i dettagli completi del super admin
SELECT 
    '🛡️ SUPER ADMIN - DETTAGLI COMPLETI' as info,
    au.id as auth_id,
    au.email as email_auth,
    au.created_at as registrato_il,
    au.last_sign_in_at as ultimo_accesso,
    pu.id as user_id,
    pu.email as email_users,
    pu.nome,
    pu.cognome,
    pu.ruolo,
    pu.telefono,
    pu.pin_code as pin
FROM auth.users au
INNER JOIN public.users pu ON au.id = pu.auth_id
WHERE au.id = '0536c4f6-e377-4e81-ab81-95e14a2214d7';

-- Messaggio di conferma
DO $$ 
BEGIN 
    RAISE NOTICE '✅ Email aggiornata con successo!';
    RAISE NOTICE '📧 Nuova email: diegomarruchi@outlook.it';
    RAISE NOTICE '🔐 Ora puoi fare login con: diegomarruchi@outlook.it';
END $$;
