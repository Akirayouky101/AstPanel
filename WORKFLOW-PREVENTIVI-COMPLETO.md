# 🚀 WORKFLOW COMPLETO: Preventivi → Ordini → Lavorazioni

## ✅ Sistema Implementato

Hai ora un sistema completo per gestire l'intero ciclo di vita da preventivo a lavorazione con scarico automatico magazzino.

---

## 📋 STEP 1: Esegui gli script SQL su Supabase

**IMPORTANTE:** Vai su https://hrqhckksrunniqnzqogk.supabase.co/project/hrqhckksrunniqnzqogk/sql/new

Esegui questi file SQL **nell'ordine seguente**:

### 1️⃣ **create-ordini-fornitori-system.sql** (PRIORITÀ MASSIMA)
```sql
-- Copia e incolla TUTTO il contenuto del file (500+ righe)
-- Crea:
-- ✅ Tabella fornitori
-- ✅ Tabella ordini_fornitore  
-- ✅ Tabella ordini_fornitore_items
-- ✅ Tabella movimenti_magazzino
-- ✅ Funzioni: generate_ordine_numero(), carica_magazzino(), scarica_magazzino(), verifica_disponibilita_preventivo()
-- ✅ Aggiunge giacenza e giacenza_minima a components
-- ✅ Aggiunge giacenza_disponibile e da_ordinare a preventivi_items
-- ✅ Aggiunge fornitore_preferito_id a components
```

### 2️⃣ **add-preventivo-to-tasks.sql**
```sql
-- Copia e incolla il file
-- Aggiunge campo preventivo_id alla tabella tasks
-- Permette di collegare lavorazioni ai preventivi
```

### 3️⃣ **create-workflow-preventivi-ordini.sql**
```sql
-- Copia e incolla il file
-- Crea funzione genera_ordini_da_preventivo()
-- Genera automaticamente ordini per materiali mancanti
```

### 4️⃣ Dopo aver eseguito gli script:
Vai su **Settings → API → Reload Schema** per aggiornare la cache di Supabase.

---

## 🔄 WORKFLOW COMPLETO

### **Fase 1: Gestione Fornitori**
📍 `/Admin/gestione-fornitori.html`

1. Aggiungi fornitori con:
   - Anagrafica (P.IVA, CF, ragione sociale)
   - Contatti (email, telefono, PEC)
   - Condizioni commerciali (giorni consegna, IBAN)
   - Categoria (es: Idraulica, Elettrico, Edile)

### **Fase 2: Gestione Magazzino**
📍 `/magazzino-prodotti.html`

1. Per ogni prodotto, **opzionalmente** imposta:
   - `giacenza`: quantità attuale in magazzino
   - `giacenza_minima`: soglia di riordino
   - `fornitore_preferito_id`: fornitore default per ordini automatici

### **Fase 3: Creazione Preventivo**
📍 `/gestione-preventivi.html`

1. Clicca "Nuovo Preventivo"
2. Seleziona cliente
3. Aggiungi prodotti:
   - 🟢 **Badge verde "Disponibile"** → materiale in stock
   - 🔴 **Badge rosso "Da ordinare"** → materiale mancante
4. Il sistema mostra la giacenza disponibile per ogni prodotto
5. Salva come `bozza` → `inviato` → **`accettato`**

### **Fase 4: Preventivo Accettato - Nuove Azioni**

Quando il preventivo è `accettato`, compaiono 2 nuovi pulsanti:

#### 🛒 **Genera Ordini Materiali** (pulsante arancione)
- Verifica disponibilità magazzino
- Crea automaticamente ordini per materiali mancanti
- Raggruppa prodotti per fornitore preferito
- Genera numero ordine automatico (ORD-2026-001)
- Stato iniziale: `da_ordinare`

**Risultato:**
```
✅ Ordini generati con successo!

• Fornitore Idraulica SRL: 3 prodotti, € 450.00
• Fornitore Elettrico SPA: 2 prodotti, € 280.00

Vai su "Ordini Fornitori" per confermare e inviare gli ordini.
```

#### 🛠️ **Crea Lavorazione** (pulsante verde)
- Crea automaticamente una lavorazione (task)
- Collega il preventivo alla lavorazione
- **Scarica automaticamente i materiali dal magazzino**
- Crea movimenti magazzino di tipo `scarico`
- Aggiorna giacenza in tempo reale

**Cosa succede:**
1. Nuovo record in `tasks` con `preventivo_id`
2. Per ogni prodotto nel preventivo:
   - Chiama `scarica_magazzino(prodotto_id, quantita, task_id, user_id)`
   - Riduce `components.giacenza`
   - Crea record in `movimenti_magazzino` (tipo: scarico)
   - Traccia causale: "Scarico per lavorazione TASK-123"

