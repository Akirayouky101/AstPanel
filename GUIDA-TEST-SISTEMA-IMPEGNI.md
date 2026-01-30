# 🧪 GUIDA COMPLETA TEST SISTEMA IMPEGNI MAGAZZINO

## 📋 PREREQUISITI
- ✅ Database resettato (RESET-TOTALE-TUTTO.sql eseguito)
- ✅ Trigger eliminazione kit installati (add-trigger-elimina-kit-completo.sql eseguito)
- ✅ Pulizia righe orfane eseguita (pulisci-righe-orfane-kit.sql eseguito)

---

## FASE 1: SETUP DATI BASE (5 minuti)

### 1.1 Crea un Fornitore
📍 **Pagina**: Gestione Fornitori

**Dati da inserire**:
- Ragione Sociale: `Fornitore Test SRL`
- P.IVA: `12345678901`
- Email: `test@fornitore.it`
- Telefono: `0123456789`

✅ **Verifica**: Il fornitore appare nella lista

---

### 1.2 Crea un Cliente
📍 **Pagina**: Gestione Clienti

**Dati da inserire**:
- Ragione Sociale: `Cliente Test SPA`
- Email: `test@cliente.it`
- Telefono: `9876543210`
- Indirizzo: `Via Test 123, Milano`

✅ **Verifica**: Il cliente appare nella lista

---

### 1.3 Carica 3 Prodotti in Magazzino
📍 **Pagina**: Gestione Magazzino Prodotti

#### Prodotto 1: EV-MOD BWL
- **Codice**: `F102EVMODBWL`
- **Nome**: `EV-MOD BWL`
- **Descrizione**: `Modulo elettronico BWL`
- **Unità di misura**: `pz`
- **Categoria**: `Elettronica`
- **Fornitore**: Seleziona "Fornitore Test SRL"
- **Prezzo acquisto**: `15.50`
- **Giacenza minima**: `5`
- **Quantità disponibile**: `50` ⬅️ **IMPORTANTE: Metti almeno 50**

#### Prodotto 2: SPEED8 STD
- **Codice**: `F101SPEED8STD`
- **Nome**: `SPEED8 STD`
- **Descrizione**: `Controllore SPEED8 Standard`
- **Unità di misura**: `pz`
- **Categoria**: `Elettronica`
- **Fornitore**: Seleziona "Fornitore Test SRL"
- **Prezzo acquisto**: `25.00`
- **Giacenza minima**: `3`
- **Quantità disponibile**: `30` ⬅️ **IMPORTANTE: Metti almeno 30**

#### Prodotto 3: CAVO USB
- **Codice**: `F201CABUSB3M`
- **Nome**: `CAVO USB 3M`
- **Descrizione**: `Cavo USB 3 metri`
- **Unità di misura**: `pz`
- **Categoria**: `Accessori`
- **Fornitore**: Seleziona "Fornitore Test SRL"
- **Prezzo acquisto**: `8.00`
- **Giacenza minima**: `10`
- **Quantità disponibile**: `100` ⬅️ **IMPORTANTE: Metti almeno 100**

✅ **Verifica dopo inserimento**:
- I 3 prodotti appaiono nella lista magazzino
- **Giacenza Libera** = **Giacenza Fisica** (nessun impegno ancora)
- Badge **Disponibile** verde per tutti i prodotti

---

## FASE 2: TEST KIT - Creazione e Impegno Automatico (10 minuti)

### 2.1 Crea un Kit
📍 **Pagina**: Gestione Kit

**Clic su**: `+ Nuovo Kit`

**Dati Kit**:
- **Nome Kit**: `Kit Prova Impegni`
- **Descrizione**: `Test sistema impegni magazzino`
- **Destinatario**: Seleziona "Cliente" → "Cliente Test SPA"
- **Stato**: Lascia `preparazione` (default)

**Clic su**: `Salva Kit`

✅ **Verifica**: Il kit appare nella lista con stato "Preparazione"

---

### 2.2 Aggiungi Componenti al Kit
📍 **Apri il kit appena creato** (clic sul kit nella lista)

#### Aggiungi Componente 1: EV-MOD BWL
1. **Cerca prodotto**: Digita `F102` o `EV-MOD` nella barra di ricerca
2. **Seleziona**: EV-MOD BWL dall'elenco
3. **Quantità**: `10`
4. **Clic su**: `Aggiungi`

🎯 **Cosa dovrebbe succedere**:
- ✅ Componente aggiunto alla lista del kit
- ✅ Nessun errore (hai 50 pezzi disponibili)
- ✅ Il prodotto appare nella sezione "Componenti nel Kit"

#### Aggiungi Componente 2: SPEED8 STD
1. **Cerca prodotto**: Digita `F101` o `SPEED8`
2. **Seleziona**: SPEED8 STD
3. **Quantità**: `5`
4. **Clic su**: `Aggiungi`

✅ **Verifica**: Componente aggiunto, nessun errore

