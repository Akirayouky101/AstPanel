-- =====================================================
-- FIX: RLS Policies email_destinatari
-- Problema: 401 Unauthorized quando si cerca di inserire
-- Soluzione: Aggiornare policies per permettere INSERT con autenticazione
-- =====================================================

-- Step 1: Drop vecchie policies
DROP POLICY IF EXISTS "Solo admin vedono destinatari email" ON email_destinatari;
DROP POLICY IF EXISTS "Solo admin gestiscono destinatari" ON email_destinatari;

-- Step 2: Ricrea policies corrette
-- SELECT - Solo admin autenticati
CREATE POLICY "Admin possono vedere destinatari" 
ON email_destinatari 
FOR SELECT 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- INSERT - Solo admin autenticati
CREATE POLICY "Admin possono inserire destinatari" 
ON email_destinatari 
FOR INSERT 
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- UPDATE - Solo admin autenticati
CREATE POLICY "Admin possono modificare destinatari" 
ON email_destinatari 
FOR UPDATE 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- DELETE - Solo admin autenticati
CREATE POLICY "Admin possono eliminare destinatari" 
ON email_destinatari 
FOR DELETE 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- Step 3: Verifica che RLS sia abilitato
ALTER TABLE email_destinatari ENABLE ROW LEVEL SECURITY;

-- Step 4: Grant permissions
GRANT ALL ON email_destinatari TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ RLS Policies email_destinatari aggiornate!';
    RAISE NOTICE '✅ Admin possono: SELECT, INSERT, UPDATE, DELETE';
    RAISE NOTICE '✅ Dipendenti: nessun accesso';
END $$;

COMMENT ON TABLE email_destinatari IS 'Destinatari email commercialista - RLS FIXED 2025-12-07';
