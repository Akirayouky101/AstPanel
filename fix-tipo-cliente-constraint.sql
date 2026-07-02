-- ============================================================
-- FIX 1: aggiorna il CHECK constraint tipo_cliente su clients
-- ============================================================

ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_tipo_cliente_check;

ALTER TABLE clients
    ADD CONSTRAINT clients_tipo_cliente_check
    CHECK (tipo_cliente IN (
        'privato',
        'azienda',
        'condominio',
        'associazione',
        'struttura',
        'comune',
        'amministratore_condominio',
        'scuola'
    ));

-- ============================================================
-- FIX 2: cambia FK azienda_id da aziende(id) a clients(id)
-- (le strutture si collegano ad un cliente di tipo azienda,
--  non alle aziende emittenti preventivi)
-- ============================================================

ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_azienda_id_fkey;

ALTER TABLE clients
    ADD CONSTRAINT clients_azienda_id_fkey
    FOREIGN KEY (azienda_id)
    REFERENCES clients(id)
    ON DELETE SET NULL;

DO $$ BEGIN
    RAISE NOTICE '✅ CHECK tipo_cliente e FK azienda_id aggiornati';
END $$;