#### Aggiungi Componente 3: CAVO USB
1. **Cerca prodotto**: Digita `F201` o `CAVO`
2. **Seleziona**: CAVO USB 3M
3. **Quantità**: `15`
4. **Clic su**: `Aggiungi`

✅ **Verifica**: Componente aggiunto, nessun errore

**Totale componenti nel kit**: 3 (EV-MOD BWL x10, SPEED8 STD x5, CAVO USB x15)

---

### 2.3 Verifica Impegni Creati
📍 **Pagina**: Gestione Impegni Magazzino

✅ **VERIFICA CRITICA**:

**Dovresti vedere 3 impegni attivi**:

| Prodotto      | Tipo    | Quantità | Stato  | Riferimento           |
|---------------|---------|----------|--------|-----------------------|
| EV-MOD BWL    | Kit     | 10       | Attivo | KIT-XXXXXXX-XXXXX     |
| SPEED8 STD    | Kit     | 5        | Attivo | KIT-XXXXXXX-XXXXX     |
| CAVO USB 3M   | Kit     | 15       | Attivo | KIT-XXXXXXX-XXXXX     |

**Stats in alto**:
- **Impegni Attivi**: 3
- **Prodotti Impegnati**: 3

---

### 2.4 Verifica Giacenze Aggiornate
📍 **Pagina**: Gestione Magazzino Prodotti

✅ **VERIFICA GIACENZE**:

| Prodotto      | Fisica | Impegnata | Libera | Stato        |
|---------------|--------|-----------|--------|--------------|
| EV-MOD BWL    | 50     | 10        | 40     | Disponibile  |
| SPEED8 STD    | 30     | 5         | 25     | Disponibile  |
| CAVO USB 3M   | 100    | 15        | 85     | Disponibile  |

🎯 **IMPORTANTE**: La **Giacenza Libera** deve essere diminuita esattamente della quantità impegnata!

---

## FASE 3: TEST ELIMINAZIONE KIT - Liberazione Impegni (5 minuti)

### 3.1 Elimina il Kit
📍 **Pagina**: Gestione Kit

1. **Trova il kit** "Kit Prova Impegni" nella lista
2. **Clic su**: `Elimina` (icona cestino rosso)
3. **Conferma eliminazione**

🎯 **Cosa dovrebbe succedere AUTOMATICAMENTE**:

#### A. Impegni Annullati
📍 **Vai su**: Gestione Impegni Magazzino

✅ **Verifica**:
- **Impegni Attivi**: 0 (erano 3, ora 0)
- **Filtro**: Cambia a "Annullati" → Dovresti vedere i 3 impegni con stato "Annullato"
- **Note**: Ogni impegno ha scritto "Kit eliminato: KIT-XXXXXXX"

#### B. Giacenze Liberate
📍 **Vai su**: Gestione Magazzino Prodotti

✅ **VERIFICA CRITICA**:

| Prodotto      | Fisica | Impegnata | Libera | Stato        |
|---------------|--------|-----------|--------|--------------|
| EV-MOD BWL    | 50     | 0         | 50     | Disponibile  |
| SPEED8 STD    | 30     | 0         | 30     | Disponibile  |
| CAVO USB 3M   | 100    | 0         | 100    | Disponibile  |

🎯 **IMPORTANTE**: La **Giacenza Libera** deve essere tornata uguale alla **Giacenza Fisica**!

#### C. Storico Registrato
📍 **Apri un prodotto** (es. EV-MOD BWL) → **Clic su "Storico"**

✅ **Verifica movimenti**:
- Dovrebbe esserci un movimento di tipo **"Reintegro"**
- **Causale**: "Kit eliminato: KIT-XXXXXXX - Prodotto: EV-MOD BWL reintegrato (10 pz)"
- **Quantità**: 10

---

## FASE 4: TEST EDGE CASES - Casi Limite (10 minuti)

### 4.1 Test: Giacenza Insufficiente
📍 **Crea un nuovo kit** e prova ad aggiungere:
- **Prodotto**: SPEED8 STD
- **Quantità**: `100` ⬅️ **Più di quanto disponibile (30)**

🎯 **Risultato atteso**:
- ❌ **ERRORE**: "Giacenza libera insufficiente per SPEED8 STD: disponibili 30.00, richieste 100.00"
- ✅ Il componente **NON viene aggiunto** al kit
- ✅ **Nessun impegno creato** (controlla Gestione Impegni)

---

### 4.2 Test: Rimozione Singolo Componente
📍 **Crea un nuovo kit** con 2 componenti:
- CAVO USB x20
- EV-MOD BWL x5

✅ **Verifica impegni creati**: 2 impegni attivi

📍 **Rimuovi SOLO CAVO USB** dal kit (clic cestino rosso sul componente)

🎯 **Risultato atteso**:
- ✅ Impegno CAVO USB annullato
- ✅ Impegno EV-MOD BWL ancora **attivo**
- ✅ Giacenza libera CAVO USB tornata a 100
- ✅ Giacenza libera EV-MOD BWL ancora impegnata (45 se avevi 50 - 5)

