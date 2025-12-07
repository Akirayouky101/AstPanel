/**
 * PDF Email Service - Sistema generazione PDF e invio email per commercialista
 * Genera report mensili con costo_orario e invia automaticamente via email
 */

class PDFEmailService {
    constructor() {
        this.supabase = window.supabaseClient;
        this.currentUser = null;
    }

    /**
     * Genera PDF per report mensile dipendenti
     * @param {number} anno - Anno di riferimento
     * @param {number} mese - Mese di riferimento (1-12)
     * @returns {Blob} PDF generato
     */
    async generateMonthlyPDF(anno, mese) {
        try {
            console.log(`📄 Generazione PDF per ${mese}/${anno}...`);

            // Recupera dati report dal database
            const { data: reportData, error } = await this.supabase
                .rpc('get_email_report_data', { 
                    p_anno: anno, 
                    p_mese: mese 
                });

            if (error) {
                console.error('❌ Errore recupero dati report:', error);
                throw new Error('Impossibile recuperare dati per il report');
            }

            if (!reportData || reportData.length === 0) {
                throw new Error('Nessun dato disponibile per il periodo selezionato');
            }

            // Genera HTML per PDF
            const htmlContent = this.generateHTMLReport(reportData, anno, mese);

            // Converti HTML in PDF usando libreria jsPDF
            const pdf = await this.convertHTMLToPDF(htmlContent, anno, mese);

            console.log('✅ PDF generato con successo');
            return pdf;

        } catch (err) {
            console.error('❌ Errore generazione PDF:', err);
            throw err;
        }
    }

    /**
     * Genera HTML formattato per il report
     */
    generateHTMLReport(data, anno, mese) {
        const nomiMesi = [
            'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
            'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
        ];

        const meseNome = nomiMesi[mese - 1];
        const dataGenerazione = new Date().toLocaleDateString('it-IT', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });

        // Calcola totali
        const totaleDipendenti = data.length;
        const totaleOre = data.reduce((sum, d) => sum + parseFloat(d.totale_ore || 0), 0);
        const totaleCosto = data.reduce((sum, d) => sum + parseFloat(d.totale_costo || 0), 0);

