-- ============================================
-- SISTEMA IMPEGNI MAGAZZINO
-- ============================================
-- Sistema completo per gestione prenotazioni/impegni prodotti
-- Permette di distinguere tra giacenza fisica e giacenza disponibile

-- ============================================
-- 1. TABELLA IMPEGNI
-- ============================================
CREATE TABLE IF NOT EXISTS impegni_magazzino (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prodotto_id UUID NOT NULL REFERENCES components(id) ON DELETE CASCADE,
    quantita_impegnata DECIMAL(10,2) NOT NULL CHECK (quantita_impegnata > 0),
    
    -- Tipo impegno
    tipo_impegno VARCHAR(50) NOT NULL CHECK (tipo_impegno IN ('preventivo', 'lavorazione', 'kit', 'altro')),
    
    -- Riferimenti (almeno uno deve essere valorizzato)
    preventivo_id UUID REFERENCES preventivi(id) ON DELETE CASCADE,
    lavorazione_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    kit_id UUID REFERENCES kits(id) ON DELETE CASCADE,
    
    -- Metadati
    note TEXT,
    stato VARCHAR(20) DEFAULT 'attivo' CHECK (stato IN ('attivo', 'completato', 'annullato')),
    
    -- Audit
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    completed_at TIMESTAMPTZ,
    
    -- Constraint: almeno un riferimento deve esistere
    CONSTRAINT impegni_almeno_un_riferimento CHECK (
        preventivo_id IS NOT NULL OR 
        lavorazione_id IS NOT NULL OR 
        kit_id IS NOT NULL
    )
);

-- Indici per performance
CREATE INDEX idx_impegni_prodotto ON impegni_magazzino(prodotto_id);
CREATE INDEX idx_impegni_preventivo ON impegni_magazzino(preventivo_id) WHERE preventivo_id IS NOT NULL;
CREATE INDEX idx_impegni_lavorazione ON impegni_magazzino(lavorazione_id) WHERE lavorazione_id IS NOT NULL;
CREATE INDEX idx_impegni_kit ON impegni_magazzino(kit_id) WHERE kit_id IS NOT NULL;
CREATE INDEX idx_impegni_stato ON impegni_magazzino(stato) WHERE stato = 'attivo';

COMMENT ON TABLE impegni_magazzino IS 'Prenotazioni/impegni di prodotti per preventivi, lavorazioni e kit';

-- ============================================
-- 2. VISTA GIACENZE CON IMPEGNI
-- ============================================
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
    
    -- Alert automatici
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

