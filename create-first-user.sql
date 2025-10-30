-- =====================================================
-- Crea il primo utente ADMIN
-- =====================================================
-- Esegui questo script per creare il tuo primo utente admin

INSERT INTO users (email, nome, cognome, ruolo, telefono, stato)
VALUES 
    ('admin@astpanel.com', 'Admin', 'Sistema', 'admin', '+39 123 456 7890', 'attivo')
RETURNING *;

-- =====================================================
-- Query utile: Visualizza tutti gli utenti
-- =====================================================
-- SELECT * FROM users ORDER BY created_at DESC;
