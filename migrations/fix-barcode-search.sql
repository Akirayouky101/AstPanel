-- ================================================
-- FIX: Ricerca barcode migliorata
-- Data: 4 dicembre 2025
-- Descrizione: Cerca barcode sia in campo barcode che codice
-- ================================================

-- Modifica funzione per cercare in entrambi i campi
CREATE OR REPLACE FUNCTION find_component_by_barcode(p_barcode VARCHAR)
RETURNS TABLE (
    id UUID,
    codice VARCHAR,
    nome VARCHAR,
    categoria VARCHAR,
    quantita_magazzino INTEGER,
    quantita_minima INTEGER,
    unita_misura VARCHAR,
    barcode VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.codice,
        c.nome,
        c.categoria,
        c.quantita_magazzino,
        c.quantita_minima,
        c.unita_misura,
        c.barcode
    FROM components c
    WHERE c.barcode = p_barcode           -- Cerca nel campo barcode generato
       OR c.codice = p_barcode            -- Cerca nel campo codice prodotto
       OR c.barcode = 'COMP-' || p_barcode -- Cerca con prefisso COMP-
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Commento aggiornato
COMMENT ON FUNCTION find_component_by_barcode IS 'Ricerca componente tramite barcode (cerca in barcode, codice, e COMP-prefisso)';

-- ================================================
-- VERIFICA
-- ================================================
-- Test con barcode reale
-- SELECT * FROM find_component_by_barcode('8033971444582');
-- Test con barcode generato
-- SELECT * FROM find_component_by_barcode('COMP-8033971444582');
