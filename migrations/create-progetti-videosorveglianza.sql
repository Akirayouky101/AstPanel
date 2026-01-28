-- =====================================================
-- SISTEMA PROGETTI VIDEOSORVEGLIANZA
-- Data: 28 gennaio 2026
-- Descrizione: Gestione progetti con planimetrie disegnabili
--              Editor integrato (Grid + Canvas) + Upload
-- =====================================================

-- 1. TABELLA PROGETTI
-- =====================================================

CREATE TABLE IF NOT EXISTS progetti (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Numerazione automatica
    numero VARCHAR(50) UNIQUE NOT NULL, -- es: "PROG-2026-001"
    
    -- Dati progetto
    nome VARCHAR(200) NOT NULL,
    tipologia VARCHAR(50) DEFAULT 'Videosorveglianza', 
    -- 'Videosorveglianza', 'Allarme', 'Controllo Accessi', 'Rete Dati', 'Citofonia', 'Automazione'
    
    -- Cliente
    cliente_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    cliente_nome VARCHAR(200),
    
    -- Indirizzo installazione
    indirizzo_installazione TEXT,
    citta VARCHAR(100),
    cap VARCHAR(10),
    
    -- Date
    data_creazione DATE NOT NULL DEFAULT CURRENT_DATE,
    data_prevista_installazione DATE,
    data_completamento DATE,
    
    -- Stato
    stato VARCHAR(50) DEFAULT 'preventivo',
    -- 'preventivo', 'approvato', 'in_corso', 'completato', 'annullato'
    
    -- Costi
    costo_materiali DECIMAL(10,2) DEFAULT 0,
    costo_manodopera DECIMAL(10,2) DEFAULT 0,
    ore_previste DECIMAL(5,2) DEFAULT 0,
    costo_orario DECIMAL(8,2) DEFAULT 35, -- €/ora default
    costi_extra DECIMAL(10,2) DEFAULT 0, -- trasferte, noleggi, ecc.
    totale_preventivato DECIMAL(10,2) DEFAULT 0,
    totale_consuntivo DECIMAL(10,2) DEFAULT 0,
    
    -- Planimetria
    planimetria_tipo VARCHAR(20), -- 'upload', 'grid', 'canvas'
    planimetria_url TEXT, -- URL file uploadato (se upload)
    planimetria_data JSONB, -- Dati grid/canvas salvati come JSON
    
    -- Note
    descrizione TEXT,
    note_tecniche TEXT,
    note_installazione TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- 2. TABELLA COMPONENTI PROGETTO
-- =====================================================

CREATE TABLE IF NOT EXISTS progetti_componenti (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    progetto_id UUID NOT NULL REFERENCES progetti(id) ON DELETE CASCADE,
    componente_id UUID REFERENCES components(id) ON DELETE SET NULL,
    
    -- Dati componente (cache)
    codice VARCHAR(100),
    descrizione TEXT NOT NULL,
    categoria VARCHAR(100),
    
    -- Quantità e prezzi
    quantita DECIMAL(10,2) NOT NULL DEFAULT 1,
    um VARCHAR(20) DEFAULT 'pz',
    prezzo_acquisto DECIMAL(10,2) DEFAULT 0,
    prezzo_vendita DECIMAL(10,2) DEFAULT 0,
    totale DECIMAL(10,2) DEFAULT 0,
    
    -- Posizione in planimetria (se applicabile)
    posizione_x INTEGER, -- Coordinate X sulla mappa
    posizione_y INTEGER, -- Coordinate Y sulla mappa
    note_posizione TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABELLA DISPOSITIVI/TELECAMERE
-- =====================================================

CREATE TABLE IF NOT EXISTS progetti_dispositivi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    progetto_id UUID NOT NULL REFERENCES progetti(id) ON DELETE CASCADE,
    componente_id UUID REFERENCES components(id) ON DELETE SET NULL,
    
    -- Identificativo
    codice_dispositivo VARCHAR(50), -- es: "CAM-01", "CAM-02"
    nome VARCHAR(100), -- es: "Telecamera Ingresso"
    tipo VARCHAR(50), -- 'telecamera', 'nvr', 'sensore', 'sirena', 'lettore'
    
    -- Posizione planimetria
    pos_x INTEGER NOT NULL,
    pos_y INTEGER NOT NULL,
    
    -- Specifiche tecniche
    angolo_visuale INTEGER DEFAULT 90, -- gradi
    direzione INTEGER DEFAULT 0, -- 0-359 gradi
    altezza_installazione DECIMAL(5,2), -- metri
    note_installazione TEXT,
    
    -- Cablaggio
    cavo_tipo VARCHAR(50), -- 'UTP Cat6', 'Coassiale', 'Fibra'
    cavo_metri DECIMAL(6,2), -- lunghezza cavo
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABELLA CHECKLIST INSTALLAZIONE
-- =====================================================

CREATE TABLE IF NOT EXISTS progetti_checklist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    progetto_id UUID NOT NULL REFERENCES progetti(id) ON DELETE CASCADE,
    
    -- Item checklist
    descrizione TEXT NOT NULL,
    completato BOOLEAN DEFAULT false,
    completato_da UUID REFERENCES users(id),
    completato_at TIMESTAMPTZ,
    note TEXT,
    
    -- Ordinamento
    posizione INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. INDICI
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_progetti_numero ON progetti(numero);
CREATE INDEX IF NOT EXISTS idx_progetti_cliente ON progetti(cliente_id);
CREATE INDEX IF NOT EXISTS idx_progetti_stato ON progetti(stato);
CREATE INDEX IF NOT EXISTS idx_progetti_tipologia ON progetti(tipologia);
CREATE INDEX IF NOT EXISTS idx_progetti_componenti_progetto ON progetti_componenti(progetto_id);
CREATE INDEX IF NOT EXISTS idx_progetti_dispositivi_progetto ON progetti_dispositivi(progetto_id);
CREATE INDEX IF NOT EXISTS idx_progetti_checklist_progetto ON progetti_checklist(progetto_id);

-- 6. FUNZIONE: Genera numero progetto
-- =====================================================

CREATE OR REPLACE FUNCTION generate_progetto_numero()
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_anno INTEGER;
    v_numero INTEGER;
    v_numero_formattato VARCHAR;
BEGIN
    v_anno := EXTRACT(YEAR FROM CURRENT_DATE);
    
    -- Trova ultimo numero dell'anno
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(numero FROM 'PROG-' || v_anno::TEXT || '-([0-9]+)') AS INTEGER)
    ), 0) + 1
    INTO v_numero
    FROM progetti
    WHERE numero LIKE 'PROG-' || v_anno::TEXT || '-%';
    
    v_numero_formattato := 'PROG-' || v_anno::TEXT || '-' || LPAD(v_numero::TEXT, 3, '0');
    
    RETURN v_numero_formattato;
