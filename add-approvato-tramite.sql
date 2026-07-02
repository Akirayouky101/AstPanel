-- ═══════════════════════════════════════════════════════════════════
-- Tracciamento metodo approvazione (web / pannello) + nome approvatore
-- Eseguire in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. Nuova colonna ─────────────────────────────────────────────
ALTER TABLE ordini_interni
    ADD COLUMN IF NOT EXISTS approvato_tramite TEXT;  -- 'web' | 'pannello'

-- ── 2. Setting nome responsabile approvazioni ────────────────────
INSERT INTO app_settings (key, value)
VALUES ('approver_name', '')
ON CONFLICT (key) DO NOTHING;

-- ── 3. Aggiorna RPC approva_ordine_diretto ───────────────────────
--      Ora salva approvato_da_nome, approvato_tramite e data_approvazione
CREATE OR REPLACE FUNCTION approva_ordine_diretto(p_session TEXT, p_ordine_id UUID, p_azione TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_session        TEXT;
    v_approver_name  TEXT;
    v_ordine         ordini_interni%ROWTYPE;
    v_stato          TEXT;
BEGIN
    -- Valida sessione
    SELECT value INTO v_session FROM app_settings WHERE key = 'approver_session_token';
    IF v_session IS NULL OR p_session != v_session THEN
        RETURN json_build_object('ok', false, 'err', 'Accesso non autorizzato.');
    END IF;

    -- Nome approvatore configurato in impostazioni
    SELECT COALESCE(NULLIF(TRIM(value), ''), 'Responsabile')
    INTO v_approver_name
    FROM app_settings WHERE key = 'approver_name';

    SELECT * INTO v_ordine FROM ordini_interni WHERE id = p_ordine_id;
    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'err', 'Ordine non trovato.');
    END IF;

    IF v_ordine.stato != 'in_attesa' THEN
        RETURN json_build_object('ok', false, 'err',
            'Ordine non in attesa (stato attuale: ' || v_ordine.stato || ').');
    END IF;

    v_stato := CASE WHEN p_azione = 'approva' THEN 'approvato' ELSE 'annullato' END;

    UPDATE ordini_interni
    SET stato               = v_stato,
        approvato_da_nome   = CASE WHEN p_azione = 'approva' THEN v_approver_name ELSE NULL END,
        approvato_tramite   = CASE WHEN p_azione = 'approva' THEN 'web' ELSE NULL END,
        data_approvazione   = CASE WHEN p_azione = 'approva' THEN NOW() ELSE NULL END
    WHERE id = p_ordine_id;

    RETURN json_build_object(
        'ok', true,
        'azione', p_azione,
        'nuovo_stato', v_stato,
        'numero', v_ordine.numero,
        'approvato_da', CASE WHEN p_azione = 'approva' THEN v_approver_name ELSE NULL END
    );
END;
$$;

GRANT EXECUTE ON FUNCTION approva_ordine_diretto(TEXT, UUID, TEXT) TO anon, authenticated;
