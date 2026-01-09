-- =====================================================
-- AST PANEL - Svuota Utenti (Preserva Super Admin)
-- =====================================================
-- Questo script elimina TUTTI gli utenti ECCETTO il Super Admin
-- =====================================================

-- Conta gli utenti prima della cancellazione
SELECT 
    COUNT(*) as totale_utenti,
    COUNT(*) FILTER (WHERE id = '00000000-0000-0000-0000-000000000001'::UUID) as super_admin,
    COUNT(*) FILTER (WHERE id != '00000000-0000-0000-0000-000000000001'::UUID) as utenti_normali,
    '📊 UTENTI PRIMA DELLA CANCELLAZIONE' as status
FROM users;

-- Elimina tutti gli utenti ECCETTO il super admin
DELETE FROM users 
WHERE id != '00000000-0000-0000-0000-000000000001'::UUID;

-- Mostra il risultato
SELECT 
    COUNT(*) as totale_utenti_rimasti,
    '✅ UTENTI ELIMINATI (Super Admin preservato)' as status
FROM users;

-- Verifica che il super admin sia ancora presente
SELECT 
    id,
    email,
    nome,
    cognome,
    ruolo,
    stato,
    '✅ SUPER ADMIN ANCORA PRESENTE' as status
FROM users 
WHERE id = '00000000-0000-0000-0000-000000000001'::UUID;
