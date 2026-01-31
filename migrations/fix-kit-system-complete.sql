-- FIX COMPLETO SISTEMA KIT
-- Risolve tutti i problemi di schema e allinea database con frontend

-- 1. Aggiorna vista v_kit_items_dettaglio per includere deleted_at e deleted_by
DROP VIEW IF EXISTS v_kit_items_dettaglio CASCADE;

CREATE OR REPLACE VIEW v_kit_items_dettaglio AS
SELECT 
    ki.id,
    ki.kit_id,
    k.codice_kit,
    k.nome_kit AS kit_nome,
    k.stato AS kit_stato,
    ki.prodotto_id,
    c.codice AS prodotto_codice,
    c.nome AS prodotto_nome,
    c.categoria AS prodotto_categoria,
    ki.quantita,
    ki.quantita_mancante,
    ki.prodotto_barcode,
    ki.aggiunto_il,
    ki.aggiunto_da,
    u.nome || ' ' || u.cognome AS aggiunto_da_nome,
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
LEFT JOIN users u ON ki.aggiunto_da = u.id
LEFT JOIN users u_del ON ki.deleted_by = u_del.id
ORDER BY ki.aggiunto_il DESC;

COMMENT ON VIEW v_kit_items_dettaglio IS 'Vista dettagliata componenti kit con info eliminazione';

-- 2. Verifica trigger rimossi
SELECT 'Verifica trigger su kit_items:' AS info;
SELECT tgname AS trigger_name, proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgrelid = 'kit_items'::regclass
AND NOT tgisinternal;

-- 3. Verifica colonne kit_items
SELECT 'Colonne kit_items:' AS info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'kit_items' 
  AND column_name IN ('deleted_at', 'deleted_by')
ORDER BY ordinal_position;

-- 4. Verifica colonne impegni_magazzino
SELECT 'Colonne impegni_magazzino:' AS info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'impegni_magazzino' 
  AND column_name LIKE '%quantita%'
ORDER BY ordinal_position;

SELECT '✅ Fix completo eseguito! Frontend usa "quantita_impegnata" per impegni_magazzino' AS status;
