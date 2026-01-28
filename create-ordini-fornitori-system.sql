-- =====================================================
-- SISTEMA ORDINI FORNITORI E GESTIONE MAGAZZINO
-- =====================================================
-- Integrazione: Preventivi → Ordini → Carico → Lavorazioni
-- =====================================================

-- 1. TABELLA FORNITORI
CREATE TABLE IF NOT EXISTS fornitori (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Anagrafica
    ragione_sociale VARCHAR(200) NOT NULL,
    partita_iva VARCHAR(20),
    codice_fiscale VARCHAR(20),
    
    -- Contatti
    email VARCHAR(200),
    telefono VARCHAR(50),
    cellulare VARCHAR(50),
    pec VARCHAR(200),
    
    -- Indirizzo
    indirizzo TEXT,
    citta VARCHAR(100),
    cap VARCHAR(10),
    provincia VARCHAR(2),
    nazione VARCHAR(50) DEFAULT 'Italia',
    
    -- Dati commerciali
    codice_fornitore VARCHAR(50) UNIQUE, -- Codice interno
    categoria VARCHAR(100), -- es: "Idraulica", "Elettrico", "Edile"
    
    -- Condizioni
    giorni_consegna INTEGER DEFAULT 7, -- Tempo medio consegna
    iban VARCHAR(50),
    
    -- Note
    note TEXT,
    
    -- Metadata
    attivo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- 2. TABELLA ORDINI FORNITORE
CREATE TABLE IF NOT EXISTS ordini_fornitore (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numerazione
    numero VARCHAR(50) UNIQUE NOT NULL, -- es: "ORD-2026-001"
    
    -- Relazioni
    fornitore_id UUID REFERENCES fornitori(id) ON DELETE SET NULL,
    preventivo_id UUID REFERENCES preventivi(id) ON DELETE SET NULL, -- Collegamento al preventivo origine
    
    -- Cache fornitore (per storico)
    fornitore_nome VARCHAR(200),
    fornitore_email VARCHAR(200),
    fornitore_telefono VARCHAR(50),
    
    -- Dettagli ordine
    oggetto VARCHAR(500),
    descrizione TEXT,
    
    -- Date
    data_ordine DATE NOT NULL DEFAULT CURRENT_DATE,
    data_consegna_prevista DATE,
    data_consegna_effettiva DATE,
    
    -- Stato
    stato VARCHAR(20) NOT NULL DEFAULT 'da_ordinare',
    -- 'da_ordinare', 'ordinato', 'in_arrivo', 'ricevuto', 'parzialmente_ricevuto', 'annullato'
    
    -- Importi
    totale_ordine DECIMAL(10,2) DEFAULT 0,
    
    -- Note
    note_interne TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    
    -- Tracking
    ordinato_at TIMESTAMPTZ,
    ricevuto_at TIMESTAMPTZ
);

-- 3. TABELLA RIGHE ORDINE FORNITORE
CREATE TABLE IF NOT EXISTS ordini_fornitore_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relazioni
    ordine_id UUID NOT NULL REFERENCES ordini_fornitore(id) ON DELETE CASCADE,
    prodotto_id UUID REFERENCES components(id) ON DELETE SET NULL,
    
    -- Cache prodotto
    codice VARCHAR(100),
    descrizione TEXT NOT NULL,
    um VARCHAR(20),
    
    -- Quantità
    quantita_ordinata DECIMAL(10,2) NOT NULL DEFAULT 0,
    quantita_ricevuta DECIMAL(10,2) DEFAULT 0,
    
    -- Prezzi
    prezzo_acquisto DECIMAL(10,2) NOT NULL DEFAULT 0, -- Prezzo dal fornitore
    importo DECIMAL(10,2) DEFAULT 0,
    
    -- Stato riga
    stato VARCHAR(20) DEFAULT 'da_ricevere',
    -- 'da_ricevere', 'ricevuto', 'parzialmente_ricevuto'
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABELLA MOVIMENTI MAGAZZINO
CREATE TABLE IF NOT EXISTS movimenti_magazzino (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relazioni
    prodotto_id UUID NOT NULL REFERENCES components(id) ON DELETE CASCADE,
    ordine_fornitore_id UUID REFERENCES ordini_fornitore(id) ON DELETE SET NULL,
    lavorazione_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    
    -- Cache prodotto
    codice VARCHAR(100),
    descrizione TEXT,
    
    -- Movimento
    tipo_movimento VARCHAR(20) NOT NULL,
    -- 'carico' (da ordine fornitore), 'scarico' (per lavorazione), 'rettifica', 'inventario'
    
    quantita DECIMAL(10,2) NOT NULL, -- Positivo per carico, negativo per scarico
    giacenza_prima DECIMAL(10,2),
    giacenza_dopo DECIMAL(10,2),
    
    -- Causale
    causale TEXT, -- es: "Carico da ordine ORD-2026-001", "Scarico per lavorazione TASK-123"
    
    -- Metadata
    data_movimento TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    note TEXT
);

-- 5. AGGIUNGI CAMPO GIACENZA A COMPONENTS (se non esiste)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'components' AND column_name = 'giacenza') THEN
        ALTER TABLE components ADD COLUMN giacenza DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'components' AND column_name = 'giacenza_minima') THEN
        ALTER TABLE components ADD COLUMN giacenza_minima DECIMAL(10,2) DEFAULT 0;
    END IF;
