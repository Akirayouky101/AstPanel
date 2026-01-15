-- =====================================================
-- CHECK ALL USERS - Verifica sincronizzazione completa
-- =====================================================

-- 1. Tutti gli utenti in auth.users
SELECT 
    '🔐 AUTH.USERS' as source,
    id as auth_id,
    email,
    created_at,
    confirmed_at,
    email_confirmed_at
FROM auth.users
ORDER BY created_at DESC;

-- 2. Tutti gli utenti in public.users
SELECT 
    '📊 PUBLIC.USERS' as source,
    id,
    auth_id,
    email,
    nome,
    cognome,
    ruolo,
    stato
FROM public.users
ORDER BY created_at DESC;

-- 3. ORPHAN CHECK: utenti in auth.users ma NON in public.users
SELECT 
    '🚨 ORPHAN in auth.users (mancano in public.users)' as problema,
    au.id as auth_id,
    au.email,
    au.created_at
FROM auth.users au
LEFT JOIN public.users pu ON pu.auth_id = au.id
WHERE pu.id IS NULL;

-- 4. MISMATCH CHECK: utenti in public.users ma senza auth_id valido
SELECT 
    '⚠️ INVALID in public.users (auth_id non valido)' as problema,
    pu.id,
    pu.auth_id,
    pu.email,
    pu.nome,
    pu.cognome,
    pu.ruolo
FROM public.users pu
LEFT JOIN auth.users au ON au.id = pu.auth_id
WHERE au.id IS NULL AND pu.auth_id IS NOT NULL;

-- 5. NULL auth_id in public.users
SELECT 
    '❌ NULL auth_id in public.users' as problema,
    id,
    email,
    nome,
    cognome,
    ruolo,
    stato
FROM public.users
WHERE auth_id IS NULL;
