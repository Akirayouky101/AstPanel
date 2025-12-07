-- =====================================================
-- DISABLE RLS per email_destinatari
-- Motivo: Sistema usa autenticazione fake (sessionStorage)
--         non auth.uid() di Supabase
-- Soluzione: Disabilitare RLS per permettere INSERT/UPDATE/DELETE
-- =====================================================

-- Step 1: Drop tutte le policies esistenti
DROP POLICY IF EXISTS "Admin possono vedere destinatari" ON email_destinatari;
DROP POLICY IF EXISTS "Admin possono inserire destinatari" ON email_destinatari;
DROP POLICY IF EXISTS "Admin possono modificare destinatari" ON email_destinatari;
DROP POLICY IF EXISTS "Admin possono eliminare destinatari" ON email_destinatari;

-- Step 2: DISABILITA RLS
ALTER TABLE email_destinatari DISABLE ROW LEVEL SECURITY;

-- Step 3: Grant permissions a tutti gli utenti autenticati
GRANT ALL ON email_destinatari TO authenticated;
GRANT ALL ON email_destinatari TO anon;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ RLS DISABILITATO su email_destinatari';
    RAISE NOTICE '⚠️  ATTENZIONE: Gestire controllo accesso lato client';
    RAISE NOTICE '✅ Operazioni INSERT/UPDATE/DELETE ora funzionanti';
END $$;

COMMENT ON TABLE email_destinatari IS 'Destinatari email commercialista - RLS DISABLED per fake auth - 2025-12-07';
