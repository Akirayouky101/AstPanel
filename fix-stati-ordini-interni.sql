-- =====================================================
-- Fix retroattivo: sposta ordini interni nel tab corretto
-- =====================================================
-- Eseguire in Supabase SQL Editor.
--
-- Logica:
--   Se numero_ordine_fornitore IS NOT NULL  → ordine evaso (ODF già creato)
--   Tutti gli altri approvati restano in 'approvato'
-- =====================================================

-- 1. Sposta approvati con ODF già creato → evaso
UPDATE ordini_interni
SET stato = 'evaso'
WHERE stato = 'approvato'
  AND numero_ordine_fornitore IS NOT NULL;

-- 2. Verifica risultato
SELECT stato, COUNT(*) as n
FROM ordini_interni
GROUP BY stato
ORDER BY stato;
