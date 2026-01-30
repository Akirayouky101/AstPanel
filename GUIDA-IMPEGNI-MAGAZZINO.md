# 📦 SISTEMA IMPEGNI MAGAZZINO - Guida Completa

## 🎯 OBIETTIVO
Distinguere tra **giacenza fisica** (prodotti realmente a magazzino) e **giacenza libera** (prodotti non ancora impegnati per preventivi/lavorazioni).

---

## 📊 CONCETTI BASE

### **GIACENZA FISICA** (`quantita_disponibile`)
Prodotti fisicamente presenti in magazzino.
```sql
SELECT quantita_disponibile FROM components WHERE codice = 'SENS001';
-- Risultato: 10
```

### **GIACENZA IMPEGNATA**
Prodotti prenotati per preventivi accettati o lavorazioni pianificate.
```sql
SELECT SUM(quantita_impegnata) FROM impegni_magazzino 
WHERE prodotto_id = '...' AND stato = 'attivo';
-- Risultato: 5
```

### **GIACENZA LIBERA**
Prodotti ancora disponibili per nuovi ordini/kit.
```sql
SELECT get_giacenza_libera('prodotto_id');
-- Risultato: 5 (10 fisica - 5 impegnata)
```

---

## 🔄 FLUSSO COMPLETO

### **1️⃣ PREVENTIVO CREATO**
```
Giacenza Sensore: 10 fisica | 0 impegnata | 10 libera
```
Nessun impatto sul magazzino.

---

### **2️⃣ PREVENTIVO ACCETTATO**
```sql
-- TRIGGER AUTOMATICO: impegna_prodotti_preventivo()
INSERT INTO impegni_magazzino (
    prodotto_id, quantita_impegnata, tipo_impegno, preventivo_id
) VALUES (...);
```

**Risultato:**
```
Giacenza Sensore: 10 fisica | 5 impegnata | 5 libera ✅
```

**Tabella `impegni_magazzino`:**
| prodotto | quantità | tipo | preventivo_id | stato |
|----------|----------|------|---------------|-------|
| Sensore  | 5        | preventivo | PREV-001 | attivo |

---

### **3️⃣ LAVORAZIONE CREATA DA PREVENTIVO**
```sql
-- TRIGGER AUTOMATICO: trasferisci_impegno_a_lavorazione()
UPDATE impegni_magazzino 
SET lavorazione_id = '...', tipo_impegno = 'lavorazione'
WHERE preventivo_id = '...';
```

**Risultato:**
```
Giacenza Sensore: 10 fisica | 5 impegnata | 5 libera
(Impegno trasferito da preventivo a lavorazione)
```

**Tabella `impegni_magazzino`:**
| prodotto | quantità | tipo | lavorazione_id | stato |
|----------|----------|------|----------------|-------|
| Sensore  | 5        | lavorazione | LAV-001 | attivo |

---

### **4️⃣ KIT CREATO (nel frattempo)**
```javascript
// Frontend: gestione-kit.html
// Controlla giacenza LIBERA (non fisica!)
const giacenzaLibera = await supabase.rpc('get_giacenza_libera', { 
    p_prodotto_id: prodottoId 
});

if (giacenzaLibera < quantitaRichiesta) {
    // Calcola mancanza
    const mancanti = quantitaRichiesta - giacenzaLibera;
    // Crea ordine fornitore per mancanti + scorta
}
```

**Esempio:**
```
Kit richiede: 10 Sensori
Giacenza libera: 5 (10 fisica - 5 impegnata)
→ Ordina 5 + scorta minima
```

---

### **5️⃣ LAVORAZIONE COMPLETATA**
```sql
-- TRIGGER AUTOMATICO: completa_lavorazione_con_impegno()
-- 1. Scala giacenza fisica
UPDATE components SET quantita_disponibile = quantita_disponibile - 5;

-- 2. Registra movimento
INSERT INTO movimenti_magazzino (...);

-- 3. Completa impegno
UPDATE impegni_magazzino SET stato = 'completato';
```

**Risultato:**
```
Giacenza Sensore: 5 fisica | 0 impegnata | 5 libera ✅
```

**Tabella `impegni_magazzino`:**
| prodotto | quantità | tipo | lavorazione_id | stato |
|----------|----------|------|----------------|-------|
| Sensore  | 5        | lavorazione | LAV-001 | completato ✅ |

