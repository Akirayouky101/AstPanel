-- ============================================
-- FIX TRIGGER: libera_impegno_kit
-- ============================================
-- Usa OLD.aggiunto_da invece di auth.uid()
-- perché sappiamo che chi ha aggiunto il componente esiste
-- ============================================

CREATE OR REPLACE FUNCTION libera_impegno_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_kit_code TEXT;
    v_user_id UUID;
BEGIN
    -- Recupera codice kit
    SELECT codice_kit INTO v_kit_code
    FROM kits
    WHERE id = OLD.kit_id;

    -- USA DIRETTAMENTE aggiunto_da (sappiamo che esiste!)
    v_user_id := OLD.aggiunto_da;
    
    -- Se per qualche motivo è NULL, prova con auth.uid
    IF v_user_id IS NULL THEN
        SELECT id INTO v_user_id
        FROM users
        WHERE auth_id = auth.uid();
    END IF;

    -- Annulla l'impegno
    UPDATE impegni_magazzino
    SET stato = 'annullato',
        completed_at = NOW(),
        note = COALESCE(note, '') || ' | Componente rimosso dal kit ' || v_kit_code
    WHERE prodotto_id = OLD.prodotto_id
      AND kit_id = OLD.kit_id
      AND stato = 'attivo';

    -- Crea movimento SOLO se abbiamo un user_id valido
    IF v_user_id IS NOT NULL THEN
        INSERT INTO movimenti_magazzino (
            prodotto_id,
            tipo_movimento,
            quantita,
            causale,
            created_by
        ) VALUES (
            OLD.prodotto_id,
            'reintegro',
            OLD.quantita,
            'Componente rimosso da kit ' || v_kit_code || ' - Prodotto: ' || OLD.prodotto_nome,
            v_user_id
        );
        
        RAISE NOTICE 'Liberato impegno per % dal kit %', OLD.prodotto_nome, v_kit_code;
    ELSE
        RAISE WARNING 'User ID non trovato, movimento non creato';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ricrea trigger
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;
CREATE TRIGGER trigger_libera_impegno_kit
    BEFORE DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

COMMENT ON FUNCTION libera_impegno_kit IS 'Libera impegni quando si rimuove componente da kit (usa aggiunto_da)';
