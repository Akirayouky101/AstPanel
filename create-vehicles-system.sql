-- =====================================================
-- SISTEMA GESTIONE MEZZI/FURGONI
-- =====================================================
-- Traccia mezzi aziendali, noleggi e assegnazioni
-- =====================================================

-- 1. TABELLA MEZZI (aziendali + noleggio)
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Info base
    nome VARCHAR(100) NOT NULL, -- es: "Furgone Fiat Ducato"
    targa VARCHAR(20) UNIQUE NOT NULL,
    tipo VARCHAR(50) NOT NULL, -- 'furgone', 'auto', 'van', 'camion'
    marca VARCHAR(50),
    modello VARCHAR(50),
    
    -- Tipo proprietà
    proprieta VARCHAR(20) NOT NULL DEFAULT 'aziendale', -- 'aziendale', 'noleggio'
    
    -- Info noleggio (solo se proprieta = 'noleggio')
    data_inizio_noleggio DATE,
    data_fine_noleggio DATE,
    azienda_noleggio VARCHAR(100),
    costo_giornaliero DECIMAL(10,2),
    note_noleggio TEXT,
    
    -- Status
    stato VARCHAR(20) NOT NULL DEFAULT 'disponibile', -- 'disponibile', 'in_uso', 'manutenzione', 'restituito'
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- 2. TABELLA ASSEGNAZIONI MEZZI
CREATE TABLE IF NOT EXISTS vehicle_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relazioni
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Periodo assegnazione
    data_inizio DATE NOT NULL,
    data_fine DATE,
    ora_inizio TIME,
    ora_fine TIME,
    
    -- Info
    destinazione TEXT, -- Dove va con il mezzo
    km_partenza INTEGER,
    km_arrivo INTEGER,
    note TEXT,
    
    -- Status
    stato VARCHAR(20) NOT NULL DEFAULT 'attiva', -- 'attiva', 'completata', 'annullata'
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. INDICI per performance
CREATE INDEX idx_vehicles_stato ON vehicles(stato);
CREATE INDEX idx_vehicles_proprieta ON vehicles(proprieta);
CREATE INDEX idx_vehicles_targa ON vehicles(targa);
CREATE INDEX idx_vehicle_assignments_vehicle ON vehicle_assignments(vehicle_id);
CREATE INDEX idx_vehicle_assignments_user ON vehicle_assignments(user_id);
CREATE INDEX idx_vehicle_assignments_date ON vehicle_assignments(data_inizio, data_fine);
CREATE INDEX idx_vehicle_assignments_stato ON vehicle_assignments(stato);

-- 4. TRIGGER per updated_at
CREATE OR REPLACE FUNCTION update_vehicles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vehicles_updated_at
    BEFORE UPDATE ON vehicles
    FOR EACH ROW
    EXECUTE FUNCTION update_vehicles_updated_at();

CREATE TRIGGER vehicle_assignments_updated_at
    BEFORE UPDATE ON vehicle_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_vehicles_updated_at();

-- 5. RLS POLICIES

-- Vehicles: tutti possono leggere, solo admin possono modificare
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vehicles_select_all" ON vehicles;
CREATE POLICY "vehicles_select_all" ON vehicles
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "vehicles_insert_admin" ON vehicles;
CREATE POLICY "vehicles_insert_admin" ON vehicles
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "vehicles_update_admin" ON vehicles;
CREATE POLICY "vehicles_update_admin" ON vehicles
    FOR UPDATE USING (true);

DROP POLICY IF EXISTS "vehicles_delete_admin" ON vehicles;
CREATE POLICY "vehicles_delete_admin" ON vehicles
    FOR DELETE USING (true);

-- Vehicle Assignments: tutti possono vedere, tutti possono creare (prendere mezzo)
ALTER TABLE vehicle_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vehicle_assignments_select_all" ON vehicle_assignments;
CREATE POLICY "vehicle_assignments_select_all" ON vehicle_assignments
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "vehicle_assignments_insert_own" ON vehicle_assignments;
CREATE POLICY "vehicle_assignments_insert_own" ON vehicle_assignments
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "vehicle_assignments_update_own" ON vehicle_assignments;
CREATE POLICY "vehicle_assignments_update_own" ON vehicle_assignments
    FOR UPDATE USING (true);

DROP POLICY IF EXISTS "vehicle_assignments_delete_admin" ON vehicle_assignments;
CREATE POLICY "vehicle_assignments_delete_admin" ON vehicle_assignments
    FOR DELETE USING (true);

