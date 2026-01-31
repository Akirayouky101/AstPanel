-- ============================================
-- RPC FUNCTION: rimuovi_componente_da_kit
-- ============================================
-- Rimuove un componente dal kit in modo atomico
-- 1. Annulla l'impegno magazzino
-- 2. Crea movimento di reintegro
-- 3. Elimina il kit_item
-- ============================================

CREATE OR REPLACE FUNCTION rimuovi_componente_da_kit(
    p_kit_item_id UUID
)
RETURNS jsonb AS $$
DECLARE
    v_kit_item RECORD;
    v_kit_code TEXT;
    v_user_id UUID;
    v_impegno_id UUID;
    v_quantita_impegnata DECIMAL(10,2);
    v_result jsonb;
BEGIN
    -- 1. Recupera informazioni del kit_item
    SELECT 
        ki.kit_id,
        ki.prodotto_id,
        ki.quantita,
        ki.prodotto_nome,
        ki.aggiunto_da,
        k.codice_kit
    INTO v_kit_item
    FROM kit_items ki
    JOIN kits k ON k.id = ki.kit_id
    WHERE ki.id = p_kit_item_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Kit item non trovato'
        );
    END IF;

    v_kit_code := v_kit_item.codice_kit;

    -- 2. Recupera user_id
    SELECT id INTO v_user_id
    FROM users
    WHERE auth_id = auth.uid();

    -- Fallback: usa aggiunto_da se auth.uid non disponibile
    IF v_user_id IS NULL THEN
        v_user_id := v_kit_item.aggiunto_da;
    END IF;

    -- 3. Trova e annulla l'impegno
    SELECT id, quantita_impegnata 
    INTO v_impegno_id, v_quantita_impegnata
    FROM impegni_magazzino
    WHERE prodotto_id = v_kit_item.prodotto_id
      AND kit_id = v_kit_item.kit_id
      AND stato = 'attivo'
    LIMIT 1;

    IF v_impegno_id IS NOT NULL THEN
        -- Annulla l'impegno
        UPDATE impegni_magazzino
        SET stato = 'annullato',
            completed_at = NOW(),
            note = COALESCE(note, '') || ' | Componente rimosso dal kit ' || v_kit_code
        WHERE id = v_impegno_id;

        -- Crea movimento di reintegro (solo se abbiamo un user_id valido)
        IF v_user_id IS NOT NULL AND EXISTS (SELECT 1 FROM users WHERE id = v_user_id) THEN
            INSERT INTO movimenti_magazzino (
                prodotto_id,
                tipo_movimento,
                quantita,
                causale,
                created_by
            ) VALUES (
                v_kit_item.prodotto_id,
                'reintegro',
                v_quantita_impegnata,
                'Componente rimosso da kit ' || v_kit_code || ' - Prodotto: ' || v_kit_item.prodotto_nome,
                v_user_id
            );
        END IF;

        RAISE NOTICE 'Impegno % annullato e reintegrato', v_impegno_id;
    END IF;

    -- 4. Elimina il kit_item
    DELETE FROM kit_items WHERE id = p_kit_item_id;

    -- 5. Ritorna risultato
    v_result := jsonb_build_object(
        'success', true,
        'kit_code', v_kit_code,
        'prodotto', v_kit_item.prodotto_nome,
        'quantita_liberata', COALESCE(v_quantita_impegnata, v_kit_item.quantita),
        'impegno_annullato', (v_impegno_id IS NOT NULL)
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permessi
GRANT EXECUTE ON FUNCTION rimuovi_componente_da_kit(UUID) TO authenticated;

COMMENT ON FUNCTION rimuovi_componente_da_kit IS 'Rimuove un componente dal kit annullando impegni e creando movimenti in modo atomico';
