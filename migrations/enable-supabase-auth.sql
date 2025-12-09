-- =====================================================
-- ABILITA SUPABASE AUTH UFFICIALE + RLS
-- =====================================================
-- Step 1: Aggiungi auth_id a tabella utenti
-- Step 2: Abilita RLS su tutte le tabelle
-- Step 3: Crea policies per utenti e admin
-- =====================================================

-- Step 1: Aggiungi colonna auth_id per collegare utenti a Supabase Auth
ALTER TABLE utenti 
ADD COLUMN IF NOT EXISTS auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Aggiungi flag per primo login (forza cambio password)
ALTER TABLE utenti 
ADD COLUMN IF NOT EXISTS first_login BOOLEAN DEFAULT TRUE;

-- Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_utenti_auth_id ON utenti(auth_id);

-- =====================================================
-- Step 2: ABILITA RLS su tutte le tabelle
-- =====================================================

ALTER TABLE utenti ENABLE ROW LEVEL SECURITY;
ALTER TABLE timbrature ENABLE ROW LEVEL SECURITY;
ALTER TABLE lavorazioni ENABLE ROW LEVEL SECURITY;
ALTER TABLE clienti ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_destinatari ENABLE ROW LEVEL SECURITY;
ALTER TABLE richieste_materiale ENABLE ROW LEVEL SECURITY;
ALTER TABLE prodotti_magazzino ENABLE ROW LEVEL SECURITY;
ALTER TABLE comunicazioni ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- Step 3: POLICIES per tabella UTENTI
-- =====================================================

-- Gli utenti possono vedere solo se stessi
CREATE POLICY "utenti_select_own" ON utenti
    FOR SELECT
    USING (auth.uid() = auth_id);

-- Gli ADMIN possono vedere tutti gli utenti
CREATE POLICY "utenti_select_admin" ON utenti
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- Solo ADMIN possono creare utenti
CREATE POLICY "utenti_insert_admin" ON utenti
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- Gli utenti possono aggiornare solo se stessi (per cambio password)
CREATE POLICY "utenti_update_own" ON utenti
    FOR UPDATE
    USING (auth.uid() = auth_id);

-- Gli ADMIN possono aggiornare tutti
CREATE POLICY "utenti_update_admin" ON utenti
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- Solo ADMIN possono eliminare utenti
CREATE POLICY "utenti_delete_admin" ON utenti
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- =====================================================
-- Step 4: POLICIES per TIMBRATURE
-- =====================================================

-- Gli utenti vedono solo le proprie timbrature
CREATE POLICY "timbrature_select_own" ON timbrature
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM utenti WHERE auth_id = auth.uid()
        )
    );

-- Gli ADMIN vedono tutte le timbrature
CREATE POLICY "timbrature_select_admin" ON timbrature
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- Gli utenti possono inserire solo le proprie timbrature
CREATE POLICY "timbrature_insert_own" ON timbrature
    FOR INSERT
    WITH CHECK (
        user_id IN (
            SELECT id FROM utenti WHERE auth_id = auth.uid()
        )
    );

-- Gli utenti possono aggiornare solo le proprie timbrature
CREATE POLICY "timbrature_update_own" ON timbrature
    FOR UPDATE
    USING (
        user_id IN (
            SELECT id FROM utenti WHERE auth_id = auth.uid()
        )
    );

-- Gli ADMIN possono aggiornare tutte le timbrature
CREATE POLICY "timbrature_update_admin" ON timbrature
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- =====================================================
-- Step 5: POLICIES per EMAIL_DESTINATARI
-- =====================================================

-- Solo ADMIN possono gestire destinatari email
CREATE POLICY "email_destinatari_admin_all" ON email_destinatari
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- =====================================================
-- Step 6: POLICIES per LAVORAZIONI
-- =====================================================

-- Tutti gli utenti autenticati vedono tutte le lavorazioni
CREATE POLICY "lavorazioni_select_all" ON lavorazioni
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Solo ADMIN possono creare/modificare/eliminare lavorazioni
CREATE POLICY "lavorazioni_admin_all" ON lavorazioni
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- =====================================================
-- Step 7: POLICIES per CLIENTI
-- =====================================================

-- Tutti gli utenti autenticati vedono tutti i clienti
CREATE POLICY "clienti_select_all" ON clienti
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Solo ADMIN possono gestire clienti
CREATE POLICY "clienti_admin_all" ON clienti
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- =====================================================
-- Step 8: POLICIES per RICHIESTE_MATERIALE
-- =====================================================

-- Gli utenti vedono solo le proprie richieste
CREATE POLICY "richieste_select_own" ON richieste_materiale
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM utenti WHERE auth_id = auth.uid()
        )
    );

-- Gli ADMIN vedono tutte le richieste
CREATE POLICY "richieste_select_admin" ON richieste_materiale
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- Gli utenti possono creare richieste
CREATE POLICY "richieste_insert_all" ON richieste_materiale
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Solo ADMIN possono aggiornare/eliminare richieste
CREATE POLICY "richieste_admin_modify" ON richieste_materiale
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- =====================================================
-- Step 9: POLICIES per PRODOTTI_MAGAZZINO
-- =====================================================

-- Tutti vedono i prodotti
CREATE POLICY "prodotti_select_all" ON prodotti_magazzino
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Solo ADMIN possono gestire magazzino
CREATE POLICY "prodotti_admin_all" ON prodotti_magazzino
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- =====================================================
-- Step 10: POLICIES per COMUNICAZIONI
-- =====================================================

-- Tutti vedono le comunicazioni
CREATE POLICY "comunicazioni_select_all" ON comunicazioni
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Solo ADMIN possono creare/modificare comunicazioni
CREATE POLICY "comunicazioni_admin_all" ON comunicazioni
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM utenti
            WHERE auth_id = auth.uid()
            AND ruolo IN ('Tecnico', 'Segreteria', 'Titolare')
        )
    );

-- =====================================================
-- Step 11: Function helper per ottenere user_id da auth.uid()
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_id_from_auth()
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT id FROM utenti WHERE auth_id = auth.uid() LIMIT 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Supabase Auth abilitato!';
    RAISE NOTICE '✅ RLS attivato su tutte le tabelle';
    RAISE NOTICE '✅ Policies create per utenti e admin';
    RAISE NOTICE '📋 Prossimi passi:';
    RAISE NOTICE '   1. Creare utenti in Supabase Auth quando admin aggiunge dipendente';
    RAISE NOTICE '   2. Popolare campo auth_id per utenti esistenti';
    RAISE NOTICE '   3. Aggiornare auth-helper.js per usare Supabase Auth';
END $$;

COMMENT ON COLUMN utenti.auth_id IS 'UUID collegato a auth.users di Supabase - usato per RLS';
COMMENT ON COLUMN utenti.first_login IS 'TRUE = primo accesso, forza cambio password';
