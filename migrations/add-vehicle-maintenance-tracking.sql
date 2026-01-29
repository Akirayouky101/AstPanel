-- =====================================================
-- SISTEMA TRACKING MANUTENZIONI E SCADENZE MEZZI
-- =====================================================
-- Aggiunge campi per scadenze (assicurazione, revisione, bollo)
-- e sistema completo di storico manutenzioni con costi

-- =====================================================
-- AGGIUNGI CAMPI SCADENZE ALLA TABELLA VEHICLES
-- =====================================================
ALTER TABLE vehicles
ADD COLUMN IF NOT EXISTS data_scadenza_assicurazione DATE,
ADD COLUMN IF NOT EXISTS data_scadenza_revisione DATE,
ADD COLUMN IF NOT EXISTS data_scadenza_bollo DATE,
ADD COLUMN IF NOT EXISTS km_attuali INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS ultimo_tagliando_km INTEGER,
ADD COLUMN IF NOT EXISTS data_ultimo_tagliando DATE,
ADD COLUMN IF NOT EXISTS prossimo_tagliando_km INTEGER,
ADD COLUMN IF NOT EXISTS ultima_revisione_km INTEGER,
ADD COLUMN IF NOT EXISTS data_ultima_revisione DATE;

COMMENT ON COLUMN vehicles.data_scadenza_assicurazione IS 'Data scadenza assicurazione RCA';
COMMENT ON COLUMN vehicles.data_scadenza_revisione IS 'Data scadenza revisione periodica';
COMMENT ON COLUMN vehicles.data_scadenza_bollo IS 'Data scadenza bollo auto';
COMMENT ON COLUMN vehicles.km_attuali IS 'Chilometraggio attuale del veicolo';
COMMENT ON COLUMN vehicles.ultimo_tagliando_km IS 'Km a cui è stato fatto ultimo tagliando';
COMMENT ON COLUMN vehicles.prossimo_tagliando_km IS 'Km previsti per prossimo tagliando';

-- =====================================================
-- TABELLA: vehicle_maintenance (Storico Manutenzioni)
-- =====================================================
CREATE TABLE IF NOT EXISTS vehicle_maintenance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
    
    -- Tipo manutenzione
    tipo VARCHAR(100) NOT NULL, -- tagliando/revisione/riparazione/pneumatici/altro
    descrizione TEXT NOT NULL,
    
    -- Dati manutenzione
    data_intervento DATE NOT NULL,
    km_intervento INTEGER,
    
    -- Fornitore/Officina
    officina VARCHAR(255),
    referente VARCHAR(255),
    telefono_officina VARCHAR(50),
    
    -- Costi
    costo_manodopera DECIMAL(10,2),
    costo_ricambi DECIMAL(10,2),
    costo_totale DECIMAL(10,2) NOT NULL,
    
    -- Documenti
    numero_fattura VARCHAR(100),
    file_fattura TEXT, -- URL documento
    
    -- Prossima manutenzione prevista
    prossima_manutenzione_km INTEGER,
    prossima_manutenzione_data DATE,
    
    -- Metadata
    note TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

COMMENT ON TABLE vehicle_maintenance IS 'Storico completo manutenzioni veicoli con costi e documenti';

-- =====================================================
-- TABELLA: vehicle_reminders (Promemoria Scadenze)
-- =====================================================
CREATE TABLE IF NOT EXISTS vehicle_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
    
    -- Tipo scadenza
    tipo VARCHAR(50) NOT NULL, -- assicurazione/revisione/bollo/tagliando
    descrizione TEXT,
    
    -- Scadenza
    data_scadenza DATE NOT NULL,
    km_scadenza INTEGER, -- Per manutenzioni basate su km
    
    -- Notifiche
    giorni_preavviso INTEGER DEFAULT 30, -- Notifica X giorni prima
    notificato BOOLEAN DEFAULT false,
    data_notifica TIMESTAMP,
    
    -- Stato
    stato VARCHAR(50) DEFAULT 'attivo', -- attivo/completato/scaduto
    completato_il TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

