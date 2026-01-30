-- ============================================
-- DEBUG TABELLA FORNITORI
-- ============================================
-- Script per verificare struttura, dati e policies
-- ============================================

-- 1. Verifica esistenza tabella
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'fornitori'
) as tabella_fornitori_esiste;

-- 2. Verifica struttura colonne
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'fornitori'
ORDER BY ordinal_position;

-- 3. Conta record totali
SELECT COUNT(*) as totale_fornitori FROM fornitori;

-- 4. Mostra tutti i fornitori con dettagli (usa SELECT * per vedere tutte le colonne)
SELECT *
FROM fornitori
LIMIT 10;

-- 5. Verifica RLS (Row Level Security)
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_abilitato
FROM pg_tables
WHERE schemaname = 'public' 
AND tablename = 'fornitori';

-- 6. Mostra tutte le policies RLS attive
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public' 
AND tablename = 'fornitori';

-- ============================================
-- SOLUZIONI COMUNI
-- ============================================

-- Se RLS è abilitato ma mancano policies, esegui:
/*
-- Policy per SELECT (lettura)
CREATE POLICY "Utenti autenticati possono vedere fornitori"
    ON fornitori FOR SELECT
    TO authenticated
    USING (true);

-- Policy per INSERT (creazione)
CREATE POLICY "Utenti autenticati possono creare fornitori"
    ON fornitori FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy per UPDATE (modifica)
CREATE POLICY "Utenti autenticati possono modificare fornitori"
    ON fornitori FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Policy per DELETE (eliminazione)
CREATE POLICY "Utenti autenticati possono eliminare fornitori"
    ON fornitori FOR DELETE
    TO authenticated
    USING (true);
*/

-- Se la tabella non esiste, probabilmente serve crearla:
/*
CREATE TABLE IF NOT EXISTS fornitori (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome_azienda VARCHAR(255) NOT NULL,
    codice_fornitore VARCHAR(50),
    partita_iva VARCHAR(20),
    codice_fiscale VARCHAR(20),
    indirizzo TEXT,
    citta VARCHAR(100),
    provincia VARCHAR(2),
    cap VARCHAR(10),
    nazione VARCHAR(50) DEFAULT 'Italia',
    telefono VARCHAR(20),
    email VARCHAR(255),
    pec VARCHAR(255),
    sito_web VARCHAR(255),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Abilita RLS
ALTER TABLE fornitori ENABLE ROW LEVEL SECURITY;

-- Aggiungi policies (vedi sopra)
*/

-- ============================================
-- FINE DEBUG
-- ============================================