-- ============================================
-- 3. FUNZIONE HELPER: Calcola giacenza libera
-- ============================================
CREATE OR REPLACE FUNCTION get_giacenza_libera(p_prodotto_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_giacenza_fisica DECIMAL(10,2);
    v_giacenza_impegnata DECIMAL(10,2);
BEGIN
    -- Giacenza fisica
    SELECT quantita_disponibile INTO v_giacenza_fisica
    FROM components
    WHERE id = p_prodotto_id;
    
    -- Giacenza impegnata (solo impegni attivi)
    SELECT COALESCE(SUM(quantita_impegnata), 0) INTO v_giacenza_impegnata
    FROM impegni_magazzino
    WHERE prodotto_id = p_prodotto_id AND stato = 'attivo';
    
    RETURN COALESCE(v_giacenza_fisica, 0) - COALESCE(v_giacenza_impegnata, 0);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_giacenza_libera IS 'Calcola giacenza libera (fisica - impegnata) per un prodotto';

-- ============================================
-- 4. TRIGGER: Impegno prodotti su PREVENTIVO ACCETTATO
-- ============================================
CREATE OR REPLACE FUNCTION impegna_prodotti_preventivo()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_item RECORD;
BEGIN
    -- Solo se preventivo passa a 'accettato'
    IF NEW.stato = 'accettato' AND (OLD.stato IS NULL OR OLD.stato != 'accettato') THEN
        
        -- Trova user_id da auth_id
        SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
        
        -- Impegna tutti i prodotti del preventivo
        FOR v_item IN 
            SELECT prodotto_id, quantita 
            FROM preventivo_items 
            WHERE preventivo_id = NEW.id
        LOOP
            INSERT INTO impegni_magazzino (
                prodotto_id,
                quantita_impegnata,
                tipo_impegno,
                preventivo_id,
                stato,
                created_by,
                note
            ) VALUES (
                v_item.prodotto_id,
                v_item.quantita,
                'preventivo',
                NEW.id,
                'attivo',
                v_user_id,
                'Impegno automatico per preventivo ' || NEW.numero
            );
        END LOOP;
        
        RAISE NOTICE '✅ Impegnati prodotti per preventivo %', NEW.numero;
    END IF;
    
    -- Se preventivo viene annullato o rifiutato, libera impegni
    IF NEW.stato IN ('annullato', 'rifiutato') AND OLD.stato = 'accettato' THEN
        UPDATE impegni_magazzino
        SET stato = 'annullato'
        WHERE preventivo_id = NEW.id AND stato = 'attivo';
        
        RAISE NOTICE '🔓 Liberati prodotti per preventivo annullato %', NEW.numero;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_impegna_preventivo
    AFTER UPDATE ON preventivi
    FOR EACH ROW
    EXECUTE FUNCTION impegna_prodotti_preventivo();

-- ============================================
-- 5. TRIGGER: Trasferisci impegno PREVENTIVO → LAVORAZIONE
-- ============================================
CREATE OR REPLACE FUNCTION trasferisci_impegno_a_lavorazione()
RETURNS TRIGGER AS $$
BEGIN
    -- Se lavorazione creata da preventivo
    IF NEW.preventivo_id IS NOT NULL THEN
        
        -- Trasferisci impegni da preventivo a lavorazione
        UPDATE impegni_magazzino
        SET 
            lavorazione_id = NEW.id,
            tipo_impegno = 'lavorazione',
            note = note || ' → Trasferito a lavorazione ' || NEW.titolo
        WHERE preventivo_id = NEW.preventivo_id 
        AND stato = 'attivo';
        
        RAISE NOTICE '🔄 Impegni trasferiti da preventivo a lavorazione %', NEW.titolo;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_trasferisci_impegno
    AFTER INSERT ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION trasferisci_impegno_a_lavorazione();

-- ============================================
-- 6. TRIGGER: Scala giacenza e libera impegno su LAVORAZIONE COMPLETATA
-- ============================================
CREATE OR REPLACE FUNCTION completa_lavorazione_con_impegno()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_impegno RECORD;
BEGIN
    -- Solo se lavorazione completata
    IF NEW.stato = 'completato' AND (OLD.stato IS NULL OR OLD.stato != 'completato') THEN
        
        SELECT id INTO v_user_id FROM users WHERE auth_id = NEW.assigned_user_id;
        
        -- Per ogni impegno attivo
        FOR v_impegno IN 
            SELECT * FROM impegni_magazzino 
            WHERE lavorazione_id = NEW.id AND stato = 'attivo'
        LOOP
            -- Scala giacenza fisica
            UPDATE components
            SET quantita_disponibile = quantita_disponibile - v_impegno.quantita_impegnata
            WHERE id = v_impegno.prodotto_id;
            
            -- Registra movimento
            INSERT INTO movimenti_magazzino (
                prodotto_id,
                tipo_movimento,
                quantita,
                giacenza_prima,
                giacenza_dopo,
                causale,
                data_movimento,
                created_by
            )
            SELECT 
                v_impegno.prodotto_id,
                'uscita',
                -v_impegno.quantita_impegnata,
                c.quantita_disponibile + v_impegno.quantita_impegnata,
                c.quantita_disponibile,
                'Completamento lavorazione ' || NEW.titolo,
                NOW(),
                v_user_id
            FROM components c WHERE c.id = v_impegno.prodotto_id;
            
            -- Marca impegno come completato
            UPDATE impegni_magazzino
            SET 
                stato = 'completato',
                completed_at = NOW()
            WHERE id = v_impegno.id;
        END LOOP;
        
        RAISE NOTICE '✅ Scalata giacenza per lavorazione completata %', NEW.titolo;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop vecchio trigger se esiste
DROP TRIGGER IF EXISTS trigger_scarica_componenti ON tasks;

-- Crea nuovo trigger
CREATE TRIGGER trigger_completa_lavorazione_con_impegno
    AFTER UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION completa_lavorazione_con_impegno();

-- ============================================
-- 7. MODIFICA TRIGGER KIT: Usa giacenza LIBERA
-- ============================================
-- Il trigger kit ora deve controllare giacenza_libera invece di quantita_disponibile

CREATE OR REPLACE FUNCTION verifica_giacenza_libera_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_giacenza_libera DECIMAL(10,2);
    v_prodotto_nome VARCHAR(255);
BEGIN
    -- Calcola giacenza libera
    v_giacenza_libera := get_giacenza_libera(NEW.prodotto_id);
    
    -- Se giacenza libera insufficiente, lancia warning
    IF v_giacenza_libera < NEW.quantita THEN
        SELECT nome INTO v_prodotto_nome FROM components WHERE id = NEW.prodotto_id;
        
        RAISE WARNING 'GIACENZA INSUFFICIENTE: % richiede % unità, disponibili solo % libere', 
            v_prodotto_nome, NEW.quantita, v_giacenza_libera;
        
        -- Calcola quantità mancante
        NEW.quantita_mancante := NEW.quantita - GREATEST(v_giacenza_libera, 0);
    ELSE
        NEW.quantita_mancante := 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger BEFORE INSERT per calcolare quantita_mancante
DROP TRIGGER IF EXISTS trigger_verifica_giacenza_libera_kit ON kit_items;
CREATE TRIGGER trigger_verifica_giacenza_libera_kit
    BEFORE INSERT ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION verifica_giacenza_libera_kit();

-- ============================================
-- FINE MIGRATION
-- ============================================

-- Test rapido
DO $$
BEGIN
    RAISE NOTICE '✅ Sistema impegni magazzino creato con successo!';
    RAISE NOTICE '📊 Usa v_giacenze_complete per vedere giacenze con impegni';
    RAISE NOTICE '🔍 Usa get_giacenza_libera(prodotto_id) per calcolare giacenza disponibile';
END $$;
