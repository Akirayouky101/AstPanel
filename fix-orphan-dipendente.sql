-- =====================================================
-- FIX ORPHAN DIPENDENTE - Trova e sincronizza utente
-- =====================================================

-- 1. Trova l'utente in auth.users con questo auth_id
SELECT 
    id as auth_id,
    email,
    created_at,
    confirmed_at
FROM auth.users
WHERE id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';

-- 2. Verifica se esiste in public.users
SELECT * FROM public.users WHERE auth_id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';

-- 3. Se NON esiste in public.users, crealo
-- SOSTITUISCI <EMAIL> con l'email che vedi dallo step 1
-- SOSTITUISCI <NOME> e <COGNOME> con i dati corretti

/*
INSERT INTO public.users (
    id,
    auth_id,
    email,
    nome,
    cognome,
    ruolo,
    stato,
    first_login,
    created_at
) VALUES (
    gen_random_uuid(),
    'f24ecacb-6c73-4a3d-9fdd-8758840a6e63',
    '<EMAIL>',  -- Email dall'auth.users
    '<NOME>',   -- Inserisci nome
    '<COGNOME>',  -- Inserisci cognome
    'dipendente',  -- Ruolo
    'attivo',
    true,  -- Richiede cambio password
    NOW()
);
*/

-- 4. Verifica creazione
SELECT 
    u.id,
    u.auth_id,
    u.email,
    u.nome,
    u.cognome,
    u.ruolo,
    u.stato
FROM public.users u
WHERE u.auth_id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';
