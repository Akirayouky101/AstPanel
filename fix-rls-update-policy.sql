-- =====================================================
-- FIX RLS UPDATE POLICY - Permetti agli admin di modificare tutti gli utenti
-- =====================================================
-- Gli admin devono poter modificare TUTTI gli utenti (non solo se stessi)
-- =====================================================

-- 1. Rimuovi la vecchia policy UPDATE troppo restrittiva
DROP POLICY IF EXISTS users_update_own ON users;
DROP POLICY IF EXISTS users_update_policy ON users;
DROP POLICY IF EXISTS users_update ON users;

-- 2. Crea nuova policy UPDATE per admin
-- Gli admin possono modificare tutti gli utenti
CREATE POLICY users_update_admin ON users
FOR UPDATE
USING (true)  -- Gli admin possono vedere/modificare tutti
WITH CHECK (true);  -- Permetti tutte le modifiche (i trigger proteggono il super admin)

-- 3. Verifica le policy attive
SELECT 
    tablename,
    policyname,
    cmd as operation,
    permissive,
    CASE 
        WHEN cmd = 'SELECT' THEN '👁️ Lettura'
        WHEN cmd = 'INSERT' THEN '➕ Inserimento'
        WHEN cmd = 'UPDATE' THEN '✏️ Modifica'
        WHEN cmd = 'DELETE' THEN '🗑️ Eliminazione'
        ELSE cmd
    END as tipo_operazione,
    CASE 
        WHEN policyname LIKE '%select%' THEN 'Ogni utente vede i propri dati'
        WHEN policyname LIKE '%update%' THEN 'Admin possono modificare tutti gli utenti'
        WHEN policyname LIKE '%insert%' THEN 'Inserimenti permessi (via admin)'
        WHEN policyname LIKE '%delete%' THEN 'Eliminazioni permesse (tranne super admin)'
        ELSE 'Policy generica'
    END as descrizione
FROM pg_policies
WHERE tablename = 'users'
ORDER BY 
    CASE cmd 
        WHEN 'SELECT' THEN 1
        WHEN 'INSERT' THEN 2
        WHEN 'UPDATE' THEN 3
        WHEN 'DELETE' THEN 4
    END;

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ UPDATE POLICY AGGIORNATA!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Policy UPDATE:';
    RAISE NOTICE '  ✏️  Gli admin possono modificare TUTTI gli utenti';
    RAISE NOTICE '  🛡️  I trigger proteggono il super admin da modifiche critiche';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANTE:';
    RAISE NOTICE '  - Usa window.supabaseAdmin per le modifiche (service_role_key)';
    RAISE NOTICE '  - Il super admin è protetto da: prevent_superadmin_role_change()';
    RAISE NOTICE '';
END $$;
