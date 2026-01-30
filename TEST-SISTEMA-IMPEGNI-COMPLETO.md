# 🧪 TEST COMPLETO SISTEMA IMPEGNI MAGAZZINO

## 📋 PREPARAZIONE

### 1️⃣ Esegui TUTTE le Migration (in ordine):

```sql
1. migrations/add-impegni-magazzino-system.sql
2. migrations/fix-impegni-preventivi-column.sql
3. migrations/fix-impegni-tasks-column.sql
4. migrations/add-impegni-kit.sql  ← NUOVA!
```

### 2️⃣ Prepara Prodotti di Test:

Vai su **Magazzino Prodotti** e crea/modifica questi prodotti:

| Prodotto | Codice | Giacenza Iniziale |
|----------|--------|-------------------|
| Batteria 12V | BATT-12V | 20 pz |
| Sensore Temperatura | SENS-TEMP | 15 pz |
| Cavo Ethernet 10m | CAV-ETH-10 | 30 pz |

---

## 🎯 TEST 1: PREVENTIVO → IMPEGNO

### Obiettivo:
Verificare che preventivo accettato impegni automaticamente i prodotti.

### Passi:

1. **Vai su Gestione Preventivi**
   - Click "Nuovo Preventivo"
   
2. **Compila preventivo:**
   - Cliente: qualsiasi
   - Oggetto: "Test impegni magazzino"
   - Aggiungi prodotti:
     - Batteria 12V: 5 pz
     - Sensore Temperatura: 3 pz
   
3. **Salva come BOZZA**
   - Verifica: preventivo salvato
   
4. **Controlla Magazzino PRIMA:**
   - Batteria: Fisica 20 | Impegnata 0 | Libera 20
   - Sensore: Fisica 15 | Impegnata 0 | Libera 15

5. **ACCETTA IL PREVENTIVO:**
   - Cambia stato → **Accettato**
   - Salva
   
6. **Verifica Gestione Impegni:**
   - Vai su **Gestione Impegni**
   - ✅ Dovresti vedere **2 impegni attivi**:
     - Tipo: Preventivo (blu)
     - Riferimento: PREV-2026-001
     - Batteria: 5 pz
     - Sensore: 3 pz
     - Stato: Attivo

7. **Verifica Magazzino DOPO:**
   - Batteria:
     - 📦 Fisica: 20 pz
     - 🔒 Impegnata: 5 pz
     - ✅ Libera: 15 pz
     - Badge: "Disponibile" (se 15 > scorta minima)
   - Sensore:
     - 📦 Fisica: 15 pz
     - 🔒 Impegnata: 3 pz
     - ✅ Libera: 12 pz

8. **Click "Vedi dettaglio impegni"** sulla Batteria:
   - Modal si apre
   - Tabella mostra impegno per PREV-2026-001

### ✅ Risultato Atteso:
- Preventivo mostra badge arancione "Impegnato"
- Impegni creati automaticamente
- Giacenza fisica NON cambiata
- Giacenza libera ridotta
- Dettaglio impegni visibile

---

## 🎯 TEST 2: KIT → IMPEGNO

### Obiettivo:
Verificare che componenti kit impegnino prodotti.

### Passi:

1. **Vai su Gestione Kit**
   - Click "Nuovo Kit"
   
2. **Crea kit:**
   - Codice: KIT-TEST-001
   - Nome: "Kit Test Impegni"
   - Destinatario: Cliente / Dipendente
   
3. **Aggiungi componenti:**
   - Batteria 12V: 3 pz
   - Cavo Ethernet: 5 pz
   
4. **Salva kit**

5. **Verifica Gestione Impegni:**
   - Nuovi impegni:
     - Tipo: Kit (verde)
     - Riferimento: KIT-TEST-001
     - Batteria: 3 pz
     - Cavo: 5 pz
     - Stato: Attivo

6. **Verifica Magazzino:**
   - Batteria ora ha:
     - Impegnata: 5 (prev) + 3 (kit) = **8 pz**
     - Libera: 20 - 8 = **12 pz**
   - Cavo:
     - 📦 Fisica: 30 pz
     - 🔒 Impegnata: 5 pz
     - ✅ Libera: 25 pz

### ✅ Risultato Atteso:
- Impegni kit creati automaticamente
- Giacenza impegnata cumulativa (prev + kit)
- Dettaglio impegni mostra entrambi

---

## 🎯 TEST 3: LIBERAZIONE MANUALE IMPEGNO

### Obiettivo:
Verificare che liberazione manuale funzioni.

