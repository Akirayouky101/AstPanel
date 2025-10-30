-- =====================================================
-- DISABLE RLS FOR DEVELOPMENT
-- =====================================================
-- Esegui questo script nel SQL Editor di Supabase
-- per disabilitare temporaneamente Row Level Security
-- =====================================================

ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE teams DISABLE ROW LEVEL SECURITY;
ALTER TABLE team_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE components DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE task_components DISABLE ROW LEVEL SECURITY;
ALTER TABLE requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE communications DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- NOTA: Questo è solo per development!
-- Per production, riattiva RLS con:
-- ALTER TABLE nome_tabella ENABLE ROW LEVEL SECURITY;
-- =====================================================
