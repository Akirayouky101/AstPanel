-- =====================================================
-- VERIFICA STATO COMPLETO UTENTI
-- =====================================================

-- 1. Utenti in public.users
SELECT 
    'PUBLIC.USERS' as fonte,
    id,
    nome,
    cognome,
    email,
    ruolo,
    auth_id,
    CASE 
        WHEN auth_id IS NULL THEN '❌ NO AUTH_ID'
        ELSE '✅ Has auth_id'
    END as stato_auth
FROM public.users
ORDER BY created_at;

-- 2. Utenti in auth.users
SELECT 
    'AUTH.USERS' as fonte,
    id,
    email,
    created_at,
    CASE 
        WHEN EXISTS (SELECT 1 FROM public.users WHERE auth_id = auth.users.id) 
        THEN '✅ Linked to public.users'
        ELSE '❌ ORPHAN - No link'
    END as stato_link
FROM auth.users
ORDER BY created_at;

-- 3. Cross-check: quali utenti hanno problemi
SELECT 
    pu.email as public_email,
    pu.nome,
    pu.cognome,
    pu.ruolo,
    pu.auth_id as public_auth_id,
    au.id as auth_user_id,
    CASE 
        WHEN pu.auth_id IS NULL THEN '❌ NO AUTH_ID in public.users'
        WHEN au.id IS NULL THEN '❌ AUTH USER NOT FOUND'
        WHEN pu.auth_id = au.id THEN '✅ CORRETTO'
        ELSE '⚠️ MISMATCH'
    END as stato
FROM public.users pu
LEFT JOIN auth.users au ON pu.auth_id = au.id
ORDER BY pu.created_at;
