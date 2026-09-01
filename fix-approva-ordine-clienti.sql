-- Aggiunge cliente_id e cliente_nome_cache agli items restituiti dalla funzione
-- di approvazione, così la pagina può raggruppare gli articoli per cliente.

CREATE OR REPLACE FUNCTION get_ordini_approvazione(p_token TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_approvatore_id   UUID;
    v_approvatore_nome TEXT;
    v_result           JSON;
BEGIN
    -- Verifica token approvatore
    SELECT id, nome
    INTO   v_approvatore_id, v_approvatore_nome
    FROM   approvatori
    WHERE  token = p_token AND attivo = TRUE
    LIMIT  1;

    IF v_approvatore_id IS NULL THEN
        RETURN json_build_object('ok', false, 'err', 'Token non valido o approvatore non attivo.');
    END IF;

    SELECT json_build_object(
        'ok',               true,
        'approvatore_nome', v_approvatore_nome,
        'ordini', COALESCE(json_agg(
            json_build_object(
                'id',                     o.id,
                'numero',                 o.numero,
                'tipo',                   o.tipo,
                'oggetto',                o.oggetto,
                'stato',                  o.stato,
                'fornitore_nome',         o.fornitore_nome,
                'fornitore_email',        o.fornitore_email,
                'fornitore_telefono',     o.fornitore_telefono,
                'fornitore_riferimento',  o.fornitore_riferimento,
                'chi_ha_ordinato',        o.chi_ha_ordinato,
                'canale_ordine',          o.canale_ordine,
                'data_ordine',            o.data_ordine,
                'data_consegna_prevista', o.data_consegna_prevista,
                'subtotale',              o.subtotale,
                'sconto_percentuale',     o.sconto_percentuale,
                'sconto_importo',         o.sconto_importo,
                'iva_percentuale',        o.iva_percentuale,
                'totale_iva',             o.totale_iva,
                'totale',                 o.totale,
                'note',                   o.note,
                'note_interne',           o.note_interne,
                'approvato_da_nome',      o.approvato_da_nome,
                'approvato_tramite',      o.approvato_tramite,
                'data_approvazione',      o.data_approvazione,
                'note_approvazione',      o.note_approvazione,
                'items', (
                    SELECT COALESCE(json_agg(json_build_object(
                        'codice',             i.codice,
                        'nome',               COALESCE(c.nome, i.descrizione),
                        'descrizione',        i.descrizione,
                        'quantita',           i.quantita,
                        'um',                 i.um,
                        'prezzo_unitario',    i.prezzo_unitario,
                        'sconto_percentuale', i.sconto_percentuale,
                        'importo',            i.importo,
                        'note',               i.note,
                        'cliente_id',         i.cliente_id,
                        'cliente_nome_cache', i.cliente_nome_cache
                    ) ORDER BY i.posizione), '[]'::json)
                    FROM ordini_interni_items i
                    LEFT JOIN components c ON c.id = i.prodotto_id
                    WHERE i.ordine_id = o.id
                )
            ) ORDER BY o.created_at
        ), '[]'::json)
    )
    INTO v_result
    FROM ordini_interni o WHERE o.stato = 'in_attesa';

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_ordini_approvazione(TEXT) TO anon, authenticated;

SELECT '✅ get_ordini_approvazione aggiornata con cliente_id negli items' AS status;
