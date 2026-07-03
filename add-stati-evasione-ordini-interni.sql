-- =====================================================
-- Nuovi stati per ordini interni: da_evadere + evaso
-- =====================================================
-- Nessuna modifica schema necessaria (stato è VARCHAR(30))
-- Questo file documenta i nuovi stati aggiunti via UI.
--
-- Workflow completo:
--   bozza → in_attesa → approvato → da_evadere → evaso
--                             ↓              ↓
--                          annullato      annullato
--
-- da_evadere : ordine approvato, esplicitamente marcato per evasione fornitore
-- evaso       : ordine evaso → ordine fornitore creato (ODF)

-- Verifica stati esistenti
SELECT stato, COUNT(*) as n
FROM ordini_interni
GROUP BY stato
ORDER BY stato;

-- Se vuoi retroattivamente marcare come "evaso" gli ordini
-- che hanno già un numero_ordine_fornitore collegato:
-- UPDATE ordini_interni
--    SET stato = 'evaso'
--  WHERE numero_ordine_fornitore IS NOT NULL
--    AND stato = 'approvato';
