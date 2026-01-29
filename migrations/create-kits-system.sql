-- ============================================
-- SISTEMA KIT COMPONENTI
-- ============================================
-- Descrizione: Sistema gestione kit/pacchi con componenti, tracking consegne, doppio QR
-- Data: 2026-01-29
-- ============================================

-- Tabella principale KIT
CREATE TABLE IF NOT EXISTS kits (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    codice_kit varchar(50) UNIQUE NOT NULL, -- Codice univoco per QR identificativo
    nome_kit varchar(255) NOT NULL,
    descrizione text,
    
    -- Destinatario
    destinatario_tipo varchar(20) NOT NULL, -- 'cliente', 'dipendente', 'altro'
    cliente_id uuid REFERENCES clients(id) ON DELETE SET NULL,
    dipendente_id uuid REFERENCES users(auth_id) ON DELETE SET NULL,
    destinatario_altro varchar(255), -- Se tipo = 'altro'
    
    -- Stati
    stato varchar(20) NOT NULL DEFAULT 'preparazione', -- preparazione, pronto, consegnato, annullato
    
    -- QR Codes
    qr_kit text NOT NULL, -- QR per identificare kit (codice_kit)
    qr_consegna text NOT NULL, -- QR per conferma consegna (codice_consegna univoco)
    codice_consegna varchar(50) UNIQUE NOT NULL, -- Codice per QR consegna
    
    -- Consegna
    consegnato_a timestamp with time zone,
    consegnato_da_user uuid REFERENCES auth.users(id),
    consegnato_da_nome varchar(255), -- Nome di chi ha scansionato
    consegna_latitudine decimal(10, 8),
    consegna_longitudine decimal(11, 8),
    note_consegna text,
    
    -- Audit
    created_by uuid REFERENCES auth.users(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Tabella componenti del kit
CREATE TABLE IF NOT EXISTS kit_items (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    kit_id uuid NOT NULL REFERENCES kits(id) ON DELETE CASCADE,
    prodotto_id uuid NOT NULL REFERENCES prodotti(id) ON DELETE RESTRICT,
    quantita decimal(10, 2) NOT NULL DEFAULT 1,
    
    -- Info prodotto al momento dell'aggiunta (snapshot)
    prodotto_nome varchar(255),
    prodotto_codice varchar(100),
    prodotto_barcode varchar(100),
    
    -- Audit
    aggiunto_da uuid REFERENCES auth.users(id),
    aggiunto_il timestamp with time zone DEFAULT now(),
    
    CONSTRAINT kit_items_quantita_positiva CHECK (quantita > 0)
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_kits_codice ON kits(codice_kit);
CREATE INDEX IF NOT EXISTS idx_kits_codice_consegna ON kits(codice_consegna);
CREATE INDEX IF NOT EXISTS idx_kits_stato ON kits(stato);
CREATE INDEX IF NOT EXISTS idx_kits_destinatario_tipo ON kits(destinatario_tipo);
CREATE INDEX IF NOT EXISTS idx_kits_cliente ON kits(cliente_id) WHERE cliente_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_kits_dipendente ON kits(dipendente_id) WHERE dipendente_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_kit_items_kit ON kit_items(kit_id);
CREATE INDEX IF NOT EXISTS idx_kit_items_prodotto ON kit_items(prodotto_id);

-- RLS Policies
ALTER TABLE kits ENABLE ROW LEVEL SECURITY;
ALTER TABLE kit_items ENABLE ROW LEVEL SECURITY;

-- Policy KIT: Utenti autenticati possono vedere tutti i kit
CREATE POLICY "Utenti autenticati possono vedere kit"
    ON kits FOR SELECT
    TO authenticated
    USING (true);

-- Policy KIT: Utenti autenticati possono creare kit
CREATE POLICY "Utenti autenticati possono creare kit"
    ON kits FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy KIT: Utenti autenticati possono aggiornare kit
CREATE POLICY "Utenti autenticati possono aggiornare kit"
    ON kits FOR UPDATE
    TO authenticated
    USING (true);

-- Policy KIT: Solo admin possono eliminare kit
CREATE POLICY "Admin possono eliminare kit"
    ON kits FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE auth_id = auth.uid() 
            AND ruolo IN ('admin', 'superadmin')
        )
    );

-- Policy KIT_ITEMS: Utenti autenticati possono vedere componenti
CREATE POLICY "Utenti autenticati possono vedere componenti kit"
    ON kit_items FOR SELECT
    TO authenticated
    USING (true);

-- Policy KIT_ITEMS: Utenti autenticati possono aggiungere componenti
CREATE POLICY "Utenti autenticati possono aggiungere componenti kit"
    ON kit_items FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy KIT_ITEMS: Utenti autenticati possono aggiornare componenti
CREATE POLICY "Utenti autenticati possono aggiornare componenti kit"
    ON kit_items FOR UPDATE
    TO authenticated
    USING (true);

-- Policy KIT_ITEMS: Utenti autenticati possono eliminare componenti
CREATE POLICY "Utenti autenticati possono eliminare componenti kit"
    ON kit_items FOR DELETE
    TO authenticated
    USING (true);

-- Trigger updated_at per kits
CREATE OR REPLACE FUNCTION update_kits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_kits_updated_at
    BEFORE UPDATE ON kits
    FOR EACH ROW
    EXECUTE FUNCTION update_kits_updated_at();

-- Funzione generazione codice kit univoco
CREATE OR REPLACE FUNCTION genera_codice_kit()
RETURNS varchar(50) AS $$
DECLARE
    nuovo_codice varchar(50);
    esiste boolean;
BEGIN
    LOOP
        -- Genera codice: KIT-YYYYMMDD-XXXXX
        nuovo_codice := 'KIT-' || TO_CHAR(now(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 99999)::TEXT, 5, '0');
        
        -- Verifica unicità
        SELECT EXISTS(SELECT 1 FROM kits WHERE codice_kit = nuovo_codice) INTO esiste;
        
        EXIT WHEN NOT esiste;
    END LOOP;
    
    RETURN nuovo_codice;
END;
$$ LANGUAGE plpgsql;

-- Funzione generazione codice consegna univoco
CREATE OR REPLACE FUNCTION genera_codice_consegna()
RETURNS varchar(50) AS $$
DECLARE
    nuovo_codice varchar(50);
    esiste boolean;
BEGIN
    LOOP
        -- Genera codice: CONS-YYYYMMDD-XXXXX
        nuovo_codice := 'CONS-' || TO_CHAR(now(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 99999)::TEXT, 5, '0');
        
        -- Verifica unicità
        SELECT EXISTS(SELECT 1 FROM kits WHERE codice_consegna = nuovo_codice) INTO esiste;
        
        EXIT WHEN NOT esiste;
    END LOOP;
    
    RETURN nuovo_codice;
END;
$$ LANGUAGE plpgsql;

-- Trigger auto-generazione codici QR alla creazione kit
CREATE OR REPLACE FUNCTION auto_genera_codici_kit()
RETURNS TRIGGER AS $$
BEGIN
    -- Genera codice_kit se non fornito
    IF NEW.codice_kit IS NULL OR NEW.codice_kit = '' THEN
        NEW.codice_kit := genera_codice_kit();
    END IF;
    
    -- Genera codice_consegna se non fornito
    IF NEW.codice_consegna IS NULL OR NEW.codice_consegna = '' THEN
        NEW.codice_consegna := genera_codice_consegna();
    END IF;
    
    -- Genera QR kit (usa codice_kit)
    IF NEW.qr_kit IS NULL OR NEW.qr_kit = '' THEN
        NEW.qr_kit := NEW.codice_kit;
    END IF;
    
    -- Genera QR consegna (usa codice_consegna)
    IF NEW.qr_consegna IS NULL OR NEW.qr_consegna = '' THEN
        NEW.qr_consegna := NEW.codice_consegna;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_genera_codici_kit
    BEFORE INSERT ON kits
    FOR EACH ROW
    EXECUTE FUNCTION auto_genera_codici_kit();

-- Trigger: Scala giacenza quando aggiungi prodotto a kit
CREATE OR REPLACE FUNCTION scala_giacenza_kit()
RETURNS TRIGGER AS $$
BEGIN
    -- Scala giacenza dal magazzino
    UPDATE prodotti 
    SET giacenza = giacenza - NEW.quantita
    WHERE id = NEW.prodotto_id;
    
    -- Registra movimento magazzino
    INSERT INTO movimenti_magazzino (
        prodotto_id,
        tipo_movimento,
        quantita,
        causale,
        riferimento_tipo,
        riferimento_id,
        eseguito_da
    ) VALUES (
        NEW.prodotto_id,
        'uscita',
        NEW.quantita,
        'Aggiunto a kit',
        'kit',
        NEW.kit_id,
        NEW.aggiunto_da
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_scala_giacenza_kit
    AFTER INSERT ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION scala_giacenza_kit();

-- Trigger: Ripristina giacenza quando rimuovi prodotto da kit (solo se non consegnato)
CREATE OR REPLACE FUNCTION ripristina_giacenza_kit()
RETURNS TRIGGER AS $$
DECLARE
    kit_stato varchar(20);
BEGIN
    -- Verifica stato kit
    SELECT stato INTO kit_stato FROM kits WHERE id = OLD.kit_id;
    
    -- Ripristina solo se kit non è consegnato
    IF kit_stato != 'consegnato' THEN
        UPDATE prodotti 
        SET giacenza = giacenza + OLD.quantita
        WHERE id = OLD.prodotto_id;
        
        -- Registra movimento magazzino
        INSERT INTO movimenti_magazzino (
            prodotto_id,
            tipo_movimento,
            quantita,
            causale,
            riferimento_tipo,
            riferimento_id,
            eseguito_da
        ) VALUES (
            OLD.prodotto_id,
            'entrata',
            OLD.quantita,
            'Rimosso da kit',
            'kit',
            OLD.kit_id,
            auth.uid()
        );
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ripristina_giacenza_kit
    BEFORE DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION ripristina_giacenza_kit();

-- View completa kits con dettagli
CREATE OR REPLACE VIEW v_kits_completi AS
SELECT 
    k.*,
    
    -- Creatore
    CONCAT(u_created.nome, ' ', u_created.cognome) as creato_da_nome,
    
    -- Destinatario info
    CASE 
        WHEN k.destinatario_tipo = 'cliente' THEN c.ragione_sociale
        WHEN k.destinatario_tipo = 'dipendente' THEN CONCAT(u_dest.nome, ' ', u_dest.cognome)
        ELSE k.destinatario_altro
    END as destinatario_nome,
    
    CASE 
        WHEN k.destinatario_tipo = 'cliente' THEN c.email
        WHEN k.destinatario_tipo = 'dipendente' THEN u_dest.email
        ELSE NULL
    END as destinatario_email,
    
    -- Statistiche componenti
    COUNT(DISTINCT ki.id) as numero_componenti,
    SUM(ki.quantita) as quantita_totale,
    
    -- Chi ha consegnato
    COALESCE(k.consegnato_da_nome, CONCAT(u_consegna.nome, ' ', u_consegna.cognome)) as consegnato_da_nome_completo

FROM kits k
LEFT JOIN users u_created ON k.created_by = u_created.auth_id
LEFT JOIN clients c ON k.cliente_id = c.id
LEFT JOIN users u_dest ON k.dipendente_id = u_dest.auth_id
LEFT JOIN users u_consegna ON k.consegnato_da_user = u_consegna.auth_id
LEFT JOIN kit_items ki ON k.id = ki.kit_id
GROUP BY 
    k.id, 
    u_created.nome, u_created.cognome,
    c.ragione_sociale, c.email,
    u_dest.nome, u_dest.cognome, u_dest.email,
    u_consegna.nome, u_consegna.cognome
ORDER BY k.created_at DESC;

-- View dettaglio componenti kit
CREATE OR REPLACE VIEW v_kit_items_dettaglio AS
SELECT 
    ki.*,
    p.descrizione as prodotto_descrizione_corrente,
    p.codice as prodotto_codice_corrente,
    p.barcode as prodotto_barcode_corrente,
    p.giacenza as prodotto_giacenza_corrente,
    CONCAT(u.nome, ' ', u.cognome) as aggiunto_da_nome,
    k.codice_kit,
    k.stato as kit_stato
FROM kit_items ki
JOIN prodotti p ON ki.prodotto_id = p.id
LEFT JOIN users u ON ki.aggiunto_da = u.auth_id
JOIN kits k ON ki.kit_id = k.id
ORDER BY ki.aggiunto_il DESC;

-- Commenti
COMMENT ON TABLE kits IS 'Kit/Pacchi di componenti da consegnare a clienti/dipendenti';
COMMENT ON TABLE kit_items IS 'Componenti contenuti in ogni kit';
COMMENT ON COLUMN kits.codice_kit IS 'Codice univoco per QR identificativo kit (KIT-YYYYMMDD-XXXXX)';
COMMENT ON COLUMN kits.codice_consegna IS 'Codice univoco per QR conferma consegna (CONS-YYYYMMDD-XXXXX)';
COMMENT ON COLUMN kits.qr_kit IS 'Dati QR per identificare kit (codice_kit)';
COMMENT ON COLUMN kits.qr_consegna IS 'Dati QR per confermare consegna (codice_consegna)';
COMMENT ON COLUMN kits.stato IS 'Stati: preparazione, pronto, consegnato, annullato';
COMMENT ON COLUMN kits.destinatario_tipo IS 'Tipo destinatario: cliente, dipendente, altro';

-- ============================================
-- FINE MIGRATION
-- ============================================
