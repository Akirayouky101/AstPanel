-- ============================================================
-- APPROVAZIONE RICHIESTE PREVENTIVO FORNITORI
-- Esegui nel Supabase SQL Editor
-- ============================================================

-- Colonne di approvazione sulla richiesta principale
ALTER TABLE richieste_preventivo_fornitori
ADD COLUMN IF NOT EXISTS approvazione_stato TEXT DEFAULT 'non_richiesta',
-- 'non_richiesta', 'in_attesa', 'approvata', 'rifiutata'
ADD COLUMN IF NOT EXISTS approvato_da TEXT,
ADD COLUMN IF NOT EXISTS approvato_at TIMESTAMPTZ;

-- ── RPC: restituisce le richieste in attesa per un approvatore ────────────────
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
            WHERE r.approvazione_stato = 'in_attesa'
        ), '[]'::json)
    ) INTO v_result;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_preventivi_approvazione(TEXT) TO anon, authenticated;

-- ── RPC: approva o rifiuta una richiesta ─────────────────────────────────────
CREATE OR REPLACE FUNCTION approva_preventivo_diretto(
    p_token         TEXT,
    p_preventivo_id UUID,
    p_azione        TEXT   -- 'approva' | 'rifiuta'
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_approvatore RECORD;
    v_nuovo_stato TEXT;
BEGIN
    SELECT * INTO v_approvatore
    FROM approvatori
    WHERE token = p_token AND attivo = true
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'err', 'Token non valido.');
    END IF;

    IF p_azione NOT IN ('approva', 'rifiuta') THEN
        RETURN json_build_object('ok', false, 'err', 'Azione non valida.');
    END IF;

    v_nuovo_stato := CASE p_azione WHEN 'approva' THEN 'approvata' ELSE 'rifiutata' END;

    UPDATE richieste_preventivo_fornitori
    SET approvazione_stato = v_nuovo_stato,
        approvato_da       = v_approvatore.nome,
        approvato_at       = NOW()
    WHERE id = p_preventivo_id
      AND approvazione_stato = 'in_attesa';

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'err', 'Richiesta non trovata o già elaborata.');
    END IF;

    RETURN json_build_object('ok', true, 'azione', p_azione, 'approvatore', v_approvatore.nome);
END;
$$;

GRANT EXECUTE ON FUNCTION approva_preventivo_diretto(TEXT, UUID, TEXT) TO anon, authenticated;