-- 6. FUNZIONE: Mezzi disponibili in un periodo
CREATE OR REPLACE FUNCTION get_available_vehicles(
    p_data_inizio DATE,
    p_data_fine DATE DEFAULT NULL
)
RETURNS TABLE(
    vehicle_id UUID,
    nome VARCHAR,
    targa VARCHAR,
    tipo VARCHAR,
    proprieta VARCHAR,
    stato VARCHAR
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Se data_fine è NULL, usa data_inizio
    p_data_fine := COALESCE(p_data_fine, p_data_inizio);
    
    RETURN QUERY
    SELECT 
        v.id,
        v.nome,
        v.targa,
        v.tipo,
        v.proprieta,
        v.stato
    FROM vehicles v
    WHERE v.stato = 'disponibile'
    AND NOT EXISTS (
        -- Escludi mezzi già assegnati nel periodo
        SELECT 1 FROM vehicle_assignments va
        WHERE va.vehicle_id = v.id
        AND va.stato = 'attiva'
        AND (
            (va.data_inizio <= p_data_fine AND COALESCE(va.data_fine, va.data_inizio) >= p_data_inizio)
        )
    )
    -- Se è noleggio, deve essere nel periodo di validità
    AND (
        v.proprieta = 'aziendale' 
        OR (
            v.proprieta = 'noleggio' 
            AND v.data_inizio_noleggio <= p_data_fine 
            AND COALESCE(v.data_fine_noleggio, '9999-12-31'::DATE) >= p_data_inizio
        )
    )
    ORDER BY v.proprieta DESC, v.nome;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_available_vehicles(DATE, DATE) TO authenticated;

-- 7. FUNZIONE: Dashboard mezzi (chi ha cosa adesso)
CREATE OR REPLACE FUNCTION get_vehicles_dashboard()
RETURNS TABLE(
    vehicle_id UUID,
    vehicle_nome VARCHAR,
    vehicle_targa VARCHAR,
    vehicle_tipo VARCHAR,
    vehicle_proprieta VARCHAR,
    assignment_id UUID,
    user_id UUID,
    user_nome TEXT,
    data_inizio DATE,
    data_fine DATE,
    destinazione TEXT,
    km_partenza INTEGER,
    stato_assignment VARCHAR
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id,
        v.nome,
        v.targa,
        v.tipo,
        v.proprieta,
        va.id,
        u.id,
        (u.nome || ' ' || u.cognome)::TEXT,
        va.data_inizio,
        va.data_fine,
        va.destinazione,
        va.km_partenza,
        va.stato
    FROM vehicles v
    LEFT JOIN vehicle_assignments va ON va.vehicle_id = v.id AND va.stato = 'attiva'
    LEFT JOIN users u ON u.id = va.user_id
    WHERE v.stato IN ('disponibile', 'in_uso')
    ORDER BY 
        CASE WHEN va.id IS NULL THEN 1 ELSE 0 END, -- Prima i mezzi in uso
        v.proprieta DESC, -- Prima aziendali
        v.nome;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_vehicles_dashboard() TO authenticated;

-- 8. SEED DATA - Mezzi aziendali di esempio
INSERT INTO vehicles (nome, targa, tipo, marca, modello, proprieta, stato) VALUES
('Furgone Fiat Ducato 1', 'AB123CD', 'furgone', 'Fiat', 'Ducato', 'aziendale', 'disponibile'),
('Furgone Fiat Ducato 2', 'EF456GH', 'furgone', 'Fiat', 'Ducato', 'aziendale', 'disponibile'),
('Auto Aziendale', 'IJ789KL', 'auto', 'Ford', 'Transit', 'aziendale', 'disponibile')
ON CONFLICT (targa) DO NOTHING;

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ SISTEMA MEZZI/FURGONI CREATO!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Tabelle create:';
    RAISE NOTICE '  • vehicles (mezzi aziendali + noleggio)';
    RAISE NOTICE '  • vehicle_assignments (assegnazioni)';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Funzioni disponibili:';
    RAISE NOTICE '  • get_available_vehicles(data_inizio, data_fine)';
    RAISE NOTICE '  • get_vehicles_dashboard()';
    RAISE NOTICE '';
    RAISE NOTICE '🚗 Mezzi di esempio inseriti:';
    RAISE NOTICE '  • Furgone Fiat Ducato 1 (AB123CD)';
    RAISE NOTICE '  • Furgone Fiat Ducato 2 (EF456GH)';
    RAISE NOTICE '  • Auto Aziendale (IJ789KL)';
    RAISE NOTICE '';
    RAISE NOTICE '📱 Prossimo step: creare interfaccia UI';
    RAISE NOTICE '';
END $$;
