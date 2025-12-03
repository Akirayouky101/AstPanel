# 📦 Configurazione Supabase Storage per PDF Reports

## Step 1: Creare Bucket Storage

1. Vai su **Supabase Dashboard**: https://supabase.com/dashboard
2. Seleziona il tuo progetto **AST Panel**
3. Nel menu laterale, clicca su **Storage**
4. Clicca su **Create a new bucket** (o **New Bucket**)
5. Configura il bucket:
   ```
   Nome: reports
   Public bucket: ✅ YES (importante per download PDF)
   File size limit: 10 MB
   Allowed MIME types: application/pdf, image/png
   ```
6. Clicca **Create bucket**

## Step 2: Eseguire Migration Database

1. Vai su **Supabase Dashboard** > **SQL Editor**
2. Copia il contenuto del file `migrations/add-firma-digitale.sql`
3. Incolla nell'editor SQL
4. Clicca **RUN** per eseguire

## Step 3: Verificare Configurazione

### Test Bucket Storage:
```javascript
// Console browser (pannello-utente.html)
const { data, error } = await window.supabase.storage
  .from('reports')
  .list();

console.log('Bucket reports:', data, error);
// Output atteso: { data: [], error: null }
```

### Test Colonne Database:
```sql
SELECT firma_cliente, firma_timestamp, pdf_report_url 
FROM lavorazioni 
LIMIT 1;
```

## Step 4: Test Upload PDF

1. Apri `pannello-utente.html`
2. Vai su una lavorazione NON completata
3. Clicca **Fai Firmare**
4. Firma con il mouse/dito
5. Clicca **Conferma & Genera PDF**
6. Verifica:
   - ✅ PDF scaricato localmente
   - ✅ Firma salvata nel database
   - ✅ PDF caricato su Storage
   - ✅ URL salvato in `pdf_report_url`

## Struttura Folder Storage

```
reports/
  └── lavorazioni/
      └── {lavorazione_id}/
          └── Lavorazione_{cliente}_{data}.pdf
```

Esempio:
```
reports/lavorazioni/123e4567-e89b-12d3-a456-426614174000/Lavorazione_Mario_Rossi_2025-12-03.pdf
```

## Troubleshooting

### Errore: "Bucket not found"
- Verifica che il bucket "reports" sia stato creato
- Controlla che sia pubblico

### Errore: "Row level security"
- Il bucket pubblico non dovrebbe avere RLS
- Se necessario, disabilita RLS sul bucket

### PDF non si carica
- Verifica console browser per errori
- Controlla dimensione file (max 10MB)
- Verifica MIME type (deve essere application/pdf)

## Comandi Utili

### Vedere tutti i file nel bucket:
```javascript
const { data } = await window.supabase.storage
  .from('reports')
  .list('lavorazioni', { limit: 100 });
console.log(data);
```

### Eliminare un file:
```javascript
await window.supabase.storage
  .from('reports')
  .remove(['lavorazioni/123/file.pdf']);
```

### Get public URL:
```javascript
const { data } = window.supabase.storage
  .from('reports')
  .getPublicUrl('lavorazioni/123/file.pdf');
console.log(data.publicUrl);
```

## ✅ Checklist Configurazione

- [ ] Bucket "reports" creato
- [ ] Bucket configurato come pubblico
- [ ] Migration SQL eseguita
- [ ] Colonne aggiunte a tabella lavorazioni
- [ ] Test upload PDF funzionante
- [ ] Test download PDF funzionante
- [ ] Firma salvata in database
- [ ] URL PDF salvato in database
