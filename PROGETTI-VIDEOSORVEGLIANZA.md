# 📹 SISTEMA PROGETTI VIDEOSORVEGLIANZA

## 🎯 Panoramica

Sistema completo per la gestione di progetti di videosorveglianza con **editor planimetrie integrato** (Grid + Canvas + Upload).

---

## ✨ Funzionalità Principali

### 1️⃣ **GESTIONE PROGETTI**
- Numerazione automatica (PROG-2026-001)
- Tipologie: Videosorveglianza, Allarme, Controllo Accessi, Rete Dati, Citofonia, Automazione
- Stati: Preventivo → Approvato → In Corso → Completato
- Collegamento cliente e indirizzo installazione
- Date previste e completamento

### 2️⃣ **EDITOR PLANIMETRIE (3 MODALITÀ)**

#### A) **UPLOAD** 📤
- Carica planimetria cliente (PDF, JPG, PNG)
- Visualizzazione su canvas
- Posizionamento dispositivi sopra l'immagine

#### B) **GRID BUILDER** 📊 (Veloce!)
```
Griglia 30x30 quadrati (1 quadrato = 1 metro)
┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤  Click per colorare stanze
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤  Strumenti:
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤  • Muro (grigio scuro)
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤  • Stanza (bianco)
└─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘  • Porta/Finestra
                       • Cancella
```

#### C) **CANVAS DRAW** ✏️ (Flessibile!)
```
Disegno libero su tela bianca
• Linea (muri)
• Rettangolo (stanze)
• Testo/Etichette
• Gomma
• Colori personalizzabili
```

### 3️⃣ **POSIZIONAMENTO DISPOSITIVI**
Su qualsiasi planimetria (upload/grid/canvas):

```
📹 CAM-01: Telecamera Ingresso
   • Tipo: Dome 4MP
   • Angolo: 90° 
   • Direzione: 180° (Sud)
   • Altezza: 3.5m
   • Cavo: UTP Cat6 - 25m
   • Note: Visione portone principale
```

**Drag & Drop:**
- Trascini icona telecamera sulla mappa
- Click per modificare proprietà
- Visualizza cono visuale (angolo copertura)
- Calcolo automatico lunghezza cavi

### 4️⃣ **COMPONENTI PROGETTO**
Collegamento diretto al magazzino:

| Componente | Qta | Costo | Vendita | Totale |
|------------|-----|-------|---------|--------|
| Telecamera Dome IP 4MP | 4 | €80 | €120 | €480 |
| NVR 8 canali H.265 | 1 | €250 | €380 | €380 |
| Cavo UTP Cat6 | 100m | €0.50 | €0.80 | €80 |
| Switch PoE 8 porte | 1 | €90 | €135 | €135 |
| Hard Disk 2TB | 1 | €60 | €90 | €90 |

**Totale Materiali: €1,165**

### 5️⃣ **CALCOLO MANODOPERA**
```
Ore previste: 12h
Costo orario: €35/h
Manodopera: €420

Costi extra:
• Trasferta: €50
• Noleggio scala: €30
Totale extra: €80

TOTALE PROGETTO: €1,665 (esente IVA)
```

### 6️⃣ **CHECKLIST INSTALLAZIONE**
```
□ Sopralluogo completato
□ Cablaggio UTP installato
□ Telecamere montate e orientate
□ NVR configurato
□ Indirizzi IP assegnati
□ App mobile configurata
□ Test registrazione 24h
□ Formazione cliente
☑ Collaudo e firma
☑ Consegna credenziali
```

### 7️⃣ **PREVENTIVO PDF**
Genera automaticamente:
- Dati cliente e progetto
- **Planimetria con posizioni telecamere**
- Lista componenti con prezzi
- Manodopera e costi extra
- Totale con/senza IVA
- Note tecniche
- Condizioni di pagamento

---

## 🗂️ Struttura Database

### **Tabella `progetti`**
```sql
- numero (PROG-2026-001)
- nome, tipologia, stato
- cliente_id, indirizzo_installazione
- costo_materiali, costo_manodopera, ore_previste
- planimetria_tipo (upload/grid/canvas)
- planimetria_url (se upload)
- planimetria_data (JSON se grid/canvas)
```

### **Tabella `progetti_componenti`**
```sql
- componente_id (link a magazzino)
- quantita, prezzo_acquisto, prezzo_vendita
- posizione_x, posizione_y (opzionale)
```

