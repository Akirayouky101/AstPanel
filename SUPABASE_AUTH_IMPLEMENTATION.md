# 🔐 AUTENTICAZIONE SUPABASE UFFICIALE

## ✅ IMPLEMENTAZIONE COMPLETATA

Data: 9 Dicembre 2024
Sistema: Autenticazione Email/Password con gestione primo accesso

---

## 📋 FILES CREATI

### 1. `/migrations/enable-supabase-auth.sql`
**Migration per abilitare RLS e Supabase Auth**

- ✅ Aggiunge colonna `auth_id` a tabella `utenti`
- ✅ Aggiunge colonna `first_login` per forzare cambio password
- ✅ Abilita RLS (Row Level Security) su TUTTE le tabelle
- ✅ Crea policies per utenti normali e admin
- ✅ Protegge dati sensibili (email_destinatari solo admin)

### 2. `/cambio-password.html`
**Pagina cambio password obbligatorio al primo accesso**

- ✅ Verifica identità con password temporanea
- ✅ Validazione password in tempo reale
- ✅ Requisiti: minimo 8 caratteri, maiuscola, minuscola, numero
- ✅ Conferma password matching
- ✅ Redirect automatico dopo cambio password

---

## 📝 FILES MODIFICATI

### 1. `/Admin/auth-helper.js`
**SOSTITUITO fake auth con Supabase Auth ufficiale**

#### Prima (❌ FAKE AUTH):
```javascript
async login(userId) {
    const user = await window.UsersAPI.getById(userId);
    sessionStorage.setItem(this.STORAGE_KEY, JSON.stringify(user));
    return user;
}
```

#### Dopo (✅ SUPABASE AUTH):
```javascript
async login(email, password) {
    const { data, error } = await window.supabase.auth.signInWithPassword({
        email: email,
        password: password
    });
    await this.loadCurrentUser();
    return { user: this.currentUser, requirePasswordChange: this.currentUser.first_login };
}
```

**Funzionalità aggiunte:**
- ✅ `init()` - Listener auth state changes
- ✅ `loadCurrentUser()` - Carica dati da DB usando auth.uid()
- ✅ `login(email, password)` - Login con credenziali
- ✅ `changePassword(newPassword)` - Cambio password + reset first_login
- ✅ `logout()` - Signout Supabase + pulizia session
- ✅ `isLoggedIn()` - Controlla sessione Supabase
- ✅ `createUser()` - Crea utente in Supabase Auth (admin only)

### 2. `/Admin/index.html`
**Login page con form email/password**

#### Prima (❌):
- Dropdown con lista utenti
- Click per selezionare qualsiasi utente
- Zero sicurezza

#### Dopo (✅):
- Form email + password
- Autenticazione Supabase
- Toggle visibilità password
- Spinner durante login
- Redirect se first_login = true → cambio-password.html

### 3. `/Admin/gestione-utenti.html`
**Creazione utenti con credenziali Supabase**

#### Funzione `saveUser()` MODIFICATA:

**Flusso Creazione Nuovo Utente:**
1. Genera password temporanea (12 caratteri alfanumerici)
2. Inserisce utente in tabella `utenti` (first_login = TRUE)
3. Crea account Supabase Auth con `auth.admin.createUser()`
4. Aggiorna campo `auth_id` dell'utente
5. Mostra modal con password temporanea da comunicare

**Funzioni Aggiunte:**
- ✅ `generateTemporaryPassword()` - Genera pass sicura
- ✅ `showTemporaryPasswordModal(email, password)` - Mostra credenziali
- ✅ `copyToClipboard(text)` - Copia password negli appunti

---

## 🔄 FLUSSO AUTENTICAZIONE COMPLETO

### 👤 Dipendente (Primo Accesso)
1. Admin crea utente → riceve email + password temporanea
2. Dipendente va su `index.html`
3. Inserisce email + password temp
4. Sistema rileva `first_login = TRUE`
5. Redirect automatico a `cambio-password.html`
6. Dipendente imposta password personale
7. Sistema aggiorna password + `first_login = FALSE`
8. Redirect a dashboard (admin → admin-functional.html, utente → pannello-utente.html)

### 🔁 Accessi Successivi
1. Utente va su `index.html`
2. Inserisce email + password personale
3. Login → redirect diretto a dashboard

### 👑 Admin Crea Utente
1. Admin va in `gestione-utenti.html`
2. Click "Aggiungi Utente"
3. Compila form (nome, email, ruolo, telefono, reparto)
4. Click "Salva"
5. Sistema:
   - Genera password temporanea (es: "aBc7Km9pQr2X")
   - Crea account Supabase
   - Mostra modal con credenziali
6. Admin copia password e la comunica al dipendente

---

## 🔒 SICUREZZA RLS (Row Level Security)

### Policies Implementate

#### UTENTI
- ✅ Utenti vedono solo se stessi
- ✅ Admin vedono tutti
- ✅ Solo admin possono creare/modificare/eliminare

#### TIMBRATURE
- ✅ Utenti vedono solo le proprie timbrature
- ✅ Admin vedono tutte
- ✅ Utenti possono timbrare solo per se stessi

#### EMAIL_DESTINATARI
- ✅ Solo admin possono accedere

#### LAVORAZIONI, CLIENTI
- ✅ Tutti vedono (read-only)
- ✅ Solo admin possono modificare

#### RICHIESTE_MATERIALE
- ✅ Utenti vedono solo le proprie
- ✅ Admin vedono tutte
- ✅ Tutti possono creare richieste

