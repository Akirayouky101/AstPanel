-- =====================================================
-- SYNC ORPHAN USER - Sincronizza utente esistente
-- =====================================================
-- Auth ID dal log: f24ecacb-6c73-4a3d-9fdd-8758840a6e63
-- =====================================================

-- 1. Trova l'email dell'utente in auth.users
SELECT 
    id as auth_id,
    email,
    created_at,
    raw_user_meta_data
FROM auth.users
WHERE id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';

-- 2. Verifica se esiste in public.users (dovrebbe essere vuoto)
SELECT * FROM public.users WHERE auth_id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';

-- 3. CREA l'utente in public.users
-- PRIMA esegui lo step 1 per vedere l'email, poi sostituisci qui sotto:
-- Sostituisci <EMAIL_FROM_STEP_1>, <NOME>, <COGNOME> con i valori corretti

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
    'EMAIL_DA_SOSTITUIRE',  -- ⚠️ SOSTITUISCI con email dallo step 1
    'NOME_DA_SOSTITUIRE',    -- ⚠️ SOSTITUISCI con nome utente
    'COGNOME_DA_SOSTITUIRE', -- ⚠️ SOSTITUISCI con cognome utente
    'dipendente',            -- ✅ Ruolo lowercase
    'attivo',
    true,  -- Richiederà cambio password al primo login
    NOW()
)
ON CONFLICT (auth_id) DO UPDATE SET
    ruolo = EXCLUDED.ruolo,  -- Aggiorna a lowercase se già esiste
    stato = EXCLUDED.stato;

-- 4. Verifica creazione
SELECT 
    id,
    auth_id,
    email,
    nome,
    cognome,
    ruolo,
    stato,
    first_login
FROM public.users
WHERE auth_id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';

-- 5. Se ci sono task assegnati all'auth_id, aggiorna il riferimento
-- (questo succede se hai creato task prima di sincronizzare)
UPDATE tasks
SET assigned_user_id = (
    SELECT id FROM public.users WHERE auth_id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63'
)
WHERE assigned_user_id IN (
    SELECT id FROM auth.users WHERE id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63'
);
