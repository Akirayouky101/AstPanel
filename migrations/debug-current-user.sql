-- ============================================
-- DEBUG CURRENT USER ID
-- ============================================
-- Verifica qual è l'utente corrente e il suo ID
-- ============================================

-- 1. Mostra l'utente auth corrente
SELECT 
    'AUTH USER' as tipo,
    id as user_id,
    email,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 2. Mostra gli utenti nella tabella custom
SELECT 
    'CUSTOM USER' as tipo,
    id as user_id,
    auth_id,
    email,
    ruolo,
    created_at
FROM users
ORDER BY created_at DESC
LIMIT 5;

-- 3. Verifica se l'ID specifico esiste
SELECT 
    'VERIFICA ID' as tipo,
    CASE 
        WHEN EXISTS (SELECT 1 FROM users WHERE id = '0536c4f6-e377-4e81-ab81-95e14a2214d7') 
        THEN 'ID ESISTE in users'
        WHEN EXISTS (SELECT 1 FROM auth.users WHERE id = '0536c4f6-e377-4e81-ab81-95e14a2214d7')
        THEN 'ID ESISTE in auth.users (ERRORE!)'
        ELSE 'ID NON ESISTE'
    END as risultato;

-- 4. Cerca corrispondenza auth_id -> user_id
SELECT 
    'MAPPATURA' as tipo,
    au.id as auth_id,
    au.email as auth_email,
    u.id as user_id,
    u.email as user_email,
    u.ruolo
FROM auth.users au
LEFT JOIN users u ON u.auth_id = au.id
ORDER BY au.created_at DESC
LIMIT 5;

-- ============================================
-- FINE DEBUG
-- ============================================
