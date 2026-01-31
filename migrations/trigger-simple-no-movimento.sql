-- ============================================
-- TRIGGER SEMPLIFICATO: libera_impegno_kit
-- ============================================
-- Questo trigger si occupa SOLO di annullare l'impegno
-- Il movimento viene creato dal frontend con currentUserId
-- ============================================

CREATE OR REPLACE FUNCTION libera_impegno_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_kit_code TEXT;
BEGIN
    -- Recupera codice kit per il messaggio
    SELECT codice_kit INTO v_kit_code
    FROM kits
    WHERE id = OLD.kit_id;

    -- Annulla l'impegno (se non è già stato annullato dal frontend)
    UPDATE impegni_magazzino
    SET stato = 'annullato',
        completed_at = NOW(),
        note = COALESCE(note, '') || ' | Componente rimosso dal kit ' || COALESCE(v_kit_code, 'N/A')
    WHERE prodotto_id = OLD.prodotto_id
      AND kit_id = OLD.kit_id
      AND stato = 'attivo';

    -- NON crea movimento qui - lo fa il frontend con currentUserId valido

    RAISE NOTICE 'Impegno annullato per kit %', v_kit_code;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ricrea trigger
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;
CREATE TRIGGER trigger_libera_impegno_kit
    BEFORE DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

COMMENT ON FUNCTION libera_impegno_kit IS 'Annulla impegni quando si rimuove componente (movimento gestito da frontend)';
