-- =====================================================
-- DELETE ORPHAN FROM AUTH.USERS
-- =====================================================
-- Elimina utente che esiste solo in auth.users ma non in public.users
-- Auth ID: f24ecacb-6c73-4a3d-9fdd-8758840a6e63
-- =====================================================

-- 1. Verifica l'utente in auth.users
SELECT 
    '🔐 UTENTE IN AUTH.USERS' as info,
    id as auth_id,
    email,
    created_at
FROM auth.users
WHERE id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';

-- 2. Verifica che NON esista in public.users (dovrebbe essere vuoto)
SELECT 
    '📊 UTENTE IN PUBLIC.USERS (dovrebbe essere vuoto)' as info,
    *
FROM public.users
WHERE auth_id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';

-- 3. ELIMINA da auth.users (usa auth schema con permessi admin)
DELETE FROM auth.users
WHERE id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';

-- 4. Verifica eliminazione (dovrebbe essere vuoto)
SELECT 
    '✅ VERIFICA ELIMINAZIONE (dovrebbe essere vuoto)' as info,
    id,
    email
FROM auth.users
WHERE id = 'f24ecacb-6c73-4a3d-9fdd-8758840a6e63';

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ UTENTE ELIMINATO DA AUTH.USERS!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Ora puoi ricreare l''utente dalla UI';
    RAISE NOTICE '';
END $$;