### **Tabella `progetti_dispositivi`**
```sql
- codice_dispositivo (CAM-01, NVR-01, etc.)
- tipo (telecamera, nvr, sensore, sirena)
- pos_x, pos_y (coordinate mappa)
- angolo_visuale, direzione, altezza
- cavo_tipo, cavo_metri
```

### **Tabella `progetti_checklist`**
```sql
- descrizione task
- completato (bool)
- completato_da, completato_at
```

---

## 🎨 UI/UX Planimetria Editor

### **Toolbar** (sopra la mappa)
```
[📤 Upload] [📊 Grid] [✏️ Canvas] | [📹 Telecamera] [🔌 Sensore] [📡 NVR] | [💾 Salva] [🗑️ Cancella]
```

### **Sidebar Sinistra** (Lista dispositivi)
```
📹 Dispositivi (4)
├─ CAM-01: Ingresso
├─ CAM-02: Giardino
├─ CAM-03: Garage
└─ NVR-01: Locale tecnico

Click per selezionare e modificare
```

### **Canvas Centrale**
- Planimetria disegnata/uploadata
- Icone dispositivi posizionati
- Linee cavi (opzionale)
- Zoom/Pan

### **Panel Destro** (Proprietà dispositivo selezionato)
```
📹 CAM-01: Telecamera Ingresso
─────────────────────────
Tipo: [Dropdown: Dome/Bullet/PTZ]
Modello: [Link magazzino]
Angolo visuale: [90°] ◄────►
Direzione: [180°] 🧭
Altezza: [3.5m]
Cavo: [UTP Cat6] [25m]
Note: [Textarea]

[💾 Salva] [🗑️ Elimina]
```

---

## 📦 Workflow Completo

```
1. CREA PROGETTO
   ├─ Info base (nome, cliente, indirizzo)
   └─ Scelta tipologia (Videosorveglianza)

2. DISEGNA PLANIMETRIA
   ├─ Opzione A: Upload planimetria cliente
   ├─ Opzione B: Disegna su grid
   └─ Opzione C: Disegna a mano libera

3. POSIZIONA DISPOSITIVI
   ├─ Drag & drop telecamere
   ├─ Imposta proprietà (angolo, altezza, cavo)
   └─ Visualizza copertura

4. AGGIUNGI COMPONENTI
   ├─ Selezione da magazzino
   ├─ Quantità automatiche
   └─ Calcolo costi

5. CALCOLA MANODOPERA
   ├─ Ore previste
   ├─ Costo orario
   └─ Extra (trasferte, noleggi)

6. GENERA PREVENTIVO
   ├─ PDF con planimetria
   ├─ Lista componenti
   └─ Totali

7. APPROVAZIONE & INSTALLAZIONE
   ├─ Cliente approva → Stato: "Approvato"
   ├─ Collega a lavorazione calendario
   └─ Checklist installazione

8. COMPLETAMENTO
   ├─ Firma digitale cliente
   ├─ Scarico magazzino automatico
   └─ Archivio progetto
```

---

## 🚀 Prossimi Passi

1. ✅ Database schema creato (`create-progetti-videosorveglianza.sql`)
2. ⏳ Pagina HTML `gestione-progetti.html`
3. ⏳ Editor planimetrie (Grid + Canvas + Upload)
4. ⏳ Generazione PDF preventivo
5. ⏳ Integrazione con calendario lavorazioni
6. ⏳ Template progetti predefiniti (4 cam, 8 cam, 16 cam)

---

## 💡 Template Progetti Predefiniti

### **4 Telecamere Base**
- 4x Telecamera Dome 2MP
- 1x NVR 4 canali
- 1x Switch PoE 4 porte
- 50m cavo UTP Cat6
- 1x HDD 1TB

### **8 Telecamere Standard**
- 8x Telecamera Dome/Bullet 4MP
- 1x NVR 8 canali
- 1x Switch PoE 8 porte
- 100m cavo UTP Cat6
- 1x HDD 2TB

### **16 Telecamere Pro**
- 16x Mix Dome/Bullet/PTZ 4MP
- 1x NVR 16 canali
- 2x Switch PoE 8 porte
- 200m cavo UTP Cat6
- 2x HDD 4TB

---

Pronto per procedere con la creazione della pagina HTML? 🎯
