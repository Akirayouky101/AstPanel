# 🚀 Guida Rapida: Esegui Migration su Supabase

## ⏱️ Tempo richiesto: 2 minuti

---

## 📋 STEP 1: Apri Supabase SQL Editor

1. Vai su: **https://supabase.com/dashboard**
2. Seleziona il tuo progetto: **AstPanel** (o nome simile)
3. Nella sidebar sinistra, clicca: **SQL Editor**
4. Clicca il bottone verde: **+ New Query**

---

## 📝 STEP 2: Copia la Migration

1. Apri il file: `migrations/QUICK-MIGRATION-costo-orario.sql`
2. Seleziona **TUTTO** il contenuto (Ctrl+A / Cmd+A)
3. Copia (Ctrl+C / Cmd+C)

---

## ✏️ STEP 3: Modifica la Email

**IMPORTANTE!** Prima di eseguire, trova questa riga:

```sql
WHERE email = 'tua@email.com';
```

E sostituisci `'tua@email.com'` con la **TUA email** che usi per il login!

Esempio:
```sql
WHERE email = 'mario.rossi@example.com';
```

---

## ▶️ STEP 4: Esegui la Migration

1. Incolla tutto nel SQL Editor di Supabase (Ctrl+V / Cmd+V)
2. Clicca il bottone verde: **Run** (o premi Ctrl+Enter)
3. Aspetta 2-3 secondi...

---

## ✅ STEP 5: Verifica il Risultato

Dovresti vedere una **tabella** con tutti i tuoi utenti:

```
| email                  | nome  | cognome | ruolo      | costo_orario | stato             |
|------------------------|-------|---------|------------|--------------|-------------------|
| mario.rossi@email.com  | Mario | Rossi   | Dipendente | 25.00        | ✅ Configurato    |
| ...                    | ...   | ...     | ...        | 0.00         | ⚠️ Da configurare |
```

**Cosa controllare:**
- ✅ La TUA riga deve avere `costo_orario = 25.00` (o altro valore > 0)
- ✅ Nella colonna `stato` deve esserci: **✅ Configurato**

---

## 🐛 Troubleshooting

### ❌ Errore: "column costo_orario already exists"
**Soluzione:** La colonna esiste già! Vai direttamente allo STEP "Verifica":
```sql
SELECT id, email, nome, cognome, ruolo, costo_orario 
FROM users 
WHERE email = 'tua@email.com';
```

Se `costo_orario` è `0` o `NULL`, esegui solo l'UPDATE:
```sql
UPDATE users SET costo_orario = 25.00 WHERE email = 'tua@email.com';
```

### ❌ Errore: "permission denied"
**Soluzione:** Devi essere Owner o Admin del progetto Supabase.

### ⚠️ Il mio utente ha ancora `costo_orario = 0`
**Soluzione:** Hai dimenticato di modificare l'email nell'UPDATE! Esegui:
```sql
UPDATE users SET costo_orario = 25.00 WHERE email = 'LA_TUA_EMAIL_VERA';
SELECT * FROM users WHERE email = 'LA_TUA_EMAIL_VERA';
```

---

## 🎯 Prossimo Step

Una volta che vedi **✅ Configurato** per il tuo utente:

1. Vai su: `https://[tuo-dominio].vercel.app/orari-dipendente.html`
2. Fai login
3. Clicca **"Timbra Ingresso"**
4. Guarda **"Guadagno Oggi"** → dovrebbe aumentare in tempo reale!

---

## 💡 Valori Consigliati per costo_orario

| Ruolo           | Tariffa suggerita |
|-----------------|-------------------|
| Dipendente      | €20 - €25 /ora   |
| Tecnico         | €25 - €30 /ora   |
| Amministratore  | €30 - €40 /ora   |
| Sviluppatore    | €35 - €50 /ora   |

**Puoi modificare in qualsiasi momento:**
```sql
UPDATE users SET costo_orario = 30.00 WHERE email = 'tua@email.com';
```

---

## ✨ Cosa Succede Dopo

Con `costo_orario` configurato, il sistema calcolerà **automaticamente**:

- 💰 **Guadagno Oggi**: Aggiornato ogni secondo durante la timbratura
- 💰 **Guadagno Mese**: Totale mensile nella sezione "Mese Corrente"
- 📊 **Statistiche**: Disponibili per admin in `gestione-orari.html`

---

**File migration completo:** `migrations/add-costo-orario-users.sql`  
**File quick migration:** `migrations/QUICK-MIGRATION-costo-orario.sql` ⭐ (Usa questo!)

**Pronto?** Copia il contenuto di `QUICK-MIGRATION-costo-orario.sql` e incollalo su Supabase! 🚀
