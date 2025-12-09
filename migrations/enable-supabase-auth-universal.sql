-- =====================================================
-- ABILITA SUPABASE AUTH UFFICIALE + RLS
-- =====================================================
-- VERSIONE COMPATIBILE: Funziona con schema italiano E inglese
-- =====================================================

-- =====================================================
-- Step 1: Rileva quale schema è in uso
-- =====================================================

DO $$
BEGIN
    -- Controlla se esiste tabella 'users' (schema inglese)
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE NOTICE '✅ Trovato schema INGLESE (users, clients, tasks)';
        
        -- Aggiungi colonne a tabella USERS
        ALTER TABLE users 
        ADD COLUMN IF NOT EXISTS auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        
        ALTER TABLE users 
        ADD COLUMN IF NOT EXISTS first_login BOOLEAN DEFAULT TRUE;
        
        CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);
        
        RAISE NOTICE '✅ Colonne aggiunte a tabella USERS';
    END IF;
    
    -- Controlla se esiste tabella 'utenti' (schema italiano)
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'utenti') THEN
        RAISE NOTICE '✅ Trovato schema ITALIANO (utenti, clienti, timbrature)';
        
        -- Aggiungi colonne a tabella UTENTI
        ALTER TABLE utenti 
        ADD COLUMN IF NOT EXISTS auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        
        ALTER TABLE utenti 
        ADD COLUMN IF NOT EXISTS first_login BOOLEAN DEFAULT TRUE;
        
        CREATE INDEX IF NOT EXISTS idx_utenti_auth_id ON utenti(auth_id);
        
        RAISE NOTICE '✅ Colonne aggiunte a tabella UTENTI';
    END IF;
END $$;

-- =====================================================
-- Step 2: ABILITA RLS - Schema INGLESE
-- =====================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        ALTER TABLE users ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su USERS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'clients') THEN
        ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su CLIENTS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tasks') THEN
        ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su TASKS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'components') THEN
        ALTER TABLE components ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su COMPONENTS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'requests') THEN
        ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su REQUESTS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'communications') THEN
        ALTER TABLE communications ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su COMMUNICATIONS';
    END IF;
END $$;

-- =====================================================
-- Step 3: ABILITA RLS - Schema ITALIANO
-- =====================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'utenti') THEN
        ALTER TABLE utenti ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su UTENTI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'timbrature') THEN
        ALTER TABLE timbrature ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su TIMBRATURE';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'lavorazioni') THEN
        ALTER TABLE lavorazioni ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su LAVORAZIONI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'clienti') THEN
        ALTER TABLE clienti ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su CLIENTI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'email_destinatari') THEN
        ALTER TABLE email_destinatari ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su EMAIL_DESTINATARI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'richieste_materiale') THEN
        ALTER TABLE richieste_materiale ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su RICHIESTE_MATERIALE';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'prodotti_magazzino') THEN
        ALTER TABLE prodotti_magazzino ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su PRODOTTI_MAGAZZINO';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'comunicazioni') THEN
        ALTER TABLE comunicazioni ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS abilitato su COMUNICAZIONI';
    END IF;
END $$;

