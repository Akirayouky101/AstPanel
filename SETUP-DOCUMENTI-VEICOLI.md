# 📁 Setup Storage e Database per Documenti Veicoli

## ⚠️ ISTRUZIONI DEPLOYMENT

Esegui i seguenti passi **NELL'ORDINE INDICATO** su Supabase:

---

## 1️⃣ CREA STORAGE BUCKET

### Dashboard Supabase → Storage → Create Bucket

**Configurazione:**
```
Bucket Name: vehicle-documents
Public: NO (privato)
File Size Limit: 10 MB
Allowed MIME types: image/*, application/pdf
```

**Oppure via SQL:**
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('vehicle-documents', 'vehicle-documents', false);
```

---

## 2️⃣ CONFIGURA STORAGE POLICIES

### Dashboard Supabase → Storage → vehicle-documents → Policies

Crea le seguenti 3 policies:

### Policy 1: SELECT (Lettura)
```sql
CREATE POLICY "Utenti autenticati possono leggere documenti veicoli"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'vehicle-documents');
```

### Policy 2: INSERT (Upload)
```sql
CREATE POLICY "Utenti autenticati possono caricare documenti veicoli"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'vehicle-documents');
```

### Policy 3: DELETE (Eliminazione)
```sql
CREATE POLICY "Utenti autenticati possono eliminare documenti veicoli"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'vehicle-documents');
```

---

## 3️⃣ ESEGUI SQL MIGRATION

### Dashboard Supabase → SQL Editor → New Query

Copia e incolla il contenuto di `migrations/add-vehicle-documents.sql`:

```sql
-- ============================================
-- SISTEMA DOCUMENTI VEICOLI
-- ============================================

