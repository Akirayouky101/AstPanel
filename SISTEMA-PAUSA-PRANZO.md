# 🍽️ Sistema Pausa Pranzo Flessibile - AST Panel

## 📋 Panoramica

Sistema che permette di configurare **pause personalizzate** per ogni dipendente, sottraendo automaticamente la pausa dalle ore lavorate.

---

## 🎯 Caratteristiche

### ✅ Pausa Personalizzata per Utente
- Ogni dipendente può avere una pausa diversa
- Configurabile in minuti: `30`, `45`, `60`, `90`, ecc.
- Default: **60 minuti (1 ora)**

### ✅ Calcolo Automatico Ore Nette
- **Ore Lorde**: Tempo totale tra ingresso e uscita
- **Ore Nette**: Ore lorde - pausa pranzo
- Esempio: `08:00-17:00` con pausa 60min = **8h nette** (non 9h)

### ✅ Tracciamento Opzionale
- Possibilità di timbrare inizio/fine pausa (futuro)
- Per ora: sottrazione automatica basata su configurazione utente

---

## 🗄️ Schema Database

### Tabella `users` - Nuovi Campi

```sql
pausa_pranzo_minuti INTEGER DEFAULT 60
```

**Esempi:**
- `0` = Nessuna pausa automatica (es: Amministratore)
- `30` = 30 minuti (es: Part-time)
- `45` = 45 minuti (es: Operai)
- `60` = 1 ora (es: Standard dipendenti)

### Tabella `timbrature` - Nuovi Campi

```sql
pausa_inizio     TIME     -- Opzionale: quando inizia la pausa
pausa_fine       TIME     -- Opzionale: quando finisce la pausa
pausa_minuti     INTEGER  -- Minuti sottratti (default: da users.pausa_pranzo_minuti)
```

---

## ⚙️ Installazione

### 1️⃣ Esegui Migration su Supabase

```sql
-- Vai su Supabase SQL Editor
-- Copia TUTTO il file migrations/ADD-PAUSA-PRANZO.sql
-- Incolla ed ESEGUI
```

### 2️⃣ Verifica Installazione

Dopo l'esecuzione, dovresti vedere:

```
✅ Column 'pausa_pranzo_minuti' added
✅ Trigger created
✅ Function 'calcola_ore_nette' created
```

### 3️⃣ Controlla Configurazione

```sql
SELECT nome, cognome, pausa_pranzo_minuti 
FROM users 
ORDER BY pausa_pranzo_minuti;
```

---

## 🔧 Configurazione Utenti

### Impostare Pausa Personalizzata

```sql
-- Pausa 30 minuti per part-time
UPDATE users 
SET pausa_pranzo_minuti = 30 
WHERE email = 'parttime@example.com';

-- Pausa 45 minuti per operai
UPDATE users 
SET pausa_pranzo_minuti = 45 
WHERE ruolo = 'Operaio';

-- No pausa per amministratori
UPDATE users 
SET pausa_pranzo_minuti = 0 
WHERE ruolo = 'Amministratore';

-- Pausa 60 minuti per tutti gli altri (standard)
UPDATE users 
SET pausa_pranzo_minuti = 60 
WHERE pausa_pranzo_minuti IS NULL;
```

---

## 📊 Esempi Calcolo

### Esempio 1: Giornata Standard con 1h Pausa

```
Ingresso:  08:00
Uscita:    17:00
-----------------
Ore Lorde: 9h
Pausa:     -1h
Ore Nette: 8h ✅
```

### Esempio 2: Part-time con 30min Pausa

```
Ingresso:  09:00
Uscita:    14:00
-----------------
Ore Lorde: 5h
Pausa:     -0.5h
Ore Nette: 4.5h ✅
```

### Esempio 3: No Pausa (Admin)

```
Ingresso:  10:00
Uscita:    18:00
-----------------
Ore Lorde: 8h
Pausa:     -0h
Ore Nette: 8h ✅
```

---

## 🎨 Frontend - Implementazione UI

### Timer Live con Pausa

```javascript
// Nel timer live, sottrai pausa in tempo reale
const oreLorde = calculateHours(ingresso, now);
const pausaOre = user.pausa_pranzo_minuti / 60;
const oreNette = Math.max(0, oreLorde - pausaOre);

display.textContent = `${oreNette.toFixed(2)}h (pausa ${user.pausa_pranzo_minuti}min)`;
```

### Mostrare Ore Lorde vs Nette

```html
<div class="stats">
    <div>Ore Lorde: <span id="oreLorde">8h 30m</span></div>
    <div>Pausa: <span id="pausa">-1h</span></div>
    <div class="font-bold">Ore Nette: <span id="oreNette">7h 30m</span></div>
</div>
```

---

## 🔮 Funzionalità Future (Opzionali)

### 1️⃣ Timbratura Pausa Manuale

```html
<button id="timbraPausaBtn">
    🍽️ Timbra Pausa
</button>
```

- Utente timbra quando inizia la pausa
- Timbra quando finisce la pausa
- Sistema calcola pausa effettiva vs configurata

### 2️⃣ Pause Multiple

- Pausa pranzo: 60 minuti
- Pause caffè: 2 × 10 minuti
- Totale sottratto: 80 minuti

### 3️⃣ Controllo Pause

- Alert se pausa > configurata
- Report ore nette vs ore contrattuali
- Export PDF con dettaglio pause

---

## 📝 Note Importanti

### ⚠️ Calcolo Automatico

Il trigger `trigger_calcola_ore_lavorate` calcola automaticamente `ore_lavorate` quando viene inserito `ora_uscita`:

```sql
-- Automaticamente eseguito al INSERT/UPDATE
ore_lavorate = calcola_ore_nette(ora_ingresso, ora_uscita, pausa_minuti)
```

### ⚠️ Modifiche Manuali

Se serve sovrascrivere la pausa per una timbratura specifica:

```sql
UPDATE timbrature 
SET pausa_minuti = 45  -- Pausa diversa solo per oggi
WHERE id = 'xxx';
```

Il trigger ricalcolerà `ore_lavorate` con la nuova pausa.

---

## 🐛 Troubleshooting

### Problema: Ore Lavorate Errate

```sql
-- Verifica configurazione utente
SELECT u.nome, u.pausa_pranzo_minuti, 
       t.ora_ingresso, t.ora_uscita, 
       t.pausa_minuti, t.ore_lavorate
FROM timbrature t
JOIN users u ON t.user_id = u.id
WHERE t.data = CURRENT_DATE;
```

### Problema: Pausa Non Sottratta

```sql
-- Forza ricalcolo per tutte le timbrature
UPDATE timbrature 
SET ora_uscita = ora_uscita  -- Trigger si riattiva
WHERE ora_uscita IS NOT NULL;
```

---

## 📚 Riferimenti

- **Migration**: `migrations/ADD-PAUSA-PRANZO.sql`
- **Function**: `calcola_ore_nette(ingresso, uscita, pausa)`
- **Trigger**: `trigger_calcola_ore_lavorate`
- **Tabelle**: `users.pausa_pranzo_minuti`, `timbrature.pausa_minuti`

---

## ✅ Checklist Post-Installazione

- [ ] Migration eseguita su Supabase
- [ ] Configurato `pausa_pranzo_minuti` per ogni utente
- [ ] Testato calcolo con query di verifica
- [ ] Frontend aggiornato per mostrare ore nette
- [ ] Timer live considera la pausa
- [ ] Documentazione condivisa con team

---

**Creato il:** 7 dicembre 2025  
**Autore:** GitHub Copilot  
**Versione:** 1.0