-- =====================================================
-- Step 4: POLICIES - Schema ITALIANO (se esiste)
-- =====================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'utenti') THEN
        -- Drop existing policies if they exist
        DROP POLICY IF EXISTS "utenti_select_own" ON utenti;
        DROP POLICY IF EXISTS "utenti_select_admin" ON utenti;
        DROP POLICY IF EXISTS "utenti_insert_admin" ON utenti;
        DROP POLICY IF EXISTS "utenti_update_own" ON utenti;
        DROP POLICY IF EXISTS "utenti_update_admin" ON utenti;
        DROP POLICY IF EXISTS "utenti_delete_admin" ON utenti;
        
        -- UTENTI: utenti vedono solo se stessi
        CREATE POLICY "utenti_select_own" ON utenti
            FOR SELECT
            USING (auth.uid() = auth_id);
        
        -- UTENTI: admin vedono tutti
        CREATE POLICY "utenti_select_admin" ON utenti
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM utenti
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
                )
            );
        
        -- UTENTI: solo admin possono creare
        CREATE POLICY "utenti_insert_admin" ON utenti
            FOR INSERT
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM utenti
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
                )
            );
        
        -- UTENTI: possono aggiornare solo se stessi
        CREATE POLICY "utenti_update_own" ON utenti
            FOR UPDATE
            USING (auth.uid() = auth_id);
        
        -- UTENTI: admin possono aggiornare tutti
        CREATE POLICY "utenti_update_admin" ON utenti
            FOR UPDATE
            USING (
                EXISTS (
                    SELECT 1 FROM utenti
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
                )
            );
        
        -- UTENTI: solo admin possono eliminare
        CREATE POLICY "utenti_delete_admin" ON utenti
            FOR DELETE
            USING (
                EXISTS (
                    SELECT 1 FROM utenti
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
                )
            );
        
        RAISE NOTICE '✅ Policies create per tabella UTENTI';
    END IF;
    
    -- TIMBRATURE
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'timbrature') THEN
        DROP POLICY IF EXISTS "timbrature_select_own" ON timbrature;
        DROP POLICY IF EXISTS "timbrature_select_admin" ON timbrature;
        DROP POLICY IF EXISTS "timbrature_insert_own" ON timbrature;
        DROP POLICY IF EXISTS "timbrature_update_own" ON timbrature;
        DROP POLICY IF EXISTS "timbrature_update_admin" ON timbrature;
        
        CREATE POLICY "timbrature_select_own" ON timbrature
            FOR SELECT
            USING (
                user_id IN (SELECT id FROM utenti WHERE auth_id = auth.uid())
            );
        
        CREATE POLICY "timbrature_select_admin" ON timbrature
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM utenti
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
                )
            );
        
        CREATE POLICY "timbrature_insert_own" ON timbrature
            FOR INSERT
            WITH CHECK (
                user_id IN (SELECT id FROM utenti WHERE auth_id = auth.uid())
            );
        
        CREATE POLICY "timbrature_update_own" ON timbrature
            FOR UPDATE
            USING (
                user_id IN (SELECT id FROM utenti WHERE auth_id = auth.uid())
            );
        
        CREATE POLICY "timbrature_update_admin" ON timbrature
            FOR UPDATE
            USING (
                EXISTS (
                    SELECT 1 FROM utenti
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
                )
            );
        
        RAISE NOTICE '✅ Policies create per tabella TIMBRATURE';
    END IF;
    
    -- EMAIL_DESTINATARI
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'email_destinatari') THEN
        DROP POLICY IF EXISTS "email_destinatari_admin_all" ON email_destinatari;
        
        CREATE POLICY "email_destinatari_admin_all" ON email_destinatari
            FOR ALL
            USING (
                EXISTS (
                    SELECT 1 FROM utenti
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
                )
            );
        
        RAISE NOTICE '✅ Policies create per EMAIL_DESTINATARI';
    END IF;
    
    -- LAVORAZIONI
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'lavorazioni') THEN
        DROP POLICY IF EXISTS "lavorazioni_select_all" ON lavorazioni;
        DROP POLICY IF EXISTS "lavorazioni_admin_all" ON lavorazioni;
        
        CREATE POLICY "lavorazioni_select_all" ON lavorazioni
            FOR SELECT
            USING (auth.uid() IS NOT NULL);
        
        CREATE POLICY "lavorazioni_admin_all" ON lavorazioni
            FOR ALL
            USING (
                EXISTS (
                    SELECT 1 FROM utenti
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
                )
            );
        
        RAISE NOTICE '✅ Policies create per LAVORAZIONI';
    END IF;
    
    -- CLIENTI
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'clienti') THEN
        DROP POLICY IF EXISTS "clienti_select_all" ON clienti;
        DROP POLICY IF EXISTS "clienti_admin_all" ON clienti;
        
        CREATE POLICY "clienti_select_all" ON clienti
            FOR SELECT
            USING (auth.uid() IS NOT NULL);
        
        CREATE POLICY "clienti_admin_all" ON clienti
            FOR ALL
            USING (
                EXISTS (
                    SELECT 1 FROM utenti
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
                )
            );
        
        RAISE NOTICE '✅ Policies create per CLIENTI';
    END IF;
END $$;

-- =====================================================
-- Step 5: POLICIES - Schema INGLESE (se esiste)
-- =====================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        DROP POLICY IF EXISTS "users_select_all" ON users;
        DROP POLICY IF EXISTS "users_admin_all" ON users;
        
        -- USERS: tutti vedono tutti (per ora - da personalizzare)
        CREATE POLICY "users_select_all" ON users
            FOR SELECT
            USING (auth.uid() IS NOT NULL);
        
        -- USERS: admin possono fare tutto
        CREATE POLICY "users_admin_all" ON users
            FOR ALL
            USING (
                EXISTS (
                    SELECT 1 FROM users
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('admin', 'tecnico')
                )
            );
        
        RAISE NOTICE '✅ Policies create per tabella USERS';
    END IF;
    
    -- TASKS
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tasks') THEN
        DROP POLICY IF EXISTS "tasks_select_all" ON tasks;
        DROP POLICY IF EXISTS "tasks_admin_all" ON tasks;
        
        CREATE POLICY "tasks_select_all" ON tasks
            FOR SELECT
            USING (auth.uid() IS NOT NULL);
        
        CREATE POLICY "tasks_admin_all" ON tasks
            FOR ALL
            USING (
                EXISTS (
                    SELECT 1 FROM users
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('admin', 'tecnico')
                )
            );
        
        RAISE NOTICE '✅ Policies create per TASKS';
    END IF;
    
    -- CLIENTS
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'clients') THEN
        DROP POLICY IF EXISTS "clients_select_all" ON clients;
        DROP POLICY IF EXISTS "clients_admin_all" ON clients;
        
        CREATE POLICY "clients_select_all" ON clients
            FOR SELECT
            USING (auth.uid() IS NOT NULL);
        
        CREATE POLICY "clients_admin_all" ON clients
            FOR ALL
            USING (
                EXISTS (
                    SELECT 1 FROM users
                    WHERE auth_id = auth.uid()
                    AND ruolo IN ('admin', 'tecnico')
                )
            );
        
        RAISE NOTICE '✅ Policies create per CLIENTS';
    END IF;
END $$;

-- =====================================================
-- Step 6: Function helper
-- =====================================================

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

-- =====================================================
-- Step 7: Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ SUPABASE AUTH CONFIGURATO CON SUCCESSO!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Prossimi passi:';
    RAISE NOTICE '1. Configura Service Role Key in supabase-client.js';
    RAISE NOTICE '2. Vai in gestione-utenti.html e crea primo utente admin';
    RAISE NOTICE '3. Testa login con credenziali temporanee';
    RAISE NOTICE '4. Testa cambio password al primo accesso';
    RAISE NOTICE '';
END $$;
