-- ================================================
-- FIX LOGIN: Permetti lettura utenti per pagina login
-- ================================================

-- Aggiungi policy per utenti NON autenticati (anon)
DROP POLICY IF EXISTS "Enable read for login page" ON users;
CREATE POLICY "Enable read for login page" ON users
FOR SELECT TO anon
USING (true);

-- Mantieni anche la policy per authenticated
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON users;
CREATE POLICY "Enable read access for authenticated users" ON users
FOR SELECT TO authenticated
USING (true);

-- Verifica policies
SELECT 
    schemaname,
    tablename,
    policyname,
    roles
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Test: questa query dovrebbe funzionare SENZA login
SELECT id, nome, cognome, email, ruolo FROM users ORDER BY nome LIMIT 5;
