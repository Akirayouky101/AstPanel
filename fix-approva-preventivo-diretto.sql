-- ============================================================
-- FIX URGENTE: Ripristina le versioni corrette di:
--   1. get_preventivi_approvazione
--   2. approva_preventivo_diretto
-- ============================================================
-- PROBLEMA: add-approvazione-preventivi.sql (versione vecchia)
--   è stata eseguita dopo add-lock-preventivi.sql sovrascrivendo
--   entrambe le funzioni con versioni che:
--   - filtrano solo 'in_attesa' (non vedono modifica_in_attesa)
--   - impostano sempre 'approvata' (non gestiscono modifica_approvata)
--   Risultato: l'approvatore non vede le richieste di modifica e
--   anche se le vedesse, non verrebbero sbloccate correttamente.
--
-- ESEGUIRE nel Supabase SQL Editor
-- ============================================================

-- ── 1. get_preventivi_approvazione ─────────────────────────────────────────
-- Mostra le richieste in attesa, incluse quelle con modifica_in_attesa
-- e visione_in_attesa (non solo in_attesa come nella versione rotta)
CREATE OR REPLACE FUNCTION get_preventivi_approvazione(p_token TEXT)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_approvatore RECORD;
    v_result      JSON;
BEGIN
    SELECT * INTO v_approvatore
    FROM approvatori
    WHERE token = p_token AND attivo = true
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'err', 'Token non valido o approvatore non attivo.');
    END IF;

    SELECT json_build_object(
        'ok', true,
        'approvatore_nome', v_approvatore.nome,
        'preventivi', COALESCE((
            SELECT json_agg(
                json_build_object(
                    'id',                  r.id,
                    'numero',              r.numero,
                    'fornitore_nome',      r.fornitore_nome,
                    'oggetto',             r.oggetto,
                    'data_richiesta',      r.data_richiesta,
                    'data_risposta_entro', r.data_risposta_entro,
                    'note_interne',        r.note_interne,
                    'destinazioni',        r.destinazioni,
                    'approvazione_stato',  r.approvazione_stato,
                    'items', (
                        SELECT json_agg(json_build_object(
                            'codice',          i.codice,
                            'descrizione',     i.descrizione,
                            'quantita',        i.quantita,
                            'um',              i.um,
                            'note',            i.note,
                            'destinazione_id', i.destinazione_id
                        ) ORDER BY i.created_at)
                        FROM richieste_preventivo_items i
                        WHERE i.richiesta_id = r.id
                    )
                ) ORDER BY r.created_at DESC
            )
            FROM richieste_preventivo_fornitori r
            WHERE r.approvazione_stato IN ('in_attesa', 'modifica_in_attesa', 'visione_in_attesa')
        ), '[]'::json)
    ) INTO v_result;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_preventivi_approvazione(TEXT) TO anon, authenticated;

-- ── 2. approva_preventivo_diretto ──────────────────────────────────────────
-- Gestisce le transizioni di stato corrette inclusa modifica_approvata
CREATE OR REPLACE FUNCTION approva_preventivo_diretto(
    p_token         TEXT,
    p_preventivo_id UUID,
    p_azione        TEXT   -- 'approva' | 'rifiuta' | 'prendi_visione'
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_approvatore RECORD;
BEGIN
    -- Verifica token approvatore
    SELECT * INTO v_approvatore
    FROM approvatori
    WHERE token = p_token AND attivo = true
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'err', 'Token non valido.');
    END IF;

    IF p_azione NOT IN ('approva', 'rifiuta', 'prendi_visione', 'approva_modifica') THEN
        RETURN json_build_object('ok', false, 'err', 'Azione non valida.');
    END IF;

    -- Transizioni di stato esplicite:
    --   approva_modifica  → modifica_approvata  (sblocca il form per la modifica)
    --   approva           → approvata            (approvazione normale)
    --   rifiuta           → rifiutata
    --   prendi_visione    → presa_visione
    -- La pagina approva-preventivo.html passa 'approva_modifica' quando lo stato è modifica_in_attesa
    UPDATE richieste_preventivo_fornitori
    SET approvazione_stato = CASE
            WHEN p_azione = 'approva_modifica'  THEN 'modifica_approvata'
            WHEN p_azione = 'prendi_visione'    THEN 'presa_visione'
            WHEN p_azione = 'rifiuta'           THEN 'rifiutata'
            ELSE                                     'approvata'
        END,
        approvato_da = v_approvatore.nome,
        approvato_at = NOW()
    WHERE id = p_preventivo_id
      AND approvazione_stato IN ('in_attesa', 'modifica_in_attesa', 'visione_in_attesa');

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'err', 'Richiesta non trovata o già elaborata.');
    END IF;

    RETURN json_build_object('ok', true, 'azione', p_azione, 'approvatore', v_approvatore.nome);
END;
$$;

GRANT EXECUTE ON FUNCTION approva_preventivo_diretto(TEXT, UUID, TEXT) TO anon, authenticated;

-- Verifica
SELECT proname, prosrc
FROM pg_proc
WHERE proname = 'approva_preventivo_diretto';
