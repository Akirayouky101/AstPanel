# ✅ Checklist Testing Timbrature Ottimizzate

## 🎯 Setup Iniziale

- [ ] Esegui migration `add-costo-orario-users.sql` su Supabase
- [ ] Imposta `costo_orario` per il tuo utente (es. 25.00)
  ```sql
  UPDATE users SET costo_orario = 25.00 WHERE email = 'tua@email.com';
  ```
- [ ] Apri `orari-dipendente.html` nel browser
- [ ] Apri DevTools (F12) → Console

---

## 📦 Test 1: Caching System

### Procedura
1. [ ] Apri DevTools → Application → Local Storage
2. [ ] Ricarica la pagina
3. [ ] Cerca chiave `timbrature_cache`
4. [ ] Ricarica di nuovo (entro 5 minuti)
5. [ ] Controlla console

### ✅ Risultati Attesi
- [ ] Prima ricarica: Console mostra `🔄 Cache miss for today_...`
- [ ] Seconda ricarica: Console mostra `📦 Cache hit for today_...`
- [ ] LocalStorage contiene JSON con `data` e `timestamp`
- [ ] Dopo 5+ minuti: nuova fetch automatica

---

## ⏱️ Test 2: Timer Real-Time (1 secondo)

### Procedura
1. [ ] Clicca "Timbra Ingresso"
2. [ ] Osserva il display "Ore Lavorate" nella card "Sessione Attiva"
3. [ ] Cronometra con timer esterno

### ✅ Risultati Attesi
- [ ] Display mostra formato `HH:MM:SS` (es. `0:00:01`)
- [ ] Secondi si aggiornano **ogni secondo** (non ogni minuto!)
- [ ] Dopo 1 minuto mostra `0:01:00`
- [ ] "Oggi → Ore Lavorate" mostra formato `Xh Ym Zs`

---

## 💰 Test 3: Calcolo Costi Real-Time

### Setup
```sql
-- Imposta costo orario se non fatto
UPDATE users SET costo_orario = 30.00 WHERE id = 'TUO_UUID';
```

### Procedura
1. [ ] Timbra ingresso
2. [ ] Aspetta 1 minuto
3. [ ] Osserva "Guadagno Oggi"

### ✅ Risultati Attesi
- [ ] Dopo 1 minuto: `€0.50` (30€/h ÷ 60 min = 0.50€/min)
- [ ] Dopo 30 minuti: `€15.00`
- [ ] Dopo 1 ora: `€30.00`
- [ ] Valore si aggiorna **in tempo reale** ogni secondo

### Calcolo Manuale
```
costo_orario = 30.00€
minuti_lavorati = 30
guadagno = (30€ / 60min) × 30min = 15.00€
```

---

## 📊 Test 4: Statistiche Mensili

### Procedura
1. [ ] Timbra ingresso e uscita (completa una giornata)
2. [ ] Ricarica pagina
3. [ ] Osserva card "Mese Corrente"

### ✅ Risultati Attesi
- [ ] "Ore Ordinarie" mostra ore lavorate (es. `8h`)
- [ ] "Totale Ore" mostra somma corretta
- [ ] **"Guadagno Mese"** mostra costo totale (es. `€200.00`)
- [ ] Cache valida per 5 minuti (console: `📦 Cache hit for monthly_stats_...`)

---

## 📍 Test 5: GPS Tracking

### Procedura
1. [ ] Clicca "Timbra Ingresso"
2. [ ] Browser chiede permesso geolocalizzazione
3. [ ] Accetta
4. [ ] Controlla console

### ✅ Risultati Attesi - Permesso Concesso
- [ ] Console: `✅ [GPS] Posizione ottenuta: XX.XXXXX, YY.YYYYY`
- [ ] Database `timbrature.posizione_gps` contiene:
  ```json
  {
    "lat": 45.464203,
    "lng": 9.189982,
    "accuracy": 15.2
  }
  ```

### ✅ Risultati Attesi - Permesso Negato
- [ ] Console: `⚠️ [GPS] Errore geolocalizzazione: User denied...`
- [ ] Database `timbrature.posizione_gps` = `null`
- [ ] **Timbratura funziona comunque!** (GPS opzionale)

---

## 🔔 Test 6: Notifiche Straordinari

### Setup
**Per test rapido, modifica temporaneamente il codice:**
```javascript
// timbrature-service.js, riga ~335
// PRIMA (8 ore)
if (totalHours === 8 && totalMinutes === 0 && totalSeconds === 0) {

// DOPO (1 minuto per test)
if (totalHours === 0 && totalMinutes === 1 && totalSeconds === 0) {
```

### Procedura
1. [ ] Ricarica pagina
2. [ ] Accetta permessi notifiche browser
3. [ ] Timbra ingresso
4. [ ] Aspetta 1 minuto (o 8 ore se non modificato)

### ✅ Risultati Attesi
- [ ] Notifica browser appare:
  - Titolo: `⏰ Straordinario!`
  - Testo: `Hai lavorato X ore oggi. Ricordati di timbrare l'uscita!`
- [ ] Notifica appare **solo una volta** (non ripetuta)
- [ ] Funziona anche con tab in background

---

## 🔄 Test 7: Invalidazione Cache

### Procedura
1. [ ] Ricarica pagina (cache populate)
2. [ ] Timbra ingresso o uscita
3. [ ] Apri DevTools → Application → Local Storage
4. [ ] Verifica chiave `timbrature_cache`