---

## 🔍 QUERY UTILI

### **Vista giacenze complete**
```sql
SELECT * FROM v_giacenze_complete;
```
Mostra per ogni prodotto:
- `giacenza_fisica`
- `giacenza_impegnata`
- `giacenza_libera`
- `stato_giacenza` (OK, WARNING, CRITICO)

### **Prodotti con impegni attivi**
```sql
SELECT 
    c.codice,
    c.nome,
    i.quantita_impegnata,
    i.tipo_impegno,
    COALESCE(p.numero_preventivo, t.codice_lavorazione) AS riferimento
FROM impegni_magazzino i
JOIN components c ON c.id = i.prodotto_id
LEFT JOIN preventivi p ON p.id = i.preventivo_id
LEFT JOIN tasks t ON t.id = i.lavorazione_id
WHERE i.stato = 'attivo';
```

### **Verifica disponibilità prodotto**
```sql
SELECT get_giacenza_libera('prodotto-uuid-qui');
```

---

## ⚠️ CASI EDGE

### **Preventivo annullato dopo accettazione**
```sql
-- TRIGGER AUTOMATICO libera impegni
UPDATE impegni_magazzino SET stato = 'annullato'
WHERE preventivo_id = '...' AND stato = 'attivo';
```

### **Lavorazione cancellata prima del completamento**
```sql
-- MANUALE: liberare impegni
UPDATE impegni_magazzino SET stato = 'annullato'
WHERE lavorazione_id = '...' AND stato = 'attivo';
```

### **Impegno supera giacenza fisica**
```sql
-- Vista mostra WARNING
SELECT * FROM v_giacenze_complete 
WHERE stato_giacenza LIKE 'CRITICO%';
```

---

## 🛠️ MANUTENZIONE

### **Cleanup impegni vecchi**
```sql
-- Impegni completati più di 6 mesi fa
DELETE FROM impegni_magazzino 
WHERE stato = 'completato' 
AND completed_at < NOW() - INTERVAL '6 months';
```

### **Report impegni per preventivo**
```sql
SELECT 
    c.codice,
    c.nome,
    i.quantita_impegnata,
    i.stato,
    i.created_at
FROM impegni_magazzino i
JOIN components c ON c.id = i.prodotto_id
WHERE i.preventivo_id = 'preventivo-uuid-qui';
```

---

## 📝 TODO FRONTEND

### **1. Aggiorna `gestione-kit.html`**
```javascript
// Usa giacenza LIBERA invece di quantita_disponibile
const { data } = await supabase.rpc('get_giacenza_libera', {
    p_prodotto_id: prodottoId
});
```

### **2. Aggiorna `magazzino-prodotti.html`**
```javascript
// Mostra giacenza libera accanto a fisica
const { data } = await supabase.from('v_giacenze_complete').select('*');
// Visualizza: "Fisica: 10 | Impegnata: 5 | Libera: 5"
```

### **3. Nuovo: `gestione-impegni.html`**
Dashboard per visualizzare tutti gli impegni attivi con possibilità di liberarli manualmente.

---

## ✅ VANTAGGI

1. ✅ **Preventivi accettati** non rubano giacenze a kit/altri preventivi
2. ✅ **Ordini fornitori** calcolati correttamente (considera impegni)
3. ✅ **Tracciabilità completa**: sai sempre perché un prodotto è impegnato
4. ✅ **Alert automatici**: se impegni superano giacenza fisica
5. ✅ **Storico**: tutti gli impegni completati sono tracciati

---

## 🚀 DEPLOYMENT

1. **Esegui migration** su Supabase:
   ```bash
   migrations/add-impegni-magazzino-system.sql
   ```

2. **Aggiorna frontend** per usare `get_giacenza_libera()`

3. **Testa flusso completo**:
   - Crea preventivo → accetta → verifica impegno
   - Crea lavorazione → completa → verifica scalamento
   - Crea kit → verifica ordine fornitore per quantità corretta

---

## 📞 SUPPORTO

Per domande o problemi:
- Controlla `v_giacenze_complete` per stato giacenze
- Verifica `impegni_magazzino` per impegni attivi
- Log SQL mostrano operazioni automatiche (RAISE NOTICE)
