-- ============================================
-- CREA UTENTE DI SISTEMA
-- ============================================
-- Crea un utente "Sistema" con UUID fisso
-- usato dai trigger quando non c'è un utente autenticato
-- ============================================

INSERT INTO users (
    id,
    auth_id,
    nome,
    cognome,
    email,
    ruolo
) VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Sistema',
    'Automatico',
    'sistema@astpanel.local',
    'admin'
)
ON CONFLICT (id) DO NOTHING;

-- Verifica
SELECT id, nome, cognome, email FROM users WHERE id = '00000000-0000-0000-0000-000000000001';
