# 🚀 Guida Setup Supabase per AST Panel

## Step 1: Crea Progetto Supabase

1. Vai su [https://supabase.com](https://supabase.com)
2. Clicca su "Start your project"
3. Crea un nuovo progetto:
   - **Name**: AST-Panel
   - **Database Password**: (scegli una password sicura e salvala!)
   - **Region**: Europe West (Milan) o quella più vicina
4. Attendi che il progetto venga creato (~2 minuti)

## Step 2: Esegui lo Schema SQL

1. Nel dashboard Supabase, vai su **SQL Editor** (icona nella sidebar)
2. Clicca su **New Query**
3. Copia e incolla TUTTO il contenuto del file `database-schema.sql`
4. Clicca su **RUN** (o premi Ctrl+Enter)
5. Verifica che tutte le tabelle siano state create senza errori

## Step 3: Ottieni le Credenziali

1. Vai su **Project Settings** (icona ingranaggio in basso nella sidebar)
2. Clicca su **API**
3. Copia:
   - **Project URL** (esempio: `https://abcdefghijklmnop.supabase.co`)
   - **anon public** key (la chiave pubblica anonima)

## Step 4: Configura il Client

1. Apri il file `supabase-client.js`
2. Sostituisci le costanti all'inizio:

```javascript
const SUPABASE_URL = 'https://tuoproject.supabase.co'; // Incolla il tuo URL
const SUPABASE_ANON_KEY = 'eyJ...tua_chiave_qui'; // Incolla la tua anon key
```

## Step 5: Aggiungi Supabase JS Library

1. Apri ogni file HTML
2. Aggiungi PRIMA del tag `</head>`:

```html
<!-- Supabase -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="supabase-client.js"></script>
```

## Step 6: Crea Utente Admin Iniziale

1. Nel dashboard Supabase, vai su **SQL Editor**
2. Esegui questa query per creare un admin:

```sql
-- Inserisci utente admin
INSERT INTO users (email, nome, cognome, ruolo, telefono, avatar, reparto, data_assunzione, stato)
VALUES (
    'admin@astpanel.com',
    'Admin',
    'Sistema',
    'admin',
    '+39 123 456 7890',
    'https://i.pravatar.cc/150?img=1',
    'Amministrazione',
    CURRENT_DATE,
    'attivo'
);

-- Inserisci alcuni dipendenti di esempio
INSERT INTO users (email, nome, cognome, ruolo, telefono, avatar, reparto, data_assunzione, stato)
VALUES 
    ('mario.rossi@astpanel.com', 'Mario', 'Rossi', 'tecnico', '+39 111 222 333', 'https://i.pravatar.cc/150?img=12', 'Tecnico', '2024-01-15', 'attivo'),
    ('anna.verdi@astpanel.com', 'Anna', 'Verdi', 'tecnico', '+39 222 333 444', 'https://i.pravatar.cc/150?img=5', 'Tecnico', '2024-02-20', 'attivo'),
    ('giuseppe.neri@astpanel.com', 'Giuseppe', 'Neri', 'tecnico', '+39 333 444 555', 'https://i.pravatar.cc/150?img=8', 'Tecnico', '2024-03-10', 'attivo');
```

## Step 7: Test Connessione

1. Apri la console del browser (F12)
2. Digita:

```javascript
// Test connessione
await window.UsersAPI.getAll();
```

3. Dovresti vedere l'array degli utenti appena creati!

## 🔐 Autenticazione (da implementare dopo)

Per ora usiamo il sistema senza autenticazione vera. Quando siamo pronti:

1. Vai su **Authentication** > **Providers**
2. Abilita **Email** provider
3. Crea gli utenti con email e password
4. Usa `AuthService.login()` nel codice

## 📊 Visualizza i Dati

1. Vai su **Table Editor** nel dashboard
2. Puoi vedere e modificare tutti i dati delle tabelle
3. Puoi inserire dati manualmente per testing

## 🔄 Real-time (Opzionale)

Per abilitare aggiornamenti in tempo reale:

```javascript
// Esempio: ascolta cambiamenti sui task
window.RealtimeService.subscribe('tasks', (payload) => {
    console.log('Task updated:', payload);
    // Ricarica i task
    loadTasks();
});
```

## 🛠️ Prossimi Passi

Dopo aver configurato Supabase:
1. ✅ Testare ogni API (Users, Clients, Teams, Tasks)
2. ✅ Popolare il database con dati reali
3. ✅ Integrare le API nelle pagine HTML
4. ✅ Rimuovere localStorage e usare solo Supabase
5. ✅ Implementare autenticazione vera

---

**Note Importanti:**
- Le credenziali Supabase NON vanno committate su GitHub
- Usa file `.env` per production
- Il piano gratuito ha limiti (500MB storage, 2GB bandwidth/mese)
- Backup regolare del database consigliato
