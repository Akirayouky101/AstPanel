-- Trigger semplificato: SOLO annulla impegno, NO movimento
-- Il movimento viene creato dal frontend con currentUserId

-- Drop trigger esistente
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;

-- Funzione semplificata: solo annullamento impegno
CREATE OR REPLACE FUNCTION libera_impegno_kit()
RETURNS TRIGGER AS $$
BEGIN
    -- SOLO annulla l'impegno, nient'altro
    UPDATE impegni_magazzino
    SET stato = 'annullato',
        completed_at = NOW()
    WHERE prodotto_id = OLD.prodotto_id 
      AND kit_id = OLD.kit_id
      AND stato = 'attivo';
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ricrea trigger
CREATE TRIGGER trigger_libera_impegno_kit
    BEFORE DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

-- Verifica
SELECT 'Trigger ricreato: SOLO annullamento impegno, movimento gestito dal frontend' AS status;
