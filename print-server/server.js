const express = require('express');
const cors = require('cors');
const PDFDocument = require('pdfkit');
const bwipjs = require('bwip-js');
const QRCode = require('qrcode');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors()); // Permette richieste da Vercel
app.use(express.json());

// Directory temporanea per PDF
const TEMP_DIR = path.join(__dirname, 'temp');
if (!fs.existsSync(TEMP_DIR)) {
    fs.mkdirSync(TEMP_DIR);
}

// ========================================
// UTILITY: Genera Barcode PNG
// ========================================
async function generateBarcodePNG(barcode) {
    const png = await bwipjs.toBuffer({
        bcid: 'code128',
        text: barcode,
        scale: 3,
        height: 10,
        includetext: false,
        textxalign: 'center'
    });
    return png;
}

// ========================================
// UTILITY: Genera QR Code
// ========================================
async function generateQRDataURL(text) {
    return await QRCode.toDataURL(text, {
        width: 300,
        margin: 0,
        color: {
            dark: '#000000',
            light: '#FFFFFF'
        }
    });
}

// ========================================
// UTILITY: Crea PDF Etichetta Barcode
// ========================================
async function createBarcodePDF(barcode, nomeProdotto, codice) {
    const pdfPath = path.join(TEMP_DIR, `etichetta_${barcode}_${Date.now()}.pdf`);
    
    // Dimensioni: 80mm x 50mm = 226.77pt x 141.73pt
    const doc = new PDFDocument({
        size: [226.77, 141.73],
        margins: { top: 0, bottom: 0, left: 0, right: 0 }
    });
    
    const stream = fs.createWriteStream(pdfPath);
    doc.pipe(stream);
    
    // Nessuna rotazione - layout diretto landscape
    const width = 226.77;  // 80mm
    const height = 141.73; // 50mm
    
    let y = 15;
    
    // Nome prodotto (header)
    doc.fontSize(10)
       .font('Helvetica-Bold')
       .text(nomeProdotto, 10, y, {
           width: width - 20,
           align: 'center',
           lineGap: 2
       });
    
    y += 25;
    
    // Codice prodotto
    if (codice) {
        doc.fontSize(7)
           .font('Helvetica')
           .fillColor('#666666')
           .text(`Cod: ${codice}`, 10, y, {
               width: width - 20,
               align: 'center'
           });
        y += 12;
    }
    
    // Barcode (come immagine)
    const barcodePNG = await generateBarcodePNG(barcode);
    const barcodeTempPath = path.join(TEMP_DIR, `barcode_temp_${Date.now()}.png`);
    fs.writeFileSync(barcodeTempPath, barcodePNG);
    
    doc.image(barcodeTempPath, (width - 180) / 2, y, {
        width: 180,
        height: 60
    });
    
    y += 65;
    
    // Numero barcode sotto
    doc.fontSize(9)
       .font('Courier-Bold')
       .fillColor('#000000')
       .text(barcode, 10, y, {
           width: width - 20,
           align: 'center'
       });
    
    doc.end();
    
    // Cleanup barcode temp
    setTimeout(() => {
        if (fs.existsSync(barcodeTempPath)) {
            fs.unlinkSync(barcodeTempPath);
        }
    }, 2000);
    
    return new Promise((resolve, reject) => {
        stream.on('finish', () => resolve(pdfPath));
        stream.on('error', reject);
    });
}