END;
$$;

GRANT EXECUTE ON FUNCTION generate_progetto_numero() TO authenticated;

-- 7. FUNZIONE: Calcola totali progetto
-- =====================================================

CREATE OR REPLACE FUNCTION calcola_totali_progetto(p_progetto_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_costo_materiali DECIMAL(10,2);
    v_costo_manodopera DECIMAL(10,2);
    v_costi_extra DECIMAL(10,2);
    v_ore_previste DECIMAL(5,2);
    v_costo_orario DECIMAL(8,2);
    v_totale DECIMAL(10,2);
BEGIN
    -- Calcola costo materiali
    SELECT COALESCE(SUM(totale), 0)
    INTO v_costo_materiali
    FROM progetti_componenti
    WHERE progetto_id = p_progetto_id;
    
    -- Recupera dati progetto
    SELECT ore_previste, costo_orario, costi_extra
    INTO v_ore_previste, v_costo_orario, v_costi_extra
    FROM progetti
    WHERE id = p_progetto_id;
    
    -- Calcola manodopera
    v_costo_manodopera := v_ore_previste * v_costo_orario;
    
    -- Totale
    v_totale := v_costo_materiali + v_costo_manodopera + v_costi_extra;
    
    -- Aggiorna progetto
    UPDATE progetti
    SET 
        costo_materiali = v_costo_materiali,
        costo_manodopera = v_costo_manodopera,
        totale_preventivato = v_totale,
        updated_at = NOW()
    WHERE id = p_progetto_id;
END;
$$;

GRANT EXECUTE ON FUNCTION calcola_totali_progetto(UUID) TO authenticated;

-- 8. TRIGGER: Aggiorna updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_progetti_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_progetti_updated ON progetti;
CREATE TRIGGER trg_progetti_updated
    BEFORE UPDATE ON progetti
    FOR EACH ROW
    EXECUTE FUNCTION update_progetti_timestamp();

-- 9. RLS (Row Level Security)
-- =====================================================

ALTER TABLE progetti ENABLE ROW LEVEL SECURITY;
ALTER TABLE progetti_componenti ENABLE ROW LEVEL SECURITY;
ALTER TABLE progetti_dispositivi ENABLE ROW LEVEL SECURITY;
ALTER TABLE progetti_checklist ENABLE ROW LEVEL SECURITY;

-- Policy: Tutti gli autenticati possono leggere
CREATE POLICY "Progetti leggibili da tutti" ON progetti FOR SELECT TO authenticated USING (true);
CREATE POLICY "Componenti leggibili da tutti" ON progetti_componenti FOR SELECT TO authenticated USING (true);
CREATE POLICY "Dispositivi leggibili da tutti" ON progetti_dispositivi FOR SELECT TO authenticated USING (true);
CREATE POLICY "Checklist leggibile da tutti" ON progetti_checklist FOR SELECT TO authenticated USING (true);

-- Policy: Tutti possono inserire/modificare
CREATE POLICY "Progetti modificabili" ON progetti FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Componenti modificabili" ON progetti_componenti FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Dispositivi modificabili" ON progetti_dispositivi FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Checklist modificabile" ON progetti_checklist FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 10. VERIFICA FINALE
-- =====================================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ SISTEMA PROGETTI CREATO!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Tabelle create:';
    RAISE NOTICE '  • progetti (testata progetto)';
    RAISE NOTICE '  • progetti_componenti (materiali)';
    RAISE NOTICE '  • progetti_dispositivi (telecamere/dispositivi)';
    RAISE NOTICE '  • progetti_checklist (task installazione)';
    RAISE NOTICE '';
    RAISE NOTICE '🎨 Modalità planimetria supportate:';
    RAISE NOTICE '  • UPLOAD - Carica PDF/immagine cliente';
    RAISE NOTICE '  • GRID - Disegna su griglia';
    RAISE NOTICE '  • CANVAS - Disegno libero';
    RAISE NOTICE '';
    RAISE NOTICE '📹 Funzionalità:';
    RAISE NOTICE '  • Posizionamento telecamere su mappa';
    RAISE NOTICE '  • Calcolo automatico cavi';
    RAISE NOTICE '  • Gestione componenti da magazzino';
    RAISE NOTICE '  • Calcolo costi materiali + manodopera';
    RAISE NOTICE '  • Checklist installazione';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Funzioni disponibili:';
    RAISE NOTICE '  • generate_progetto_numero()';
    RAISE NOTICE '  • calcola_totali_progetto(id)';
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
END $$;
