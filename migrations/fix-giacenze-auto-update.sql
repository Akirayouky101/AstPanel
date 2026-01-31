-- ============================================
-- FIX: TRIGGER AGGIORNAMENTO GIACENZE AUTOMATICO
-- ============================================
-- Quando si inserisce un movimento magazzino, aggiorna automaticamente
-- la giacenza del componente

CREATE OR REPLACE FUNCTION aggiorna_giacenza_da_movimento()
RETURNS TRIGGER AS $$
BEGIN
    -- Calcola giacenza prima del movimento (se non specificata)
    IF NEW.giacenza_prima IS NULL THEN
        SELECT COALESCE(giacenza, 0) INTO NEW.giacenza_prima
        FROM components
        WHERE id = NEW.prodotto_id;
    END IF;
    
    -- Aggiorna giacenza del componente
    IF NEW.tipo_movimento = 'carico' THEN
        -- CARICO: aumenta giacenza
        UPDATE components
        SET giacenza = COALESCE(giacenza, 0) + NEW.quantita
        WHERE id = NEW.prodotto_id;
        
        -- Calcola giacenza dopo
        NEW.giacenza_dopo := NEW.giacenza_prima + NEW.quantita;
        
    ELSIF NEW.tipo_movimento = 'scarico' THEN
        -- SCARICO: diminuisce giacenza (quantità è già negativa)
        UPDATE components
        SET giacenza = COALESCE(giacenza, 0) + NEW.quantita
        WHERE id = NEW.prodotto_id;
        
        -- Calcola giacenza dopo
        NEW.giacenza_dopo := NEW.giacenza_prima + NEW.quantita;
        
    ELSIF NEW.tipo_movimento = 'reintegro' THEN
        -- REINTEGRO: aumenta giacenza (libera impegno)
        UPDATE components
        SET giacenza = COALESCE(giacenza, 0) + NEW.quantita
        WHERE id = NEW.prodotto_id;
        
        -- Calcola giacenza dopo
        NEW.giacenza_dopo := NEW.giacenza_prima + NEW.quantita;
        
    ELSIF NEW.tipo_movimento = 'rettifica' THEN
        -- RETTIFICA: può essere positiva o negativa
        UPDATE components
        SET giacenza = COALESCE(giacenza, 0) + NEW.quantita
        WHERE id = NEW.prodotto_id;
        
        -- Calcola giacenza dopo
        NEW.giacenza_dopo := NEW.giacenza_prima + NEW.quantita;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Rimuovi trigger se esiste
DROP TRIGGER IF EXISTS trigger_aggiorna_giacenza ON movimenti_magazzino;

-- Crea trigger BEFORE INSERT (per poter modificare NEW.giacenza_prima e NEW.giacenza_dopo)
CREATE TRIGGER trigger_aggiorna_giacenza
    BEFORE INSERT ON movimenti_magazzino
    FOR EACH ROW
    EXECUTE FUNCTION aggiorna_giacenza_da_movimento();

-- ============================================
-- VERIFICA
-- ============================================
SELECT '✅ Trigger aggiorna_giacenza_da_movimento creato!' AS status;
SELECT 'IMPORTANTE: Ora i movimenti magazzino aggiorneranno automaticamente le giacenze!' AS nota;
