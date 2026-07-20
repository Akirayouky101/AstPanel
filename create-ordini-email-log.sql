-- =====================================================
-- Registro invii email per ordini fornitore
-- Traccia: chi ha ricevuto, quando, eventuali CC
-- =====================================================

CREATE TABLE IF NOT EXISTS ordini_email_log (
    id              uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
    ordine_id       uuid        NOT NULL REFERENCES ordini_fornitore(id) ON DELETE CASCADE,
    ordine_numero   text        NOT NULL,
    destinatari     jsonb       NOT NULL,   -- array di stringhe email (campo "to")
    cc              text,                   -- email CC opzionale aggiunta manualmente
    inviato_da      uuid        REFERENCES auth.users(id),
    inviato_da_nome text,
    inviato_il      timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_email_log_ordine_id ON ordini_email_log(ordine_id);
CREATE INDEX IF NOT EXISTS idx_email_log_inviato_il ON ordini_email_log(inviato_il DESC);

-- RLS: solo gli autenticati possono leggere/scrivere
ALTER TABLE ordini_email_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can manage email log" ON ordini_email_log;
CREATE POLICY "Authenticated users can manage email log"
    ON ordini_email_log
    FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

SELECT 'Tabella ordini_email_log creata' AS status;
