-- =====================================================
-- MIGRAZIONE: Aggiungi colonne magazzino a components
-- Data: 28 gennaio 2026
-- Descrizione: Aggiunge colonne per compatibilità frontend magazzino
--              mantenendo le colonne originali dello schema
-- =====================================================

-- 1. AGGIUNGI COLONNE MANCANTI
-- =====================================================

-- Barcode (EAN/Codice a barre)
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS barcode VARCHAR(100);

-- Giacenza (quantità in magazzino)
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS giacenza DECIMAL(10,2) DEFAULT 0;

-- Giacenza minima (soglia riordino)
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS giacenza_minima DECIMAL(10,2) DEFAULT 0;

-- UM (unità di misura abbreviata)
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS um VARCHAR(50) DEFAULT 'pz';

-- Prezzo acquisto (esente IVA - il ricarico si calcola nel preventivo)
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS prezzo_acquisto DECIMAL(10,2) DEFAULT 0;

-- Descrizione dettagliata
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS descrizione TEXT;

-- Fornitore preferito (FK verrà aggiunta dopo se esiste tabella fornitori)
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS fornitore_preferito_id UUID;


-- 2. SINCRONIZZA VALORI ESISTENTI
-- =====================================================

-- Copia quantita_disponibile -> giacenza (se giacenza è NULL o 0)
UPDATE components 
SET giacenza = COALESCE(quantita_disponibile, 0)
WHERE giacenza IS NULL OR giacenza = 0;

-- Copia unita_misura -> um
UPDATE components 
SET um = COALESCE(unita_misura, 'pz')
WHERE um IS NULL OR um = '';

-- Copia prezzo_unitario -> prezzo_acquisto (se non già impostato)
-- NOTA: Tutti i prezzi sono esente IVA. Il ricarico si calcola nel preventivo.
UPDATE components 
SET prezzo_acquisto = COALESCE(prezzo_unitario, 0)
WHERE prezzo_acquisto IS NULL OR prezzo_acquisto = 0;

-- Copia nome -> descrizione (se descrizione vuota)
UPDATE components 
SET descrizione = nome
WHERE descrizione IS NULL OR descrizione = '';

-- Copia codice -> barcode (se barcode vuoto)
UPDATE components 
SET barcode = codice
WHERE barcode IS NULL OR barcode = '' AND codice IS NOT NULL;


-- 3. CREA INDICI PER PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_components_barcode 
ON components(barcode);

CREATE INDEX IF NOT EXISTS idx_components_giacenza 
ON components(giacenza);

CREATE INDEX IF NOT EXISTS idx_components_descrizione 
ON components USING gin(to_tsvector('italian', descrizione));


-- 4. AGGIUNGI CONSTRAINT PER FORNITORE (se tabella esiste)
-- =====================================================

DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fornitori') THEN
        ALTER TABLE components 
        ADD CONSTRAINT fk_components_fornitore 
        FOREIGN KEY (fornitore_preferito_id) 
        REFERENCES fornitori(id) 
        ON DELETE SET NULL;
        
        CREATE INDEX IF NOT EXISTS idx_components_fornitore 
        ON components(fornitore_preferito_id);
        
        RAISE NOTICE '✅ FK fornitore_preferito_id creata';
    ELSE
        RAISE NOTICE '⚠️  Tabella fornitori non trovata, FK non creata';
    END IF;
END $$;


-- 5. CREA TRIGGER PER SINCRONIZZAZIONE AUTOMATICA
-- =====================================================

-- Trigger: quando giacenza cambia, aggiorna anche quantita_disponibile
CREATE OR REPLACE FUNCTION sync_giacenza_to_quantita()
RETURNS TRIGGER AS $$
BEGIN
    -- Sincronizza giacenza -> quantita_disponibile
    IF NEW.giacenza IS DISTINCT FROM OLD.giacenza THEN
        NEW.quantita_disponibile := NEW.giacenza;
    END IF;
    
    -- Sincronizza quantita_disponibile -> giacenza
    IF NEW.quantita_disponibile IS DISTINCT FROM OLD.quantita_disponibile THEN
        NEW.giacenza := NEW.quantita_disponibile;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_giacenza ON components;
CREATE TRIGGER trg_sync_giacenza
    BEFORE UPDATE ON components
    FOR EACH ROW
    EXECUTE FUNCTION sync_giacenza_to_quantita();


-- 6. VERIFICA FINALE
-- =====================================================

DO $$ 
DECLARE
    col_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns
    WHERE table_name = 'components'
    AND column_name IN ('barcode', 'giacenza', 'giacenza_minima', 'um', 'prezzo_acquisto', 'descrizione');
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ MIGRAZIONE COMPLETATA';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Colonne aggiunte: %', col_count;
    RAISE NOTICE '';
    RAISE NOTICE '📋 Colonne disponibili in components:';
    RAISE NOTICE '  ✅ barcode (VARCHAR)';
    RAISE NOTICE '  ✅ giacenza (DECIMAL)';
    RAISE NOTICE '  ✅ giacenza_minima (DECIMAL)';
    RAISE NOTICE '  ✅ um (VARCHAR)';
    RAISE NOTICE '  ✅ prezzo_acquisto (DECIMAL - esente IVA)';
    RAISE NOTICE '  ✅ descrizione (TEXT)';
    RAISE NOTICE '  ✅ fornitore_preferito_id (UUID)';
    RAISE NOTICE '';
    RAISE NOTICE '💰 NOTA PREZZI:';
    RAISE NOTICE '  • prezzo_acquisto = prezzo esente IVA dal fornitore';
    RAISE NOTICE '  • Il ricarico % viene calcolato nel preventivo';
    RAISE NOTICE '  • NON esiste prezzo_vendita fisso in magazzino';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Sincronizzazione automatica attiva:';
    RAISE NOTICE '  • giacenza ↔ quantita_disponibile';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Stato prodotti:';
    
    SELECT COUNT(*) INTO col_count FROM components;
    RAISE NOTICE '  • Prodotti totali: %', col_count;
    
    SELECT COUNT(*) INTO col_count FROM components WHERE giacenza > 0;
    RAISE NOTICE '  • Con giacenza: %', col_count;
    
    SELECT COUNT(*) INTO col_count FROM components WHERE barcode IS NOT NULL;
    RAISE NOTICE '  • Con barcode: %', col_count;
    
    RAISE NOTICE '========================================';
END $$;
