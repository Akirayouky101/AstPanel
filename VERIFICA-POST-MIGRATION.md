# ✅ VERIFICA POST-MIGRATION - Sistema Impegni

## 🎯 Migration Eseguite:
1. ✅ `add-impegni-magazzino-system.sql`
2. ✅ `fix-impegni-preventivi-column.sql`
3. ✅ `fix-impegni-tasks-column.sql`

---

## 📋 CHECKLIST VERIFICA

### 1️⃣ **Magazzino Prodotti**

Vai su: `magazzino-prodotti.html`

#### Console Log (F12):
- [ ] `✅ Vista giacenze caricata: X prodotti` (NON più warning)
- [ ] Nessun errore "v_giacenze_complete does not exist"

#### UI Prodotti:
- [ ] **NON** tutti "Tutto Impegnato" 
- [ ] Badge corretti:
  - 🟢 **"Disponibile"** se hai giacenza > 0
  - 🟠 **"Scorta Bassa"** se giacenza ≤ scorta minima
  - 🔴 **"Tutto Impegnato"** SOLO se giacenza effettivamente = 0

#### Card Prodotto:
- [ ] **Giacenza Libera**: valore corretto (es: 10.00 pz)
- [ ] Se NON hai impegni: "Nessun impegno attivo"
- [ ] Se hai impegni (dopo test): mostra dettaglio fisica/impegnata/libera

---

### 2️⃣ **Gestione Impegni**

Vai su: `gestione-impegni.html`

#### Caricamento:
- [ ] Pagina carica senza errori
- [ ] **0 impegni** mostrati (normale se non hai ancora accettato preventivi)
- [ ] NON errori "column does not exist"

#### Stats:
- [ ] Impegni Attivi: 0
- [ ] Da Preventivi: 0
- [ ] Da Lavorazioni: 0
- [ ] Prodotti Impegnati: 0

---

### 3️⃣ **Test Flusso Completo**

#### A. Crea e Accetta Preventivo:

1. Vai su **Gestione Preventivi**
2. Crea nuovo preventivo
3. Aggiungi un prodotto (es: Batteria, quantità 2)
4. Salva preventivo
5. **Cambia stato → Accettato**

**Verifica:**
- [ ] Vai su **Gestione Impegni**
- [ ] Appare 1 impegno attivo
- [ ] Tipo: Preventivo
- [ ] Quantità: 2 pz
- [ ] Stato: Attivo

- [ ] Vai su **Magazzino Prodotti**
- [ ] Cerca "Batteria"
- [ ] Badge: "Tutto Impegnato" o "Scorta Bassa" (dipende dalla giacenza)
- [ ] **Giacenza Impegnata**: 2.00 pz
- [ ] **Giacenza Libera**: fisica - 2
- [ ] Button **"Vedi dettaglio impegni"** visibile

#### B. Click "Vedi dettaglio impegni":

- [ ] Si apre modal
- [ ] Titolo: "Impegni per [nome prodotto]"
- [ ] Tabella con impegno:
  - Tipo: Preventivo
  - Riferimento: PREV-XXX
  - Quantità: 2 pz
  - Stato: Attivo

#### C. Libera Impegno Manualmente:

1. Vai su **Gestione Impegni**
2. Click **"Libera"** sull'impegno
3. Conferma nella modal arancione

**Verifica:**
- [ ] Modal verde: "Impegno liberato con successo!"
- [ ] Impegno scompare dalla lista (o stato → Annullato)
- [ ] Torna su **Magazzino**
- [ ] Giacenza impegnata = 0
- [ ] Giacenza libera = giacenza fisica
- [ ] Torna badge "Disponibile"

---

### 4️⃣ **Test Trigger Preventivo Annullato**

1. Crea nuovo preventivo con prodotto
2. Accetta preventivo (crea impegno)
3. **Annulla preventivo**

**Verifica:**
- [ ] Impegno stato → Annullato
- [ ] Giacenza libera ripristinata

---

### 5️⃣ **Test Kit (opzionale)**

1. Vai su **Gestione Kit**
2. Crea kit con componente che ha:
   - Giacenza fisica: 10
   - Giacenza impegnata: 5
   - Giacenza libera: 5
3. Richiedi 8 componenti nel kit

**Verifica:**
- [ ] Sistema calcola mancanti: 3 (8 richiesti - 5 liberi)
- [ ] Ordine fornitore per 3 + buffer
- [ ] **NON** ordina 0 (userebbe fisica 10)

---

## ❌ PROBLEMI COMUNI

### "Tutti ancora 'Tutto Impegnato'"
**Causa**: Giacenza fisica = 0 nei tuoi prodotti
**Soluzione**: 
1. Vai su un prodotto
2. Click "Modifica"
3. Imposta giacenza > 0
4. O registra un carico/scarico

### "Vista v_giacenze_complete not found"
**Causa**: Migration non eseguita correttamente
**Soluzione**: Ri-esegui `add-impegni-magazzino-system.sql`

### "Column numero_preventivo does not exist"
**Causa**: Migration fix preventivi non eseguita
**Soluzione**: Esegui `fix-impegni-preventivi-column.sql`

### "Column codice_lavorazione does not exist"
**Causa**: Migration fix tasks non eseguita
**Soluzione**: Esegui `fix-impegni-tasks-column.sql`

---

## 🎉 SISTEMA OK SE:

✅ Magazzino carica senza errori
✅ Badge riflettono giacenza reale
✅ Gestione Impegni carica (anche con 0 impegni)
✅ Preventivo accettato crea impegno
✅ Impegno visibile in dashboard e dettaglio prodotto
✅ Liberazione manuale funziona
✅ Giacenze aggiornate in tempo reale

---

**Se tutto OK → Sistema Impegni Magazzino COMPLETO!** 🚀