### Passi:

1. **Vai su Gestione Impegni**
   
2. **Trova un impegno attivo** (es: kit)
   
3. **Click "Libera"**
   - Modal arancione di conferma
   - Messaggio: "Vuoi liberare l'impegno su..."
   
4. **Conferma**
   - Modal verde: "Impegno liberato con successo!"
   - Auto-close dopo 2.5s
   
5. **Verifica:**
   - Impegno scompare da lista "Attivi"
   - Filtro "Annullati" → lo trovi lì
   - Stato: Annullato
   
6. **Vai su Magazzino:**
   - Giacenza impegnata RIDOTTA
   - Giacenza libera AUMENTATA
   
### ✅ Risultato Atteso:
- Modal professionale (no alert)
- Impegno annullato
- Giacenze aggiornate in tempo reale

---

## 🎯 TEST 4: PREVENTIVO ANNULLATO → LIBERA IMPEGNI

### Obiettivo:
Verificare trigger automatico annullamento preventivo.

### Passi:

1. **Crea nuovo preventivo con prodotti**
   - Cavo Ethernet: 10 pz
   
2. **Accetta preventivo**
   - Verifica impegno creato
   
3. **Torna su Gestione Preventivi**
   
4. **Cambia stato → Annullato**
   
5. **Verifica Gestione Impegni:**
   - Impegno stato: Annullato
   - Liberato automaticamente
   
6. **Verifica Magazzino:**
   - Cavo: impegnata -10, libera +10

### ✅ Risultato Atteso:
- Trigger automatico funziona
- Impegni annullati quando preventivo annullato
- Giacenze ripristinate

---

## 🎯 TEST 5: CONSEGNA KIT → COMPLETA IMPEGNI

### Obiettivo:
Verificare che consegna kit completi gli impegni.

### Passi:

1. **Vai su Gestione Kit**
   
2. **Apri kit esistente** (KIT-TEST-001)
   
3. **Cambia stato → Consegnato**
   - Oppure scansiona QR consegna
   
4. **Verifica Gestione Impegni:**
   - Impegni del kit: Stato = **Completato**
   - Data completamento valorizzata
   
5. **Verifica Magazzino:**
   - Giacenza impegnata RIDOTTA
   - Giacenza libera AUMENTATA
   - Giacenza fisica **INVARIATA** (non scala automaticamente)

### ✅ Risultato Atteso:
- Impegni completati automaticamente
- Giacenza libera ripristinata
- Fisica non cambia (configurazione attuale)

---

## 🎯 TEST 6: MODIFICA KIT → IMPEGNI AGGIORNATI

### Obiettivo:
Verificare rimozione componente da kit.

### Passi:

1. **Apri kit in preparazione**
   
2. **Rimuovi un componente** (es: elimina batteria)
   
3. **Verifica Gestione Impegni:**
   - Impegno per batteria: Annullato
   - Altri impegni: ancora Attivi
   
4. **Verifica Magazzino:**
   - Batteria: impegnata -3, libera +3

### ✅ Risultato Atteso:
- Trigger DELETE funziona
- Solo impegno rimosso annullato
- Altri impegni intatti

---

## 🎯 TEST 7: LAVORAZIONE DA PREVENTIVO

### Obiettivo:
Verificare trasferimento impegni preventivo → lavorazione.

### Passi:

1. **Crea preventivo con prodotti**
   - Sensore: 5 pz
   
2. **Accetta preventivo**
   - Impegno creato
   
3. **Crea lavorazione DA QUEL PREVENTIVO**
   - Verifica che `preventivo_id` sia valorizzato
   
4. **Verifica Gestione Impegni:**
   - Impegno ora ha:
     - Tipo: Lavorazione (viola)
     - Riferimento: nome task
     - Nota: "...→ Trasferito a lavorazione..."

### ✅ Risultato Atteso:
- Impegno trasferito da preventivo a task
- Tipo cambiato
- Nota aggiornata

---

## 🎯 TEST 8: COMPLETAMENTO LAVORAZIONE

### Obiettivo:
Verificare che completare lavorazione scali giacenza e liberi impegno.

### Passi:

1. **Apri lavorazione con impegni**
   
2. **Completa lavorazione:**
   - Cambia stato → Completato
   
3. **Verifica Gestione Impegni:**
   - Impegno: Completato
   - Data completamento valorizzata
   
4. **Verifica Magazzino:**
   - Giacenza **FISICA** SCALATA (es: 15 → 10)
   - Giacenza impegnata = 0
   - Giacenza libera = fisica
   
