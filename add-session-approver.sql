-- ═══════════════════════════════════════════════════════════════════
-- Session Approver – Link unico per tutti gli ordini in attesa
-- Eseguire in Supabase SQL Editor DOPO create-approvazione-system.sql
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. Token di sessione permanente per l'approvatore ────────────
INSERT INTO app_settings (key, value)
VALUES ('approver_session_token', encode(gen_random_bytes(32), 'hex'))
ON CONFLICT (key) DO NOTHING;

-- ── 2. RPC: ottieni tutti gli ordini in attesa con articoli ──────
CREATE OR REPLACE FUNCTION get_ordini_approvazione(p_session TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_session TEXT;
BEGIN
    SELECT value INTO v_session FROM app_settings WHERE key = 'approver_session_token';
    IF v_session IS NULL OR p_session != v_session THEN
        RETURN json_build_object('ok', false, 'err', 'Link non valido o scaduto.');
    END IF;

    RETURN (
        SELECT json_build_object(
            'ok', true,
            'ordini', COALESCE(json_agg(
                json_build_object(
                    'id',                    o.id,
                    'numero',                o.numero,
                    'tipo',                  o.tipo,
                    'oggetto',               o.oggetto,
                    'fornitore_nome',        o.fornitore_nome,
                    'data_ordine',           o.data_ordine::TEXT,
                    'data_consegna_prevista',o.data_consegna_prevista::TEXT,
                    'totale',                o.totale,
                    'subtotale',             o.subtotale,
                    'sconto_percentuale',    o.sconto_percentuale,
                    'iva_percentuale',       o.iva_percentuale,
                    'note',                  o.note,
                    'note_interne',          o.note_interne,
                    'chi_ha_ordinato',       o.chi_ha_ordinato,
                    'canale_ordine',         o.canale_ordine,
                    'created_at',            o.created_at::TEXT,
                    'items', (
                        SELECT COALESCE(json_agg(json_build_object(
                            'codice',            i.codice,
                            'descrizione',       i.descrizione,
                            'quantita',          i.quantita,
                            'um',                i.um,
                            'prezzo_unitario',   i.prezzo_unitario,
                            'sconto_percentuale',i.sconto_percentuale,
                            'importo',           i.importo,
                            'note',              i.note
                        ) ORDER BY i.posizione), '[]'::json)
                        FROM ordini_interni_items i WHERE i.ordine_id = o.id
                    )
                ) ORDER BY o.created_at
            ), '[]'::json)
        )
        FROM ordini_interni o WHERE o.stato = 'in_attesa'
    );
END;
$$;

-- ── 3. RPC: approva/rifiuta tramite sessione ──────────────────────
CREATE OR REPLACE FUNCTION approva_ordine_diretto(p_session TEXT, p_ordine_id UUID, p_azione TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_session TEXT;
    v_ordine  ordini_interni%ROWTYPE;
    v_stato   TEXT;
BEGIN
    SELECT value INTO v_session FROM app_settings WHERE key = 'approver_session_token';
    IF v_session IS NULL OR p_session != v_session THEN
        RETURN json_build_object('ok', false, 'err', 'Accesso non autorizzato.');
    END IF;

    SELECT * INTO v_ordine FROM ordini_interni WHERE id = p_ordine_id;
    IF NOT FOUND THEN RETURN json_build_object('ok', false, 'err', 'Ordine non trovato.'); END IF;

    IF v_ordine.stato != 'in_attesa' THEN
        RETURN json_build_object('ok', false, 'err',
            'Ordine non in attesa (stato attuale: ' || v_ordine.stato || ').');
    END IF;

    v_stato := CASE WHEN p_azione = 'approva' THEN 'approvato' ELSE 'annullato' END;
    UPDATE ordini_interni SET stato = v_stato WHERE id = p_ordine_id;

    RETURN json_build_object(
        'ok', true, 'azione', p_azione, 'nuovo_stato', v_stato, 'numero', v_ordine.numero
    );
END;
$$;

GRANT EXECUTE ON FUNCTION get_ordini_approvazione(TEXT)            TO anon, authenticated;
GRANT EXECUTE ON FUNCTION approva_ordine_diretto(TEXT, UUID, TEXT)  TO anon, authenticated;
