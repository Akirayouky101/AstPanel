-- ============================================
-- MIGRATION COMPLETA SISTEMA IMPEGNI MAGAZZINO
-- ============================================
-- Esegui questo file INTERO su Supabase SQL Editor
-- Contiene tutte le migration in ordine corretto
-- 
-- DURATA STIMATA: ~30 secondi
-- ============================================

-- ============================================
-- MIGRATION 1/4: Sistema Base Impegni
-- ============================================
-- File originale: add-impegni-magazzino-system.sql
-- Crea tabella, vista, trigger per preventivi e lavorazioni

-- Tabella impegni_magazzino
CREATE TABLE IF NOT EXISTS impegni_magazzino (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prodotto_id UUID NOT NULL REFERENCES components(id) ON DELETE CASCADE,
    quantita_impegnata DECIMAL(10,2) NOT NULL CHECK (quantita_impegnata > 0),
    tipo_impegno VARCHAR(50) NOT NULL CHECK (tipo_impegno IN ('preventivo', 'lavorazione', 'kit')),
    preventivo_id UUID REFERENCES preventivi(id) ON DELETE CASCADE,
    lavorazione_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    kit_id UUID REFERENCES kits(id) ON DELETE CASCADE,
    stato VARCHAR(20) NOT NULL DEFAULT 'attivo' CHECK (stato IN ('attivo', 'completato', 'annullato')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    completed_at TIMESTAMP WITH TIME ZONE,
    note TEXT
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_impegni_prodotto ON impegni_magazzino(prodotto_id);
CREATE INDEX IF NOT EXISTS idx_impegni_stato ON impegni_magazzino(stato);
CREATE INDEX IF NOT EXISTS idx_impegni_tipo ON impegni_magazzino(tipo_impegno);
CREATE INDEX IF NOT EXISTS idx_impegni_preventivo ON impegni_magazzino(preventivo_id);
CREATE INDEX IF NOT EXISTS idx_impegni_lavorazione ON impegni_magazzino(lavorazione_id);
CREATE INDEX IF NOT EXISTS idx_impegni_kit ON impegni_magazzino(kit_id);

-- Vista giacenze complete
CREATE OR REPLACE VIEW v_giacenze_complete AS
SELECT 
    c.id,
    c.nome,
    c.descrizione,
    c.codice,
    c.barcode,
    c.unita_misura,
    c.categoria,
    c.fornitore_id,
    c.prezzo_acquisto,
    c.giacenza_minima,
    c.stato,
    c.quantita_disponibile as giacenza_fisica,
    COALESCE(SUM(CASE WHEN im.stato = 'attivo' THEN im.quantita_impegnata ELSE 0 END), 0) as giacenza_impegnata,
    c.quantita_disponibile - COALESCE(SUM(CASE WHEN im.stato = 'attivo' THEN im.quantita_impegnata ELSE 0 END), 0) as giacenza_libera,
    CASE 
        WHEN c.quantita_disponibile - COALESCE(SUM(CASE WHEN im.stato = 'attivo' THEN im.quantita_impegnata ELSE 0 END), 0) <= 0 THEN 'esaurito'
        WHEN c.quantita_disponibile - COALESCE(SUM(CASE WHEN im.stato = 'attivo' THEN im.quantita_impegnata ELSE 0 END), 0) <= c.giacenza_minima THEN 'basso'
        ELSE 'ok'
    END as stato_giacenza
FROM components c
LEFT JOIN impegni_magazzino im ON c.id = im.prodotto_id AND im.stato = 'attivo'
WHERE c.stato = 'attivo'
GROUP BY c.id;

-- Funzione helper: calcola giacenza libera
CREATE OR REPLACE FUNCTION get_giacenza_libera(p_prodotto_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_fisica DECIMAL(10,2);
    v_impegnata DECIMAL(10,2);
BEGIN
    SELECT quantita_disponibile INTO v_fisica
    FROM components
    WHERE id = p_prodotto_id;
    
    SELECT COALESCE(SUM(quantita_impegnata), 0) INTO v_impegnata
    FROM impegni_magazzino
    WHERE prodotto_id = p_prodotto_id AND stato = 'attivo';
    
    RETURN COALESCE(v_fisica, 0) - v_impegnata;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER: Impegna prodotti quando preventivo viene accettato
CREATE OR REPLACE FUNCTION impegna_preventivo()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_componente RECORD;
BEGIN
    IF NEW.stato = 'accettato' AND (OLD.stato IS NULL OR OLD.stato != 'accettato') THEN
        SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
        
        FOR v_componente IN
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
                v_componente.prodotto_id,
                v_componente.quantita,
                'preventivo',
                NEW.id,
                'attivo',
                v_user_id,
                'Impegno automatico da preventivo ' || NEW.numero
            );
        END LOOP;
        
        RAISE NOTICE 'Impegnati prodotti per preventivo %', NEW.numero;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_impegna_preventivo ON preventivi;
CREATE TRIGGER trigger_impegna_preventivo
    AFTER UPDATE ON preventivi
    FOR EACH ROW
    EXECUTE FUNCTION impegna_preventivo();

-- TRIGGER: Trasferisci impegni da preventivo a lavorazione
CREATE OR REPLACE FUNCTION trasferisci_impegno_a_lavorazione()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.preventivo_id IS NOT NULL THEN
        UPDATE impegni_magazzino
        SET 
            tipo_impegno = 'lavorazione',
            lavorazione_id = NEW.id,
            note = note || ' → Trasferito a lavorazione ' || NEW.titolo
        WHERE preventivo_id = NEW.preventivo_id
        AND stato = 'attivo';
        
        RAISE NOTICE 'Trasferiti impegni da preventivo a lavorazione %', NEW.titolo;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_trasferisci_impegno ON tasks;
CREATE TRIGGER trigger_trasferisci_impegno
    AFTER INSERT ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION trasferisci_impegno_a_lavorazione();

-- TRIGGER: Completa impegni quando lavorazione completata
CREATE OR REPLACE FUNCTION completa_lavorazione_con_impegno()
RETURNS TRIGGER AS $$
DECLARE
    v_impegno RECORD;
BEGIN
    IF NEW.stato = 'completata' AND (OLD.stato IS NULL OR OLD.stato != 'completata') THEN
        FOR v_impegno IN
            SELECT prodotto_id, quantita_impegnata
            FROM impegni_magazzino
            WHERE lavorazione_id = NEW.id AND stato = 'attivo'
        LOOP
            UPDATE components
            SET quantita_disponibile = quantita_disponibile - v_impegno.quantita_impegnata
            WHERE id = v_impegno.prodotto_id;
            
            UPDATE impegni_magazzino
            SET 
                stato = 'completato',
                completed_at = NOW()
            WHERE lavorazione_id = NEW.id
            AND prodotto_id = v_impegno.prodotto_id
            AND stato = 'attivo';
        END LOOP;
        
        RAISE NOTICE 'Completati impegni e scalata giacenza per lavorazione %', NEW.titolo;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_completa_lavorazione_impegno ON tasks;
CREATE TRIGGER trigger_completa_lavorazione_impegno
    AFTER UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION completa_lavorazione_con_impegno();

-- TRIGGER: Verifica giacenza LIBERA quando crei kit
CREATE OR REPLACE FUNCTION verifica_giacenza_libera_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_giacenza_libera DECIMAL(10,2);
    v_prodotto_nome VARCHAR(255);
BEGIN
    v_giacenza_libera := get_giacenza_libera(NEW.prodotto_id);
    
    IF v_giacenza_libera < NEW.quantita THEN
        SELECT nome INTO v_prodotto_nome FROM components WHERE id = NEW.prodotto_id;
        RAISE EXCEPTION 'Giacenza libera insufficiente per %: disponibili %, richieste %',
            v_prodotto_nome, v_giacenza_libera, NEW.quantita;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_verifica_giacenza_kit ON kit_items;
CREATE TRIGGER trigger_verifica_giacenza_kit
    BEFORE INSERT OR UPDATE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION verifica_giacenza_libera_kit();

DO $$ BEGIN RAISE NOTICE '✅ Migration 1/4 completata: Sistema base impegni creato'; END $$;

-- ============================================
-- MIGRATION 2/4: Fix Colonne Preventivi
-- ============================================
-- File originale: fix-impegni-preventivi-column.sql
-- Corregge uso di preventivi.numero invece di numero_preventivo

DROP TRIGGER IF EXISTS trigger_impegna_preventivo ON preventivi;
DROP FUNCTION IF EXISTS impegna_preventivo();

CREATE OR REPLACE FUNCTION impegna_preventivo()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_componente RECORD;
BEGIN
    IF NEW.stato = 'accettato' AND (OLD.stato IS NULL OR OLD.stato != 'accettato') THEN
        SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
        
        FOR v_componente IN
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
                v_componente.prodotto_id,
                v_componente.quantita,
                'preventivo',
                NEW.id,
                'attivo',
                v_user_id,
                'Impegno automatico da preventivo ' || NEW.numero
            );
        END LOOP;
        
        RAISE NOTICE 'Impegnati prodotti per preventivo %', NEW.numero;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_impegna_preventivo
    AFTER UPDATE ON preventivi
    FOR EACH ROW
    EXECUTE FUNCTION impegna_preventivo();

DO $$ BEGIN RAISE NOTICE '✅ Migration 2/4 completata: Fix colonne preventivi'; END $$;

-- ============================================
-- MIGRATION 3/4: Fix Colonne Tasks
-- ============================================
-- File originale: fix-impegni-tasks-column.sql
-- Corregge uso di tasks.titolo invece di codice_lavorazione

DROP TRIGGER IF EXISTS trigger_trasferisci_impegno ON tasks;
DROP FUNCTION IF EXISTS trasferisci_impegno_a_lavorazione();

CREATE OR REPLACE FUNCTION trasferisci_impegno_a_lavorazione()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.preventivo_id IS NOT NULL THEN
        UPDATE impegni_magazzino
        SET 
            tipo_impegno = 'lavorazione',
            lavorazione_id = NEW.id,
            note = note || ' → Trasferito a lavorazione ' || NEW.titolo
        WHERE preventivo_id = NEW.preventivo_id
        AND stato = 'attivo';
        
        RAISE NOTICE 'Trasferiti impegni da preventivo a lavorazione %', NEW.titolo;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_trasferisci_impegno
    AFTER INSERT ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION trasferisci_impegno_a_lavorazione();

DROP TRIGGER IF EXISTS trigger_completa_lavorazione_impegno ON tasks;
DROP FUNCTION IF EXISTS completa_lavorazione_con_impegno();

CREATE OR REPLACE FUNCTION completa_lavorazione_con_impegno()
RETURNS TRIGGER AS $$
DECLARE
    v_impegno RECORD;
BEGIN
    IF NEW.stato = 'completata' AND (OLD.stato IS NULL OR OLD.stato != 'completata') THEN
        FOR v_impegno IN
            SELECT prodotto_id, quantita_impegnata
            FROM impegni_magazzino
            WHERE lavorazione_id = NEW.id AND stato = 'attivo'
        LOOP
            UPDATE components
            SET quantita_disponibile = quantita_disponibile - v_impegno.quantita_impegnata
            WHERE id = v_impegno.prodotto_id;
            
            UPDATE impegni_magazzino
            SET 
                stato = 'completato',
                completed_at = NOW()
            WHERE lavorazione_id = NEW.id
            AND prodotto_id = v_impegno.prodotto_id
            AND stato = 'attivo';
        END LOOP;
        
        RAISE NOTICE 'Completati impegni e scalata giacenza per lavorazione %', NEW.titolo;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_completa_lavorazione_impegno
    AFTER UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION completa_lavorazione_con_impegno();

DO $$ BEGIN RAISE NOTICE '✅ Migration 3/4 completata: Fix colonne tasks'; END $$;

-- ============================================
-- MIGRATION 4/4: Sistema Impegni Kit
-- ============================================
-- File originale: add-impegni-kit.sql
-- Trigger automatici per impegni componenti kit

-- TRIGGER: Impegna prodotti quando aggiungi componente a kit
CREATE OR REPLACE FUNCTION impegna_prodotti_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_kit_codice VARCHAR(50);
    v_existing_impegno UUID;
    v_old_quantita DECIMAL(10,2);
BEGIN
    SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
    SELECT codice_kit INTO v_kit_codice FROM kits WHERE id = NEW.kit_id;
    
    -- Verifica se esiste già un impegno attivo per questo prodotto e kit
    SELECT id, quantita_impegnata INTO v_existing_impegno, v_old_quantita
    FROM impegni_magazzino
    WHERE kit_id = NEW.kit_id 
    AND prodotto_id = NEW.prodotto_id
    AND stato = 'attivo'
    LIMIT 1;
    
    IF v_existing_impegno IS NOT NULL THEN
        -- Aggiorna quantità esistente invece di creare nuova riga
        UPDATE impegni_magazzino
        SET quantita_impegnata = quantita_impegnata + NEW.quantita,
            note = 'Impegno automatico per kit ' || COALESCE(v_kit_codice, NEW.kit_id::TEXT) || 
                   ' (aggiornato da ' || v_old_quantita || ' a ' || (v_old_quantita + NEW.quantita) || ')'
        WHERE id = v_existing_impegno;
        
        RAISE NOTICE 'Aggiornato impegno per kit %: %.2f → %.2f', v_kit_codice, v_old_quantita, (v_old_quantita + NEW.quantita);
    ELSE
        -- Crea nuovo impegno
        INSERT INTO impegni_magazzino (
            prodotto_id,
            quantita_impegnata,
            tipo_impegno,
            kit_id,
            stato,
            created_by,
            note
        ) VALUES (
            NEW.prodotto_id,
            NEW.quantita,
            'kit',
            NEW.kit_id,
            'attivo',
            v_user_id,
            'Impegno automatico per kit ' || COALESCE(v_kit_codice, NEW.kit_id::TEXT)
        );
        
        RAISE NOTICE 'Impegnati %.2f unità di prodotto per kit %', NEW.quantita, v_kit_codice;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_impegna_kit ON kit_items;
CREATE TRIGGER trigger_impegna_kit
    AFTER INSERT ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION impegna_prodotti_kit();

-- TRIGGER: Libera impegni quando elimini componente da kit
CREATE OR REPLACE FUNCTION libera_impegno_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_kit_codice VARCHAR(50);
    v_prodotto_nome VARCHAR(255);
    v_quantita_liberata DECIMAL(10,2);
BEGIN
    SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
    SELECT codice_kit INTO v_kit_codice FROM kits WHERE id = OLD.kit_id;
    SELECT nome INTO v_prodotto_nome FROM components WHERE id = OLD.prodotto_id;
    
    SELECT quantita_impegnata INTO v_quantita_liberata
    FROM impegni_magazzino
    WHERE kit_id = OLD.kit_id 
    AND prodotto_id = OLD.prodotto_id
    AND stato = 'attivo'
    LIMIT 1;
    
    UPDATE impegni_magazzino
    SET 
        stato = 'annullato',
        completed_at = NOW()
    WHERE kit_id = OLD.kit_id 
    AND prodotto_id = OLD.prodotto_id
    AND stato = 'attivo';
    
    IF v_quantita_liberata IS NOT NULL AND v_quantita_liberata > 0 THEN
        INSERT INTO movimenti_magazzino (
            prodotto_id,
            tipo_movimento,
            quantita,
            created_by,
            note
        ) VALUES (
            OLD.prodotto_id,
            'reintegro',
            v_quantita_liberata,
            v_user_id,
            'Componente rimosso da kit ' || COALESCE(v_kit_codice, OLD.kit_id::TEXT) || 
            ' - Materiale reintegrato: ' || v_quantita_liberata || ' unità di ' || COALESCE(v_prodotto_nome, 'prodotto')
        );
        
        RAISE NOTICE 'Liberato impegno per componente rimosso da kit % (%.2f unità)', v_kit_codice, v_quantita_liberata;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;
CREATE TRIGGER trigger_libera_impegno_kit
    AFTER DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

-- TRIGGER: Libera impegni quando elimini intero kit
CREATE OR REPLACE FUNCTION libera_impegni_kit_eliminato()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_kit_codice VARCHAR(50);
    v_componente RECORD;
    v_totale_reintegrato DECIMAL(10,2) := 0;
BEGIN
    SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
    v_kit_codice := OLD.codice_kit;
    
    FOR v_componente IN 
        SELECT 
            im.prodotto_id,
            im.quantita_impegnata,
            c.nome as prodotto_nome
        FROM impegni_magazzino im
        JOIN components c ON c.id = im.prodotto_id
        WHERE im.kit_id = OLD.id 
        AND im.stato = 'attivo'
    LOOP
        UPDATE impegni_magazzino
        SET 
            stato = 'annullato',
            completed_at = NOW()
        WHERE kit_id = OLD.id 
        AND prodotto_id = v_componente.prodotto_id
        AND stato = 'attivo';
        
        INSERT INTO movimenti_magazzino (
            prodotto_id,
            tipo_movimento,
            quantita,
            created_by,
            note
        ) VALUES (
            v_componente.prodotto_id,
            'reintegro',
            v_componente.quantita_impegnata,
            v_user_id,
            'Kit eliminato: ' || COALESCE(v_kit_codice, OLD.id::TEXT) || 
            ' - Materiale reintegrato: ' || v_componente.quantita_impegnata || 
            ' unità di ' || COALESCE(v_componente.prodotto_nome, 'prodotto')
        );
        
        v_totale_reintegrato := v_totale_reintegrato + v_componente.quantita_impegnata;
    END LOOP;
    
    IF v_totale_reintegrato > 0 THEN
        RAISE NOTICE 'Kit % eliminato - Reintegrati componenti per un totale di %.2f unità', v_kit_codice, v_totale_reintegrato;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_libera_kit_eliminato ON kits;
CREATE TRIGGER trigger_libera_kit_eliminato
    BEFORE DELETE ON kits
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegni_kit_eliminato();

-- TRIGGER: Completa impegni quando kit viene consegnato
CREATE OR REPLACE FUNCTION completa_impegni_kit()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stato IN ('consegnato', 'completato', 'chiuso') AND 
       (OLD.stato IS NULL OR OLD.stato NOT IN ('consegnato', 'completato', 'chiuso')) THEN
        
        UPDATE impegni_magazzino
        SET 
            stato = 'completato',
            completed_at = NOW()
        WHERE kit_id = NEW.id 
        AND stato = 'attivo';
        
        RAISE NOTICE 'Completati impegni per kit consegnato %', NEW.codice_kit;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_completa_kit ON kits;
CREATE TRIGGER trigger_completa_kit
    AFTER UPDATE ON kits
    FOR EACH ROW
    EXECUTE FUNCTION completa_impegni_kit();

DO $$ BEGIN RAISE NOTICE '✅ Migration 4/4 completata: Sistema impegni kit'; END $$;

-- ============================================
-- RIEPILOGO FINALE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ TUTTE LE MIGRATION COMPLETATE CON SUCCESSO!';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'SISTEMA IMPEGNI MAGAZZINO ATTIVO:';
    RAISE NOTICE '';
    RAISE NOTICE '📦 PREVENTIVI:';
    RAISE NOTICE '  → Preventivo accettato = prodotti impegnati';
    RAISE NOTICE '  → Preventivo → Lavorazione = impegni trasferiti';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 LAVORAZIONI:';
    RAISE NOTICE '  → Lavorazione completata = giacenza scalata + impegni completati';
    RAISE NOTICE '';
    RAISE NOTICE '📦 KIT:';
    RAISE NOTICE '  → Aggiungi componente = impegno creato';
    RAISE NOTICE '  → Stesso prodotto più volte = quantità sommate (no duplicate)';
    RAISE NOTICE '  → Rimuovi componente = impegno liberato + storico';
    RAISE NOTICE '  → Elimina kit = tutti impegni liberati + storico dettagliato';
    RAISE NOTICE '  → Consegna kit = impegni completati';
    RAISE NOTICE '';
    RAISE NOTICE '📊 DASHBOARD:';
    RAISE NOTICE '  → Magazzino Prodotti: visualizza giacenza fisica/impegnata/libera';
    RAISE NOTICE '  → Impegni Magazzino: gestione completa impegni attivi';
    RAISE NOTICE '';
    RAISE NOTICE '📝 STORICO:';
    RAISE NOTICE '  → Tutti i reintegri registrati in movimenti_magazzino';
    RAISE NOTICE '  → Note dettagliate per ogni operazione';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE 'Pronto per il testing! Segui TEST-SISTEMA-IMPEGNI-COMPLETO.md';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
END $$;
