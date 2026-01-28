-- =====================================================
-- TABELLA CLIENTI
-- =====================================================
-- Gestione anagrafica clienti
-- =====================================================

CREATE TABLE IF NOT EXISTS clienti (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Tipo cliente
    tipo VARCHAR(20) NOT NULL DEFAULT 'privato', -- 'privato', 'azienda'
    
    -- Dati anagrafici (privato)
    nome VARCHAR(100),
    cognome VARCHAR(100),
    codice_fiscale VARCHAR(16),
    
    -- Dati azienda
    ragione_sociale VARCHAR(200),
    partita_iva VARCHAR(11),
    codice_destinatario VARCHAR(7), -- SDI
    pec VARCHAR(200),
    
    -- Contatti
    email VARCHAR(200),
    telefono VARCHAR(50),
    cellulare VARCHAR(50),
    
    -- Indirizzo
    indirizzo TEXT,
    citta VARCHAR(100),
    provincia VARCHAR(2),
    cap VARCHAR(5),
    nazione VARCHAR(50) DEFAULT 'Italia',
    
    -- Note
    note TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- Indici
CREATE INDEX idx_clienti_tipo ON clienti(tipo);
CREATE INDEX idx_clienti_ragione_sociale ON clienti(ragione_sociale);
CREATE INDEX idx_clienti_cognome ON clienti(cognome);
CREATE INDEX idx_clienti_email ON clienti(email);
CREATE INDEX idx_clienti_partita_iva ON clienti(partita_iva);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION update_clienti_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clienti_updated_at
    BEFORE UPDATE ON clienti
    FOR EACH ROW
    EXECUTE FUNCTION update_clienti_updated_at();

-- RLS Policies
ALTER TABLE clienti ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "clienti_select_all" ON clienti;
CREATE POLICY "clienti_select_all" ON clienti
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "clienti_insert_auth" ON clienti;
CREATE POLICY "clienti_insert_auth" ON clienti
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "clienti_update_auth" ON clienti;
CREATE POLICY "clienti_update_auth" ON clienti
    FOR UPDATE USING (true);

DROP POLICY IF EXISTS "clienti_delete_auth" ON clienti;
CREATE POLICY "clienti_delete_auth" ON clienti
    FOR DELETE USING (true);

-- Seed data esempi
INSERT INTO clienti (tipo, nome, cognome, email, telefono, indirizzo, citta, cap) VALUES
('privato', 'Mario', 'Rossi', 'mario.rossi@example.com', '333-1234567', 'Via Roma 1', 'Milano', '20100'),
('privato', 'Luigi', 'Bianchi', 'luigi.bianchi@example.com', '333-7654321', 'Via Verdi 10', 'Roma', '00100'),
('azienda', NULL, NULL, 'info@acmesrl.it', '02-12345678', 'Via Dante 50', 'Milano', '20121')
ON CONFLICT DO NOTHING;

UPDATE clienti 
SET ragione_sociale = 'ACME S.r.l.', partita_iva = '12345678901'
WHERE email = 'info@acmesrl.it';

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ TABELLA CLIENTI CREATA!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Campi principali:';
    RAISE NOTICE '  • Tipo (privato/azienda)';
    RAISE NOTICE '  • Dati anagrafici completi';
    RAISE NOTICE '  • Partita IVA, Codice Fiscale';
    RAISE NOTICE '  • SDI e PEC per fatturazione elettronica';
    RAISE NOTICE '  • Indirizzo completo';
    RAISE NOTICE '';
    RAISE NOTICE '📝 Dati esempio inseriti:';
    RAISE NOTICE '  • Mario Rossi (privato)';
    RAISE NOTICE '  • Luigi Bianchi (privato)';
    RAISE NOTICE '  • ACME S.r.l. (azienda)';
    RAISE NOTICE '';
END $$;