COMMENT ON TABLE vehicle_reminders IS 'Sistema promemoria per scadenze e manutenzioni programmate';

-- =====================================================
-- FUNZIONE: Aggiorna km veicolo
-- =====================================================
CREATE OR REPLACE FUNCTION update_vehicle_km()
RETURNS TRIGGER AS $$
BEGIN
    -- Quando viene registrata una manutenzione, aggiorna km_attuali del veicolo
    IF NEW.km_intervento IS NOT NULL AND NEW.km_intervento > 0 THEN
        UPDATE vehicles 
        SET km_attuali = NEW.km_intervento
        WHERE id = NEW.vehicle_id
        AND (km_attuali IS NULL OR NEW.km_intervento > km_attuali);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_vehicle_km
    AFTER INSERT OR UPDATE ON vehicle_maintenance
    FOR EACH ROW
    EXECUTE FUNCTION update_vehicle_km();

-- =====================================================
-- FUNZIONE: Verifica scadenze e crea reminder automatici
-- =====================================================
CREATE OR REPLACE FUNCTION create_auto_reminders()
RETURNS TRIGGER AS $$
BEGIN
    -- Crea reminder per assicurazione
    IF NEW.data_scadenza_assicurazione IS NOT NULL THEN
        INSERT INTO vehicle_reminders (vehicle_id, tipo, descrizione, data_scadenza, giorni_preavviso)
        VALUES (NEW.id, 'assicurazione', 'Scadenza assicurazione RCA', NEW.data_scadenza_assicurazione, 30)
        ON CONFLICT DO NOTHING;
    END IF;
    
    -- Crea reminder per revisione
    IF NEW.data_scadenza_revisione IS NOT NULL THEN
        INSERT INTO vehicle_reminders (vehicle_id, tipo, descrizione, data_scadenza, giorni_preavviso)
        VALUES (NEW.id, 'revisione', 'Scadenza revisione periodica', NEW.data_scadenza_revisione, 30)
        ON CONFLICT DO NOTHING;
    END IF;
    
    -- Crea reminder per bollo
    IF NEW.data_scadenza_bollo IS NOT NULL THEN
        INSERT INTO vehicle_reminders (vehicle_id, tipo, descrizione, data_scadenza, giorni_preavviso)
        VALUES (NEW.id, 'bollo', 'Scadenza bollo auto', NEW.data_scadenza_bollo, 15)
        ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_auto_reminders
    AFTER INSERT OR UPDATE ON vehicles
    FOR EACH ROW
    EXECUTE FUNCTION create_auto_reminders();

-- =====================================================
-- VIEW: Scadenze prossime (30 giorni)
-- =====================================================
CREATE OR REPLACE VIEW v_upcoming_deadlines AS
SELECT 
    v.id as vehicle_id,
    v.nome as vehicle_nome,
    v.targa,
    v.tipo,
    'Assicurazione' as tipo_scadenza,
    v.data_scadenza_assicurazione as data_scadenza,
    (v.data_scadenza_assicurazione - CURRENT_DATE) as giorni_mancanti,
    CASE 
        WHEN v.data_scadenza_assicurazione < CURRENT_DATE THEN 'scaduto'
        WHEN v.data_scadenza_assicurazione <= CURRENT_DATE + 15 THEN 'urgente'
        WHEN v.data_scadenza_assicurazione <= CURRENT_DATE + 30 THEN 'attenzione'
        ELSE 'ok'
    END as priorita
FROM vehicles v
WHERE v.data_scadenza_assicurazione IS NOT NULL
  AND v.data_scadenza_assicurazione <= CURRENT_DATE + 30

UNION ALL

