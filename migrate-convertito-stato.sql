-- Aggiorna le richieste già convertite (ordine_fornitore_id impostato)
-- che hanno ancora il vecchio stato (accettato, risposto, ecc.)
UPDATE richieste_preventivo_fornitori
SET stato = 'convertito'
WHERE ordine_fornitore_id IS NOT NULL
  AND stato != 'convertito';

-- Verifica
SELECT numero, stato, ordine_fornitore_id
FROM richieste_preventivo_fornitori
WHERE ordine_fornitore_id IS NOT NULL
ORDER BY data_richiesta DESC;