        let html = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        @page { 
            size: A4; 
            margin: 20mm; 
        }
        body {
            font-family: 'Arial', sans-serif;
            color: #333;
            line-height: 1.6;
        }
        .header {
            text-align: center;
            border-bottom: 3px solid #2563eb;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #2563eb;
            margin: 0;
            font-size: 28px;
        }
        .header .subtitle {
            color: #666;
            font-size: 16px;
            margin-top: 5px;
        }
        .info-box {
            background: #f3f4f6;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .info-box .label {
            font-weight: bold;
            color: #4b5563;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th {
            background: #2563eb;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: bold;
        }
        td {
            padding: 10px 12px;
            border-bottom: 1px solid #e5e7eb;
        }
        tr:nth-child(even) {
            background: #f9fafb;
        }
        .totali-row {
            background: #dbeafe !important;
            font-weight: bold;
            border-top: 2px solid #2563eb;
        }
        .totali-row td {
            padding: 15px 12px;
            font-size: 16px;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            color: #6b7280;
            font-size: 12px;
            border-top: 1px solid #e5e7eb;
            padding-top: 20px;
        }
        .cost-highlight {
            color: #dc2626;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Report Mensile Presenze</h1>
        <div class="subtitle">AST Panel - Gestione Dipendenti</div>
    </div>

    <div class="info-box">
        <div><span class="label">Periodo di riferimento:</span> ${meseNome} ${anno}</div>
        <div><span class="label">Data generazione:</span> ${dataGenerazione}</div>
        <div><span class="label">Numero dipendenti:</span> ${totaleDipendenti}</div>
    </div>

    <table>
        <thead>
            <tr>
                <th>Dipendente</th>
                <th>Ruolo</th>
                <th style="text-align: center;">Giorni</th>
                <th style="text-align: right;">Ore Totali</th>
                <th style="text-align: right;">Costo/Ora (€)</th>
                <th style="text-align: right;">Totale (€)</th>
            </tr>
        </thead>
        <tbody>
`;

        // Righe dipendenti
        data.forEach(dipendente => {
            const ore = parseFloat(dipendente.totale_ore || 0).toFixed(2);
            const costoOrario = parseFloat(dipendente.costo_orario || 0).toFixed(2);
            const totale = parseFloat(dipendente.totale_costo || 0).toFixed(2);

            html += `
            <tr>
                <td><strong>${dipendente.dipendente_cognome} ${dipendente.dipendente_nome}</strong></td>
                <td>${dipendente.dipendente_ruolo}</td>
                <td style="text-align: center;">${dipendente.giorni_lavorati}</td>
                <td style="text-align: right;">${ore} h</td>
                <td style="text-align: right;">${costoOrario} €</td>
                <td style="text-align: right;" class="cost-highlight">${totale} €</td>
            </tr>
`;
        });

        // Riga totali
        html += `
            <tr class="totali-row">
                <td colspan="3"><strong>TOTALE GENERALE</strong></td>
                <td style="text-align: right;"><strong>${totaleOre.toFixed(2)} h</strong></td>
                <td style="text-align: right;">-</td>
                <td style="text-align: right;" class="cost-highlight"><strong>${totaleCosto.toFixed(2)} €</strong></td>
            </tr>
        </tbody>
    </table>

    <div class="footer">
        <p>Report generato automaticamente da AST Panel</p>
        <p>Questo documento è confidenziale e destinato esclusivamente all'uso del commercialista</p>
    </div>
</body>
</html>
        `;

        return html;
    }

    /**
     * Converte HTML in PDF usando html2pdf.js
     */
    async convertHTMLToPDF(htmlContent, anno, mese) {
        return new Promise((resolve, reject) => {
            // Verifica che html2pdf sia caricato
            if (typeof html2pdf === 'undefined') {
                reject(new Error('Libreria html2pdf non caricata. Aggiungi <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>'));
                return;
            }

            const filename = `report_presenze_${anno}-${String(mese).padStart(2, '0')}.pdf`;

            const opt = {
                margin: 10,
                filename: filename,
                image: { type: 'jpeg', quality: 0.98 },
                html2canvas: { scale: 2, useCORS: true },
                jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
            };

            // Crea elemento temporaneo
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = htmlContent;
            tempDiv.style.position = 'absolute';
            tempDiv.style.left = '-9999px';
            document.body.appendChild(tempDiv);

            html2pdf()
                .set(opt)
                .from(tempDiv)
                .outputPdf('blob')
                .then(pdfBlob => {
                    document.body.removeChild(tempDiv);
                    pdfBlob.filename = filename;
                    resolve(pdfBlob);
                })
                .catch(err => {
                    document.body.removeChild(tempDiv);
                    reject(err);
                });
        });
    }

    /**
     * Carica lista destinatari attivi
     */
    async getActiveRecipients() {
        const { data, error } = await this.supabase
            .from('email_destinatari')
            .select('*')
            .eq('attivo', true)
            .order('nome');

        if (error) {
            console.error('❌ Errore caricamento destinatari:', error);
            throw error;
        }

        return data || [];
    }

    /**
     * Simula invio email (in produzione usare servizio backend)
     * Nota: L'invio email reale richiede un backend server-side (Supabase Edge Functions, AWS SES, SendGrid, ecc.)
     */
    async sendEmail(destinatario, pdfBlob, anno, mese) {
        console.log(`📧 Simulazione invio email a ${destinatario.email}...`);

        const nomiMesi = [
            'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
            'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
        ];

        const oggetto = `Report Presenze ${nomiMesi[mese - 1]} ${anno} - AST Panel`;
        const periodoRiferimento = `${anno}-${String(mese).padStart(2, '0')}`;
        const annoMese = `${anno}-${String(mese).padStart(2, '0')}-01`;

        // In produzione reale:
        // 1. Upload PDF su storage (Supabase Storage o S3)
        // 2. Chiamata a Edge Function per invio email via SendGrid/AWS SES
        // 3. Salvataggio log nel database

        // Per ora salviamo solo il log
        const { data: reportData } = await this.supabase.rpc('get_email_report_data', { 
            p_anno: anno, 
            p_mese: mese 
        });

        const totaleDipendenti = reportData ? reportData.length : 0;
        const totaleOre = reportData ? reportData.reduce((sum, d) => sum + parseFloat(d.totale_ore || 0), 0) : 0;
        const totaleCosto = reportData ? reportData.reduce((sum, d) => sum + parseFloat(d.totale_costo || 0), 0) : 0;

        const logEntry = {
            destinatario_id: destinatario.id,
            email_destinatario: destinatario.email,
            oggetto: oggetto,
            periodo_riferimento: periodoRiferimento,
            anno_mese: annoMese,
            pdf_filename: pdfBlob.filename || `report_${periodoRiferimento}.pdf`,
            pdf_size_kb: Math.round(pdfBlob.size / 1024),
            totale_dipendenti: totaleDipendenti,
            totale_ore_lavorate: totaleOre,
            totale_costo: totaleCosto,
            stato: 'sent', // In produzione: 'pending' → 'sent' dopo invio reale
            inviato_da: this.currentUser?.id,
            inviato_at: new Date().toISOString()
        };

        const { error: logError } = await this.supabase
            .from('email_log')
            .insert(logEntry);

        if (logError) {
            console.error('❌ Errore salvataggio log email:', logError);
            throw logError;
        }

        console.log(`✅ Email simulata inviata a ${destinatario.email}`);
        
        // Scarica PDF localmente (simulazione allegato email)
        this.downloadPDF(pdfBlob);

        return true;
    }

    /**
     * Download PDF localmente
     */
    downloadPDF(pdfBlob) {
        const url = URL.createObjectURL(pdfBlob);
        const a = document.createElement('a');
        a.href = url;
        a.download = pdfBlob.filename || 'report.pdf';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    /**
     * Processo completo: genera PDF e invia a tutti i destinatari
     */
    async sendMonthlyReport(anno, mese, currentUser) {
        try {
            this.currentUser = currentUser;

            console.log(`🚀 Avvio invio report mensile ${mese}/${anno}...`);

            // 1. Genera PDF
            const pdfBlob = await this.generateMonthlyPDF(anno, mese);

            // 2. Carica destinatari
            const recipients = await this.getActiveRecipients();

            if (recipients.length === 0) {
                throw new Error('Nessun destinatario attivo configurato');
            }

            console.log(`📧 Destinatari trovati: ${recipients.length}`);

            // 3. Invia a ciascun destinatario
            const results = [];
            for (const recipient of recipients) {
                try {
                    await this.sendEmail(recipient, pdfBlob, anno, mese);
                    results.push({ email: recipient.email, success: true });
                } catch (err) {
                    console.error(`❌ Errore invio a ${recipient.email}:`, err);
                    results.push({ email: recipient.email, success: false, error: err.message });
                }
            }

            const successCount = results.filter(r => r.success).length;
            console.log(`✅ Invio completato: ${successCount}/${recipients.length} email inviate`);

            return {
                success: true,
                total: recipients.length,
                sent: successCount,
                failed: recipients.length - successCount,
                results: results
            };

        } catch (err) {
            console.error('❌ Errore processo invio report:', err);
            throw err;
        }
    }
}

// Inizializzazione globale
if (typeof window !== 'undefined') {
    window.pdfEmailService = new PDFEmailService();
    console.log('✅ PDF Email Service inizializzato');
}
