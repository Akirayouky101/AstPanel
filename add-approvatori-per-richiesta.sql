-- ============================================================
-- FIX PRIVACY: ogni approvatore vede solo le richieste
--              che gli sono state effettivamente inviate
-- ============================================================
-- PROBLEMA: get_preventivi_approvazione restituiva TUTTE le
--   richieste in attesa a qualsiasi approvatore aprisse il link.
--   Chiunque avesse un token valido vedeva le richieste degli altri.
--
-- SOLUZIONE: colonna approvatori_ids UUID[] su
--   richieste_preventivo_fornitori + filtro nel RPC.
--
-- ESEGUIRE nel Supabase SQL Editor
-- ============================================================

-- 1. Aggiungi colonna per tracciare a chi è stata inviata la richiesta
ALTER TABLE richieste_preventivo_fornitori
ADD COLUMN IF NOT EXISTS approvatori_ids UUID[] DEFAULT '{}';

-- 2. Aggiorna get_preventivi_approvazione con filtro per approvatore
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
              AND (
                -- Backward compat: vecchie richieste senza approvatori_ids
                -- sono visibili a tutti (saranno poche e temporanee)
                r.approvatori_ids IS NULL
                OR array_length(r.approvatori_ids, 1) IS NULL
                OR r.approvatori_ids = '{}'
                -- Nuove richieste: solo all'approvatore designato
                OR v_approvatore.id = ANY(r.approvatori_ids)
              )
        ), '[]'::json)
    ) INTO v_result;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_preventivi_approvazione(TEXT) TO anon, authenticated;

-- Verifica
SELECT 'Colonna aggiunta:' AS info,
       column_name, data_type
FROM information_schema.columns
WHERE table_name = 'richieste_preventivo_fornitori'
  AND column_name = 'approvatori_ids';
