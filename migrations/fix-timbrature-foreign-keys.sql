-- ================================================
-- FIX FOREIGN KEYS TABELLA TIMBRATURE
-- Esegui questo se hai già creato la tabella con il vecchio script
-- ================================================

-- Step 1: Elimina la tabella se esiste (ATTENZIONE: cancella i dati!)
DROP TABLE IF EXISTS timbrature CASCADE;

-- Step 2: Ricrea la tabella con foreign key corrette
CREATE TABLE timbrature (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    data DATE NOT NULL,
    ora_ingresso TIME,
    ora_uscita TIME,
    tipo VARCHAR(50) NOT NULL DEFAULT 'normale',
    ore_lavorate DECIMAL(5,2),
    note TEXT,
    posizione_gps JSONB,
    stato VARCHAR(20) NOT NULL DEFAULT 'approved',
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Crea indici per performance
CREATE INDEX idx_timbrature_user_id ON timbrature(user_id);
CREATE INDEX idx_timbrature_data ON timbrature(data);
CREATE INDEX idx_timbrature_user_data ON timbrature(user_id, data);
CREATE INDEX idx_timbrature_stato ON timbrature(stato);
CREATE INDEX idx_timbrature_tipo ON timbrature(tipo);

-- Step 4: Crea function per calcolare ore lavorate automaticamente
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

-- Step 5: Crea trigger per calcolo automatico
DROP TRIGGER IF EXISTS trigger_calculate_ore ON timbrature;
CREATE TRIGGER trigger_calculate_ore
    BEFORE INSERT OR UPDATE ON timbrature
    FOR EACH ROW
    EXECUTE FUNCTION calculate_ore_lavorate();

-- Step 6: Abilita RLS
ALTER TABLE timbrature ENABLE ROW LEVEL SECURITY;

-- Step 7: Policy per SELECT - dipendenti vedono solo le proprie timbrature, admin vedono tutto
DROP POLICY IF EXISTS "timbrature_select_policy" ON timbrature;
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

-- Step 8: Policy per INSERT - tutti i dipendenti possono timbrare
DROP POLICY IF EXISTS "timbrature_insert_policy" ON timbrature;
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

-- Step 9: Policy per UPDATE - utenti modificano le proprie, admin modificano tutto
DROP POLICY IF EXISTS "timbrature_update_policy" ON timbrature;
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

-- Step 10: Policy per DELETE - solo admin
DROP POLICY IF EXISTS "timbrature_delete_policy" ON timbrature;
CREATE POLICY "timbrature_delete_policy" ON timbrature
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore')
    )
);

-- Step 11: Verifica foreign keys
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name='timbrature';

SELECT '✅ Tabella timbrature ricreata con foreign keys corrette!' as status;
