-- Permette a varianti taglia dello stesso articolo (Vestiario) di condividere lo stesso barcode.
-- Sostituisce il vincolo UNIQUE su components.barcode con un trigger che blocca i duplicati
-- SOLO tra articoli di gruppi diversi (o senza gruppo): il barcode resta univoco "per articolo",
-- non per singola taglia.

BEGIN;

ALTER TABLE public.components
    ADD COLUMN IF NOT EXISTS gruppo_taglia_id UUID DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_components_gruppo_taglia
    ON public.components(gruppo_taglia_id) WHERE gruppo_taglia_id IS NOT NULL;

-- Rimuove il vincolo UNIQUE esistente su barcode (nome del constraint non garantito: ricerca dinamica)
DO $$
DECLARE
    nome_vincolo text;
BEGIN
    SELECT tc.constraint_name INTO nome_vincolo
    FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu
      ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema
    WHERE tc.table_schema = 'public'
      AND tc.table_name = 'components'
      AND tc.constraint_type = 'UNIQUE'
      AND ccu.column_name = 'barcode'
    LIMIT 1;

    IF nome_vincolo IS NOT NULL THEN
        EXECUTE format('ALTER TABLE public.components DROP CONSTRAINT %I', nome_vincolo);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_components_barcode
    ON public.components(barcode) WHERE barcode IS NOT NULL;

-- Trigger: stesso messaggio/formato di una violazione UNIQUE nativa, così il codice
-- applicativo (che fa il parsing di error.details) continua a funzionare invariato.
CREATE OR REPLACE FUNCTION public.check_barcode_gruppo_taglia()
RETURNS TRIGGER AS $$
DECLARE
    conflitto RECORD;
BEGIN
    IF NEW.barcode IS NULL OR trim(NEW.barcode) = '' THEN
        RETURN NEW;
    END IF;

    SELECT id, gruppo_taglia_id INTO conflitto
    FROM public.components
    WHERE id <> NEW.id
      AND lower(trim(barcode)) = lower(trim(NEW.barcode))
    LIMIT 1;

    IF FOUND THEN
        IF NEW.gruppo_taglia_id IS NULL
           OR conflitto.gruppo_taglia_id IS NULL
           OR conflitto.gruppo_taglia_id <> NEW.gruppo_taglia_id THEN
            RAISE EXCEPTION 'duplicate key value violates unique constraint "components_barcode_key"'
                USING ERRCODE = '23505',
                      DETAIL  = format('Key (barcode)=(%s) already exists.', NEW.barcode);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_barcode_gruppo_taglia ON public.components;
CREATE TRIGGER trg_check_barcode_gruppo_taglia
    BEFORE INSERT OR UPDATE OF barcode, gruppo_taglia_id ON public.components
    FOR EACH ROW EXECUTE FUNCTION public.check_barcode_gruppo_taglia();

COMMIT;

-- Verifica: il vincolo UNIQUE nativo non deve più esistere, la colonna e il trigger sì
SELECT
    (SELECT count(*) FROM information_schema.table_constraints
      WHERE table_schema='public' AND table_name='components' AND constraint_type='UNIQUE'
        AND constraint_name IN (SELECT constraint_name FROM information_schema.constraint_column_usage WHERE column_name='barcode')) AS vincoli_unique_barcode_rimasti,
    (SELECT count(*) FROM information_schema.columns
      WHERE table_schema='public' AND table_name='components' AND column_name='gruppo_taglia_id') AS colonna_presente,
    (SELECT count(*) FROM pg_trigger WHERE tgname='trg_check_barcode_gruppo_taglia') AS trigger_presente;
