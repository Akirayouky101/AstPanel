-- Verifica stato utenti

SELECT 
    id,
    nome,
    cognome,
    email,
    ruolo,
    stato,
    created_at
FROM users
ORDER BY created_at DESC;
