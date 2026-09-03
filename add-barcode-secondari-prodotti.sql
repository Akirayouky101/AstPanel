-- Codici a barre alternativi per confezioni diverse dello stesso prodotto.
CREATE TABLE IF NOT EXISTS public.component_barcodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    component_id UUID NOT NULL REFERENCES public.components(id) ON DELETE CASCADE,
    barcode TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT component_barcodes_barcode_not_empty CHECK (length(trim(barcode)) > 0)
);

CREATE INDEX IF NOT EXISTS idx_component_barcodes_component_id
    ON public.component_barcodes(component_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_component_barcodes_barcode_unique
    ON public.component_barcodes(lower(barcode));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.component_barcodes TO authenticated;

ALTER TABLE public.component_barcodes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "component_barcodes_select_authenticated" ON public.component_barcodes;
CREATE POLICY "component_barcodes_select_authenticated"
    ON public.component_barcodes FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "component_barcodes_insert_authenticated" ON public.component_barcodes;
CREATE POLICY "component_barcodes_insert_authenticated"
    ON public.component_barcodes FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "component_barcodes_update_authenticated" ON public.component_barcodes;
CREATE POLICY "component_barcodes_update_authenticated"
    ON public.component_barcodes FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "component_barcodes_delete_authenticated" ON public.component_barcodes;
CREATE POLICY "component_barcodes_delete_authenticated"
    ON public.component_barcodes FOR DELETE TO authenticated USING (true);

CREATE OR REPLACE FUNCTION public.set_component_secondary_barcodes(
    p_component_id UUID,
    p_barcodes TEXT[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    normalized_barcodes TEXT[];
BEGIN
    SELECT COALESCE(array_agg(trim(value)), ARRAY[]::TEXT[])
    INTO normalized_barcodes
    FROM (
        SELECT DISTINCT ON (lower(trim(raw_value))) raw_value AS value
        FROM unnest(COALESCE(p_barcodes, ARRAY[]::TEXT[])) AS raw_value
        WHERE length(trim(raw_value)) > 0
          AND lower(trim(raw_value)) <> COALESCE(
              (SELECT lower(trim(barcode)) FROM public.components WHERE id = p_component_id),
              ''
          )
        ORDER BY lower(trim(raw_value))
    ) AS unique_values;

    IF EXISTS (
        SELECT 1
        FROM public.components
        WHERE id <> p_component_id
          AND lower(trim(barcode)) IN (
              SELECT lower(trim(value)) FROM unnest(normalized_barcodes) AS value
          )
    ) THEN
        RAISE EXCEPTION 'Uno dei codici secondari e gia usato come barcode principale';
    END IF;

    DELETE FROM public.component_barcodes WHERE component_id = p_component_id;

    INSERT INTO public.component_barcodes(component_id, barcode)
    SELECT p_component_id, value
    FROM unnest(normalized_barcodes) AS value;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_component_secondary_barcodes(UUID, TEXT[]) TO authenticated;

CREATE OR REPLACE FUNCTION public.prevent_primary_barcode_alias_conflict()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF NEW.barcode IS NOT NULL AND EXISTS (
        SELECT 1
        FROM public.component_barcodes
        WHERE component_id <> NEW.id
          AND lower(trim(barcode)) = lower(trim(NEW.barcode))
    ) THEN
        RAISE EXCEPTION 'Il barcode principale e gia usato come codice secondario';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_primary_barcode_alias_conflict ON public.components;
CREATE TRIGGER trg_prevent_primary_barcode_alias_conflict
    BEFORE INSERT OR UPDATE OF barcode ON public.components
    FOR EACH ROW EXECUTE FUNCTION public.prevent_primary_barcode_alias_conflict();

COMMENT ON TABLE public.component_barcodes IS
    'Barcode secondari associati a confezioni diverse dello stesso prodotto';