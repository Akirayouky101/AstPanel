-- =====================================================
-- FIX CONSTRAINT RUOLI - Usa ruoli distinti invece di "admin" generico
-- =====================================================
-- Ruoli DB: titolare, segreteria, tecnico, dipendente
-- Permessi admin: titolare, segreteria, tecnico
-- Permessi normali: dipendente
-- =====================================================

-- 1. Rimuovi il vecchio constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_ruolo_check;

-- 2. Aggiungi il nuovo constraint con i 4 ruoli distinti
ALTER TABLE users ADD CONSTRAINT users_ruolo_check 
CHECK (ruolo IN ('titolare', 'segreteria', 'tecnico', 'dipendente'));

-- 3. Aggiorna il super admin da 'tecnico' a 'titolare'
UPDATE users 
SET ruolo = 'titolare' 
WHERE id = '00000000-0000-0000-0000-000000000001'::UUID;

-- 4. Verifica i ruoli attuali nel database
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
