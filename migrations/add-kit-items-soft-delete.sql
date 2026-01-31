-- Aggiungi soft delete ai componenti del kit per tracciare chi ha eliminato cosa

-- Drop tutti i trigger su kit_items (basta complicazioni!)
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;
DROP TRIGGER IF EXISTS trigger_verifica_giacenza_kit ON kit_items;
DROP TRIGGER IF EXISTS trigger_impegna_kit ON kit_items;

-- Aggiungi colonne per soft delete
ALTER TABLE kit_items 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS deleted_by UUID REFERENCES users(id);

-- Commento
COMMENT ON COLUMN kit_items.deleted_at IS 'Data eliminazione componente dal kit';
COMMENT ON COLUMN kit_items.deleted_by IS 'Utente che ha rimosso il componente dal kit';

-- Verifica
SELECT 'Trigger rimossi, soft delete abilitato su kit_items' AS status;
