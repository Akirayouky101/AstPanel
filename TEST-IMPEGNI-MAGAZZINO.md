# 🧪 GUIDA TEST SISTEMA IMPEGNI MAGAZZINO

## 📋 PREREQUISITI
- ✅ Migration SQL eseguita (`add-impegni-magazzino-system.sql`)
- ✅ Migration FK movimenti eseguita (`fix-movimenti-magazzino-fk.sql`)
- ✅ Frontend deployato (git push completato)

---

## 🎯 TEST 1: PREVENTIVO → IMPEGNO

### **Obiettivo:** Verificare che preventivo accettato impegni prodotti

### **Passi:**
1. Vai su **Magazzino Prodotti**
   - Controlla giacenza iniziale (es: Sensore XYZ = 10 pz)
   - Annota: `Fisica: 10 | Impegnata: 0 | Libera: 10`

2. Vai su **Gestione Preventivi**
   - Crea nuovo preventivo
   - Aggiungi prodotto: Sensore XYZ x 5
   - Salva come bozza
   
3. **Accetta il preventivo**
   - Cambia stato → Accettato
   - Aspetta conferma

4. Torna su **Magazzino Prodotti**
   - Cerca Sensore XYZ
   - Verifica giacenze:
     - ✅ `Fisica: 10` (non cambiata)
     - ✅ `Impegnata: 5` (nuovo!)
     - ✅ `Libera: 5` (calcolata)

5. Click su **"Vedi dettaglio impegni"**
   - Verifica modal con impegno attivo
   - Tipo: Preventivo
   - Riferimento: numero preventivo
   - Quantità: 5 pz

6. Vai su **Gestione Impegni**
   - Verifica nuovo impegno nella tabella
   - Tipo: Preventivo
   - Stato: Attivo
   - Prodotto: Sensore XYZ

### **Risultato Atteso:**
✅ Impegno creato automaticamente  
✅ Giacenza libera ridotta  
✅ Giacenza fisica invariata  
✅ Badge "Impegnato" su preventivo  

---

## 🎯 TEST 2: KIT con GIACENZA IMPEGNATA

### **Obiettivo:** Verificare che kit usi solo giacenza libera per ordini

### **Passi:**
1. **Situazione iniziale** (dal Test 1):
   - Sensore XYZ: 10 fisica | 5 impegnata | 5 libera

2. Vai su **Gestione Kit**
   - Crea nuovo kit
   - Aggiungi componente: Sensore XYZ x 8

3. Click **"Vedi Componenti Mancanti"**
   - Verifica calcolo:
     - Richiesti: 8
     - Disponibili (liberi): 5
     - ✅ **Mancanti: 3** (non 0!)

4. Click **"Crea Ordini Fornitore Automatici"**
   - Verifica ordine creato
   - Quantità ordinata: 3 + scorta minima

5. Vai su **Ordini Fornitori**
   - Trova ordine per Sensore XYZ
   - Verifica quantità corretta

### **Risultato Atteso:**
✅ Kit considera solo giacenza LIBERA (5)  
✅ Ordine fornitore per differenza (3)  
✅ Non ordina prodotti già impegnati  

---

## 🎯 TEST 3: LAVORAZIONE → SCALA GIACENZA

### **Obiettivo:** Verificare che lavorazione completata scali giacenza e liberi impegno

### **Passi:**
1. Vai su **Gestione Lavorazioni** (tasks)
   - Cerca lavorazione collegata al preventivo
   - Se non esiste, creala dal preventivo

2. **Completa la lavorazione**
   - Cambia stato → Completato
   - Aspetta conferma

3. Torna su **Magazzino Prodotti**
   - Cerca Sensore XYZ
   - Verifica giacenze:
     - ✅ `Fisica: 5` (scalata da 10!)
     - ✅ `Impegnata: 0` (liberata!)
     - ✅ `Libera: 5`

4. Vai su **Gestione Impegni**
   - Cerca impegno precedente
   - Verifica stato: **Completato**
   - Completato il: data odierna

5. Vai su **Movimenti Magazzino** (se esiste la pagina)
   - Cerca movimento per Sensore XYZ
   - Tipo: Uscita
   - Quantità: -5
   - Causale: "Completamento lavorazione LAV-XXX"

### **Risultato Atteso:**
✅ Giacenza fisica scalata  
✅ Impegno completato (non più attivo)  
✅ Movimento registrato  
✅ Giacenza libera aggiornata  

---

## 🎯 TEST 4: PREVENTIVO ANNULLATO → LIBERA IMPEGNO

### **Obiettivo:** Verificare che preventivo annullato liberi prodotti

### **Passi:**
1. Crea nuovo preventivo con Sensore XYZ x 3
2. Accetta preventivo
3. Verifica impegno creato (Magazzino Prodotti)
4. **Annulla preventivo**
   - Cambia stato → Annullato
5. Verifica impegno annullato (Gestione Impegni)
6. Verifica giacenza libera aumentata

### **Risultato Atteso:**
✅ Impegno annullato automaticamente  
✅ Giacenza libera ripristinata  

---

## 🎯 TEST 5: DASHBOARD IMPEGNI

### **Obiettivo:** Testare tutte le funzionalità della dashboard

### **Passi:**
1. Vai su **Gestione Impegni**

2. Verifica **Statistiche**:
   - Impegni Attivi
   - Da Preventivi
   - Da Lavorazioni
   - Prodotti Impegnati

