-- =====================================================
-- AGGIORNA RUOLO UTENTE ADMIN ESISTENTE
-- =====================================================
-- Cambia il ruolo da 'admin' a 'Titolare'
-- =====================================================

UPDATE public.users
SET ruolo = 'Titolare'
WHERE email = 'serviziomail1@gmail.com';

-- Verifica
SELECT id, nome, cognome, email, ruolo
FROM public.users
WHERE email = 'serviziomail1@gmail.com';
