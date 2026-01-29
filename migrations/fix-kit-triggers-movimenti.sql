-- ============================================
-- FIX TRIGGER KIT_ITEMS - MOVIMENTI MAGAZZINO
-- ============================================
-- Rimuove i campi riferimento_tipo e riferimento_id
-- che non esistono nella tabella movimenti_magazzino
-- Aggiunge giacenza_prima e giacenza_dopo
-- ============================================

-- 1. FIX VIEW - Assicura che creato_da_nome non sia NULL
CREATE OR REPLACE VIEW v_kits_completi AS
SELECT 
    k.*,
    
    -- Creatore (con fallback se user cancellato)
    COALESCE(CONCAT(u_created.nome, ' ', u_created.cognome), 'Utente non disponibile') as creato_da_nome,
    
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
LEFT JOIN users u_created ON k.created_by = u_created.id
LEFT JOIN clients c ON k.cliente_id = c.id
LEFT JOIN users u_dest ON k.dipendente_id = u_dest.id
LEFT JOIN users u_consegna ON k.consegnato_da_user = u_consegna.id
LEFT JOIN kit_items ki ON k.id = ki.kit_id
GROUP BY 
    k.id, 
    u_created.nome, u_created.cognome,
    c.ragione_sociale, c.email,
    u_dest.nome, u_dest.cognome, u_dest.email,
    u_consegna.nome, u_consegna.cognome
ORDER BY k.created_at DESC;

-- 2. FIX TRIGGER - Scala giacenza quando aggiungi prodotto a kit
CREATE OR REPLACE FUNCTION scala_giacenza_kit()
RETURNS TRIGGER AS $$
BEGIN
    -- Scala giacenza dal magazzino
    UPDATE components 
    SET quantita_disponibile = quantita_disponibile - NEW.quantita
    WHERE id = NEW.prodotto_id;
    
    -- Registra movimento magazzino
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
        NEW.prodotto_id,
        'uscita',
        -NEW.quantita,
        c.quantita_disponibile + NEW.quantita,
        c.quantita_disponibile,
        'Aggiunto a kit ' || k.codice_kit,
        NOW(),
        NEW.aggiunto_da
    FROM components c
    CROSS JOIN kits k
    WHERE c.id = NEW.prodotto_id
    AND k.id = NEW.kit_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Ripristina giacenza quando rimuovi prodotto da kit (solo se non consegnato)
CREATE OR REPLACE FUNCTION ripristina_giacenza_kit()
RETURNS TRIGGER AS $$
DECLARE
    kit_stato varchar(20);
    giacenza_attuale DECIMAL(10,2);
BEGIN
    -- Verifica stato kit
    SELECT stato INTO kit_stato FROM kits WHERE id = OLD.kit_id;
    
    -- Ripristina solo se kit non è consegnato
    IF kit_stato != 'consegnato' THEN
        -- Ottieni giacenza attuale
        SELECT quantita_disponibile INTO giacenza_attuale 
        FROM components 
        WHERE id = OLD.prodotto_id;
        
        UPDATE components 
        SET quantita_disponibile = quantita_disponibile + OLD.quantita
        WHERE id = OLD.prodotto_id;
        
        -- Registra movimento magazzino
        INSERT INTO movimenti_magazzino (
            prodotto_id,
            tipo_movimento,
            quantita,
            giacenza_prima,
            giacenza_dopo,
            causale,
            data_movimento,
            created_by
        ) VALUES (
            OLD.prodotto_id,
            'entrata',
            OLD.quantita,
            giacenza_attuale,
            giacenza_attuale + OLD.quantita,
            'Rimosso da kit',
            NOW(),
            auth.uid()
        );
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FINE MIGRATION
-- ============================================