### ✅ Risultati Attesi
- [ ] Dopo timbratura: chiave `today_...` rimossa dal JSON
- [ ] Altre chiavi (es. `monthly_stats_...`) ancora presenti
- [ ] Prossima ricarica: console mostra `🔄 Cache miss` per `today`

---

## ⚡ Test 8: Optimistic Updates

### Procedura
1. [ ] Apri DevTools → Network
2. [ ] Throttle connection: "Slow 3G"
3. [ ] Timbra ingresso
4. [ ] Osserva UI

### ✅ Risultati Attesi
- [ ] UI si aggiorna **immediatamente** (prima che server risponda)
- [ ] Timer inizia subito
- [ ] Dopo risposta server: dati confermati
- [ ] Nessun "flicker" o doppio aggiornamento

---

## 🧹 Test 9: Reset UI

### Procedura
1. [ ] Timbra ingresso (timer attivo)
2. [ ] Aspetta 1+ minuti
3. [ ] Timbra uscita
4. [ ] Osserva UI

### ✅ Risultati Attesi
- [ ] Timer si ferma immediatamente
- [ ] `window.liveTimerInterval` è cleared (non continua in background)
- [ ] "Ore Lavorate" mostra valore finale fisso
- [ ] "Guadagno Oggi" mostra totale finale (non cambia più)
- [ ] Bottone diventa "Già timbrato" disabilitato

---

## 🚨 Test Edge Cases

### Test 9a: Doppia Timbratura
- [ ] Timbra ingresso
- [ ] **NON** timbrare uscita
- [ ] Ricarica pagina
- [ ] Verifica: timer riprende da dove era (no doppio ingresso)

### Test 9b: Mezzanotte
- [ ] Timbra ingresso prima di mezzanotte (es. 23:55)
- [ ] Aspetta che sia mezzanotte (00:05)
- [ ] Timbra uscita
- [ ] Verifica: calcolo ore non va negativo

### Test 9c: Senza Costo Orario
```sql
UPDATE users SET costo_orario = NULL WHERE id = 'TUO_UUID';
```
- [ ] Ricarica pagina
- [ ] Timbra ingresso
- [ ] Verifica: "Guadagno Oggi" mostra `€0.00` (non errore)

---

## 📱 Test Compatibilità Browser

### Desktop
- [ ] Chrome/Edge (Windows/Mac)
- [ ] Firefox (Windows/Mac)
- [ ] Safari (Mac)

### Mobile
- [ ] Chrome Mobile (Android)
- [ ] Safari Mobile (iOS)
- [ ] Samsung Internet

### Feature Support
- [ ] LocalStorage funziona su tutti
- [ ] GPS funziona su mobile
- [ ] Notifiche funzionano su desktop
- [ ] Timer smooth su tutti i browser

---

## 🐛 Troubleshooting Checklist

### Problema: "€0.00" sempre
- [ ] Migration eseguita?
  ```sql
  SELECT costo_orario FROM users WHERE id = 'TUO_UUID';
  ```
- [ ] Valore impostato?
  ```sql
  UPDATE users SET costo_orario = 25.00 WHERE id = 'TUO_UUID';
  ```
- [ ] JOIN funzionante? Console dovrebbe mostrare `todayTimbratura.user.costo_orario`

### Problema: Timer non si aggiorna
- [ ] Console mostra errori?
- [ ] `window.timbratureService` definito?
  ```javascript
  console.log(window.timbratureService);
  ```
- [ ] Script `timbrature-service.js` caricato?
  ```html
  <script src="./timbrature-service.js"></script>
  ```

### Problema: Cache non funziona
- [ ] LocalStorage abilitato nel browser?
- [ ] Modalità incognito? (LocalStorage limitato)
- [ ] Clear cache manuale:
  ```javascript
  localStorage.removeItem('timbrature_cache');
  ```

### Problema: GPS sempre null
- [ ] Permessi browser concessi?
- [ ] HTTPS attivo? (GPS richiede connessione sicura)
- [ ] Console mostra errore GPS specifico?

---

## 📊 Report Finale

### Performance Metrics
| Metrica | Prima | Dopo | Miglioramento |
|---------|-------|------|---------------|
| Timer update | 60s | 1s | **60x faster** |
| DB queries (5min) | 5-10 | 1-2 | **80% reduction** |
| GPS code lines | 20+ (duplicato) | 15 (centralizzato) | **Simplified** |
| Cost calculation | ❌ None | ✅ Real-time | **New feature** |
| Browser notifications | ❌ None | ✅ Overtime alert | **New feature** |

### ✅ Sign-Off
- [ ] Tutti i test passati
- [ ] Performance verificata
- [ ] Nessun errore console
- [ ] UX fluida e responsive

**Data Test:** _______________  
**Tester:** _______________  
**Note:** _____________________________________

---

## 🚀 Deploy Checklist

Prima di andare in produzione:

- [ ] Backup database
- [ ] Migration `add-costo-orario-users.sql` su production
- [ ] Test su staging environment
- [ ] Verifica RLS policies per `users.costo_orario`
- [ ] Deploy file modificati:
  - `timbrature-service.js` (NEW)
  - `orari-dipendente.html` (UPDATED)
- [ ] Invalidazione cache CDN (se applicabile)
- [ ] Smoke test post-deploy
- [ ] Monitoring errori per 24h

---

**Pronto per il testing! 🎉**
