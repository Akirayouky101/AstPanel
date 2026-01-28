-- =====================================================
-- WORKFLOW AUTOMATICO PREVENTIVI → ORDINI FORNITORI
-- =====================================================
-- Genera automaticamente ordini per prodotti mancanti
-- quando un preventivo viene accettato
-- =====================================================

-- FUNZIONE: Genera ordini fornitori da preventivo
CREATE OR REPLACE FUNCTION genera_ordini_da_preventivo(
    p_preventivo_id UUID,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    ordine_id UUID,
    fornitore_nome VARCHAR,
    prodotti_count INTEGER,
    totale_ordine DECIMAL
)
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_preventivo RECORD;
    v_fornitore_id UUID;
    v_ordine_id UUID;
    v_numero_ordine TEXT;
    v_prodotti_count INTEGER;
    v_totale DECIMAL(10,2);
    v_item RECORD;
    v_giacenza DECIMAL(10,2);
    v_da_ordinare DECIMAL(10,2);
    v_fornitore_nome VARCHAR;
BEGIN
    -- Verifica che il preventivo esista e sia accettato
    SELECT * INTO v_preventivo
    FROM preventivi
    WHERE id = p_preventivo_id AND stato = 'accettato';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Preventivo non trovato o non accettato';
    END IF;
    
    -- Per ogni prodotto nel preventivo, verifica disponibilità
    FOR v_item IN
        SELECT 
            pi.id,
            pi.prodotto_id,
            pi.codice,
            pi.descrizione,
            pi.um,
            pi.quantita,
            pi.prezzo_unitario,
            c.giacenza,
            c.prezzo_acquisto,
            c.fornitore_preferito_id
        FROM preventivi_items pi
        LEFT JOIN components c ON c.id = pi.prodotto_id
        WHERE pi.preventivo_id = p_preventivo_id
    LOOP
        v_giacenza := COALESCE(v_item.giacenza, 0);
        v_da_ordinare := GREATEST(v_item.quantita - v_giacenza, 0);
        
        -- Se manca materiale, crea ordine
        IF v_da_ordinare > 0 THEN
            -- Usa fornitore preferito del prodotto o prendi il primo attivo
            v_fornitore_id := v_item.fornitore_preferito_id;
            
            IF v_fornitore_id IS NULL THEN
                -- Prendi primo fornitore attivo
                SELECT id INTO v_fornitore_id
                FROM fornitori
                WHERE attivo = true
                ORDER BY ragione_sociale
                LIMIT 1;
            END IF;
            
            IF v_fornitore_id IS NULL THEN
                RAISE NOTICE 'Nessun fornitore disponibile per prodotto: %', v_item.descrizione;
                CONTINUE;
            END IF;
            
            -- Verifica se esiste già un ordine per questo fornitore da questo preventivo
            SELECT id INTO v_ordine_id
            FROM ordini_fornitore
            WHERE preventivo_id = p_preventivo_id 
              AND fornitore_id = v_fornitore_id
              AND stato IN ('da_ordinare', 'ordinato')
            LIMIT 1;
            
            -- Se non esiste, crea nuovo ordine
            IF v_ordine_id IS NULL THEN
                -- Genera numero ordine
                v_numero_ordine := generate_ordine_numero();
                
                -- Ottieni dati fornitore
                SELECT ragione_sociale INTO v_fornitore_nome
                FROM fornitori
                WHERE id = v_fornitore_id;
                
                -- Crea ordine
                INSERT INTO ordini_fornitore (
                    numero,
                    fornitore_id,
                    preventivo_id,
                    fornitore_nome,
                    oggetto,
                    data_ordine,
                    data_consegna_prevista,
                    stato,
                    created_by
                ) VALUES (
                    v_numero_ordine,
                    v_fornitore_id,
                    p_preventivo_id,
                    v_fornitore_nome,
                    'Ordine auto da preventivo ' || v_preventivo.numero,
                    CURRENT_DATE,
                    CURRENT_DATE + INTERVAL '7 days', -- Default 7 giorni
                    'da_ordinare',
                    p_user_id
                )
                RETURNING id INTO v_ordine_id;
            END IF;
            
            -- Aggiungi item all'ordine
            INSERT INTO ordini_fornitore_items (
                ordine_id,
                prodotto_id,
                codice,
                descrizione,
                um,
                quantita_ordinata,
                prezzo_acquisto,
                importo,
                stato
            ) VALUES (
                v_ordine_id,
                v_item.prodotto_id,
                v_item.codice,
                v_item.descrizione,
                v_item.um,
                v_da_ordinare,
                COALESCE(v_item.prezzo_acquisto, 0),
                v_da_ordinare * COALESCE(v_item.prezzo_acquisto, 0),
                'da_ricevere'
            );
            
            RAISE NOTICE 'Aggiunto % % all''ordine %', v_da_ordinare, v_item.um, v_numero_ordine;
        END IF;
    END LOOP;
    
    -- Calcola totali per ogni ordine creato e ritorna risultati
    FOR v_ordine_id, v_fornitore_nome IN
        SELECT DISTINCT o.id, o.fornitore_nome
        FROM ordini_fornitore o
        WHERE o.preventivo_id = p_preventivo_id
          AND o.stato IN ('da_ordinare', 'ordinato')
    LOOP
        -- Calcola totale ordine
        SELECT 
            COUNT(*),
            COALESCE(SUM(importo), 0)
        INTO v_prodotti_count, v_totale
        FROM ordini_fornitore_items
        WHERE ordine_id = v_ordine_id;
        
        -- Aggiorna totale ordine
        UPDATE ordini_fornitore
        SET totale_ordine = v_totale
        WHERE id = v_ordine_id;
        
        -- Ritorna info ordine
        ordine_id := v_ordine_id;
        fornitore_nome := v_fornitore_nome;
        prodotti_count := v_prodotti_count;
        totale_ordine := v_totale;
        RETURN NEXT;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION genera_ordini_da_preventivo(UUID, UUID) TO authenticated;

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ WORKFLOW PREVENTIVI → ORDINI CREATO!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Funzione disponibile:';
    RAISE NOTICE '  • genera_ordini_da_preventivo(preventivo_id, user_id)';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Funzionalità:';
    RAISE NOTICE '  • Verifica giacenza per ogni prodotto nel preventivo';
    RAISE NOTICE '  • Crea ordini automatici per materiali mancanti';
    RAISE NOTICE '  • Raggruppa prodotti per fornitore preferito';
    RAISE NOTICE '  • Calcola totali ordine automaticamente';
    RAISE NOTICE '';
    RAISE NOTICE '💡 Utilizzo: SELECT * FROM genera_ordini_da_preventivo(''uuid-preventivo'', ''uuid-user'')';
    RAISE NOTICE '';
END $$;
