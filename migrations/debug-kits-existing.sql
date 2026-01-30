-- ============================================
-- DEBUG KITS ESISTENTI
-- ============================================
-- Verifica i kit esistenti e i loro created_by
-- ============================================

-- 1. Mostra tutti i kit con i loro created_by
SELECT 
    id,
    nome,
    created_by,
    stato,
    created_at
FROM kits
ORDER BY created_at DESC;

-- 2. Verifica se i created_by dei kit esistono nella tabella users
SELECT 
    k.id as kit_id,
    k.nome as kit_nome,
    k.created_by,
    CASE 
        WHEN u.id IS NOT NULL THEN 'OK - User esiste'
        WHEN au.id IS NOT NULL THEN 'ERRORE - È un auth.users ID'
        ELSE 'ERRORE - ID non esiste'
    END as status,
    u.email as user_email,
    u.ruolo as user_ruolo
FROM kits k
LEFT JOIN users u ON u.id = k.created_by
LEFT JOIN auth.users au ON au.id = k.created_by
ORDER BY k.created_at DESC;

-- 3. Conta quanti kit hanno created_by valido vs non valido
SELECT 
    CASE 
        WHEN created_by IS NULL THEN 'NULL'
        WHEN EXISTS (SELECT 1 FROM users WHERE id = k.created_by) THEN 'VALIDO'
        ELSE 'NON VALIDO'
    END as tipo,
    COUNT(*) as count
FROM kits k
GROUP BY 
    CASE 
        WHEN created_by IS NULL THEN 'NULL'
        WHEN EXISTS (SELECT 1 FROM users WHERE id = k.created_by) THEN 'VALIDO'
        ELSE 'NON VALIDO'
    END;

-- ============================================
-- FINE DEBUG
-- ============================================
