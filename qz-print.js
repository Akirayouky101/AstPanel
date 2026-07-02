// ================================================
// QZ Tray Print Utility — Stampa diretta senza dialog
// Richiede: https://cdn.jsdelivr.net/npm/qz-tray@2.2.4/qz-tray.js
// ================================================
(function () {

    // ---- Sicurezza: connessione non firmata ----
    // QZ Tray mostrerà un prompt "Consenti/Rifiuta" la prima volta.
    // Scegli "Consenti sempre" per non rivederlo.
    let _securitySet = false;
    function _initSecurity() {
        if (_securitySet || typeof qz === 'undefined') return;
        qz.security.setCertificatePromise(function (resolve) { resolve(''); });
        qz.security.setSignaturePromise(function (toSign) {
            return function (resolve) { resolve(''); };
        });
        _securitySet = true;
    }

    async function _connect() {
        if (typeof qz === 'undefined') throw new Error('qz-tray.js non caricato');
        _initSecurity();
        if (qz.websocket.isActive()) return;
        await qz.websocket.connect();
    }

    // ---- API pubblica ----
    window.QZPrint = {

        async getPrinters() {
            await _connect();
            const result = await qz.printers.find();
            return Array.isArray(result) ? result : (result ? [result] : []);
        },

        async printLabel(base64png, printerName, widthMm, heightMm) {
            await _connect();
            const config = qz.configs.create(printerName, {
                size: { width: widthMm / 25.4, height: heightMm / 25.4 },
                units: 'in',
                colorType: 'grayscale',
                margins: 0,
                scaleContent: true,
                copies: 1
            });
            await qz.print(config, [{
                type: 'pixel',
                format: 'image',
                flavor: 'base64',
                data: base64png
            }]);
        },

        // Genera Canvas con QR + testo, ritorna base64 PNG (senza header data:image)
        async renderLabelCanvas(qrImgSrc, title, caption, widthMm, heightMm) {
            const DPI  = 203; // 203 DPI — risoluzione standard stampante termica
            const wPx  = Math.round(widthMm  * DPI / 25.4);
            const hPx  = Math.round(heightMm * DPI / 25.4);
            const cv   = document.createElement('canvas');
            cv.width   = wPx;
            cv.height  = hPx;
            const ctx  = cv.getContext('2d');

            // Sfondo bianco
            ctx.fillStyle = '#ffffff';
            ctx.fillRect(0, 0, wPx, hPx);

            const pad    = Math.round(wPx * 0.03);
            const qrSize = Math.round(Math.min(hPx * 0.80, wPx * 0.44));
            const qrY    = Math.round((hPx - qrSize) / 2);

            // Disegna QR
            if (qrImgSrc) {
                await new Promise(res => {
                    const img = new Image();
                    img.crossOrigin = 'anonymous';
                    img.onload = () => { ctx.drawImage(img, pad, qrY, qrSize, qrSize); res(); };
                    img.onerror = res;
                    img.src = qrImgSrc;
                });
            }

            // Area testo
            const textX = qrSize + pad * 2.5;
            const textW = wPx - textX - pad;
            const fSize = Math.round(hPx * 0.10);

            ctx.fillStyle    = '#111111';
            ctx.font         = `bold ${fSize}px Arial, sans-serif`;
            ctx.textBaseline = 'top';

            // Word-wrap titolo
            const words = title.split(' ');
            let line = '', lines = [];
            for (const w of words) {
                const test = line + w + ' ';
                if (ctx.measureText(test).width > textW && line) {
                    lines.push(line.trim()); line = w + ' ';
                } else { line = test; }
            }
            if (line.trim()) lines.push(line.trim());

            const lineH  = fSize * 1.3;
            const totalH = lines.length * lineH;
            const startY = Math.round((hPx - totalH) / 2) - Math.round(fSize * 0.3);
            lines.forEach((l, i) => ctx.fillText(l, textX, startY + i * lineH, textW));

            // Caption
            ctx.fillStyle = '#888888';
            ctx.font      = `${Math.round(fSize * 0.72)}px Arial, sans-serif`;
            ctx.fillText(caption, textX, startY + totalH + Math.round(fSize * 0.4), textW);

            return cv.toDataURL('image/png').replace('data:image/png;base64,', '');
        }
    };

    // ---- Helper DOM condivisi ----

    // Dati dell'etichetta corrente (impostati da showPrintLabel)
    window._currentLabelData = null;

    window.detectQZPrinters = async function () {
        const sel = document.getElementById('qzPrinterSelect');
        if (!sel) return;
        _showQZStatus('Ricerca stampanti in corso...', 'loading');
        try {
            const printers = await window.QZPrint.getPrinters();
            sel.innerHTML = '<option value="">-- Seleziona stampante --</option>';
            printers.forEach(p => {
                const opt = document.createElement('option');
                opt.value = opt.textContent = p;
                // Auto-seleziona Vretti o label printer
                const pl = p.toLowerCase();
                if (pl.includes('vretti') || pl.includes('thermal') || pl.includes('label') || pl.includes('etichett')) {
                    opt.selected = true;
                }
                sel.appendChild(opt);
            });
            _showQZStatus(`${printers.length} stampante${printers.length !== 1 ? 'i' : ''} trovate`, 'ok');
        } catch (e) {
            const msg = e?.message || String(e);
            _showQZStatus('Errore: ' + msg, 'error');
            console.error('[QZPrint] Dettaglio errore:', e);
        }
    };

    window.printWithQZ = async function () {
        const sel    = document.getElementById('qzPrinterSelect');
        const wInput = document.getElementById('labelW');
        const hInput = document.getElementById('labelH');
        const btn    = document.querySelector('#printLabelModal button[onclick="printWithQZ()"]');

        const printer = sel?.value;
        const wMm     = parseFloat(wInput?.value) || 100;
        const hMm     = parseFloat(hInput?.value) || 70;

        if (!printer) { _showQZStatus('Seleziona prima una stampante (premi Trova).', 'error'); return; }
        if (!window._currentLabelData) return;

        const { imgSrc, title, caption } = window._currentLabelData;

        if (btn) { btn.disabled = true; btn.textContent = 'Stampa in corso...'; }
        _showQZStatus('Generazione etichetta...', 'loading');

        try {
            const base64 = await window.QZPrint.renderLabelCanvas(imgSrc, title, caption, wMm, hMm);
            _showQZStatus('Invio alla stampante...', 'loading');
            await window.QZPrint.printLabel(base64, printer, wMm, hMm);
            _showQZStatus('✓ Etichetta inviata con successo!', 'ok');
            setTimeout(() => window.closePrintLabel && window.closePrintLabel(), 1800);
        } catch (e) {
            _showQZStatus('Errore: ' + (e.message || String(e)), 'error');
            console.error('[QZPrint]', e);
        } finally {
            if (btn) { btn.disabled = false; btn.textContent = '🖨️ Stampa Diretto'; }
        }
    };

    window.setLabelSize = function (w, h) {
        const wEl = document.getElementById('labelW');
        const hEl = document.getElementById('labelH');
        if (wEl) wEl.value = w;
        if (hEl) hEl.value = h;
    };

    function _showQZStatus(msg, type) {
        const el = document.getElementById('qzStatus');
        if (!el) return;
        el.classList.remove('hidden');
        const cls = {
            loading: 'text-blue-600 bg-blue-50',
            ok:      'text-green-700 bg-green-50',
            error:   'text-red-600 bg-red-50'
        }[type] || '';
        el.className = `w-full mt-2 text-xs text-center py-1.5 rounded-lg ${cls}`;
        el.textContent = msg;
    }

})();
