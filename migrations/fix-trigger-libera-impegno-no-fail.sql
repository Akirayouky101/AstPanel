-- ============================================
-- FIX TRIGGER: libera_impegno_kit - NO FAIL
-- ============================================
-- Il trigger NON DEVE MAI fallire
-- Se non riesce a creare il movimento, lo salta semplicemente
-- L'importante è annullare l'impegno
-- ============================================

CREATE OR REPLACE FUNCTION libera_impegno_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_kit_code TEXT;
    v_user_id UUID;
    v_movimento_creato BOOLEAN := FALSE;
BEGIN
    -- Recupera codice kit
    SELECT codice_kit INTO v_kit_code
    FROM kits
    WHERE id = OLD.kit_id;

    -- Annulla SEMPRE l'impegno (priorità massima)
    UPDATE impegni_magazzino
    SET stato = 'annullato',
        completed_at = NOW(),
        note = COALESCE(note, '') || ' | Componente rimosso dal kit ' || COALESCE(v_kit_code, 'N/A')
    WHERE prodotto_id = OLD.prodotto_id
      AND kit_id = OLD.kit_id
      AND stato = 'attivo';

    -- Prova a recuperare user_id (prima da auth.uid, poi da aggiunto_da)
    BEGIN
        SELECT id INTO v_user_id
        FROM users
        WHERE auth_id = auth.uid();
        
        -- Se NULL, prova con aggiunto_da
        IF v_user_id IS NULL AND OLD.aggiunto_da IS NOT NULL THEN
            -- Verifica che aggiunto_da esista in users
            IF EXISTS (SELECT 1 FROM users WHERE id = OLD.aggiunto_da) THEN
                v_user_id := OLD.aggiunto_da;
            END IF;
        END IF;
        
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
                'Componente rimosso da kit ' || COALESCE(v_kit_code, 'N/A') || ' - Prodotto: ' || COALESCE(OLD.prodotto_nome, 'N/A'),
                v_user_id
            );
            v_movimento_creato := TRUE;
            RAISE NOTICE 'Movimento reintegro creato per kit %', v_kit_code;
        ELSE
            RAISE NOTICE 'User ID non valido, movimento non creato (impegno comunque annullato)';
        END IF;
        
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE WARNING 'Foreign key violation su movimenti_magazzino, movimento saltato';
        WHEN OTHERS THEN
            RAISE WARNING 'Errore durante creazione movimento: %, movimento saltato', SQLERRM;
    END;

    -- Ritorna sempre OLD (non bloccare mai la DELETE)
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ricrea il trigger
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;
CREATE TRIGGER trigger_libera_impegno_kit
    BEFORE DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

COMMENT ON FUNCTION libera_impegno_kit IS 'Annulla impegni quando si rimuove componente da kit (non fallisce mai)';
