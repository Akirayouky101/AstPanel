-- ============================================
-- FIX TRIGGER: libera_impegno_kit
-- ============================================
-- Modifica il trigger per gestire correttamente
-- il created_by quando si elimina un componente dal kit
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

    -- Recupera user_id (prova prima con auth.uid, poi con aggiunto_da)
    SELECT id INTO v_user_id
    FROM users
    WHERE auth_id = auth.uid();
    
    -- Se non trovato via auth.uid, usa aggiunto_da del kit_item
    IF v_user_id IS NULL THEN
        v_user_id := OLD.aggiunto_da;
    END IF;

    -- Cancella l'impegno
    UPDATE impegni_magazzino
    SET stato = 'annullato',
        completed_at = NOW(),
        note = COALESCE(note, '') || ' | Componente rimosso dal kit ' || v_kit_code
    WHERE prodotto_id = OLD.prodotto_id
      AND kit_id = OLD.kit_id
      AND stato = 'attivo';

    -- Registra lo storico del reintegro SOLO se user_id è valido
    -- Altrimenti il movimento sarà già stato creato manualmente dal frontend
    IF v_user_id IS NOT NULL THEN
        -- Verifica che l'utente esista nella tabella users
        IF EXISTS (SELECT 1 FROM users WHERE id = v_user_id) THEN
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
            
            RAISE NOTICE 'Movimento reintegro creato per % (qtà: %) dal kit %', 
                OLD.prodotto_nome, OLD.quantita, v_kit_code;
        ELSE
            RAISE WARNING 'User ID % non trovato, movimento non creato (verrà creato dal frontend)', v_user_id;
        END IF;
    ELSE
        RAISE NOTICE 'User ID non disponibile, movimento gestito dal frontend';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ricrea il trigger
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;
CREATE TRIGGER trigger_libera_impegno_kit
    BEFORE DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

COMMENT ON FUNCTION libera_impegno_kit IS 'Annulla impegni e crea movimento reintegro quando si rimuove componente da kit';