3. Usa **Filtri**:
   - Cerca per nome prodotto
   - Filtra per tipo (Preventivo/Lavorazione/Kit)
   - Filtra per stato (Attivo/Completato/Annullato)

4. **Libera Impegno Manuale**:
   - Click "Libera" su un impegno attivo
   - Conferma nella modal
   - Verifica impegno annullato
   - Torna a Magazzino → verifica giacenza libera aumentata

### **Risultato Atteso:**
✅ Stats accurate  
✅ Filtri funzionanti  
✅ Liberazione manuale OK  
✅ Giacenze aggiornate  

---

## 🎯 TEST 6: SCENARIO COMPLETO

### **Flow completo dalla A alla Z:**

```
INIZIO: Sensore XYZ = 10 pz (tutto libero)
    ↓
[1] PREVENTIVO PREV-001: 3 pz
    → Fisica: 10 | Impegnata: 3 | Libera: 7
    ↓
[2] PREVENTIVO PREV-002: 4 pz  
    → Fisica: 10 | Impegnata: 7 | Libera: 3
    ↓
[3] KIT richiede 8 pz
    → Usa solo 3 liberi
    → Ordina 5 pz dal fornitore ✅
    ↓
[4] COMPLETA Lavorazione PREV-001
    → Fisica: 7 (scalata 3)
    → Impegnata: 4 (solo PREV-002)
    → Libera: 3
    ↓
[5] ANNULLA PREV-002
    → Fisica: 7
    → Impegnata: 0
    → Libera: 7 ✅
```

### **Verifica Finale:**
- ✅ Ordine fornitore per 5 pz (non 0)
- ✅ Impegno PREV-001 completato
- ✅ Impegno PREV-002 annullato
- ✅ Giacenza finale corretta
- ✅ Nessuna giacenza negativa
- ✅ Tutti i movimenti tracciati

---

## ❌ PROBLEMI COMUNI

### **1. Vista v_giacenze_complete non esiste**
**Sintomo:** Errore "relation does not exist"  
**Soluzione:** Esegui migration `add-impegni-magazzino-system.sql`

### **2. FK Error su movimenti_magazzino**
**Sintomo:** "violates foreign key constraint movimenti_magazzino_created_by_fkey"  
**Soluzione:** Esegui migration `fix-movimenti-magazzino-fk.sql`

### **3. Impegni non vengono creati**
**Sintomo:** Preventivo accettato ma giacenza impegnata = 0  
**Soluzione:** 
- Verifica trigger `trigger_impegna_preventivo` esista
- Controlla log SQL per errori
- Verifica tabella `preventivo_items` popolata

### **4. Giacenza libera negativa**
**Sintomo:** Giacenza libera < 0  
**Soluzione:**
- Verifica impegni attivi in `impegni_magazzino`
- Controlla giacenza fisica corretta
- Possibile doppio impegno: cerca duplicati

### **5. Kit ordina tutto invece di solo mancante**
**Sintomo:** Ordine fornitore per 10 pz invece di 3  
**Soluzione:**
- Verifica trigger `verifica_giacenza_libera_kit` 
- Usa `get_giacenza_libera()` non `quantita_disponibile`

---

## 📊 QUERY DEBUG UTILI

### **1. Verifica giacenze prodotto**
```sql
SELECT * FROM v_giacenze_complete 
WHERE codice = 'CODICE_PRODOTTO';
```

### **2. Impegni attivi per prodotto**
```sql
SELECT * FROM impegni_magazzino 
WHERE prodotto_id = 'UUID_PRODOTTO' AND stato = 'attivo';
```

### **3. Cronologia impegni**
```sql
SELECT 
    i.*,
    c.codice,
    c.nome,
    p.numero_preventivo
FROM impegni_magazzino i
JOIN components c ON c.id = i.prodotto_id
LEFT JOIN preventivi p ON p.id = i.preventivo_id
ORDER BY i.created_at DESC
LIMIT 20;
```

### **4. Prodotti con impegni critici**
```sql
SELECT * FROM v_giacenze_complete 
WHERE stato_giacenza LIKE 'CRITICO%';
```

### **5. Totale impegnato per tipo**
```sql
SELECT 
    tipo_impegno,
    COUNT(*) as num_impegni,
    SUM(quantita_impegnata) as totale_impegnato
FROM impegni_magazzino 
WHERE stato = 'attivo'
GROUP BY tipo_impegno;
```

---

## ✅ CHECKLIST FINALE

Prima di considerare il test completato:

- [ ] Preventivo accettato crea impegno
- [ ] Preventivo annullato libera impegno
- [ ] Lavorazione completata scala giacenza e libera impegno
- [ ] Kit usa giacenza libera (non fisica)
- [ ] Ordini fornitore calcolati su giacenza libera
- [ ] Dashboard impegni mostra dati corretti
- [ ] Liberazione manuale funziona
- [ ] Badge "Impegnato" su preventivi accettati
- [ ] Dettaglio impegni in card prodotto
- [ ] Nessuna giacenza negativa
- [ ] Tutti i movimenti tracciati
- [ ] Performance accettabili (< 2s per caricamento)

---

## 🎉 TEST SUPERATO!

Se tutti i test passano:
1. ✅ Sistema impegni funziona correttamente
2. ✅ Giacenze sempre coerenti
3. ✅ Nessuna sovrapposizione ordini
4. ✅ Tracciabilità completa
5. ✅ UX intuitiva e chiara

**Sistema pronto per produzione!** 🚀
