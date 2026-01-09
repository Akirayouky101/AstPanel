# 🔐 Setup Super Admin con PIN - AST Panel

## 📋 Informazioni Super Admin

- **Email**: diegomarruchi@outlook.it
- **Nome**: Diego Marruchi
- **Telefono**: 3896136963
- **Ruolo**: Tecnico
- **PIN Sicurezza**: 4658101
- **Auth ID**: 0536c4f6-e377-4e81-ab81-95e14a2214d7

---

## 🚀 Installazione (ESEGUI IN ORDINE)

### 1️⃣ Aggiungi campo PIN alla tabella users
```sql
-- Esegui: add-pin-column.sql
```
Questo aggiunge la colonna `pin_code` alla tabella users esistente.

### 2️⃣ Crea il Super Admin Protetto
```sql
-- Esegui: create-super-admin.sql
```

Questo script:
- ✅ Crea il super admin con i tuoi dati
- ✅ Collega l'account al tuo auth_id Supabase esistente
- ✅ Imposta il PIN di sicurezza
- ✅ Crea trigger che impediscono:
  - ❌ Cancellazione del super admin
  - ❌ Modifica del ruolo
  - ❌ Disattivazione dell'account

---

## 🔒 Protezioni Attive

### Trigger Database
Il super admin è protetto da 2 trigger:

1. **`protect_superadmin`** - Impedisce cancellazione
2. **`protect_superadmin_role`** - Impedisce modifica ruolo/stato

### Sistema PIN
Quando accedi come super admin:
1. Inserisci email e password (Supabase Auth)
2. Inserisci il PIN a 7 cifre: **4658101**
3. Massimo 3 tentativi
4. Blocco automatico per 5 minuti dopo 3 tentativi errati

---

## 📁 File Creati/Modificati

### Nuovi File
- ✅ `create-super-admin.sql` - Crea super admin e protezioni
- ✅ `add-pin-column.sql` - Aggiunge campo PIN
- ✅ `pin-verification.js` - Sistema verifica PIN
- ✅ `clear-users-keep-admin.sql` - Svuota utenti preservando admin

### File Modificati
- ✅ `database-schema.sql` - Aggiunto campo pin_code
- ✅ `reset-database.sql` - Preserva super admin durante reset
- ✅ `Admin/auth-helper.js` - Integrazione verifica PIN
- ✅ `Admin/index.html` - Caricamento script PIN

---

## 🎯 Test Finale

Dopo aver eseguito gli script:

1. Vai su: **https://ast-panel.vercel.app/Admin/**
2. Inserisci email: `diegomarruchi@outlook.it`
3. Inserisci password (quella configurata su Supabase)
4. Inserisci PIN: `4658101`
5. ✅ Accesso completato!

---

## 🗑️ Svuotare Utenti (Mantenendo Super Admin)

Per eliminare tutti gli utenti TRANNE il super admin:
```sql
-- Esegui: clear-users-keep-admin.sql
```

Questo elimina tutti gli utenti ma il super admin rimane **sempre protetto**.

---

## 🛡️ ID Fisso Super Admin

Il super admin ha un ID fisso riconoscibile:
```
00000000-0000-0000-0000-000000000001
```

Tutti i trigger e le protezioni si basano su questo ID.

---

## ⚠️ IMPORTANTE

1. **NON CANCELLARE MAI** il super admin manualmente dal database
2. Il PIN è memorizzato in chiaro nel DB (solo per questo utente)
3. I tentativi di PIN sono tracciati in localStorage
4. Il lockout PIN è di 5 minuti dopo 3 tentativi errati

---

## 🔧 Troubleshooting

### "Cannot coerce the result to a single JSON object"
➡️ Il super admin non esiste ancora. Esegui `create-super-admin.sql`

### PIN non richiesto al login
➡️ Verifica che il campo `pin_code` sia popolato nel database
➡️ Controlla che `/pin-verification.js` sia caricato

### Lockout PIN
➡️ Aspetta 5 minuti OPPURE cancella localStorage:
```javascript
localStorage.removeItem('pin_attempts_00000000-0000-0000-0000-000000000001');
localStorage.removeItem('pin_lockout_00000000-0000-0000-0000-000000000001');
```

---

**✨ Il tuo Super Admin è ora completamente protetto e pronto all'uso!**
