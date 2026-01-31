-- Vista per storico completo kit (inclusi componenti eliminati)

CREATE OR REPLACE VIEW v_kit_storico AS
SELECT 
    ki.id,
    ki.kit_id,
    k.codice_kit,
    k.nome_kit,
    k.stato AS kit_stato,
    ki.prodotto_id,
    c.codice AS codice_componente,
    c.nome AS prodotto_nome,
    ki.quantita,
    ki.aggiunto_il,
    ki.aggiunto_da,
    u_add.nome || ' ' || u_add.cognome AS aggiunto_da_nome,
    ki.deleted_at,
    ki.deleted_by,
    u_del.nome || ' ' || u_del.cognome AS eliminato_da_nome,
    CASE 
        WHEN ki.deleted_at IS NOT NULL THEN 'eliminato'
        ELSE 'attivo'
    END AS stato_componente
FROM kit_items ki
JOIN kits k ON ki.kit_id = k.id
JOIN components c ON ki.prodotto_id = c.id
LEFT JOIN users u_add ON ki.aggiunto_da = u_add.id
LEFT JOIN users u_del ON ki.deleted_by = u_del.id
ORDER BY ki.aggiunto_il DESC;

-- Vista per storico kit (solo i kit)
CREATE OR REPLACE VIEW v_kits_storico AS
SELECT 
    k.id,
    k.codice_kit,
    k.nome_kit,
    k.cliente_id,
    cl.nome AS cliente_nome,
    k.stato,
    k.created_at,
    k.created_by,
    u_create.nome || ' ' || u_create.cognome AS creato_da_nome,
    k.deleted_at,
    k.deleted_by,
    u_del.nome || ' ' || u_del.cognome AS eliminato_da_nome,
    (SELECT COUNT(*) FROM kit_items ki WHERE ki.kit_id = k.id AND ki.deleted_at IS NULL) AS componenti_attivi,
    (SELECT COUNT(*) FROM kit_items ki WHERE ki.kit_id = k.id AND ki.deleted_at IS NOT NULL) AS componenti_eliminati
FROM kits k
LEFT JOIN clients cl ON k.cliente_id = cl.id
LEFT JOIN users u_create ON k.created_by = u_create.id
LEFT JOIN users u_del ON k.deleted_by = u_del.id
ORDER BY k.created_at DESC;

COMMENT ON VIEW v_kit_storico IS 'Storico completo componenti kit (attivi ed eliminati)';
COMMENT ON VIEW v_kits_storico IS 'Storico completo kit con info eliminazioni';
