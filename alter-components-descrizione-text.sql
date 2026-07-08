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
DROP VIEW IF EXISTS movimenti_recenti CASCADE;
DROP VIEW IF EXISTS v_movimenti_operatore_pending CASCADE;
DROP VIEW IF EXISTS v_cronologia_movimenti_operatore CASCADE;

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

-- 6. Ricrea movimenti_recenti
CREATE OR REPLACE VIEW movimenti_recenti AS
SELECT 
    im.id,
    im.tipo,
    im.quantita,
    im.quantita_precedente,
    im.quantita_attuale,
    c.nome AS componente,
    c.categoria,
    t.titolo AS task,
    u.nome || ' ' || u.cognome AS utente,
    im.motivo,
    im.created_at
FROM inventory_movements im
LEFT JOIN components c ON c.id = im.component_id
LEFT JOIN tasks t ON t.id = im.task_id
LEFT JOIN users u ON u.id = im.user_id
ORDER BY im.created_at DESC
LIMIT 100;

-- 7. Ricrea v_movimenti_operatore_pending
CREATE OR REPLACE VIEW v_movimenti_operatore_pending AS
SELECT
    mo.*,
    c.nome        AS prodotto_nome_live,
    c.codice      AS prodotto_codice_live,
    c.quantita_disponibile AS giacenza_attuale,
    c.unita_misura,
    u_op.nome     AS op_nome,
    u_op.cognome  AS op_cognome,
    u_op.email    AS op_email,
    u_adm.nome    AS admin_nome,
    u_adm.cognome AS admin_cognome
FROM movimenti_operatore mo
JOIN components c  ON c.id  = mo.prodotto_id
JOIN users u_op    ON u_op.id = mo.operatore_id
LEFT JOIN users u_adm ON u_adm.id = mo.approvato_da
ORDER BY mo.created_at DESC;

-- 8. Ricrea v_cronologia_movimenti_operatore
CREATE OR REPLACE VIEW v_cronologia_movimenti_operatore AS
SELECT
    mo.id,
    mo.created_at,
    mo.tipo,
    mo.stato,
    mo.quantita_richiesta,
    mo.quantita_effettiva,
    mo.note_operatore,
    mo.note_admin,
    mo.approvato_at,
    mo.giacenza_al_momento,
    c.nome            AS prodotto_nome,
    c.codice          AS prodotto_codice,
    c.unita_misura,
    CONCAT(u_op.nome, ' ', u_op.cognome) AS operatore_nome_completo,
    u_op.email        AS operatore_email,
    CONCAT(u_adm.nome, ' ', u_adm.cognome) AS approvato_da_nome,
    ref.created_at    AS prelievo_originale_at,
    ref.quantita_richiesta AS prelievo_originale_qty
FROM movimenti_operatore mo
JOIN components c   ON c.id   = mo.prodotto_id
JOIN users u_op     ON u_op.id = mo.operatore_id
LEFT JOIN users u_adm ON u_adm.id = mo.approvato_da
LEFT JOIN movimenti_operatore ref ON ref.id = mo.prelievo_ref_id
ORDER BY mo.created_at DESC;

-- 9. Verifica
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'components'
  AND column_name IN ('nome', 'descrizione');

SELECT 'Completato: colonne TEXT, viste ricreate' AS status;
