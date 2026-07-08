-- =====================================================
-- Rimuove il limite VARCHAR(255) da nome e descrizione
-- della tabella components.
-- La vista v_kit_items_dettaglio usa la colonna 'nome'
-- quindi va droppata e ricreata.
-- =====================================================

-- 1. Drop vista (CASCADE rimuove eventuali dipendenze)
DROP VIEW IF EXISTS v_kit_items_dettaglio CASCADE;

-- 2. Altera le colonne
ALTER TABLE components
  ALTER COLUMN nome TYPE TEXT,
  ALTER COLUMN descrizione TYPE TEXT;

-- 3. Ricrea la vista (identica alla versione in fix-kit-system-complete.sql)
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

-- 4. Verifica
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'components'
  AND column_name IN ('nome', 'descrizione');

SELECT 'Vista ricreata con successo' AS status;
