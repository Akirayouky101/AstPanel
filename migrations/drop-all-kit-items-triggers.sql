-- Rimuovi TUTTI i trigger da kit_items per gestire tutto dal frontend

DROP TRIGGER IF EXISTS trigger_ripristina_giacenza_kit ON kit_items;
DROP TRIGGER IF EXISTS trigger_scala_giacenza_kit ON kit_items;
DROP TRIGGER IF EXISTS trigger_verifica_giacenza_libera_kit ON kit_items;
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;
DROP TRIGGER IF EXISTS trigger_verifica_giacenza_kit ON kit_items;
DROP TRIGGER IF EXISTS trigger_impegna_kit ON kit_items;

-- Verifica che non ci siano più trigger
SELECT 'Tutti i trigger su kit_items sono stati rimossi' AS status;

-- Controlla (dovrebbe essere vuoto)
SELECT tgname AS trigger_name
FROM pg_trigger t
WHERE t.tgrelid = 'kit_items'::regclass
AND NOT tgisinternal;
