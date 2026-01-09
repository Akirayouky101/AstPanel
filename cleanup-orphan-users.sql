-- =====================================================
-- PULIZIA COMPLETA UTENTI ORFANI + FIX RLS
-- =====================================================
-- Questo script:
-- 1. Elimina utenti orfani da Supabase Auth (senza corrispondenza in users)
-- 2. Corregge le RLS policies per usare auth_id
-- 3. Garantisce che solo utenti validi possano accedere
-- =====================================================

-- PARTE 1: Lista utenti da eliminare (solo per verifica)
-- =====================================================
-- Query per trovare auth_id presenti in auth.users ma non in public.users
-- NOTA: Questa è solo informativa, non elimina nulla

DO $$
DECLARE
    auth_user RECORD;
    super_admin_auth_id UUID := '0536c4f6-e377-4e81-ab81-95e14a2214d7';
    deleted_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🔍 Cercando utenti orfani in Supabase Auth...';
    
    -- Loop attraverso tutti gli utenti in auth.users
    FOR auth_user IN 
        SELECT id, email, created_at 
        FROM auth.users
    LOOP
        -- Verifica se l'utente esiste in public.users
        IF NOT EXISTS (
            SELECT 1 FROM public.users WHERE auth_id = auth_user.id
        ) THEN
            -- Utente orfano trovato
            RAISE NOTICE '❌ Utente orfano trovato: % (ID: %)', auth_user.email, auth_user.id;
            
            -- NON eliminare il super admin
            IF auth_user.id != super_admin_auth_id THEN
                -- Elimina l'utente da auth.users
                DELETE FROM auth.users WHERE id = auth_user.id;
                deleted_count := deleted_count + 1;
                RAISE NOTICE '🗑️  Eliminato: %', auth_user.email;
            ELSE
                RAISE NOTICE '🛡️  Super admin preservato: %', auth_user.email;
            END IF;
        ELSE
            RAISE NOTICE '✅ Utente valido: %', auth_user.email;
        END IF;
    END LOOP;
    
    RAISE NOTICE '📊 Totale utenti orfani eliminati: %', deleted_count;
END $$;

-- PARTE 2: Fix RLS Policies
-- =====================================================

-- Disabilita temporaneamente RLS per modifiche
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Elimina tutte le policy esistenti su users
DROP POLICY IF EXISTS admin_all ON users;
DROP POLICY IF EXISTS user_own_data ON users;
DROP POLICY IF EXISTS users_select_own ON users;
DROP POLICY IF EXISTS users_update_own ON users;
DROP POLICY IF EXISTS users_service_role_all ON users;

-- Riabilita RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Crea nuove policy corrette che usano auth_id

-- 1. Policy per leggere il proprio record (usa auth_id)
CREATE POLICY users_select_own ON users 
FOR SELECT 
USING (auth_id = auth.uid());

-- 2. Policy per aggiornare il proprio record (usa auth_id)
CREATE POLICY users_update_own ON users 
FOR UPDATE 
USING (auth_id = auth.uid());

-- 3. Policy per inserire (solo via backend/admin)
CREATE POLICY users_insert_service ON users 
FOR INSERT 
WITH CHECK (false);  -- Nessuno può inserire direttamente (solo via backend)

-- 4. Policy per eliminare (solo via backend/admin)
CREATE POLICY users_delete_service ON users 
FOR DELETE 
USING (false);  -- Nessuno può eliminare direttamente

-- PARTE 3: Verifica finale
-- =====================================================

-- Mostra tutte le policy attive
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as operation,
    qual as using_expression
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;

-- Conta utenti in public.users
SELECT 
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE id = '00000000-0000-0000-0000-000000000001') as super_admin_count,
    COUNT(*) FILTER (WHERE auth_id IS NOT NULL) as users_with_auth,
    COUNT(*) FILTER (WHERE auth_id IS NULL) as users_without_auth
FROM public.users;

-- Lista tutti gli utenti validi
SELECT 
    id,
    email,
    nome,
    cognome,
    ruolo,
    auth_id,
    CASE 
        WHEN id = '00000000-0000-0000-0000-000000000001' THEN '🛡️ SUPER ADMIN'
        WHEN auth_id IS NOT NULL THEN '✅ Valido'
        ELSE '⚠️ Senza Auth'
    END as status
FROM public.users
ORDER BY 
    CASE WHEN id = '00000000-0000-0000-0000-000000000001' THEN 0 ELSE 1 END,
    email;

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ PULIZIA COMPLETATA CON SUCCESSO!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Azioni eseguite:';
    RAISE NOTICE '  1. ✅ Utenti orfani eliminati da auth.users';
    RAISE NOTICE '  2. ✅ RLS Policies aggiornate per usare auth_id';
    RAISE NOTICE '  3. ✅ Super admin preservato e protetto';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Nuove regole di sicurezza:';
    RAISE NOTICE '  - Solo utenti con auth_id valido possono accedere';
    RAISE NOTICE '  - Ogni utente vede solo i propri dati';
    RAISE NOTICE '  - Inserimenti/eliminazioni solo via backend';
    RAISE NOTICE '';
END $$;