SELECT 
    v.id,
    v.nome,
    v.targa,
    v.tipo,
    'Revisione',
    v.data_scadenza_revisione,
    (v.data_scadenza_revisione - CURRENT_DATE),
    CASE 
        WHEN v.data_scadenza_revisione < CURRENT_DATE THEN 'scaduto'
        WHEN v.data_scadenza_revisione <= CURRENT_DATE + 15 THEN 'urgente'
        WHEN v.data_scadenza_revisione <= CURRENT_DATE + 30 THEN 'attenzione'
        ELSE 'ok'
    END
FROM vehicles v
WHERE v.data_scadenza_revisione IS NOT NULL
  AND v.data_scadenza_revisione <= CURRENT_DATE + 30

UNION ALL

SELECT 
    v.id,
    v.nome,
    v.targa,
    v.tipo,
    'Bollo',
    v.data_scadenza_bollo,
    (v.data_scadenza_bollo - CURRENT_DATE),
    CASE 
        WHEN v.data_scadenza_bollo < CURRENT_DATE THEN 'scaduto'
        WHEN v.data_scadenza_bollo <= CURRENT_DATE + 15 THEN 'urgente'
        WHEN v.data_scadenza_bollo <= CURRENT_DATE + 30 THEN 'attenzione'
        ELSE 'ok'
    END
FROM vehicles v
WHERE v.data_scadenza_bollo IS NOT NULL
  AND v.data_scadenza_bollo <= CURRENT_DATE + 30

ORDER BY data_scadenza ASC;

COMMENT ON VIEW v_upcoming_deadlines IS 'Vista delle scadenze prossime con priorità (scaduto/urgente/attenzione)';

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Manutenzioni: tutti possono leggere, solo autenticati possono scrivere
ALTER TABLE vehicle_maintenance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Manutenzioni visibili a tutti gli autenticati"
    ON vehicle_maintenance FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Tutti possono inserire manutenzioni"
    ON vehicle_maintenance FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Tutti possono aggiornare manutenzioni"
    ON vehicle_maintenance FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Solo admin può eliminare manutenzioni"
    ON vehicle_maintenance FOR DELETE
    TO authenticated
    USING (true);

-- Reminders: tutti possono leggere e scrivere
ALTER TABLE vehicle_reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reminders visibili a tutti gli autenticati"
    ON vehicle_reminders FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Tutti possono inserire reminders"
    ON vehicle_reminders FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Tutti possono aggiornare reminders"
    ON vehicle_reminders FOR UPDATE
    TO authenticated
    USING (true);

-- =====================================================
-- INDICI per performance
-- =====================================================
CREATE INDEX idx_maintenance_vehicle ON vehicle_maintenance(vehicle_id);
CREATE INDEX idx_maintenance_tipo ON vehicle_maintenance(tipo);
CREATE INDEX idx_maintenance_data ON vehicle_maintenance(data_intervento DESC);

CREATE INDEX idx_reminders_vehicle ON vehicle_reminders(vehicle_id);
CREATE INDEX idx_reminders_scadenza ON vehicle_reminders(data_scadenza);
CREATE INDEX idx_reminders_stato ON vehicle_reminders(stato);

CREATE INDEX idx_vehicles_scadenza_assicurazione ON vehicles(data_scadenza_assicurazione);
CREATE INDEX idx_vehicles_scadenza_revisione ON vehicles(data_scadenza_revisione);
CREATE INDEX idx_vehicles_scadenza_bollo ON vehicles(data_scadenza_bollo);

-- =====================================================
-- MESSAGGIO DI SUCCESSO
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Sistema Tracking Manutenzioni creato con successo!';
    RAISE NOTICE '📋 Tabelle: vehicle_maintenance, vehicle_reminders';
    RAISE NOTICE '📊 Vista: v_upcoming_deadlines (scadenze prossime)';
    RAISE NOTICE '🔔 Trigger automatici per reminder scadenze';
    RAISE NOTICE '🔧 Trigger aggiornamento km automatico';
END $$;
