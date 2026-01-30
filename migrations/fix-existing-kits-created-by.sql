-- ============================================
-- FIX KIT ESISTENTE CON CREATED_BY NON VALIDO
-- ============================================
-- Converte i created_by dei kit da auth.users.id a users.id
-- ============================================

-- 1. Prima vediamo quale kit ha il problema
SELECT 
    k.id as kit_id,
    k.codice_kit,
    k.nome_kit,
    k.created_by as old_created_by,
    au.email as auth_email,
    u.id as new_user_id,
    u.email as user_email
FROM kits k
LEFT JOIN auth.users au ON au.id = k.created_by
LEFT JOIN users u ON u.auth_id = k.created_by
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = k.created_by)
AND k.created_by IS NOT NULL;

-- 2. Aggiorna i kit convertendo created_by da auth.users.id a users.id
UPDATE kits k
SET created_by = u.id
FROM users u
WHERE k.created_by = u.auth_id
AND NOT EXISTS (SELECT 1 FROM users WHERE id = k.created_by)
AND k.created_by IS NOT NULL;

-- 3. Fa lo stesso per consegnato_da_user
UPDATE kits k
SET consegnato_da_user = u.id
FROM users u
WHERE k.consegnato_da_user = u.auth_id
AND NOT EXISTS (SELECT 1 FROM users WHERE id = k.consegnato_da_user)
AND k.consegnato_da_user IS NOT NULL;

-- 4. Verifica che ora tutti i kit siano validi
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
-- FINE FIX
-- ============================================
