-- Allarga la colonna stato su ordini_fornitore_items e ordini_fornitore
-- per supportare 'parzialmente_ricevuto' (21 caratteri)

ALTER TABLE ordini_fornitore_items
ALTER COLUMN stato TYPE TEXT;

ALTER TABLE ordini_fornitore
ALTER COLUMN stato TYPE TEXT;