// ========================================
// UTILITY: Crea PDF Etichetta QR
// ========================================
async function createQRPDF(barcode, nomeProdotto, codice) {
    const pdfPath = path.join(TEMP_DIR, `etichetta_qr_${barcode}_${Date.now()}.pdf`);
    
    const doc = new PDFDocument({
        size: [226.77, 141.73],
        margins: { top: 0, bottom: 0, left: 0, right: 0 }
    });
    
    const stream = fs.createWriteStream(pdfPath);
    doc.pipe(stream);
    
    // Nessuna rotazione - layout diretto landscape
    const width = 226.77;  // 80mm
    const height = 141.73; // 50mm
    
    let y = 10;
    
    // Nome prodotto
    doc.fontSize(9)
       .font('Helvetica-Bold')
       .text(nomeProdotto, 10, y, {
           width: width - 20,
           align: 'center',
           lineGap: 1
       });
    
    y += 20;
    
    // Codice prodotto
    if (codice) {
        doc.fontSize(6)
           .font('Helvetica')
           .fillColor('#666666')
           .text(`Cod: ${codice}`, 10, y, {
               width: width - 20,
               align: 'center'
           });
        y += 10;
    }
    
    // QR Code (più piccolo per entrare nell'etichetta)
    const qrDataURL = await generateQRDataURL(barcode);
    const qrBuffer = Buffer.from(qrDataURL.split(',')[1], 'base64');
    const qrTempPath = path.join(TEMP_DIR, `qr_temp_${Date.now()}.png`);
    fs.writeFileSync(qrTempPath, qrBuffer);
    
    doc.image(qrTempPath, (width - 70) / 2, y, {
        width: 70,
        height: 70
    });
    
    y += 75;
    
    // Numero sotto QR
    doc.fontSize(9)
       .font('Courier-Bold')
       .fillColor('#000000')
       .text(barcode, 10, y, {
           width: width - 20,
           align: 'center'
       });
    
    doc.end();
    
    setTimeout(() => {
        if (fs.existsSync(qrTempPath)) {
            fs.unlinkSync(qrTempPath);
        }
    }, 2000);
    
    return new Promise((resolve, reject) => {
        stream.on('finish', () => resolve(pdfPath));
        stream.on('error', reject);
    });
}

// ========================================
// UTILITY: Invia a stampante via CUPS
// ========================================
function printPDF(pdfPath, printerName = null) {
    try {
        // Se non specificata, usa stampante di default
        const cmd = printerName 
            ? `lp -d "${printerName}" "${pdfPath}"`
            : `lp "${pdfPath}"`;
        
        execSync(cmd);
        
        // Cleanup dopo stampa
        setTimeout(() => {
            if (fs.existsSync(pdfPath)) {
                fs.unlinkSync(pdfPath);
            }
        }, 5000);
        
        return true;
    } catch (error) {
        console.error('Errore stampa CUPS:', error);
        throw error;
    }
}

// ========================================
// API ENDPOINTS
// ========================================

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        message: 'Print server attivo',
        timestamp: new Date().toISOString()
    });
});

// Lista stampanti disponibili
app.get('/api/stampanti', (req, res) => {
    try {
        const output = execSync('lpstat -p -d').toString();
        res.json({ 
            success: true, 
            output: output.split('\n').filter(l => l.trim())
        });
    } catch (error) {
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

// Stampa Barcode
app.post('/api/stampa-barcode', async (req, res) => {
    try {
        const { barcode, nomeProdotto, codice, stampante } = req.body;
        
        if (!barcode || !nomeProdotto) {
            return res.status(400).json({ 
                success: false, 
                error: 'Barcode e nome prodotto obbligatori' 
            });
        }
        
        console.log(`📋 Stampa barcode: ${barcode} - ${nomeProdotto}`);
        
        const pdfPath = await createBarcodePDF(barcode, nomeProdotto, codice);
        printPDF(pdfPath, stampante);
        
        res.json({ 
            success: true, 
            message: 'Etichetta barcode inviata alla stampante',
            barcode,
            nomeProdotto
        });
        
    } catch (error) {
        console.error('Errore stampa barcode:', error);
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

// Stampa QR
app.post('/api/stampa-qr', async (req, res) => {
    try {
        const { barcode, nomeProdotto, codice, stampante } = req.body;
        
        if (!barcode || !nomeProdotto) {
            return res.status(400).json({ 
                success: false, 
                error: 'Barcode e nome prodotto obbligatori' 
            });
        }
        
        console.log(`🔲 Stampa QR: ${barcode} - ${nomeProdotto}`);
        
        const pdfPath = await createQRPDF(barcode, nomeProdotto, codice);
        printPDF(pdfPath, stampante);
        
        res.json({ 
            success: true, 
            message: 'Etichetta QR inviata alla stampante',
            barcode,
            nomeProdotto
        });
        
    } catch (error) {
        console.error('Errore stampa QR:', error);
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

// ========================================
// START SERVER
// ========================================
app.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════════╗
║  🖨️  AST Print Server                            ║
║  📡 Server attivo su http://localhost:${PORT}     ║
║                                                   ║
║  Endpoints disponibili:                          ║
║  • GET  /health                                  ║
║  • GET  /api/stampanti                           ║
║  • POST /api/stampa-barcode                      ║
║  • POST /api/stampa-qr                           ║
╚═══════════════════════════════════════════════════╝
    `);
});