5. **Verifica Movimenti Magazzino:**
   - Nuovo movimento:
     - Tipo: Uscita
     - Quantità: -5
     - Causale: "Completamento lavorazione..."

### ✅ Risultato Atteso:
- Giacenza fisica scalata
- Movimento registrato
- Impegno completato
- Giacenza libera = fisica

---

## 🎯 TEST 9: SCENARIO COMPLETO (Integration Test)

### Setup Iniziale:
- Batteria: 20 pz fisica

### Flow:

```
STATO                    FISICA  IMPEGNATA  LIBERA
--------------------------------------------------
1. Inizio                  20        0        20

2. Preventivo 5 pz         20        5        15
   (accettato)

3. Kit 3 pz                20        8        12
   (preparazione)

4. Preventivo 2 annullato  20        8        12
   (crea e annulla)        20        6        14

5. Consegna kit            20        3        17
   (impegni kit liberati)

6. Lavorazione completata  15        0        15
   (da preventivo 1)       ↓fisica scalata
```

### ✅ Risultato Finale Atteso:
- Fisica: 15 (scalata di 5 dalla lavorazione)
- Impegnata: 0
- Libera: 15
- Movimenti tracciati
- Impegni tutti completati/annullati

---

## ❌ ERRORI COMUNI E FIX

### "Vista v_giacenze_complete non esiste"
**Fix:** Esegui `add-impegni-magazzino-system.sql`

### "Column numero_preventivo does not exist"
**Fix:** Esegui `fix-impegni-preventivi-column.sql`

### "Column codice_lavorazione does not exist"
**Fix:** Esegui `fix-impegni-tasks-column.sql`

### "Impegni kit non creati"
**Fix:** Esegui `add-impegni-kit.sql`

### "Tutti prodotti 'Tutto Impegnato'"
**Causa:** Giacenza fisica = 0
**Fix:** Registra carico o modifica giacenza

### "Modal non appare"
**Causa:** Codice frontend non aggiornato
**Fix:** CTRL+F5 (hard refresh)

---

## 📊 QUERY DEBUG UTILI

### 1. Tutti impegni attivi:
```sql
SELECT 
    i.*,
    c.nome as prodotto,
    p.numero as preventivo,
    k.codice_kit
FROM impegni_magazzino i
JOIN components c ON c.id = i.prodotto_id
LEFT JOIN preventivi p ON p.id = i.preventivo_id
LEFT JOIN kits k ON k.id = i.kit_id
WHERE i.stato = 'attivo'
ORDER BY i.created_at DESC;
```

### 2. Giacenze complete:
```sql
SELECT * FROM v_giacenze_complete 
WHERE giacenza_impegnata > 0;
```

### 3. Storico impegni prodotto:
```sql
SELECT * FROM impegni_magazzino 
WHERE prodotto_id = 'UUID_PRODOTTO'
ORDER BY created_at DESC;
```

### 4. Verifica trigger esistenti:
```sql
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table
FROM information_schema.triggers
WHERE trigger_name LIKE '%impegn%'
ORDER BY event_object_table;
```

---

## 🎉 CHECKLIST FINALE

- [ ] Preventivo accettato crea impegni
- [ ] Kit con componenti crea impegni
- [ ] Impegni visibili in dashboard
- [ ] Dettaglio impegni su card prodotto
- [ ] Giacenze aggiornate (fisica/impegnata/libera)
- [ ] Badge corretti (Disponibile/Impegnato/Scorta Bassa)
- [ ] Liberazione manuale funziona
- [ ] Preventivo annullato libera impegni
- [ ] Kit consegnato completa impegni
- [ ] Rimozione componente kit annulla impegno
- [ ] Lavorazione completata scala giacenza
- [ ] Movimenti registrati
- [ ] Modal professionali (no alert)
- [ ] Performance accettabili

---

**Se tutti i test passano → SISTEMA COMPLETO E FUNZIONANTE!** 🚀

## 📝 NOTE FINALI

- **Giacenza fisica kit**: Attualmente NON scala automaticamente alla consegna. Se vuoi che scali, decomment sezione nel trigger `completa_impegni_kit()`
  
- **Preventivo rifiutato**: Stesso comportamento di annullato (libera impegni)

- **Impegni multipli**: Un prodotto può avere impegni da preventivi + kit + lavorazioni contemporaneamente (cumulativi)

- **Performance**: Vista `v_giacenze_complete` calcola impegni in real-time. Su grandi volumi considera materializzazione

- **Backup**: Fai backup database prima di test massivi!