---

### 4.3 Test: Kit con Stesso Prodotto Due Volte
📍 **Crea un nuovo kit**

**Aggiungi**:
1. EV-MOD BWL x10
2. EV-MOD BWL x5 (stesso prodotto, altra quantità)

🎯 **Risultato atteso**:
- ✅ **UN SOLO impegno** per EV-MOD BWL
- ✅ **Quantità totale**: 15 (10 + 5, sommate)
- ✅ **NO DUPLICATI** nella tabella impegni

---

## FASE 5: TEST PREVENTIVI (Opzionale - 15 minuti)

### 5.1 Crea un Preventivo
📍 **Pagina**: Gestione Preventivi

**Dati**:
- **Cliente**: Cliente Test SPA
- **Oggetto**: Test impegni preventivo
- **Data emissione**: Oggi

**Aggiungi righe**:
- EV-MOD BWL x20
- SPEED8 STD x10

**Salva** → Stato: "In attesa"

✅ **Verifica**: Nessun impegno ancora (preventivo non accettato)

---

### 5.2 Accetta il Preventivo

**Cambia stato** → "Accettato"

🎯 **Risultato atteso**:
- ✅ 2 impegni creati automaticamente (tipo: "Preventivo")
- ✅ Giacenze aggiornate:
  - EV-MOD BWL: libera = 50 - 20 = 30
  - SPEED8 STD: libera = 30 - 10 = 20

---

### 5.3 Annulla il Preventivo

**Cambia stato** → "Rifiutato" o "Annullato"

🎯 **Risultato atteso**:
- ✅ Impegni annullati
- ✅ Giacenze liberate
- ✅ Badge "Impegnato" sparito dal preventivo

---

## ✅ CHECKLIST FINALE

Alla fine di tutti i test, verifica che:

- [ ] Kit crea impegni automaticamente quando aggiungi componenti
- [ ] Giacenza libera diminuisce correttamente
- [ ] Errore se provi a impegnare più di quanto disponibile
- [ ] Eliminazione kit annulla TUTTI gli impegni
- [ ] Giacenze tornano libere dopo eliminazione kit
- [ ] Storico registra i reintegri
- [ ] Rimozione singolo componente annulla solo quell'impegno
- [ ] NO DUPLICATI: stesso prodotto due volte = un solo impegno con quantità sommata
- [ ] Dashboard impegni mostra dati corretti (attivi/annullati)
- [ ] Preventivo accettato crea impegni
- [ ] Preventivo annullato libera impegni

---

## 🐛 SE QUALCOSA NON FUNZIONA

### Problema: "Tutto impegnato" anche se non ci sono kit
**Soluzione**: Esegui `pulisci-righe-orfane-kit.sql`

### Problema: Componente aggiunto ma nessun impegno creato
**Possibile causa**: Trigger non installato correttamente
**Soluzione**: Riesegui `add-trigger-elimina-kit-completo.sql`

### Problema: Eliminazione kit non libera giacenze
**Possibile causa**: Trigger eliminazione mancante
**Soluzione**: Riesegui `add-trigger-elimina-kit-completo.sql`

### Problema: Righe duplicate in impegni
**Possibile causa**: Trigger ordine sbagliato
**Soluzione**: Esegui `fix-trigger-order-kit-impegni.sql`

---

## 📊 QUERY DEBUG UTILI

### Verifica impegni per un prodotto specifico
```sql
SELECT 
    i.*,
    COALESCE(p.numero, k.codice_kit, t.titolo) as riferimento
FROM impegni_magazzino i
LEFT JOIN components c ON c.id = i.prodotto_id
LEFT JOIN preventivi p ON p.id = i.preventivo_id
LEFT JOIN kits k ON k.id = i.kit_id
LEFT JOIN tasks t ON t.id = i.lavorazione_id
WHERE c.codice = 'F102EVMODBWL'  -- ⬅️ Cambia con il tuo codice
ORDER BY i.created_at DESC;
```

### Verifica giacenze complete
```sql
SELECT * FROM v_giacenze_complete
ORDER BY nome;
```

### Conta impegni attivi per tipo
```sql
SELECT 
    tipo_impegno,
    COUNT(*) as totale,
    SUM(quantita_impegnata) as quantita_totale
FROM impegni_magazzino
WHERE stato = 'attivo'
GROUP BY tipo_impegno;
```

---

## 🎯 OBIETTIVO FINALE

Al termine dei test, dovresti avere:
1. ✅ Sistema che gestisce correttamente le giacenze impegnate
2. ✅ Nessuna possibilità di sovra-impegnare prodotti
3. ✅ Pulizia automatica quando elimini kit/preventivi
4. ✅ Storico completo di tutti i movimenti
5. ✅ Dashboard impegni funzionante e accurata

**Tempo totale stimato**: 30-45 minuti

Buon test! 🚀
