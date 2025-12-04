-- ================================================
-- MIGRATION: Inventory Tracking System
-- Data: 3 dicembre 2025
-- Descrizione: Sistema di tracking automatico magazzino
-- ================================================

-- 1. Aggiungi campi magazzino alla tabella components
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS quantita_magazzino INTEGER DEFAULT 0 CHECK (quantita_magazzino >= 0),
ADD COLUMN IF NOT EXISTS quantita_minima INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS unita_misura VARCHAR(20) DEFAULT 'pz',
ADD COLUMN IF NOT EXISTS fornitore VARCHAR(255),
ADD COLUMN IF NOT EXISTS codice_fornitore VARCHAR(100),
ADD COLUMN IF NOT EXISTS prezzo_acquisto DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS ultimo_carico TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS note_magazzino TEXT;

-- 2. Crea tabella movimenti magazzino
CREATE TABLE IF NOT EXISTS inventory_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    component_id UUID REFERENCES components(id) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('carico', 'scarico', 'rettifica', 'inventario')),
    quantita INTEGER NOT NULL,
    quantita_precedente INTEGER NOT NULL,
    quantita_attuale INTEGER NOT NULL,
    
    -- Riferimenti
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Dettagli movimento
    motivo TEXT,
    note TEXT,
    documento_riferimento VARCHAR(100), -- DDT, fattura, etc
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- 3. Indici per performance
CREATE INDEX IF NOT EXISTS idx_inventory_movements_component ON inventory_movements(component_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_task ON inventory_movements(task_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_created ON inventory_movements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_tipo ON inventory_movements(tipo);
CREATE INDEX IF NOT EXISTS idx_components_stock ON components(quantita_magazzino);

-- 4. Funzione per registrare movimento magazzino
CREATE OR REPLACE FUNCTION registra_movimento_magazzino(
    p_component_id UUID,
    p_tipo VARCHAR(50),
    p_quantita INTEGER,
    p_task_id UUID DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_motivo TEXT DEFAULT NULL,
    p_note TEXT DEFAULT NULL
) RETURNS TABLE (
    movimento_id UUID,
    quantita_precedente INTEGER,
    quantita_attuale INTEGER,
    success BOOLEAN
) AS $$
DECLARE
    v_movimento_id UUID;
    v_quantita_attuale INTEGER;
    v_quantita_precedente INTEGER;
BEGIN
    -- Leggi quantità attuale
    SELECT quantita_magazzino INTO v_quantita_precedente
    FROM components
    WHERE id = p_component_id;

    IF v_quantita_precedente IS NULL THEN
        RAISE EXCEPTION 'Componente non trovato';
    END IF;

    -- Calcola nuova quantità
    IF p_tipo = 'carico' THEN
        v_quantita_attuale := v_quantita_precedente + p_quantita;
    ELSIF p_tipo = 'scarico' THEN
        IF v_quantita_precedente < p_quantita THEN
            RAISE EXCEPTION 'Quantità insufficiente in magazzino';
        END IF;
        v_quantita_attuale := v_quantita_precedente - p_quantita;
    ELSIF p_tipo = 'rettifica' THEN
        v_quantita_attuale := p_quantita;
    ELSIF p_tipo = 'inventario' THEN
        v_quantita_attuale := p_quantita;
    ELSE
        RAISE EXCEPTION 'Tipo movimento non valido';
    END IF;

    -- Aggiorna quantità componente
    UPDATE components
    SET quantita_magazzino = v_quantita_attuale,
        ultimo_carico = CASE WHEN p_tipo = 'carico' THEN NOW() ELSE ultimo_carico END
    WHERE id = p_component_id;

    -- Registra movimento
    INSERT INTO inventory_movements (
        component_id,
        tipo,
        quantita,
        quantita_precedente,
        quantita_attuale,
        task_id,
        user_id,
        motivo,
        note,
        created_by
    ) VALUES (
        p_component_id,
        p_tipo,
        p_quantita,
        v_quantita_precedente,
        v_quantita_attuale,
        p_task_id,
        p_user_id,
        p_motivo,
        p_note,
        p_user_id
    ) RETURNING id INTO v_movimento_id;

    RETURN QUERY SELECT v_movimento_id, v_quantita_precedente, v_quantita_attuale, TRUE;
END;
$$ LANGUAGE plpgsql;

-- 5. Trigger automatico: scarica componenti quando task completato
CREATE OR REPLACE FUNCTION scarica_componenti_task_completato()
RETURNS TRIGGER AS $$
DECLARE
    v_component RECORD;
BEGIN
    -- Solo se stato cambia a 'completato'
    IF NEW.stato = 'completato' AND (OLD.stato IS NULL OR OLD.stato != 'completato') THEN
        
        -- Scarica tutti i componenti associati al task
        FOR v_component IN 
            SELECT tc.component_id, tc.quantita, c.nome
            FROM task_components tc
            JOIN components c ON c.id = tc.component_id
            WHERE tc.task_id = NEW.id
        LOOP
            BEGIN
                -- Registra scarico
                PERFORM registra_movimento_magazzino(
                    v_component.component_id,
                    'scarico',
                    v_component.quantita,
                    NEW.id,
                    NEW.assigned_user_id,
                    'Scarico automatico per completamento lavorazione',
                    'Task: ' || NEW.titolo
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Impossibile scaricare componente %: %', v_component.nome, SQLERRM;
            END;
        END LOOP;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crea trigger
DROP TRIGGER IF EXISTS trigger_scarica_componenti ON tasks;
CREATE TRIGGER trigger_scarica_componenti
    AFTER UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION scarica_componenti_task_completato();

-- 6. Vista per componenti sotto scorta
CREATE OR REPLACE VIEW componenti_sotto_scorta AS
SELECT 
    c.id,
    c.nome,
    c.categoria,
    c.quantita_magazzino,
    c.quantita_minima,
    c.unita_misura,
    c.fornitore,
    (c.quantita_minima - c.quantita_magazzino) AS quantita_da_ordinare,
    c.prezzo_acquisto,
    c.ultimo_carico
FROM components c
WHERE c.quantita_magazzino < c.quantita_minima
ORDER BY (c.quantita_minima - c.quantita_magazzino) DESC;

-- 7. Vista movimenti recenti
CREATE OR REPLACE VIEW movimenti_recenti AS
SELECT 
    im.id,
    im.tipo,
    im.quantita,
    im.quantita_precedente,
    im.quantita_attuale,
    c.nome AS componente,
    c.categoria,
    t.titolo AS task,
    u.nome || ' ' || u.cognome AS utente,
    im.motivo,
    im.created_at
FROM inventory_movements im
LEFT JOIN components c ON c.id = im.component_id
LEFT JOIN tasks t ON t.id = im.task_id
LEFT JOIN users u ON u.id = im.user_id
ORDER BY im.created_at DESC
LIMIT 100;

-- 8. Commenti
COMMENT ON TABLE inventory_movements IS 'Storico movimenti magazzino (carico/scarico/inventario)';
COMMENT ON COLUMN components.quantita_magazzino IS 'Quantità disponibile in magazzino';
COMMENT ON COLUMN components.quantita_minima IS 'Soglia minima per alert riordino';
COMMENT ON FUNCTION registra_movimento_magazzino IS 'Registra movimento magazzino e aggiorna disponibilità';
COMMENT ON FUNCTION scarica_componenti_task_completato IS 'Trigger automatico: scarica componenti quando task completato';

-- 9. Inizializza quantità magazzino per componenti esistenti
UPDATE components 
SET quantita_magazzino = 50, -- Default 50 pezzi per componenti esistenti
    quantita_minima = 10
WHERE quantita_magazzino IS NULL;

-- 10. Verifica migrazione
SELECT 
    'Components with stock' AS check_name,
    COUNT(*) AS count
FROM components 
WHERE quantita_magazzino IS NOT NULL
UNION ALL
SELECT 
    'Inventory movements table exists' AS check_name,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inventory_movements') 
        THEN 1 ELSE 0 END AS count;
