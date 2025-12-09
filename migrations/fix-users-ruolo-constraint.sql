-- =====================================================
-- FIX CONSTRAINT RUOLO
-- =====================================================
-- Rimuove vecchio constraint e ne crea uno nuovo
-- con valori corretti: admin, dipendente, tecnico
-- =====================================================

-- Step 1: Drop vecchio constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_ruolo_check;

-- Step 2: Normalizza valori esistenti (da maiuscolo a minuscolo)
UPDATE users SET ruolo = LOWER(ruolo);

-- Step 3: Converti valori non standard a valori validi
UPDATE users 
SET ruolo = CASE
    WHEN LOWER(ruolo) LIKE '%admin%' OR LOWER(ruolo) LIKE '%titolare%' THEN 'admin'
    WHEN LOWER(ruolo) LIKE '%tecn%' THEN 'tecnico'
    WHEN LOWER(ruolo) LIKE '%segret%' THEN 'dipendente'
    ELSE 'dipendente'
END
WHERE ruolo NOT IN ('admin', 'dipendente', 'tecnico');

-- Step 4: Crea nuovo constraint con valori corretti
ALTER TABLE users 
ADD CONSTRAINT users_ruolo_check 
CHECK (ruolo IN ('admin', 'dipendente', 'tecnico'));

-- Verifica
DO $$
BEGIN
    RAISE NOTICE '✅ Constraint users_ruolo_check aggiornato';
    RAISE NOTICE '   Valori permessi: admin, dipendente, tecnico';
    RAISE NOTICE '';
    RAISE NOTICE 'Dati normalizzati:';
    RAISE NOTICE '- Titolare → admin';
    RAISE NOTICE '- Tecnico/tecnico → tecnico';
    RAISE NOTICE '- Segreteria/dipendente → dipendente';
END $$;
