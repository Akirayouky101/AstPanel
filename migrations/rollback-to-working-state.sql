-- ================================================
-- ROLLBACK: Torna allo stato funzionante
-- ================================================

-- 1. RIABILITA LE RLS come prima
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- 2. Ricrea le policy di base che funzionavano
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON users;
CREATE POLICY "Enable read access for authenticated users" ON users
FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "Enable all access for authenticated users" ON tasks;
CREATE POLICY "Enable all access for authenticated users" ON tasks
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- 3. Policy per user_availability (se serve)
ALTER TABLE user_availability ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all for authenticated" ON user_availability;
CREATE POLICY "Enable all for authenticated" ON user_availability
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- 4. Verifica
SELECT '✅ RLS riabilitata con policy permissive' as status;
