-- =====================================================
-- FIX auth_id per utente admin esistente
-- =====================================================
-- Il problema: quando creiamo l'utente con first-setup.html
-- viene creato in auth.users MA non viene aggiornato auth_id
-- nella tabella public.users
-- =====================================================

-- Aggiorna auth_id per l'utente admin
UPDATE public.users
SET auth_id = 'a603e505-c739-46d0-9076-470c3cbb35c3'
WHERE email = 'serviziomail1@gmail.com'
AND auth_id IS NULL;

-- Verifica
SELECT 
    id,
    nome,
    cognome, 
    email,
    ruolo,
    auth_id,
    first_login,
    CASE 
        WHEN auth_id IS NOT NULL THEN '✅ auth_id COLLEGATO'
        ELSE '❌ auth_id MANCANTE'
    END as status
FROM public.users
WHERE email = 'serviziomail1@gmail.com';
