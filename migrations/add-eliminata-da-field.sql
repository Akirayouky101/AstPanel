-- Add eliminata_da field to track user deletions
-- This stores an array of objects with user_id and timestamp when user "deletes" a communication

ALTER TABLE communications 
ADD COLUMN IF NOT EXISTS eliminata_da JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN communications.eliminata_da IS 'Array of {user_id: UUID, deleted_at: timestamp} tracking who deleted this communication';

-- Add archiviata_da field to track user archives
ALTER TABLE communications 
ADD COLUMN IF NOT EXISTS archiviata_da UUID[] DEFAULT ARRAY[]::UUID[];

COMMENT ON COLUMN communications.archiviata_da IS 'Array of user UUIDs who archived this communication';
