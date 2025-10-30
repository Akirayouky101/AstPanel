-- =====================================================
-- AST PANEL - Reset Database (Drop Everything)
-- =====================================================
-- ⚠️ ATTENZIONE: Questo script elimina TUTTI i dati!
-- Eseguire solo per reset completo del database
-- =====================================================

-- Disable foreign key checks temporarily
SET session_replication_role = 'replica';

-- Drop views first (dipendono dalle tabelle)
DROP VIEW IF EXISTS tasks_complete CASCADE;
DROP VIEW IF EXISTS teams_with_members CASCADE;

-- Drop policies (RLS)
DROP POLICY IF EXISTS admin_all ON users;
DROP POLICY IF EXISTS admin_all ON clients;
DROP POLICY IF EXISTS admin_all ON teams;
DROP POLICY IF EXISTS admin_all ON team_members;
DROP POLICY IF EXISTS admin_all ON components;
DROP POLICY IF EXISTS admin_all ON tasks;
DROP POLICY IF EXISTS admin_all ON task_components;
DROP POLICY IF EXISTS admin_all ON requests;
DROP POLICY IF EXISTS admin_all ON communications;
DROP POLICY IF EXISTS user_own_data ON users;
DROP POLICY IF EXISTS user_tasks ON tasks;
DROP POLICY IF EXISTS user_requests ON requests;
DROP POLICY IF EXISTS user_read_communications ON communications;

-- Drop tables in reverse order (rispetto alle foreign keys)
DROP TABLE IF EXISTS communications CASCADE;
DROP TABLE IF EXISTS requests CASCADE;
DROP TABLE IF EXISTS task_components CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS components CASCADE;
DROP TABLE IF EXISTS team_members CASCADE;
DROP TABLE IF EXISTS teams CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop functions (triggers vengono eliminati automaticamente con CASCADE)
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Re-enable foreign key checks
SET session_replication_role = 'origin';

-- Note: Non rimuoviamo l'estensione uuid-ossp perché potrebbe essere usata da altre app
-- Se vuoi rimuoverla comunque, decommenta la riga seguente:
-- DROP EXTENSION IF EXISTS "uuid-ossp" CASCADE;

-- =====================================================
-- Conferma reset completato
-- =====================================================
DO $$ 
BEGIN 
    RAISE NOTICE '✅ Database reset completato. Tutte le tabelle, viste e trigger sono stati eliminati.';
    RAISE NOTICE '📋 Ora puoi eseguire database-schema.sql per ricreare la struttura.';
END $$;
