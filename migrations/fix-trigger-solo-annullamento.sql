-- ============================================
-- FIX TRIGGER: libera_impegno_kit - SOLO ANNULLAMENTO
-- ============================================
-- Il trigger si occupa SOLO di annullare l'impegno
-- NON crea movimenti di magazzino (troppo problematico con foreign key)
-- I movimenti possono essere gestiti dal frontend o da altri trigger
-- ============================================

CREATE OR REPLACE FUNCTION libera_impegno_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_kit_code TEXT;
BEGIN
    -- Recupera codice kit
    SELECT codice_kit INTO v_kit_code
    FROM kits
    WHERE id = OLD.kit_id;

    -- Annulla l'impegno (unica responsabilità di questo trigger)
    UPDATE impegni_magazzino
    SET stato = 'annullato',
        completed_at = NOW(),
        note = COALESCE(note, '') || ' | Componente rimosso dal kit ' || COALESCE(v_kit_code, 'N/A')
    WHERE prodotto_id = OLD.prodotto_id
      AND kit_id = OLD.kit_id
      AND stato = 'attivo';

    RAISE NOTICE 'Impegno annullato per prodotto % del kit %', OLD.prodotto_nome, v_kit_code;

    -- NON creiamo movimento qui (problemi con foreign key)
    -- Il movimento verrà creato dal frontend o da un trigger separato

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ricrea il trigger
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;
CREATE TRIGGER trigger_libera_impegno_kit
    BEFORE DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

COMMENT ON FUNCTION libera_impegno_kit IS 'Annulla impegni quando si rimuove componente da kit (solo annullamento, no movimenti)';