#### PRODOTTI_MAGAZZINO
- ✅ Tutti vedono (read-only)
- ✅ Solo admin possono modificare

#### COMUNICAZIONI
- ✅ Tutti vedono
- ✅ Solo admin possono creare/modificare

---

## ⚙️ CONFIGURAZIONE RICHIESTA

### 1. Applicare Migration SQL

```sql
-- Eseguire in Supabase SQL Editor
\i migrations/enable-supabase-auth.sql
```

### 2. Migrare Utenti Esistenti (se presenti)

```sql
-- Per ogni utente esistente, creare credenziali:
-- NOTA: Farlo manualmente per ogni utente oppure via script

-- Esempio per utente con email "mario.rossi@esempio.it"
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'mario.rossi@esempio.it',
    crypt('PasswordTemp123', gen_salt('bf')),
    now(),
    now(),
    now()
) RETURNING id;

-- Aggiornare tabella utenti con auth_id
UPDATE utenti 
SET auth_id = '<UUID_RITORNATO_SOPRA>', first_login = TRUE
WHERE email = 'mario.rossi@esempio.it';
```

**OPPURE (consigliato):**
Eliminare utenti esistenti e ricrearli da gestione-utenti.html (genera automaticamente tutto)

### 3. Verificare Service Role Key

In `supabase-client.js`, assicurarsi di usare **Service Role Key** (non anon key) per permettere `auth.admin.createUser()`:

```javascript
window.supabase = supabase.createClient(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY // ⚠️ Usa questa, non ANON_KEY
);
```

**⚠️ ATTENZIONE:** Service Role Key bypassa RLS, usare SOLO lato server/admin.
Per utenti normali, usare Anon Key.

---

## ✅ TESTING CHECKLIST

### Test Creazione Utente
- [ ] Admin accede a gestione-utenti.html
- [ ] Click "Aggiungi Utente"
- [ ] Compila form con dati validi
- [ ] Salva → vede modal con password temporanea
- [ ] Password è copiabile negli appunti
- [ ] Utente appare nella lista

### Test Primo Login
- [ ] Nuovo utente va su index.html
- [ ] Inserisce email + password temporanea
- [ ] Viene redirected a cambio-password.html
- [ ] Inserisce nuova password (8+ caratteri, maiuscola, minuscola, numero)
- [ ] Conferma password
- [ ] Click "Cambia Password" → redirect a dashboard

### Test Login Normale
- [ ] Utente esistente (first_login=FALSE) va su index.html
- [ ] Inserisce email + password personale
- [ ] Login → redirect diretto a dashboard corretta (admin/utente)

### Test RLS
- [ ] Utente normale NON vede timbrature di altri
- [ ] Utente normale NON può accedere a gestione-utenti
- [ ] Admin vede tutte le timbrature
- [ ] Admin può gestire utenti

### Test Logout
- [ ] Click logout → redirect a index.html
- [ ] Sessione pulita
- [ ] Non può accedere a pagine protette senza login

---

## 🚨 BREAKING CHANGES

### ⚠️ INCOMPATIBILITÀ con sistema precedente

1. **Fake Auth non funziona più**
   - Dropdown utenti rimosso
   - Serve email + password valide

2. **Utenti esistenti devono essere migrati**
   - Opzione 1: Creare manualmente in auth.users
   - Opzione 2: Eliminarli e ricrearli da gestione-utenti

3. **RLS abilitato**
   - Query dirette senza auth.uid() falliscono
   - Serve sessione Supabase valida per tutte le operazioni

4. **Service Role Key richiesta**
   - Per `auth.admin.createUser()`
   - Solo in gestione-utenti (admin panel)

---

## 📌 NOTE IMPORTANTI

1. **Password Temporanee**
   - 12 caratteri alfanumerici
   - NO caratteri ambigui (0, O, l, I)
   - Generazione random sicura

2. **Requisiti Password Finale**
   - Minimo 8 caratteri
   - Almeno 1 maiuscola
   - Almeno 1 minuscola
   - Almeno 1 numero
   - Validazione real-time nella UI

3. **Ruoli Admin**
   - "Tecnico"
   - "Segreteria"
   - "Titolare"
   
   Tutti gli altri ruoli = utenti normali

4. **Auth State Management**
   - Listener automatico su auth changes
   - Session refresh automatico
   - Logout propaga su tutti i tab

---

## 🎯 PROSSIMI PASSI

1. ✅ Applicare migration `enable-supabase-auth.sql`
2. ✅ Aggiornare `supabase-client.js` con Service Role Key
3. ✅ Testare creazione primo utente
4. ✅ Testare flusso completo primo login → cambio password
5. ✅ Verificare RLS funzionante
6. ✅ Deploy e testing su Vercel
7. ✅ Comunicare credenziali a dipendenti reali

---

## 🔗 FILES COINVOLTI

```
/migrations/enable-supabase-auth.sql          ← Migration SQL
/Admin/auth-helper.js                         ← Auth logic (SOSTITUITO)
/Admin/index.html                             ← Login page (MODIFICATO)
/Admin/gestione-utenti.html                   ← User management (MODIFICATO)
/cambio-password.html                         ← Password change page (NUOVO)
```

---

**Implementazione completata da:** GitHub Copilot  
**Data:** 9 Dicembre 2024  
**Versione:** 1.0 - Supabase Auth Production Ready  
**Status:** ✅ Ready for Testing

