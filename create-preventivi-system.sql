-- =====================================================
-- SISTEMA GESTIONE PREVENTIVI
-- =====================================================
-- Preventivi veloci collegati al magazzino prodotti
-- =====================================================

-- 1. TABELLA PREVENTIVI
CREATE TABLE IF NOT EXISTS preventivi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numerazione
    numero VARCHAR(50) UNIQUE NOT NULL, -- es: "PREV-2026-001"
    
    -- Cliente
    cliente_id UUID REFERENCES clienti(id) ON DELETE SET NULL,
    cliente_nome VARCHAR(200), -- Cache per storico
    cliente_email VARCHAR(200),
    cliente_telefono VARCHAR(50),
    cliente_indirizzo TEXT,
    
    -- Dettagli preventivo
    oggetto VARCHAR(500), -- "Fornitura materiale idraulico"
    descrizione TEXT,
    
    -- Importi
    subtotale DECIMAL(10,2) DEFAULT 0,
    sconto_percentuale DECIMAL(5,2) DEFAULT 0,
    sconto_importo DECIMAL(10,2) DEFAULT 0,
    iva_percentuale DECIMAL(5,2) DEFAULT 22,
    totale_iva DECIMAL(10,2) DEFAULT 0,
    totale DECIMAL(10,2) DEFAULT 0,
    
    -- Date
    data_emissione DATE NOT NULL DEFAULT CURRENT_DATE,
    data_validita DATE, -- Scadenza preventivo
    
    -- Stato
    stato VARCHAR(20) NOT NULL DEFAULT 'bozza', 
    -- 'bozza', 'inviato', 'accettato', 'rifiutato', 'scaduto'
    
    -- Note
    note_interne TEXT, -- Visibili solo internamente
    note_cliente TEXT, -- Visibili nel preventivo
    condizioni_pagamento TEXT, -- es: "30 giorni data fattura"
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    
    -- Tracking
    inviato_at TIMESTAMPTZ,
    accettato_at TIMESTAMPTZ,
    rifiutato_at TIMESTAMPTZ
);

-- 2. TABELLA RIGHE PREVENTIVO
CREATE TABLE IF NOT EXISTS preventivi_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relazioni
    preventivo_id UUID NOT NULL REFERENCES preventivi(id) ON DELETE CASCADE,
    prodotto_id UUID REFERENCES prodotti(id) ON DELETE SET NULL,
    
    -- Dati prodotto (cache per storico)
    codice VARCHAR(100),
    descrizione TEXT NOT NULL,
    um VARCHAR(20), -- Unità di misura
    
    -- Quantità e prezzi
    quantita DECIMAL(10,2) NOT NULL DEFAULT 1,
    prezzo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    sconto_percentuale DECIMAL(5,2) DEFAULT 0,
    importo DECIMAL(10,2) NOT NULL DEFAULT 0, -- (quantita * prezzo_unitario) - sconto
    
    -- Ordinamento
    posizione INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. INDICI
CREATE INDEX idx_preventivi_numero ON preventivi(numero);
CREATE INDEX idx_preventivi_cliente ON preventivi(cliente_id);
CREATE INDEX idx_preventivi_stato ON preventivi(stato);
CREATE INDEX idx_preventivi_data_emissione ON preventivi(data_emissione DESC);
CREATE INDEX idx_preventivi_created_by ON preventivi(created_by);
CREATE INDEX idx_preventivi_items_preventivo ON preventivi_items(preventivo_id);
CREATE INDEX idx_preventivi_items_prodotto ON preventivi_items(prodotto_id);

-- 4. TRIGGER per updated_at
CREATE OR REPLACE FUNCTION update_preventivi_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER preventivi_updated_at
    BEFORE UPDATE ON preventivi
    FOR EACH ROW
    EXECUTE FUNCTION update_preventivi_updated_at();

-- 5. FUNZIONE: Genera numero preventivo automatico
CREATE OR REPLACE FUNCTION generate_preventivo_numero()
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
    
    -- Trova l'ultimo numero dell'anno corrente
    SELECT COALESCE(
        MAX(CAST(SUBSTRING(numero FROM 'PREV-' || anno || '-(\d+)') AS INTEGER)),
        0
    ) INTO ultimo_numero
    FROM preventivi
    WHERE numero LIKE 'PREV-' || anno || '-%';
    
    -- Genera nuovo numero
    nuovo_numero := 'PREV-' || anno || '-' || LPAD((ultimo_numero + 1)::TEXT, 3, '0');
    
    RETURN nuovo_numero;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION generate_preventivo_numero() TO authenticated;