END $$;

-- 6. AGGIUNGI CAMPI A PREVENTIVI_ITEMS PER TRACCIARE DISPONIBILITÀ
ALTER TABLE preventivi_items 
    ADD COLUMN IF NOT EXISTS giacenza_disponibile DECIMAL(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS da_ordinare BOOLEAN DEFAULT false;

-- 7. INDICI
CREATE INDEX idx_fornitori_codice ON fornitori(codice_fornitore);
CREATE INDEX idx_fornitori_categoria ON fornitori(categoria);
CREATE INDEX idx_ordini_numero ON ordini_fornitore(numero);
CREATE INDEX idx_ordini_fornitore ON ordini_fornitore(fornitore_id);
CREATE INDEX idx_ordini_preventivo ON ordini_fornitore(preventivo_id);
CREATE INDEX idx_ordini_stato ON ordini_fornitore(stato);
CREATE INDEX idx_ordini_data ON ordini_fornitore(data_ordine DESC);
CREATE INDEX idx_ordini_items_ordine ON ordini_fornitore_items(ordine_id);
CREATE INDEX idx_ordini_items_prodotto ON ordini_fornitore_items(prodotto_id);
CREATE INDEX idx_movimenti_prodotto ON movimenti_magazzino(prodotto_id);
CREATE INDEX idx_movimenti_tipo ON movimenti_magazzino(tipo_movimento);
CREATE INDEX idx_movimenti_data ON movimenti_magazzino(data_movimento DESC);

-- 8. TRIGGER per updated_at
CREATE OR REPLACE FUNCTION update_fornitori_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER fornitori_updated_at
    BEFORE UPDATE ON fornitori
    FOR EACH ROW
    EXECUTE FUNCTION update_fornitori_updated_at();

CREATE OR REPLACE FUNCTION update_ordini_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ordini_updated_at
    BEFORE UPDATE ON ordini_fornitore
    FOR EACH ROW
    EXECUTE FUNCTION update_ordini_updated_at();

-- 9. FUNZIONE: Genera numero ordine fornitore
CREATE OR REPLACE FUNCTION generate_ordine_numero()
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    anno TEXT;
    ultimo_numero INTEGER;
    nuovo_numero TEXT;
BEGIN
    anno := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;
    
    SELECT COALESCE(
        MAX(CAST(SUBSTRING(numero FROM 'ORD-' || anno || '-(\d+)') AS INTEGER)),
        0
    ) INTO ultimo_numero
    FROM ordini_fornitore
    WHERE numero LIKE 'ORD-' || anno || '-%';
    
    nuovo_numero := 'ORD-' || anno || '-' || LPAD((ultimo_numero + 1)::TEXT, 3, '0');
    
    RETURN nuovo_numero;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION generate_ordine_numero() TO authenticated;

-- 10. FUNZIONE: Carica merce in magazzino
CREATE OR REPLACE FUNCTION carica_magazzino(
    p_ordine_item_id UUID,
    p_quantita_ricevuta DECIMAL,
    p_user_id UUID
)
RETURNS void
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_prodotto_id UUID;
    v_ordine_id UUID;
    v_codice VARCHAR(100);
    v_descrizione TEXT;
    v_giacenza_attuale DECIMAL(10,2);
    v_nuova_giacenza DECIMAL(10,2);
    v_quantita_ordinata DECIMAL(10,2);
    v_quantita_gia_ricevuta DECIMAL(10,2);
    v_ordine_numero VARCHAR(50);
BEGIN
    -- Recupera dati riga ordine
    SELECT oi.prodotto_id, oi.ordine_id, oi.codice, oi.descrizione,
           oi.quantita_ordinata, oi.quantita_ricevuta
    INTO v_prodotto_id, v_ordine_id, v_codice, v_descrizione,
         v_quantita_ordinata, v_quantita_gia_ricevuta
    FROM ordini_fornitore_items oi
    WHERE oi.id = p_ordine_item_id;
    
    -- Recupera numero ordine
    SELECT numero INTO v_ordine_numero
    FROM ordini_fornitore
    WHERE id = v_ordine_id;
    
    -- Recupera giacenza attuale prodotto
    SELECT COALESCE(giacenza, 0) INTO v_giacenza_attuale
    FROM components
    WHERE id = v_prodotto_id;
    
    -- Calcola nuova giacenza
    v_nuova_giacenza := v_giacenza_attuale + p_quantita_ricevuta;
    
    -- Aggiorna giacenza prodotto
    UPDATE components
    SET giacenza = v_nuova_giacenza
    WHERE id = v_prodotto_id;
    
    -- Aggiorna quantità ricevuta nell'ordine
    UPDATE ordini_fornitore_items
    SET 
        quantita_ricevuta = v_quantita_gia_ricevuta + p_quantita_ricevuta,
        stato = CASE 
            WHEN (v_quantita_gia_ricevuta + p_quantita_ricevuta) >= v_quantita_ordinata THEN 'ricevuto'
            ELSE 'parzialmente_ricevuto'
        END
    WHERE id = p_ordine_item_id;
    
    -- Registra movimento magazzino
    INSERT INTO movimenti_magazzino (
        prodotto_id, ordine_fornitore_id, codice, descrizione,
        tipo_movimento, quantita, giacenza_prima, giacenza_dopo,
        causale, created_by
    ) VALUES (
        v_prodotto_id, v_ordine_id, v_codice, v_descrizione,
        'carico', p_quantita_ricevuta, v_giacenza_attuale, v_nuova_giacenza,
        'Carico da ordine ' || v_ordine_numero, p_user_id
    );
    
    -- Aggiorna stato ordine se tutto ricevuto
    UPDATE ordini_fornitore o
    SET stato = CASE
        WHEN EXISTS (
            SELECT 1 FROM ordini_fornitore_items oi
            WHERE oi.ordine_id = o.id AND oi.stato != 'ricevuto'
        ) THEN 'parzialmente_ricevuto'
        ELSE 'ricevuto'
    END,
    ricevuto_at = CASE
        WHEN NOT EXISTS (
            SELECT 1 FROM ordini_fornitore_items oi
            WHERE oi.ordine_id = o.id AND oi.stato != 'ricevuto'
        ) THEN NOW()
        ELSE ricevuto_at
    END
    WHERE id = v_ordine_id;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION carica_magazzino(UUID, DECIMAL, UUID) TO authenticated;

-- 11. FUNZIONE: Scarica merce per lavorazione
CREATE OR REPLACE FUNCTION scarica_magazzino(
    p_prodotto_id UUID,
    p_quantita DECIMAL,
    p_lavorazione_id UUID,
    p_user_id UUID
)
RETURNS void
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_codice VARCHAR(100);
    v_descrizione TEXT;
    v_giacenza_attuale DECIMAL(10,2);
    v_nuova_giacenza DECIMAL(10,2);
BEGIN
    -- Recupera dati prodotto
    SELECT codice, descrizione, COALESCE(giacenza, 0)
    INTO v_codice, v_descrizione, v_giacenza_attuale
    FROM components
    WHERE id = p_prodotto_id;
    
    -- Verifica disponibilità
    IF v_giacenza_attuale < p_quantita THEN
        RAISE EXCEPTION 'Giacenza insufficiente: disponibili % %', v_giacenza_attuale, 
            (SELECT um FROM components WHERE id = p_prodotto_id);
    END IF;
    
    -- Calcola nuova giacenza
    v_nuova_giacenza := v_giacenza_attuale - p_quantita;
    
    -- Aggiorna giacenza
    UPDATE components
    SET giacenza = v_nuova_giacenza
    WHERE id = p_prodotto_id;
    
    -- Registra movimento
    INSERT INTO movimenti_magazzino (
        prodotto_id, lavorazione_id, codice, descrizione,
        tipo_movimento, quantita, giacenza_prima, giacenza_dopo,
        causale, created_by
    ) VALUES (
        p_prodotto_id, p_lavorazione_id, v_codice, v_descrizione,
        'scarico', -p_quantita, v_giacenza_attuale, v_nuova_giacenza,
        'Scarico per lavorazione ID: ' || p_lavorazione_id::TEXT, p_user_id
    );
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION scarica_magazzino(UUID, DECIMAL, UUID, UUID) TO authenticated;

-- 12. FUNZIONE: Verifica disponibilità e crea ordini automatici
CREATE OR REPLACE FUNCTION verifica_disponibilita_preventivo(p_preventivo_id UUID)
RETURNS TABLE(
    prodotto_id UUID,
    codice VARCHAR,
    descrizione TEXT,
    quantita_necessaria DECIMAL,
    giacenza_disponibile DECIMAL,
    da_ordinare DECIMAL
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pi.prodotto_id,
        pi.codice,
        pi.descrizione,
        pi.quantita as quantita_necessaria,
        COALESCE(c.giacenza, 0) as giacenza_disponibile,
        GREATEST(pi.quantita - COALESCE(c.giacenza, 0), 0) as da_ordinare
    FROM preventivi_items pi
    LEFT JOIN components c ON c.id = pi.prodotto_id
    WHERE pi.preventivo_id = p_preventivo_id;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION verifica_disponibilita_preventivo(UUID) TO authenticated;

-- 13. RLS POLICIES
ALTER TABLE fornitori ENABLE ROW LEVEL SECURITY;
ALTER TABLE ordini_fornitore ENABLE ROW LEVEL SECURITY;
ALTER TABLE ordini_fornitore_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimenti_magazzino ENABLE ROW LEVEL SECURITY;

-- Fornitori
DROP POLICY IF EXISTS "fornitori_select_all" ON fornitori;
CREATE POLICY "fornitori_select_all" ON fornitori FOR SELECT USING (true);

DROP POLICY IF EXISTS "fornitori_insert_auth" ON fornitori;
CREATE POLICY "fornitori_insert_auth" ON fornitori FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "fornitori_update_auth" ON fornitori;
CREATE POLICY "fornitori_update_auth" ON fornitori FOR UPDATE USING (true);

DROP POLICY IF EXISTS "fornitori_delete_auth" ON fornitori;
CREATE POLICY "fornitori_delete_auth" ON fornitori FOR DELETE USING (true);

-- Ordini
DROP POLICY IF EXISTS "ordini_select_all" ON ordini_fornitore;
CREATE POLICY "ordini_select_all" ON ordini_fornitore FOR SELECT USING (true);

DROP POLICY IF EXISTS "ordini_insert_auth" ON ordini_fornitore;
CREATE POLICY "ordini_insert_auth" ON ordini_fornitore FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "ordini_update_auth" ON ordini_fornitore;
CREATE POLICY "ordini_update_auth" ON ordini_fornitore FOR UPDATE USING (true);

DROP POLICY IF EXISTS "ordini_delete_auth" ON ordini_fornitore;
CREATE POLICY "ordini_delete_auth" ON ordini_fornitore FOR DELETE USING (true);

-- Ordini Items
DROP POLICY IF EXISTS "ordini_items_select_all" ON ordini_fornitore_items;
CREATE POLICY "ordini_items_select_all" ON ordini_fornitore_items FOR SELECT USING (true);

DROP POLICY IF EXISTS "ordini_items_insert_auth" ON ordini_fornitore_items;
CREATE POLICY "ordini_items_insert_auth" ON ordini_fornitore_items FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "ordini_items_update_auth" ON ordini_fornitore_items;
CREATE POLICY "ordini_items_update_auth" ON ordini_fornitore_items FOR UPDATE USING (true);

DROP POLICY IF EXISTS "ordini_items_delete_auth" ON ordini_fornitore_items;
CREATE POLICY "ordini_items_delete_auth" ON ordini_fornitore_items FOR DELETE USING (true);

-- Movimenti
DROP POLICY IF EXISTS "movimenti_select_all" ON movimenti_magazzino;
CREATE POLICY "movimenti_select_all" ON movimenti_magazzino FOR SELECT USING (true);

DROP POLICY IF EXISTS "movimenti_insert_auth" ON movimenti_magazzino;
CREATE POLICY "movimenti_insert_auth" ON movimenti_magazzino FOR INSERT WITH CHECK (true);

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ SISTEMA ORDINI FORNITORI CREATO!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Tabelle create:';
    RAISE NOTICE '  • fornitori (anagrafica fornitori)';
    RAISE NOTICE '  • ordini_fornitore (testata ordini)';
    RAISE NOTICE '  • ordini_fornitore_items (righe ordini)';
    RAISE NOTICE '  • movimenti_magazzino (storico carichi/scarichi)';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Campi aggiunti a components:';
    RAISE NOTICE '  • giacenza (quantità disponibile)';
    RAISE NOTICE '  • giacenza_minima (scorta minima)';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Funzioni disponibili:';
    RAISE NOTICE '  • generate_ordine_numero() - Numerazione automatica';
    RAISE NOTICE '  • carica_magazzino() - Carico merce da ordine';
    RAISE NOTICE '  • scarica_magazzino() - Scarico per lavorazione';
    RAISE NOTICE '  • verifica_disponibilita_preventivo() - Controllo giacenze';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Workflow completo:';
    RAISE NOTICE '  Preventivo → Verifica giacenze → Ordine fornitore';
    RAISE NOTICE '  → Carico magazzino → Lavorazione → Scarico magazzino';
    RAISE NOTICE '';
END $$;
