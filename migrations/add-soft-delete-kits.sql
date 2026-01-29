-- ============================================
-- SOFT DELETE PER KITS
-- ============================================
-- Aggiunge campi per implementare soft delete sui kit
-- Mantiene integrità dati storici e ripristino componenti
-- ============================================

-- Aggiungi colonne soft delete
ALTER TABLE kits ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE kits ADD COLUMN IF NOT EXISTS deleted_by UUID REFERENCES users(id);

-- Indice per filtrare kit attivi/eliminati
CREATE INDEX IF NOT EXISTS idx_kits_deleted_at ON kits(deleted_at) WHERE deleted_at IS NULL;

-- Aggiorna il trigger per ripristinare giacenza quando kit viene eliminato
CREATE OR REPLACE FUNCTION ripristina_componenti_kit_eliminato()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo se stato passa a 'eliminato' e non era già eliminato
    IF NEW.stato = 'eliminato' AND OLD.stato != 'eliminato' THEN
        -- Ripristina giacenza di tutti i componenti del kit
        UPDATE components c
        SET quantita_disponibile = quantita_disponibile + ki.quantita
        FROM kit_items ki
        WHERE ki.kit_id = NEW.id
        AND ki.prodotto_id = c.id;
        
        -- Registra movimenti di ripristino
        INSERT INTO movimenti_magazzino (
            prodotto_id,
            tipo_movimento,
            quantita,
            giacenza_prima,
            giacenza_dopo,
            causale,
            data_movimento,
            created_by
        )
        SELECT 
            ki.prodotto_id,
            'entrata',
            ki.quantita,
            c.quantita_disponibile - ki.quantita,
            c.quantita_disponibile,
            'Ripristino da kit eliminato: ' || OLD.codice_kit,
            NOW(),
            NEW.deleted_by
        FROM kit_items ki
        JOIN components c ON c.id = ki.prodotto_id
        WHERE ki.kit_id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crea trigger
DROP TRIGGER IF EXISTS trigger_ripristina_componenti_eliminato ON kits;
CREATE TRIGGER trigger_ripristina_componenti_eliminato
    AFTER UPDATE ON kits
    FOR EACH ROW
    EXECUTE FUNCTION ripristina_componenti_kit_eliminato();

-- ============================================
-- FINE MIGRATION
-- ============================================