-- 6. FUNZIONE: Calcola totali preventivo
CREATE OR REPLACE FUNCTION calcola_totali_preventivo(p_preventivo_id UUID)
RETURNS void
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_subtotale DECIMAL(10,2);
    v_sconto_importo DECIMAL(10,2);
    v_imponibile DECIMAL(10,2);
    v_iva DECIMAL(10,2);
    v_totale DECIMAL(10,2);
    v_sconto_perc DECIMAL(5,2);
    v_iva_perc DECIMAL(5,2);
BEGIN
    -- Recupera dati preventivo
    SELECT sconto_percentuale, iva_percentuale
    INTO v_sconto_perc, v_iva_perc
    FROM preventivi
    WHERE id = p_preventivo_id;
    
    -- Calcola subtotale dalle righe
    SELECT COALESCE(SUM(importo), 0)
    INTO v_subtotale
    FROM preventivi_items
    WHERE preventivo_id = p_preventivo_id;
    
    -- Calcola sconto
    v_sconto_importo := ROUND((v_subtotale * v_sconto_perc / 100), 2);
    v_imponibile := v_subtotale - v_sconto_importo;
    
    -- Calcola IVA
    v_iva := ROUND((v_imponibile * v_iva_perc / 100), 2);
    v_totale := v_imponibile + v_iva;
    
    -- Aggiorna preventivo
    UPDATE preventivi
    SET 
        subtotale = v_subtotale,
        sconto_importo = v_sconto_importo,
        totale_iva = v_iva,
        totale = v_totale
    WHERE id = p_preventivo_id;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION calcola_totali_preventivo(UUID) TO authenticated;

-- 7. TRIGGER: Ricalcola totali quando cambiano le righe
CREATE OR REPLACE FUNCTION trigger_ricalcola_totali()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM calcola_totali_preventivo(OLD.preventivo_id);
    ELSE
        PERFORM calcola_totali_preventivo(NEW.preventivo_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER preventivi_items_update_totals
    AFTER INSERT OR UPDATE OR DELETE ON preventivi_items
    FOR EACH ROW
    EXECUTE FUNCTION trigger_ricalcola_totali();

-- 8. RLS POLICIES
ALTER TABLE preventivi ENABLE ROW LEVEL SECURITY;
ALTER TABLE preventivi_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "preventivi_select_all" ON preventivi;
CREATE POLICY "preventivi_select_all" ON preventivi
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "preventivi_insert_auth" ON preventivi;
CREATE POLICY "preventivi_insert_auth" ON preventivi
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "preventivi_update_auth" ON preventivi;
CREATE POLICY "preventivi_update_auth" ON preventivi
    FOR UPDATE USING (true);

DROP POLICY IF EXISTS "preventivi_delete_auth" ON preventivi;
CREATE POLICY "preventivi_delete_auth" ON preventivi
    FOR DELETE USING (true);

-- Items policies
DROP POLICY IF EXISTS "preventivi_items_select_all" ON preventivi_items;
CREATE POLICY "preventivi_items_select_all" ON preventivi_items
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "preventivi_items_insert_auth" ON preventivi_items;
CREATE POLICY "preventivi_items_insert_auth" ON preventivi_items
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "preventivi_items_update_auth" ON preventivi_items;
CREATE POLICY "preventivi_items_update_auth" ON preventivi_items
    FOR UPDATE USING (true);

DROP POLICY IF EXISTS "preventivi_items_delete_auth" ON preventivi_items;
CREATE POLICY "preventivi_items_delete_auth" ON preventivi_items
    FOR DELETE USING (true);

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ SISTEMA PREVENTIVI CREATO!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Tabelle create:';
    RAISE NOTICE '  • preventivi (testata)';
    RAISE NOTICE '  • preventivi_items (righe dettaglio)';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Funzioni disponibili:';
    RAISE NOTICE '  • generate_preventivo_numero() - Numerazione automatica';
    RAISE NOTICE '  • calcola_totali_preventivo(id) - Calcolo totali';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Funzionalità:';
    RAISE NOTICE '  • Numerazione automatica PREV-YYYY-NNN';
    RAISE NOTICE '  • Collegamento a clienti e prodotti magazzino';
    RAISE NOTICE '  • Calcolo automatico totali con IVA e sconti';
    RAISE NOTICE '  • Stati: bozza, inviato, accettato, rifiutato, scaduto';
    RAISE NOTICE '  • Cache dati cliente/prodotti per storico';
    RAISE NOTICE '';
    RAISE NOTICE '📱 Prossimo step: creare interfaccia UI';
    RAISE NOTICE '';
END $$;
