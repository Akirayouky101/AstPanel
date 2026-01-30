-- ============================================
-- FIX FOREIGN KEYS KITS -> USERS
-- ============================================
-- Cambia le foreign keys da auth.users a users
-- per consistenza con il resto del sistema
-- ============================================

-- 1. Rimuovi vecchie foreign keys
ALTER TABLE kits DROP CONSTRAINT IF EXISTS kits_created_by_fkey;
ALTER TABLE kits DROP CONSTRAINT IF EXISTS kits_consegnato_da_user_fkey;

-- 2. Aggiungi nuove foreign keys verso tabella users
ALTER TABLE kits 
ADD CONSTRAINT kits_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE kits 
ADD CONSTRAINT kits_consegnato_da_user_fkey 
FOREIGN KEY (consegnato_da_user) REFERENCES users(id) ON DELETE SET NULL;

-- 3. Aggiorna eventuali record esistenti con auth_id
-- (converte da auth.users.id a users.id)
UPDATE kits k
SET created_by = u.id
FROM users u
WHERE k.created_by = u.auth_id::uuid
AND k.created_by IS NOT NULL;

UPDATE kits k
SET consegnato_da_user = u.id
FROM users u
WHERE k.consegnato_da_user = u.auth_id::uuid
AND k.consegnato_da_user IS NOT NULL;

-- ============================================
-- FINE MIGRATION
-- ============================================
