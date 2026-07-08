-- =====================================================
-- Rimuove il limite VARCHAR(255) da nome e descrizione
-- della tabella components.
-- Tutte le viste che usano c.nome devono essere
-- droppate e ricreate.
-- =====================================================

-- 1. Drop viste dipendenti (CASCADE gestisce eventuali sotto-dipendenze)
DROP VIEW IF EXISTS v_kit_items_dettaglio CASCADE;
DROP VIEW IF EXISTS componenti_sotto_scorta CASCADE;
DROP VIEW IF EXISTS v_giacenze_complete CASCADE;

-- 2. Altera le colonne
ALTER TABLE components
  ALTER COLUMN nome TYPE TEXT,
  ALTER COLUMN descrizione TYPE TEXT;

-- 3. Ricrea v_giacenze_complete
CREATE OR REPLACE VIEW v_giacenze_complete AS
SELECT 
    c.id,
    c.codice,
    c.nome,
    c.quantita_disponibile AS giacenza_fisica,
    COALESCE(SUM(i.quantita_impegnata) FILTER (WHERE i.stato = 'attivo'), 0) AS giacenza_impegnata,
    c.quantita_disponibile - COALESCE(SUM(i.quantita_impegnata) FILTER (WHERE i.stato = 'attivo'), 0) AS giacenza_libera,
    c.scorta_minima,
    c.unita_misura,
    CASE 
        WHEN (c.quantita_disponibile - COALESCE(SUM(i.quantita_impegnata) FILTER (WHERE i.stato = 'attivo'), 0)) < 0 
        THEN 'CRITICO: Giacenza impegnata supera disponibile'
        WHEN (c.quantita_disponibile - COALESCE(SUM(i.quantita_impegnata) FILTER (WHERE i.stato = 'attivo'), 0)) < c.scorta_minima 
        THEN 'WARNING: Sotto scorta minima'
        WHEN (c.quantita_disponibile - COALESCE(SUM(i.quantita_impegnata) FILTER (WHERE i.stato = 'attivo'), 0)) = 0 
        THEN 'ATTENZIONE: Tutto impegnato'
        ELSE 'OK'
    END AS stato_giacenza
FROM components c
LEFT JOIN impegni_magazzino i ON i.prodotto_id = c.id AND i.stato = 'attivo'
GROUP BY c.id, c.codice, c.nome, c.quantita_disponibile, c.scorta_minima, c.unita_misura;

COMMENT ON VIEW v_giacenze_complete IS 'Vista completa giacenze con distinzione fisica/impegnata/libera';

-- 4. Ricrea componenti_sotto_scorta
CREATE OR REPLACE VIEW componenti_sotto_scorta AS
SELECT 
    c.id,
    c.nome,
    c.categoria,
    c.quantita_magazzino,
    c.quantita_minima,
    c.unita_misura,
    c.fornitore,
    (c.quantita_minima - c.quantita_magazzino) AS quantita_da_ordinare,
    c.prezzo_acquisto,
    c.ultimo_carico
FROM components c
WHERE c.quantita_magazzino < c.quantita_minima
ORDER BY (c.quantita_minima - c.quantita_magazzino) DESC;

-- 5. Ricrea v_kit_items_dettaglio
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

-- 6. Verifica
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'components'
  AND column_name IN ('nome', 'descrizione');

SELECT 'Completato: colonne TEXT, viste ricreate' AS status;
