-- ================================================
-- CREAZIONE TABELLA TIMBRATURE
-- Sistema di gestione orari di lavoro con approvazioni
-- ================================================

-- Step 1: Crea la tabella timbrature
CREATE TABLE IF NOT EXISTS timbrature (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    data DATE NOT NULL,
    ora_ingresso TIME,
    ora_uscita TIME,
    tipo VARCHAR(50) NOT NULL DEFAULT 'normale',
    -- Tipi: normale, straordinario, permesso, ferie, malattia, trasferta
    ore_lavorate DECIMAL(5,2),
    note TEXT,
    posizione_gps JSONB,
    -- {lat: 45.123, lng: 9.456, accuracy: 10}
    stato VARCHAR(20) NOT NULL DEFAULT 'approved',
    -- Stati: pending (richiede approvazione), approved, rejected
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Crea indici per performance
CREATE INDEX IF NOT EXISTS idx_timbrature_user_id ON timbrature(user_id);
CREATE INDEX IF NOT EXISTS idx_timbrature_data ON timbrature(data);
CREATE INDEX IF NOT EXISTS idx_timbrature_user_data ON timbrature(user_id, data);
CREATE INDEX IF NOT EXISTS idx_timbrature_stato ON timbrature(stato);
CREATE INDEX IF NOT EXISTS idx_timbrature_tipo ON timbrature(tipo);

-- Step 3: Crea function per calcolare ore lavorate automaticamente
CREATE OR REPLACE FUNCTION calculate_ore_lavorate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ora_ingresso IS NOT NULL AND NEW.ora_uscita IS NOT NULL THEN
        NEW.ore_lavorate := EXTRACT(EPOCH FROM (NEW.ora_uscita::time - NEW.ora_ingresso::time)) / 3600;
    END IF;
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Crea trigger per calcolo automatico
DROP TRIGGER IF EXISTS trigger_calculate_ore ON timbrature;
CREATE TRIGGER trigger_calculate_ore
    BEFORE INSERT OR UPDATE ON timbrature
    FOR EACH ROW
    EXECUTE FUNCTION calculate_ore_lavorate();

-- Step 5: Abilita RLS
ALTER TABLE timbrature ENABLE ROW LEVEL SECURITY;

-- Step 6: Policy per SELECT - dipendenti vedono solo le proprie timbrature, admin vedono tutto
CREATE POLICY "timbrature_select_policy" ON timbrature
FOR SELECT TO authenticated
USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore')
    )
);

-- Step 7: Policy per INSERT - tutti i dipendenti possono timbrare
CREATE POLICY "timbrature_insert_policy" ON timbrature
FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() = user_id
    OR
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore')
    )
);

-- Step 8: Policy per UPDATE - utenti modificano le proprie, admin modificano tutto
CREATE POLICY "timbrature_update_policy" ON timbrature
FOR UPDATE TO authenticated
USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore')
    )
)
WITH CHECK (
    auth.uid() = user_id 
    OR 
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore')
    )
);

-- Step 9: Policy per DELETE - solo admin
CREATE POLICY "timbrature_delete_policy" ON timbrature
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore')
    )
);

-- Step 10: Verifica creazione
SELECT 
    'timbrature' as table_name,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'timbrature';

SELECT '✅ Tabella timbrature creata con successo!' as status;