### **Fase 5: Gestione Ordini Fornitori**
📍 `/Admin/gestione-ordini-fornitori.html`

1. Vedi gli ordini generati automaticamente (o crea manualmente)
2. Modifica quantità/prezzi se necessario
3. Cambia stato: `da_ordinare` → `ordinato` → `in_arrivo`
4. Quando arriva la merce: clicca **"Ricevi Merce"**

#### 📦 **Ricezione Merce**
- Inserisci quantità ricevuta per ogni prodotto
- Clicca "Conferma Ricezione"
- Il sistema chiama automaticamente `carica_magazzino()`:
  - Aggiorna `components.giacenza` (+quantità)
  - Crea movimento magazzino (tipo: carico)
  - Aggiorna stato ordine → `ricevuto` o `parzialmente_ricevuto`
  - Traccia causale: "Carico da ordine ORD-2026-001"

### **Fase 6: Gestione Lavorazioni**
📍 `/gestione-lavorazioni.html`

1. Trova la lavorazione creata dal preventivo
2. Assegna team/utente
3. Imposta date inizio/fine
4. Traccia avanzamento lavoro
5. I materiali sono già stati scaricati automaticamente!

---

## 📊 TABELLE E RELAZIONI

```
┌─────────────┐
│  CLIENTI    │
└──────┬──────┘
       │
       ▼
┌─────────────────┐         ┌──────────────────┐
│  PREVENTIVI     │────────>│ PREVENTIVI_ITEMS │
│                 │         │  - giacenza_disp │
│  stato:         │         │  - da_ordinare   │
│  - bozza        │         └──────────────────┘
│  - inviato      │                   │
│  - accettato ✅ │                   │
└────┬────────────┘                   │
     │                                │
     │ [ACCETTATO]                    │
     │                                ▼
     │                      ┌──────────────────┐
     │                      │   COMPONENTS     │
     │                      │  - giacenza      │
     │                      │  - giacenza_min  │
     │                      │  - fornitore_pref│
     │                      └──────┬───────────┘
     │                             │
     ├─────────[Genera Ordini]────┘
     │                             │
     ▼                             ▼
┌─────────────────┐      ┌──────────────────────┐
│ ORDINI_FORNIT.  │◄─────│ ORDINI_FORNIT_ITEMS  │
│                 │      │  - quantita_ordinata │
│  stato:         │      │  - quantita_ricevuta │
│  - da_ordinare  │      └──────────────────────┘
│  - ordinato     │                   │
│  - in_arrivo    │                   │ [Ricevi Merce]
│  - ricevuto     │                   │
└─────────────────┘                   ▼
     │                      ┌──────────────────┐
     └─────────────────────>│ MOVIMENTI_MAG.   │
                            │  tipo: carico    │
                            └──────────────────┘
                                      ▲
┌─────────────┐                       │
│   TASKS     │                       │
│             │                       │
│ preventivo_id◄──[Crea Lavorazione]─┘
└─────────────┘                       │
     │                                │
     └────[Scarica Materiali]─────────┘
                            ┌──────────────────┐
                            │ MOVIMENTI_MAG.   │
                            │  tipo: scarico   │
                            └──────────────────┘
```

---

## 🔧 FUNZIONI DISPONIBILI

### 1. **generate_ordine_numero()**
```sql
SELECT generate_ordine_numero();
-- Ritorna: 'ORD-2026-001' (auto-incrementale per anno)
```

### 2. **carica_magazzino(ordine_item_id, quantita, user_id)**
```sql
SELECT carica_magazzino(
    'uuid-ordine-item',
    10.5,  -- quantità ricevuta
    'uuid-utente'
);
-- Aggiorna giacenza, crea movimento, aggiorna stato ordine
```

### 3. **scarica_magazzino(prodotto_id, quantita, lavorazione_id, user_id)**
```sql
SELECT scarica_magazzino(
    'uuid-prodotto',
    5.0,  -- quantità da scaricare
    'uuid-task',
    'uuid-utente'
);
-- Riduce giacenza, crea movimento scarico
-- ERRORE se giacenza insufficiente
```

### 4. **verifica_disponibilita_preventivo(preventivo_id)**
```sql
SELECT * FROM verifica_disponibilita_preventivo('uuid-preventivo');

-- Ritorna:
-- prodotto_id | quantita_necessaria | giacenza_disponibile | da_ordinare
-- ----------------------------------------------------------------
-- uuid-1      | 10.00              | 8.00                | 2.00
-- uuid-2      | 5.00               | 5.00                | 0.00
```

### 5. **genera_ordini_da_preventivo(preventivo_id, user_id)**
```sql
SELECT * FROM genera_ordini_da_preventivo('uuid-preventivo', 'uuid-utente');

-- Ritorna:
-- ordine_id | fornitore_nome        | prodotti_count | totale_ordine
-- -------------------------------------------------------------------
-- uuid-ord1 | Idraulica SRL         | 3             | 450.00
-- uuid-ord2 | Elettrico SPA         | 2             | 280.00
```

