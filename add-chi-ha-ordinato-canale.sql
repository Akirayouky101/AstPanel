-- Aggiunge i campi "chi ha effettuato l'ordine" e "canale ordine" alla tabella ordini_interni
-- Esegui questo script nel SQL Editor di Supabase (dashboard.supabase.com)

ALTER TABLE ordini_interni
  ADD COLUMN IF NOT EXISTS chi_ha_ordinato VARCHAR(200),
  ADD COLUMN IF NOT EXISTS canale_ordine   VARCHAR(50);
