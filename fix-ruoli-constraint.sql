-- =====================================================
-- FIX CONSTRAINT RUOLI - Usa ruoli distinti invece di "admin" generico
-- =====================================================
-- Ruoli DB: titolare, segreteria, tecnico, dipendente
-- Permessi admin: titolare, segreteria, tecnico
-- Permessi normali: dipendente
-- =====================================================

-- 1. PRIMA rimuovi il vecchio constraint (così possiamo modificare liberamente)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_ruolo_check;

-- 2. Aggiorna gli utenti esistenti con i vecchi ruoli
-- Converti 'admin' → 'titolare' (per il super admin e altri admin)
UPDATE users 
SET ruolo = 'titolare' 
WHERE ruolo = 'admin';

-- 3. Il ruolo 'tecnico' rimane invariato (già corretto)
-- 4. Il ruolo 'dipendente' rimane invariato (già corretto)

-- 5. Verifica che non ci siano ruoli strani
SELECT DISTINCT ruolo, COUNT(*) as count
FROM users
GROUP BY ruolo
ORDER BY ruolo;

-- 6. INFINE aggiungi il nuovo constraint con i 4 ruoli distinti
ALTER TABLE users ADD CONSTRAINT users_ruolo_check 
CHECK (ruolo IN ('titolare', 'segreteria', 'tecnico', 'dipendente'));

-- 7. Verifica i ruoli attuali nel database
SELECT 
    id,
    nome,
    cognome,
    email,
    ruolo,
    CASE 
        WHEN ruolo IN ('titolare', 'segreteria', 'tecnico') THEN '✅ Admin'
        WHEN ruolo = 'dipendente' THEN '👤 Utente normale'
        ELSE '⚠️ Ruolo non riconosciuto'
    END as tipo_accesso
FROM users
ORDER BY 
    CASE ruolo
        WHEN 'titolare' THEN 1
        WHEN 'segreteria' THEN 2
        WHEN 'tecnico' THEN 3
        WHEN 'dipendente' THEN 4
        ELSE 5
    END;

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ CONSTRAINT RUOLI AGGIORNATO!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Ruoli disponibili:';
    RAISE NOTICE '  👑 titolare    → Permessi admin';
    RAISE NOTICE '  📝 segreteria  → Permessi admin';
    RAISE NOTICE '  🔧 tecnico     → Permessi admin';
    RAISE NOTICE '  👤 dipendente  → Permessi normali';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANTE:';
    RAISE NOTICE '  - Aggiorna il codice per usare i nuovi ruoli';
    RAISE NOTICE '  - Aggiorna isAdmin() per includere: titolare, segreteria, tecnico';
    RAISE NOTICE '';
END $$;
