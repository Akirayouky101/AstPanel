-- ============================================================
-- ROLLBACK: riporta il CHECK constraint di preventivi
-- agli stati originali (senza 'ricevuto')
-- Il stato 'ricevuto' appartiene agli Ordini Fornitori, non ai preventivi.
-- ============================================================

ALTER TABLE preventivi DROP CONSTRAINT IF EXISTS preventivi_stato_check;

ALTER TABLE preventivi
    ADD CONSTRAINT preventivi_stato_check
    CHECK (stato IN ('bozza', 'inviato', 'accettato', 'rifiutato', 'scaduto'));

DO $$ BEGIN
    RAISE NOTICE '✅ CHECK constraint preventivi ripristinato (rimosso "ricevuto")';
END $$;
