# 🖨️ AST Print Server

Server Node.js locale per stampa automatica etichette tramite CUPS.

## 🚀 Setup

```bash
# Installa dipendenze
npm install

# Avvia server
npm start

# Dev mode (auto-restart)
npm run dev
```

## 📡 API Endpoints

### Health Check
```bash
GET http://localhost:3000/health
```

### Lista Stampanti
```bash
GET http://localhost:3000/api/stampanti
```

### Stampa Barcode
```bash
POST http://localhost:3000/api/stampa-barcode
Content-Type: application/json

{
  "barcode": "9788827604212",
  "nomeProdotto": "Alexander McQueen - Giacca Donna",
  "codice": "AMQ-001",
  "stampante": "Nome_Stampante"  // Opzionale
}
```

### Stampa QR
```bash
POST http://localhost:3000/api/stampa-qr
Content-Type: application/json

{
  "barcode": "9788827604212",
  "nomeProdotto": "Alexander McQueen - Giacca Donna",
  "codice": "AMQ-001",
  "stampante": "Nome_Stampante"  // Opzionale
}
```

## 🔧 Configurazione Stampante

Il server usa CUPS. Per vedere le stampanti disponibili:

```bash
lpstat -p -d
```

Se non specifichi `stampante` nella richiesta, usa la stampante di default.

## 🌐 Integrazione Frontend

Modifica `magazzino-prodotti.html` per chiamare l'API:

```javascript
async function stampaBarcode() {
    const response = await fetch('http://localhost:3000/api/stampa-barcode', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            barcode: currentBarcodeData.barcode,
            nomeProdotto: currentBarcodeData.nomeProdotto,
            codice: currentBarcodeData.codice
        })
    });
    
    const result = await response.json();
    if (result.success) {
        alert('✅ Etichetta inviata alla stampante!');
    }
}
```

## 📋 Note

- **Porta:** 3000 (modificabile in `server.js`)
- **CORS:** Abilitato per accettare richieste da Vercel
- **PDF temporanei:** Salvati in `/temp` e cancellati dopo stampa
- **Rotazione:** Etichette ruotate 90° per stampanti landscape

## 🔐 Sicurezza

⚠️ **Il server accetta richieste da qualsiasi origine (CORS aperto)**.

Per produzione, limita CORS solo al tuo dominio:

```javascript
app.use(cors({
    origin: 'https://tuo-dominio.vercel.app'
}));
```