---

## ⚠️ CONTROLLI E VALIDAZIONI

### ✅ Carico Magazzino
- Verifica che ordine_item_id esista
- Quantità ricevuta non può superare quantità ordinata
- Aggiorna automaticamente stato ordine:
  - Se tutti i prodotti ricevuti → `ricevuto`
  - Se solo alcuni → `parzialmente_ricevuto`

### ✅ Scarico Magazzino
- **ERRORE** se giacenza < quantità richiesta
- Crea movimento con quantità negativa
- Traccia lavorazione_id per audit

### ✅ Generazione Ordini Automatica
- Usa fornitore preferito del prodotto (se impostato)
- Altrimenti usa primo fornitore attivo
- Raggruppa prodotti per fornitore
- Calcola totali automaticamente

---

## 🎯 TEST DEL SISTEMA

### **Test Completo (15 minuti)**

1. **Crea Fornitore**
   - Nome: "Test Idraulica SRL"
   - Giorni consegna: 7
   - Categoria: "Idraulica"

2. **Aggiungi Prodotto**
   - Codice: "TUBO-001"
   - Giacenza: 5 pz
   - Fornitore preferito: Test Idraulica SRL

3. **Crea Preventivo**
   - Aggiungi TUBO-001
   - Quantità: 10 pz (più della giacenza!)
   - Verifica badge rosso "Da ordinare"
   - Cambia stato → Accettato

4. **Genera Ordini**
   - Clicca pulsante "Genera Ordini Materiali"
   - Verifica creazione ordine per 5 pz (mancanti)

5. **Ricevi Merce**
   - Vai su Ordini Fornitori
   - Clicca "Ricevi Merce"
   - Inserisci 5 pz
   - Conferma

6. **Verifica Giacenza**
   - Magazzino → TUBO-001
   - Giacenza ora: 10 pz ✅

7. **Crea Lavorazione**
   - Torna al preventivo
   - Clicca "Crea Lavorazione"
   - Conferma

8. **Verifica Scarico**
   - Magazzino → TUBO-001
   - Giacenza ora: 0 pz (10 scaricati) ✅
   - Movimenti Magazzino → Vedi movimento "scarico"

---

## 📈 FUNZIONALITÀ FUTURE (Opzionali)

- [ ] Dashboard magazzino con grafici giacenze
- [ ] Alert automatici per prodotti sotto giacenza minima
- [ ] Invio email automatica ordini ai fornitori
- [ ] PDF preventivi con logo aziendale
- [ ] Calendario consegne previste
- [ ] Reportistica costi materiali per lavorazione
- [ ] Integrazione barcode scanner per carichi/scarichi
- [ ] Storico prezzi fornitori
- [ ] Confronto preventivi/consuntivi

---

## 🆘 TROUBLESHOOTING

### ❌ Errore: "relation fornitori does not exist"
**Soluzione:** Non hai eseguito `create-ordini-fornitori-system.sql` su Supabase

### ❌ Errore: "function genera_ordini_da_preventivo does not exist"
**Soluzione:** Non hai eseguito `create-workflow-preventivi-ordini.sql`

### ❌ Errore: "giacenza insufficiente"
**Soluzione:** Normale! Devi prima ricevere la merce o ridurre quantità preventivo

### ❌ Pulsanti "Genera Ordini" non compaiono
**Soluzione:** Il preventivo deve avere stato = `accettato`

### ❌ Ordini non creati automaticamente
**Soluzione:** 
1. Verifica che components.fornitore_preferito_id sia impostato
2. Oppure assicurati di avere almeno 1 fornitore attivo
3. Controlla console browser per errori JavaScript

---

## 📞 SUPPORTO

Sistema creato il: 28 gennaio 2026
Versione: 1.0.0

Commit hash: d999a85

**Repository:** https://github.com/Akirayouky101/AstPanel

---

## ✅ CHECKLIST IMPLEMENTAZIONE

- [ ] Eseguito `create-ordini-fornitori-system.sql`
- [ ] Eseguito `add-preventivo-to-tasks.sql`
- [ ] Eseguito `create-workflow-preventivi-ordini.sql`
- [ ] Reload schema Supabase (Settings → API)
- [ ] Creato almeno 1 fornitore
- [ ] Impostato giacenza su alcuni prodotti
- [ ] Testato creazione preventivo con badge disponibilità
- [ ] Testato generazione ordini automatica
- [ ] Testato ricezione merce e carico magazzino
- [ ] Testato creazione lavorazione e scarico automatico
- [ ] Verificato movimenti magazzino registrati correttamente

---

**🎉 Buon lavoro con il nuovo sistema!**
