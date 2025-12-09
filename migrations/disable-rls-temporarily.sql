-- =====================================================
-- DISABILITA TEMPORANEAMENTE RLS
-- =====================================================
-- Usare SOLO per configurazione iniziale
-- Riabilitare dopo aver creato primo utente admin
-- =====================================================

DO $$
BEGIN
    -- Disabilita RLS su tutte le tabelle (schema ITALIANO)
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'utenti') THEN
        ALTER TABLE utenti DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su UTENTI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'timbrature') THEN
        ALTER TABLE timbrature DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su TIMBRATURE';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'lavorazioni') THEN
        ALTER TABLE lavorazioni DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su LAVORAZIONI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'clienti') THEN
        ALTER TABLE clienti DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su CLIENTI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'email_destinatari') THEN
        ALTER TABLE email_destinatari DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su EMAIL_DESTINATARI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'richieste_materiale') THEN
        ALTER TABLE richieste_materiale DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su RICHIESTE_MATERIALE';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'prodotti_magazzino') THEN
        ALTER TABLE prodotti_magazzino DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su PRODOTTI_MAGAZZINO';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'comunicazioni') THEN
        ALTER TABLE comunicazioni DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su COMUNICAZIONI';
    END IF;
    
    -- Disabilita RLS su tutte le tabelle (schema INGLESE)
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        ALTER TABLE users DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su USERS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'clients') THEN
        ALTER TABLE clients DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su CLIENTS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tasks') THEN
        ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su TASKS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'components') THEN
        ALTER TABLE components DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su COMPONENTS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'requests') THEN
        ALTER TABLE requests DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su REQUESTS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'communications') THEN
        ALTER TABLE communications DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 RLS disabilitato su COMMUNICATIONS';
    END IF;
END $$;

-- =====================================================
-- Drop tutte le policies esistenti
-- =====================================================

DO $$
BEGIN
    -- Schema ITALIANO
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'utenti') THEN
        DROP POLICY IF EXISTS "utenti_select_own" ON utenti;
        DROP POLICY IF EXISTS "utenti_select_admin" ON utenti;
        DROP POLICY IF EXISTS "utenti_insert_admin" ON utenti;
        DROP POLICY IF EXISTS "utenti_update_own" ON utenti;
        DROP POLICY IF EXISTS "utenti_update_admin" ON utenti;
        DROP POLICY IF EXISTS "utenti_delete_admin" ON utenti;
        RAISE NOTICE '🗑️  Policies rimosse da UTENTI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'timbrature') THEN
        DROP POLICY IF EXISTS "timbrature_select_own" ON timbrature;
        DROP POLICY IF EXISTS "timbrature_select_admin" ON timbrature;
        DROP POLICY IF EXISTS "timbrature_insert_own" ON timbrature;
        DROP POLICY IF EXISTS "timbrature_update_own" ON timbrature;
        DROP POLICY IF EXISTS "timbrature_update_admin" ON timbrature;
        RAISE NOTICE '🗑️  Policies rimosse da TIMBRATURE';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'email_destinatari') THEN
        DROP POLICY IF EXISTS "email_destinatari_admin_all" ON email_destinatari;
        RAISE NOTICE '🗑️  Policies rimosse da EMAIL_DESTINATARI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'lavorazioni') THEN
        DROP POLICY IF EXISTS "lavorazioni_select_all" ON lavorazioni;
        DROP POLICY IF EXISTS "lavorazioni_admin_all" ON lavorazioni;
        RAISE NOTICE '🗑️  Policies rimosse da LAVORAZIONI';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'clienti') THEN
        DROP POLICY IF EXISTS "clienti_select_all" ON clienti;
        DROP POLICY IF EXISTS "clienti_admin_all" ON clienti;
        RAISE NOTICE '🗑️  Policies rimosse da CLIENTI';
    END IF;
    
    -- Schema INGLESE
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        DROP POLICY IF EXISTS "users_select_all" ON users;
        DROP POLICY IF EXISTS "users_admin_all" ON users;
        RAISE NOTICE '🗑️  Policies rimosse da USERS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tasks') THEN
        DROP POLICY IF EXISTS "tasks_select_all" ON tasks;
        DROP POLICY IF EXISTS "tasks_admin_all" ON tasks;
        RAISE NOTICE '🗑️  Policies rimosse da TASKS';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'clients') THEN
        DROP POLICY IF EXISTS "clients_select_all" ON clients;
        DROP POLICY IF EXISTS "clients_admin_all" ON clients;
        RAISE NOTICE '🗑️  Policies rimosse da CLIENTS';
    END IF;
END $$;

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ RLS TEMPORANEAMENTE DISABILITATO';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  ATTENZIONE: Database NON protetto!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Prossimi passi:';
    RAISE NOTICE '1. Configura Service Role Key in supabase-client.js';
    RAISE NOTICE '2. Vai in gestione-utenti.html e crea primo utente admin';
    RAISE NOTICE '3. Verifica che auth_id sia popolato';
    RAISE NOTICE '4. Esegui migrations/enable-supabase-auth-universal.sql per riabilitare RLS';
    RAISE NOTICE '';
END $$;
