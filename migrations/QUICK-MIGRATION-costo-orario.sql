-- ================================================
-- QUICK MIGRATION: Costo Orario per Sistema Timbrature
-- Data: 7 dicembre 2025
-- COPIA TUTTO E INCOLLA IN SUPABASE SQL EDITOR
-- ================================================

-- STEP 1: Aggiungi campo costo_orario
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS costo_orario DECIMAL(10,2) DEFAULT 0;

-- STEP 2: Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_users_costo_orario 
ON users(costo_orario);

-- STEP 3: Aggiungi commento descrittivo
COMMENT ON COLUMN users.costo_orario IS 'Costo orario del dipendente in euro (es: 25.00 = 25€/ora)';

-- ================================================
-- CONFIGURAZIONE INIZIALE (MODIFICA I VALORI!)
-- ================================================

-- Imposta costo orario per il TUO utente (per testare)
-- SOSTITUISCI 'tua@email.com' con la tua email!
UPDATE users 
SET costo_orario = 25.00 
WHERE email = 'tua@email.com';

-- OPPURE imposta per TUTTI i ruoli (decommentare se vuoi):
-- UPDATE users SET costo_orario = 20.00 WHERE ruolo = 'Dipendente' AND costo_orario = 0;
-- UPDATE users SET costo_orario = 25.00 WHERE ruolo = 'Tecnico' AND costo_orario = 0;
-- UPDATE users SET costo_orario = 35.00 WHERE ruolo = 'Amministratore' AND costo_orario = 0;
-- UPDATE users SET costo_orario = 30.00 WHERE ruolo = 'Sviluppatore' AND costo_orario = 0;

-- ================================================
-- VERIFICA CHE FUNZIONI
-- ================================================

-- Controlla tutti gli utenti e i loro costi orari
SELECT 
    id,
    email,
    nome,
    cognome,
    ruolo,
    costo_orario,
    CASE 
        WHEN costo_orario > 0 THEN '✅ Configurato'
        ELSE '⚠️ Da configurare'
    END as stato
FROM users
ORDER BY costo_orario DESC;

-- ================================================
-- RISULTATO ATTESO
-- ================================================
-- Dovresti vedere una tabella con tutti gli utenti
-- La colonna 'costo_orario' deve avere valori > 0
-- La colonna 'stato' deve mostrare '✅ Configurato'
-- 
-- Se vedi '⚠️ Da configurare', esegui l'UPDATE sopra!
-- ================================================
