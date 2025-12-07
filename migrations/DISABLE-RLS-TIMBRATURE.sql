-- ================================================
-- DISABILITA RLS PER TIMBRATURE (SOLO PER TEST CON LOGIN SEMPLIFICATO)
-- ================================================
-- ATTENZIONE: Questo disabilita la sicurezza RLS
-- Usare SOLO in sviluppo/test
-- Prima di andare in produzione, configurare policy corrette
-- ================================================

-- Disabilita RLS sulla tabella timbrature
ALTER TABLE timbrature DISABLE ROW LEVEL SECURITY;

-- Verifica che RLS sia disabilitato
SELECT 
    tablename,
    rowsecurity,
    CASE 
        WHEN rowsecurity = false THEN '✅ RLS Disabilitato (OK per test)'
        ELSE '⚠️ RLS Attivo'
    END as stato
FROM pg_tables 
WHERE tablename = 'timbrature';

-- ================================================
-- RISULTATO ATTESO
-- ================================================
-- rowsecurity | false
-- stato       | ✅ RLS Disabilitato (OK per test)
-- ================================================

-- ================================================
-- NOTE IMPORTANTI
-- ================================================
-- 1. Questo permette a CHIUNQUE di inserire/modificare timbrature
-- 2. Va bene per test con login semplificato
-- 3. Prima di produzione, riabilitare RLS e creare policy corrette:
--    
--    ALTER TABLE timbrature ENABLE ROW LEVEL SECURITY;
--    
--    CREATE POLICY "Users can insert own timbrature"
--    ON timbrature FOR INSERT
--    WITH CHECK (auth.uid() = user_id);
--    
--    CREATE POLICY "Users can view own timbrature"
--    ON timbrature FOR SELECT
--    USING (auth.uid() = user_id);
-- ================================================
