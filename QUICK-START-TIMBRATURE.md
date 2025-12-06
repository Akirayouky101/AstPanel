# 🚀 Quick Start - Sistema Timbrature Ottimizzato

## ⚡ 3 Passi per Iniziare

### 1️⃣ Esegui Migration Database (2 minuti)

```sql
-- Vai su Supabase → SQL Editor → New Query
-- Copia e incolla questo:

-- Aggiungi campo costo_orario
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS costo_orario DECIMAL(10,2) DEFAULT 0;

-- Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_users_costo_orario 
ON users(costo_orario);

-- Imposta costi orari per i tuoi utenti
UPDATE users SET costo_orario = 25.00 WHERE ruolo = 'dipendente';
UPDATE users SET costo_orario = 35.00 WHERE ruolo = 'amministratore';

-- OPPURE per un utente specifico:
UPDATE users SET costo_orario = 30.00 WHERE email = 'tua@email.com';
```

### 2️⃣ Apri Interfaccia Dipendente

Vai su: `orari-dipendente.html`

### 3️⃣ Inizia a Usare! 🎉

---

## 📱 Come Usare il Nuovo Sistema

### Timbrare Ingresso
1. Clicca **"Timbra Ingresso"**
2. Accetta permessi GPS (opzionale)
3. Accetta permessi notifiche (opzionale)
4. ✅ Timer parte automaticamente!

### Durante la Giornata
- **Timer live** si aggiorna ogni secondo: `0:05:23` → `0:05:24` → ...
- **"Guadagno Oggi"** mostra quanto stai guadagnando in tempo reale: `€12.50` → `€12.51` → ...
- Tutto in **tempo reale**! Nessun refresh necessario.

### Timbrare Uscita
1. Clicca **"Timbra Uscita"**
2. ✅ Timer si ferma
3. Ore totali e guadagno giornaliero salvati

### Notifiche Automatiche
- Dopo **8 ore** di lavoro ricevi notifica: *"⏰ Straordinario!"*
- Funziona anche con tab in background

---

## 📊 Cosa Vedi nell'Interfaccia

### Card "Oggi" (Verde)
```
📥 Ingresso:        09:00
📤 Uscita:          --:--
⏱️ Ore Lavorate:    8h 45m 30s
💰 Guadagno Oggi:   €218.75
```

### Card "Sessione Attiva" (Timer Live)
```
🕐 Ingresso ore: 09:00
⏱️ Ore lavorate: 8:45:30    ← Si aggiorna ogni secondo!
```

### Card "Mese Corrente" (Viola)
```
📊 Ore Ordinarie:      160h
🕐 Ore Straordinarie:  12h
🏖️ Permessi/Ferie:     2 giorni
📈 Totale Ore:         172h
💰 Guadagno Mese:      €4,300.00    ← NUOVO!
```

---

## 🎯 Differenze dal Sistema Vecchio

### ❌ Prima (Lento)
- Timer aggiornato ogni **60 secondi**
- Nessun calcolo guadagni
- Nessuna notifica
- Ogni caricamento = query database
- GPS ripetuto ovunque

### ✅ Adesso (Veloce!)
- Timer aggiornato ogni **1 secondo** (60x più veloce!)
- Guadagno **in tempo reale** + mensile
- Notifiche dopo 8 ore
- **Cache 5 minuti** = meno query
- GPS centralizzato

---

## 💡 Tips & Tricks

### Vedere la Cache
1. F12 (DevTools)
2. Application → Local Storage
3. Cerca `timbrature_cache`
4. Vedi i dati salvati per 5 minuti

### Vedere i Log
Console mostra tutto:
```
⏰ [INIT] Avvio caricamento dati...
📦 Cache hit for today_...
✅ [GPS] Posizione ottenuta: 45.464, 9.190
⏱️ Timer avviato - aggiornamento ogni secondo
```

### Impostare Costo Orario
```sql
-- Controlla il tuo attuale
SELECT costo_orario FROM users WHERE email = 'tua@email.com';

-- Modifica
UPDATE users SET costo_orario = 28.50 WHERE email = 'tua@email.com';
```

### Forzare Refresh Cache
Se i dati sembrano vecchi:
```javascript
// Console browser (F12)
localStorage.removeItem('timbrature_cache');
location.reload();
```

---

## 🐛 Problemi Comuni

### "Guadagno Oggi" mostra sempre €0.00
**Causa:** `costo_orario` non impostato  
**Fix:**
```sql
UPDATE users SET costo_orario = 25.00 WHERE id = 'TUO_USER_ID';
```

### Timer non si aggiorna
**Causa:** JavaScript non caricato  
**Fix:** 
1. F12 → Console
2. Cerca errori rossi
3. Verifica che `timbrature-service.js` sia nella stessa cartella
4. Ricarica con Ctrl+F5 (hard refresh)

### GPS non funziona
**Causa:** Permessi negati o no HTTPS  
**Fix:** 
- Clicca icona lucchetto browser → Permessi → Posizione → Consenti
- GPS è **opzionale** - timbratura funziona senza!

### Notifiche non arrivano
**Causa:** Permessi browser  
**Fix:**
- Chrome: Impostazioni → Privacy → Notifiche → Aggiungi sito
- Firefox: Preferenze → Privacy → Permessi → Notifiche

---

## 🔒 Privacy & Sicurezza

### Cosa viene salvato
- ✅ Ore lavorate
- ✅ Costo orario (visibile solo a te e admin)
- ✅ Posizione GPS (se accetti)
- ✅ Cache nel TUO browser (non condivisa)

### Cosa NON viene condiviso
- ❌ Guadagno giornaliero (solo tuo)
- ❌ GPS preciso ad altri dipendenti
- ❌ Cache tra dispositivi diversi

---

## 📞 Supporto

### Documenti Utili
- 📖 `TIMBRATURE-OPTIMIZATION.md` - Documentazione completa
- ✅ `TEST-CHECKLIST-TIMBRATURE.md` - Checklist testing

### In Caso di Problemi
1. Controlla Console (F12) per errori
2. Verifica migration database eseguita
3. Testa cache: `localStorage.getItem('timbrature_cache')`
4. Contatta amministratore sistema

---

## 🎉 Enjoy!

Il nuovo sistema è **60x più veloce** e mostra i tuoi guadagni **in tempo reale**!

**Domande?** Controlla la documentazione completa in `TIMBRATURE-OPTIMIZATION.md`
