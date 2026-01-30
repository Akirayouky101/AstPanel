-- ============================================
-- FIX FOREIGN KEY movimenti_magazzino.created_by
-- ============================================
-- Il problema: il trigger usa aggiunto_da (auth_id) ma il FK punta a users.id

-- 1. DROP vecchio FK se esiste
ALTER TABLE movimenti_magazzino 
DROP CONSTRAINT IF EXISTS movimenti_magazzino_created_by_fkey;

-- 2. Aggiungi nuova colonna per auth_id se non esiste
ALTER TABLE movimenti_magazzino 
ADD COLUMN IF NOT EXISTS created_by_auth_id UUID;

-- 3. Ricrea FK corretto verso users.id (non auth.users.id)
ALTER TABLE movimenti_magazzino
ADD CONSTRAINT movimenti_magazzino_created_by_fkey 
FOREIGN KEY (created_by) 
REFERENCES users(id) 
ON DELETE SET NULL;

-- 4. Ricrea TRIGGER corretto - usa users.id invece di auth_id
CREATE OR REPLACE FUNCTION scala_giacenza_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Trova users.id partendo da auth_id
    SELECT id INTO v_user_id 
    FROM users 
    WHERE auth_id = NEW.aggiunto_da;
    
    -- Scala giacenza dal magazzino
    UPDATE components 
    SET quantita_disponibile = quantita_disponibile - NEW.quantita
    WHERE id = NEW.prodotto_id;
    
    -- Registra movimento magazzino con users.id
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
        v_user_id  -- USA users.id NON auth_id
    FROM components c
    CROSS JOIN kits k
    WHERE c.id = NEW.prodotto_id 
    AND k.id = NEW.kit_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Ricrea TRIGGER per ripristino giacenza
CREATE OR REPLACE FUNCTION ripristina_giacenza_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Trova users.id partendo da auth_id (se disponibile)
    SELECT id INTO v_user_id 
    FROM users 
    WHERE auth_id = OLD.aggiunto_da;
    
    -- Se non trovato, usa un valore di default o NULL
    IF v_user_id IS NULL THEN
        v_user_id := NULL;
    END IF;
    
    -- Solo se il kit NON è stato eliminato (soft delete)
    IF (SELECT stato FROM kits WHERE id = OLD.kit_id) != 'eliminato' THEN
        -- Ripristina giacenza
        UPDATE components 
        SET quantita_disponibile = quantita_disponibile + OLD.quantita
        WHERE id = OLD.prodotto_id;
        
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
            OLD.prodotto_id,
            'entrata',
            OLD.quantita,
            c.quantita_disponibile - OLD.quantita,
            c.quantita_disponibile,
            'Rimosso da kit ' || k.codice_kit,
            NOW(),
            v_user_id  -- USA users.id NON auth_id
        FROM components c
        CROSS JOIN kits k
        WHERE c.id = OLD.prodotto_id 
        AND k.id = OLD.kit_id;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FINE FIX
-- ============================================
