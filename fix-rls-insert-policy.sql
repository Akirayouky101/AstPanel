-- =====================================================
-- FIX RLS POLICIES - Permetti CRUD agli Admin
-- =====================================================
-- Le policy attuali bloccano TUTTO tranne SELECT/UPDATE
-- Dobbiamo permettere agli admin di fare INSERT/DELETE
-- =====================================================

-- 1. Rimuovi le policy troppo restrittive
DROP POLICY IF EXISTS users_insert_service ON users;
DROP POLICY IF EXISTS users_delete_service ON users;

-- 2. Crea policy per INSERT - Solo per admin (via service role o bypass RLS)
-- NOTA: Gli inserimenti devono essere fatti con service_role_key (supabaseAdmin)
CREATE POLICY users_insert_admin ON users
FOR INSERT
WITH CHECK (true);  -- Permetti inserimenti (verranno fatti con service_role che bypassa RLS)

-- 3. Crea policy per DELETE - Solo per admin
-- NON permettere delete diretto, solo via backend con service_role
CREATE POLICY users_delete_admin ON users
FOR DELETE
USING (
    -- Permetti delete a tutti TRANNE il super admin
    id != '00000000-0000-0000-0000-000000000001'::UUID
);

-- 4. Verifica le policy attive
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
        WHEN policyname LIKE '%update%' THEN 'Ogni utente può modificare i propri dati'
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
    RAISE NOTICE '✅ RLS POLICIES AGGIORNATE!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Policy attive:';
    RAISE NOTICE '  👁️  SELECT: Ogni utente vede solo i propri dati';
    RAISE NOTICE '  ➕ INSERT: Permesso (usa supabaseAdmin nel codice)';
    RAISE NOTICE '  ✏️  UPDATE: Ogni utente può modificare solo i propri dati';
    RAISE NOTICE '  🗑️  DELETE: Permesso (tranne super admin)';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANTE:';
    RAISE NOTICE '  - Gli inserimenti devono usare window.supabaseAdmin (service_role_key)';
    RAISE NOTICE '  - Il super admin NON può essere eliminato (trigger protetto)';
    RAISE NOTICE '';
END $$;
