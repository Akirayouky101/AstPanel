# 🚀 INTEGRAZIONE SUPABASE - Guida Rapida

## ✅ Cosa è stato fatto

1. **Configurato `supabase-client.js`** con le tue credenziali
2. **Creato `auth-helper.js`** per gestire login/logout
3. **Creato `data-migration.js`** per sostituire localStorage con Supabase
4. **Creato pagina login** (`Admin/index.html`)
5. **Creato script SQL** per il primo utente admin

---

## 📋 PROSSIMI PASSI

### 1️⃣ Crea il primo utente Admin

Vai su **Supabase → SQL Editor** ed esegui:

```sql
INSERT INTO users (email, nome, cognome, ruolo, telefono, stato)
VALUES 
    ('tuoemail@example.com', 'Tuo Nome', 'Tuo Cognome', 'admin', '+39 123456789', 'attivo')
RETURNING *;
```

Oppure esegui il file `create-first-user.sql`.

---

### 2️⃣ Aggiungi gli script nelle pagine HTML

In **TUTTE** le pagine HTML esistenti, aggiungi questi script nell'`<head>`, **PRIMA** di `shared-data.js`:

```html
<!-- Supabase -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="supabase-client.js"></script>
<script src="Admin/auth-helper.js"></script>
<script src="data-migration.js"></script>
```

**Pagine da modificare:**
- [ ] `admin-functional.html`
- [ ] `gestione-clienti.html`
- [ ] `gestione-utenti.html`
- [ ] `gestione-lavorazioni.html`
- [ ] `gestione-squadre.html`
- [ ] `gestione-richieste.html`
- [ ] `calendario-admin.html`
- [ ] `calendario-dipendente.html`
- [ ] `pannello-utente.html`
- [ ] `comunicazioni.html`

---

### 3️⃣ Sostituisci localStorage con dataManager

In ogni pagina, sostituisci:

#### ❌ VECCHIO (localStorage):
```javascript
// Carica dati
const clienti = window.syncData.clienti || [];

// Salva dati
window.syncData.clienti.push(newCliente);
window.syncData.saveData();
```

#### ✅ NUOVO (Supabase):
```javascript
// Carica dati
const clienti = await window.dataManager.getClienti();

// Salva dati
await window.dataManager.saveCliente(newCliente);
```

---

### 4️⃣ Aggiungi protezione login

All'inizio dello script di ogni pagina, aggiungi:

```javascript
// All'inizio di ogni pagina
document.addEventListener('DOMContentLoaded', async () => {
    // Proteggi pagine admin
    if (!window.AuthHelper.requireAdmin()) return; // Solo per pagine admin
    
    // Oppure per pagine dipendenti:
    // if (!window.AuthHelper.requireLogin()) return;
    
    // ... resto del codice
});
```

---

### 5️⃣ Aggiungi logout button

Nel menu/header di ogni pagina, aggiungi:

```html
<button onclick="window.AuthHelper.logout()" class="...">
    <i class="fas fa-sign-out-alt"></i> Logout
</button>
```

---

## 🔄 MIGRAZIONE GRADUALE

Puoi migrare una pagina alla volta:

### Esempio: Migrazione `gestione-clienti.html`

1. **Aggiungi gli script Supabase** nell'<head>
2. **Trova la funzione `loadClienti()`** e sostituisci:
   ```javascript
   // PRIMA:
   const clienti = window.syncData.clienti || [];
   
   // DOPO:
   const clienti = await window.dataManager.getClienti();
   ```

3. **Trova `saveCliente()`** e sostituisci:
   ```javascript
   // PRIMA:
   window.syncData.clienti.push(newCliente);
   window.syncData.saveData();
   
   // DOPO:
   const saved = await window.dataManager.saveCliente(newCliente);
   await loadClienti(); // Ricarica lista
   ```

4. **Trova `deleteCliente()`** e sostituisci:
   ```javascript
   // PRIMA:
   const index = window.syncData.clienti.findIndex(c => c.id === id);
   window.syncData.clienti.splice(index, 1);
   window.syncData.saveData();
   
   // DOPO:
   await window.dataManager.deleteCliente(id);
   await loadClienti(); // Ricarica lista
   ```

5. **Rendi async le funzioni** che usano dataManager:
   ```javascript
   // PRIMA:
   function loadClienti() { ... }
   
   // DOPO:
   async function loadClienti() { ... }
   ```

---

## 🧪 TEST

### 1. Testa login:
1. Vai su `http://localhost:3005/Admin/index.html`
2. Dovresti vedere l'utente admin nella dropdown
3. Fai login → redirect a `admin-functional.html`

### 2. Testa database:
Apri console browser e prova:
```javascript
// Carica utenti
const users = await window.UsersAPI.getAll();
console.log(users);

// Crea cliente
const client = await window.ClientsAPI.create({
    ragione_sociale: 'Test SRL',
    tipo_cliente: 'azienda',
    stato: 'attivo'
});
console.log(client);
```

---

## 🆘 TROUBLESHOOTING

### "Cannot read property 'getAll' of undefined"
→ Assicurati di aver caricato gli script nella sequenza corretta

### "User is not authorized"
→ Controlla le RLS policies in Supabase. Per sviluppo, puoi disabilitarle temporaneamente

### "Fetch failed"
→ Verifica che Supabase URL e Key siano corretti in `supabase-client.js`

---

## 📞 VUOI CHE INIZIO A MIGRARE LE PAGINE?

Posso modificare automaticamente tutte le pagine HTML per integrare Supabase.

**Dimmi se:**
1. Vuoi che le migri tutte insieme
2. Vuoi iniziare da una pagina specifica
3. Vuoi farlo manualmente seguendo questa guida

🎯 **Consiglio**: Inizia da `gestione-clienti.html` per testare tutto!
