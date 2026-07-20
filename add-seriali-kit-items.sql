-- Aggiunge seriali a kit_items per tracciamento numeri di serie nei kit
ALTER TABLE kit_items
ADD COLUMN IF NOT EXISTS seriali TEXT[] DEFAULT '{}';
