-- =====================================================
-- SETUP INIZIALE SUPABASE AUTH (SENZA RLS)
-- =====================================================
-- Aggiunge colonne auth_id e first_login
-- NON abilita RLS (per setup iniziale)
-- =====================================================

-- Step 1: Aggiungi colonne auth_id e first_login
DO $$
BEGIN
    -- Schema INGLESE
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE NOTICE '✅ Trovato schema INGLESE (users)';
        
        ALTER TABLE users 
        ADD COLUMN IF NOT EXISTS auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        
        ALTER TABLE users 
        ADD COLUMN IF NOT EXISTS first_login BOOLEAN DEFAULT TRUE;
        
        CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);
        
        RAISE NOTICE '✅ Colonne aggiunte a tabella USERS';
        RAISE NOTICE '   - auth_id (UUID)';
        RAISE NOTICE '   - first_login (BOOLEAN)';
    END IF;
    
    -- Schema ITALIANO
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'utenti') THEN
        RAISE NOTICE '✅ Trovato schema ITALIANO (utenti)';
        
        ALTER TABLE utenti 
        ADD COLUMN IF NOT EXISTS auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        
        ALTER TABLE utenti 
        ADD COLUMN IF NOT EXISTS first_login BOOLEAN DEFAULT TRUE;
        
        CREATE INDEX IF NOT EXISTS idx_utenti_auth_id ON utenti(auth_id);
        
        RAISE NOTICE '✅ Colonne aggiunte a tabella UTENTI';
        RAISE NOTICE '   - auth_id (UUID)';
        RAISE NOTICE '   - first_login (BOOLEAN)';
    END IF;
END $$;

-- Step 2: Crea function helper
CREATE OR REPLACE FUNCTION get_user_id_from_auth()
RETURNS UUID AS $$
BEGIN
    -- Prova prima schema italiano
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'utenti') THEN
        RETURN (SELECT id FROM utenti WHERE auth_id = auth.uid() LIMIT 1);
    END IF;
    
    -- Prova schema inglese
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        RETURN (SELECT id FROM users WHERE auth_id = auth.uid() LIMIT 1);
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ SETUP INIZIALE COMPLETATO';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Prossimi passi:';
    RAISE NOTICE '1. Trova Service Role Key in Supabase Dashboard → Settings → API';
    RAISE NOTICE '2. Aggiorna supabase-client.js con Service Role Key';
    RAISE NOTICE '3. Vai in gestione-utenti.html';
    RAISE NOTICE '4. Crea primo utente admin';
    RAISE NOTICE '5. Verifica che venga generata password temporanea';
    RAISE NOTICE '6. Testa login con email + password temporanea';
    RAISE NOTICE '7. Testa cambio password';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANTE: RLS NON è ancora abilitato!';
    RAISE NOTICE '   Database accessibile senza restrizioni.';
    RAISE NOTICE '   Dopo aver creato primo admin, esegui:';
    RAISE NOTICE '   migrations/enable-supabase-auth-universal.sql';
    RAISE NOTICE '';
END $$;

COMMENT ON COLUMN users.auth_id IS 'UUID collegato a auth.users di Supabase';
COMMENT ON COLUMN users.first_login IS 'TRUE = primo accesso, forza cambio password';
