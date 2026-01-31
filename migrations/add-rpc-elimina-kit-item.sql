-- ============================================
-- RPC Function: elimina_kit_item
-- ============================================
-- Elimina un kit_item senza attivare il trigger
-- che crea i movimenti di magazzino
-- (i movimenti vengono gestiti manualmente dal frontend)
-- ============================================

CREATE OR REPLACE FUNCTION elimina_kit_item(p_kit_item_id UUID)
RETURNS void AS $$
BEGIN
    -- Disabilita temporaneamente il trigger
    SET LOCAL session_replication_role = 'replica';
    
    -- Elimina il kit_item
    DELETE FROM kit_items WHERE id = p_kit_item_id;
    
    -- Riabilita i trigger
    SET LOCAL session_replication_role = 'origin';
    
    RAISE NOTICE 'Kit item % eliminato senza attivare trigger', p_kit_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permetti agli utenti autenticati di eseguire questa funzione
GRANT EXECUTE ON FUNCTION elimina_kit_item(UUID) TO authenticated;

COMMENT ON FUNCTION elimina_kit_item IS 'Elimina un kit_item senza attivare trigger di movimenti magazzino';
