-- ============================================================
-- FIX URGENTE: Ripristina la versione corretta di
--              approva_preventivo_diretto
-- ============================================================
-- PROBLEMA: add-approvazione-preventivi.sql (versione vecchia)
--   è stata eseguita dopo add-lock-preventivi.sql sovrascrivendo
--   la logica che gestisce modifica_in_attesa → modifica_approvata.
--   Risultato: approvare una richiesta di modifica non sblocca il
--   form per l'utente.
--
-- ESEGUIRE nel Supabase SQL Editor
-- ============================================================

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

    IF p_azione NOT IN ('approva', 'rifiuta', 'prendi_visione') THEN
        RETURN json_build_object('ok', false, 'err', 'Azione non valida.');
    END IF;

    -- Transizione di stato intelligente:
    --   in_attesa        + approva        → approvata
    --   modifica_in_attesa + approva      → modifica_approvata  ← sblocca la richiesta per la modifica
    --   visione_in_attesa  + prendi_visione → presa_visione
    --   qualsiasi        + rifiuta        → rifiutata
    UPDATE richieste_preventivo_fornitori
    SET approvazione_stato = CASE
            WHEN p_azione = 'rifiuta'
                THEN 'rifiutata'
            WHEN p_azione = 'approva' AND approvazione_stato = 'modifica_in_attesa'
                THEN 'modifica_approvata'
            WHEN p_azione = 'prendi_visione' AND approvazione_stato = 'visione_in_attesa'
                THEN 'presa_visione'
            ELSE 'approvata'
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
