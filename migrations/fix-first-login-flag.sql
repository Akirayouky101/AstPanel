-- =====================================================
-- FIX first_login flag per utente admin
-- =====================================================
-- Il cambio password è andato a buon fine, ma il flag
-- first_login non è stato aggiornato
-- =====================================================

UPDATE public.users
SET first_login = false
WHERE email = 'serviziomail1@gmail.com';

-- Verifica
SELECT 
    id, 
    nome, 
    email, 
    first_login, 
    updated_at,
    CASE 
        WHEN first_login = false THEN '✅ PRIMO LOGIN COMPLETATO'
        ELSE '❌ ANCORA IN ATTESA'
    END as status
FROM public.users
WHERE email = 'serviziomail1@gmail.com';