-- Tabella documenti veicoli
CREATE TABLE IF NOT EXISTS vehicle_documents (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id uuid NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    nome_file varchar(255) NOT NULL,
    tipo_documento varchar(50) NOT NULL,
    descrizione text,
    url_file text NOT NULL,
    mime_type varchar(100),
    dimensione_kb integer,
    data_scadenza date,
    uploaded_by uuid REFERENCES auth.users(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- [... resto del codice SQL ...]
```

**Oppure esegui direttamente il file:**
```bash
# Dal terminale, se hai psql configurato
psql -h <your-db-host> -U postgres -d postgres -f migrations/add-vehicle-documents.sql
```

---

## 4️⃣ VERIFICA INSTALLAZIONE

### Test Tabella
```sql
SELECT COUNT(*) FROM vehicle_documents;
-- Deve ritornare 0 (nessun errore)
```

### Test View
```sql
SELECT * FROM v_vehicle_documents LIMIT 1;
-- Deve ritornare 0 righe (nessun errore)
```

### Test Storage
```sql
SELECT * FROM storage.buckets WHERE id = 'vehicle-documents';
-- Deve ritornare 1 riga con il bucket
```

### Test Policies Storage
```sql
SELECT * FROM storage.policies WHERE bucket_id = 'vehicle-documents';
-- Deve ritornare 3 righe (SELECT, INSERT, DELETE)
```

### Test RLS
```sql
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'vehicle_documents';
-- rowsecurity deve essere 't' (true)
```

---

## ✅ CHECKLIST POST-DEPLOYMENT

- [ ] Bucket `vehicle-documents` creato
- [ ] Bucket configurato come PRIVATO
- [ ] 3 Storage policies attive (SELECT, INSERT, DELETE)
- [ ] Tabella `vehicle_documents` creata
- [ ] View `v_vehicle_documents` creata
- [ ] RLS abilitato su `vehicle_documents`
- [ ] 4 RLS policies attive (SELECT, INSERT, UPDATE, DELETE)
- [ ] Indici creati (3 indici)
- [ ] Trigger `update_vehicle_documents_updated_at` attivo
- [ ] ON DELETE CASCADE configurato su `vehicle_id`

---

## 🧪 TEST FUNZIONALITÀ

1. **Apri** `gestione-mezzi.html`
2. **Modifica** un veicolo esistente
3. **Vai al tab "Documenti"**
4. **Click** "Carica Documento"
5. **Seleziona** un file (immagine o PDF)
6. **Compila** tipo documento e descrizione
7. **Click** "Conferma Upload"
8. **Verifica** documento apparso nella gallery
9. **Click** "Visualizza" → apre in nuova tab
10. **Click** "Scarica" → download file
11. **Click** cestino → elimina documento
12. **Verifica** documento rimosso da lista
13. **Elimina veicolo** dalla lista mezzi
14. **Verifica su Supabase Storage** → file eliminati
15. **Verifica su database** → record `vehicle_documents` eliminati

---

## 🗄️ STRUTTURA DATABASE

### Tabella: `vehicle_documents`

| Colonna | Tipo | Descrizione | Constraints |
|---------|------|-------------|-------------|
| id | uuid | Primary Key | PK, auto-generated |
| vehicle_id | uuid | FK veicolo | NOT NULL, ON DELETE CASCADE |
| nome_file | varchar(255) | Nome file originale | NOT NULL |
| tipo_documento | varchar(50) | Tipo documento | NOT NULL |
| descrizione | text | Descrizione | NULL |
| url_file | text | URL Supabase Storage | NOT NULL |
| mime_type | varchar(100) | Tipo MIME | NULL |
| dimensione_kb | integer | Dimensione in KB | NULL |
| data_scadenza | date | Data scadenza | NULL |
| uploaded_by | uuid | FK utente | NULL |
| created_at | timestamp | Data creazione | DEFAULT now() |
| updated_at | timestamp | Data modifica | DEFAULT now() |

### Tipi Documento Supportati:
- `libretto` - 📘 Libretto circolazione
- `assicurazione` - 🛡️ Polizza assicurativa
- `revisione` - ✅ Certificato revisione
- `bollo` - 💰 Ricevuta bollo auto
- `contratto_noleggio` - 📄 Contratto noleggio
- `fattura` - 🧾 Fattura manutenzione/acquisto
- `altro` - 📎 Altro documento

### Indici Creati:
```sql
idx_vehicle_documents_vehicle  -- Su vehicle_id
idx_vehicle_documents_tipo     -- Su tipo_documento
idx_vehicle_documents_scadenza -- Su data_scadenza (WHERE NOT NULL)
```

---

## 🔒 SICUREZZA

### RLS (Row Level Security)
- ✅ Abilitato su `vehicle_documents`
- ✅ Tutti gli utenti autenticati possono: SELECT, INSERT, UPDATE, DELETE
- ✅ Utenti non autenticati: NESSUN ACCESSO

### Storage Security
- ✅ Bucket PRIVATO (non pubblico)
- ✅ Solo utenti autenticati possono caricare/leggere/eliminare
- ✅ File accessibili solo via signed URL o con token auth

### Cascade Delete
- ✅ Eliminando un veicolo → elimina automaticamente tutti i documenti dal DB
- ✅ Codice frontend elimina anche i file da Storage prima di eliminare il veicolo

---

## 🚀 FUNZIONALITÀ FRONTEND

### Upload Documenti
1. Click "Carica Documento"
2. Seleziona file (multipli supportati)
3. Compila metadata:
   - Tipo documento (obbligatorio)
   - Data scadenza (opzionale)
   - Descrizione (opzionale)
4. Click "Conferma Upload"
5. File caricati su Storage
6. Metadata salvati su DB
7. Gallery aggiornata automaticamente

### Visualizzazione
- **Card per ogni documento** con:
  - Icon tipo documento
  - Nome file e dimensione
  - Anteprima immagini
  - Badge scadenza (giallo/rosso se scaduto)
  - Pulsanti: Visualizza, Scarica, Elimina
  - Data caricamento

### Gestione Scadenze
- Se `data_scadenza` impostata:
  - Badge giallo se non scaduto
  - Badge rosso + bordo rosso card se scaduto
  - Calcolo automatico stato scadenza

### Eliminazione Sicura
- Conferma prima di eliminare
- Elimina file da Storage
- Elimina record da DB
- Aggiorna UI automaticamente

---

## 🔧 TROUBLESHOOTING

### Errore: "Bucket not found"
➡️ Verifica che il bucket `vehicle-documents` sia stato creato  
➡️ Controlla Storage → Buckets

### Errore: "Permission denied for storage"
➡️ Verifica che le 3 storage policies siano attive  
➡️ Storage → vehicle-documents → Policies

### Errore: "relation vehicle_documents does not exist"
➡️ Esegui la migration SQL  
➡️ SQL Editor → Esegui `add-vehicle-documents.sql`

### Errore: "insert or update on table violates foreign key constraint"
➡️ Verifica che la tabella `vehicles` esista  
➡️ Verifica che il `vehicle_id` sia corretto

### Documenti non si eliminano quando elimino veicolo
➡️ Verifica ON DELETE CASCADE su `vehicle_id`  
➡️ Esegui: `SELECT confdeltype FROM pg_constraint WHERE conname LIKE '%vehicle_documents%';`  
➡️ Deve ritornare 'c' (CASCADE)

### File rimangono su Storage dopo eliminazione veicolo
➡️ Verifica che il codice frontend esegua `loadDocuments()` prima di eliminare  
➡️ Verifica console browser per errori JavaScript

---

## 📊 QUERY UTILI

### Conta documenti per veicolo
```sql
SELECT 
    v.targa,
    v.marca,
    v.modello,
    COUNT(vd.id) as totale_documenti,
    SUM(vd.dimensione_kb) as totale_kb
FROM vehicles v
LEFT JOIN vehicle_documents vd ON v.id = vd.vehicle_id
GROUP BY v.id, v.targa, v.marca, v.modello
ORDER BY totale_documenti DESC;
```

### Documenti in scadenza nei prossimi 30 giorni
```sql
SELECT 
    v.targa,
    vd.tipo_documento,
    vd.nome_file,
    vd.data_scadenza,
    (vd.data_scadenza - CURRENT_DATE) as giorni_mancanti
FROM vehicle_documents vd
JOIN vehicles v ON vd.vehicle_id = v.id
WHERE vd.data_scadenza IS NOT NULL
  AND vd.data_scadenza <= CURRENT_DATE + 30
ORDER BY vd.data_scadenza ASC;
```

### Documenti scaduti
```sql
SELECT 
    v.targa,
    vd.tipo_documento,
    vd.nome_file,
    vd.data_scadenza,
    (CURRENT_DATE - vd.data_scadenza) as giorni_scaduti
FROM vehicle_documents vd
JOIN vehicles v ON vd.vehicle_id = v.id
WHERE vd.data_scadenza < CURRENT_DATE
ORDER BY vd.data_scadenza ASC;
```

### Totale spazio Storage occupato
```sql
SELECT 
    COUNT(*) as totale_documenti,
    SUM(dimensione_kb) as totale_kb,
    ROUND(SUM(dimensione_kb)::numeric / 1024, 2) as totale_mb
FROM vehicle_documents;
```

### Documenti per tipo
```sql
SELECT 
    tipo_documento,
    COUNT(*) as quantita,
    SUM(dimensione_kb) as totale_kb
FROM vehicle_documents
GROUP BY tipo_documento
ORDER BY quantita DESC;
```

---

## 📝 NOTE IMPORTANTI

### Limiti Storage
- **File size**: Max 10 MB per file
- **Formati**: Solo immagini e PDF
- **Quota Supabase**: Verifica piano (Free tier: 1 GB)

### Performance
- Indici creati su colonne frequentemente interrogate
- View materializzata per performance su query complesse
- Trigger per auto-update `updated_at`

### Backup
- I file Storage NON sono inclusi nel backup automatico DB
- Backup manuale necessario per Storage bucket
- Considera export periodico documenti critici

### Privacy
- File Storage privati (no public URL)
- Accesso solo via autenticazione
- Considera encryption at rest per documenti sensibili

---

## ✅ DEPLOYMENT COMPLETATO

Dopo aver eseguito tutti i passi:

1. ✅ Storage bucket creato e configurato
2. ✅ Policies storage attive
3. ✅ Tabella database creata
4. ✅ RLS e policies DB attive
5. ✅ Trigger e view funzionanti
6. ✅ Cascade delete configurato
7. ✅ Frontend aggiornato
8. ✅ Test eseguiti con successo

**Sistema documenti veicoli OPERATIVO! 🚀**

---

_Documento creato: 2026-01-29_  
_File SQL: migrations/add-vehicle-documents.sql_  
_Frontend: gestione-mezzi.html_
