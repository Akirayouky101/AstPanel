/**
 * ================================================
 * COMPONENT MULTI SCANNER - Sistema Selezione Multipla Componenti
 * ================================================
 * Sistema IDENTICO al carico multiplo del magazzino
 * - Doppia colonna: Trovati / Non Trovati
 * - Scanner automatico con barcode
 * - Somma automatica prodotti uguali
 * - Statistiche in tempo reale
 * ================================================
 */

class ComponentMultiScanner {
    constructor(options = {}) {
        this.onComponentsSelected = options.onComponentsSelected || (() => {});
        this.modalId = options.modalId || 'componentMultiScannerModal';
        
        // State
        this.scannerActive = false;
        this.componentiTrovati = new Map(); // Map<componentId, {component, quantita}>
        this.componentiNonTrovati = new Map(); // Map<barcode, barcode>
        this.allComponents = [];
        this.scanBuffer = '';
        this.scanTimeout = null;
    }

    // Inizializza
    async initialize() {
        await this.loadComponents();
    }

    // Carica componenti dal database
    async loadComponents() {
        try {
            this.allComponents = await window.dataManager.getComponenti();
            console.log(`✅ Caricati ${this.allComponents.length} componenti`);
        } catch (error) {
            console.error('❌ Errore caricamento componenti:', error);
            this.allComponents = [];
        }
    }

    // Apri modal
    async open(preselectedComponents = []) {
        // Reset
        this.componentiTrovati.clear();
        this.componentiNonTrovati.clear();

        // Carica componenti preselezionati
        if (preselectedComponents && preselectedComponents.length > 0) {
            preselectedComponents.forEach(item => {
                const component = this.allComponents.find(c => c.id === item.id);
                if (component) {
                    this.componentiTrovati.set(item.id, {
                        component: component,
                        quantita: item.quantita || 1
                    });
                }
            });
        }

        // Mostra modal
        const modal = document.getElementById(this.modalId);
        if (modal) {
            modal.classList.remove('hidden');
            modal.classList.add('flex');

            // Focus su input nascosto per catturare scansioni
            setTimeout(() => {
                const focusInput = document.getElementById('componentScannerFocusInput');
                if (focusInput) {
                    focusInput.focus();
                }
            }, 100);

            // 🆕 Event listener per input manuale (INVIO)
            const manualInput = document.getElementById('componentManualSearchInput');
            if (manualInput) {
                manualInput.addEventListener('keypress', (e) => {
                    if (e.key === 'Enter') {
                        e.preventDefault();
                        this.searchManual();
                    }
                });
            }

            this.updateLists();
            this.updateStats();
            this.renderInventory();
            this.startScanner();
        }
    }

    // Chiudi modal
    close() {
        this.stopScanner();
        const modal = document.getElementById(this.modalId);
        if (modal) {
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        }
    }

    // Avvia scanner
    startScanner() {
        if (this.scannerActive) return;

        this.scannerActive = true;
        this.scanBuffer = '';
        document.addEventListener('keypress', this.handleScan.bind(this));
        this.updateScannerStatus('Scanner attivo - Pronto...', 'bg-green-500');
    }

    // Ferma scanner
    stopScanner() {
        this.scannerActive = false;
        document.removeEventListener('keypress', this.handleScan.bind(this));
        this.scanBuffer = '';
        this.updateScannerStatus('Scanner in pausa', 'bg-gray-500');
    }

    // Gestisci input scanner
    handleScan(event) {
        if (!this.scannerActive) return;

        // Previeni comportamento default per evitare problemi
        if (event.key === 'Enter') {
            event.preventDefault();
            const barcode = this.scanBuffer.trim();
            this.scanBuffer = '';
            if (barcode) {
                this.processBarcode(barcode);
            }
        } else {
            // Aggiungi carattere al buffer
            this.scanBuffer += event.key;
            
            // Reset timeout - se passano più di 50ms, considera il barcode completo
            clearTimeout(this.scanTimeout);
            this.scanTimeout = setTimeout(() => {
                const barcode = this.scanBuffer.trim();
                if (barcode && barcode.length >= 3) { // Minimo 3 caratteri per essere un barcode valido
                    this.processBarcode(barcode);
                }
                this.scanBuffer = '';
            }, 50); // Ridotto a 50ms per maggiore reattività
        }
    }

    // Processa barcode scansionato
    async processBarcode(barcode) {
        this.updateScannerStatus(`Scansionato: ${barcode}...`, 'bg-blue-500');

        // Cerca componente
        const component = this.allComponents.find(c => 
            c.barcode === barcode || c.codice === barcode
        );

        if (component) {
            // TROVATO!
            if (this.componentiTrovati.has(component.id)) {
                // Incrementa quantità
                const item = this.componentiTrovati.get(component.id);
                item.quantita++;
            } else {
                // Aggiungi nuovo
                this.componentiTrovati.set(component.id, {
                    component: component,
                    quantita: 1
                });
            }
            this.updateScannerStatus(`✅ ${component.nome} (+1)`, 'bg-green-500');
        } else {
            // NON TROVATO
            if (!this.componentiNonTrovati.has(barcode)) {
                this.componentiNonTrovati.set(barcode, barcode);
            }
            this.updateScannerStatus(`❌ Codice ${barcode} non trovato!`, 'bg-red-500');
        }

        this.updateLists();
        this.updateStats();

        // Torna a "Pronto" dopo 1 secondo
        setTimeout(() => {
            this.updateScannerStatus('Pronto per prossima scansione...', 'bg-green-500');
        }, 1000);
    }

    // Aggiorna status scanner
    updateScannerStatus(message, colorClass) {
        const statusEl = document.getElementById('componentScannerStatus');
        if (statusEl) {
            statusEl.textContent = message;
            statusEl.className = `px-4 py-2 rounded-lg font-mono text-sm ${colorClass} text-white`;
        }
    }

    // 🆕 RICERCA MANUALE
    searchManual() {
        const inputEl = document.getElementById('componentManualSearchInput');
        if (!inputEl) return;

        const searchTerm = inputEl.value.trim();
        if (!searchTerm || searchTerm.length < 3) {
            this.updateScannerStatus('❌ Inserisci almeno 3 caratteri', 'bg-red-500');
            setTimeout(() => {
                this.updateScannerStatus('In attesa...', 'bg-white/30');
            }, 2000);
            return;
        }

        // Processa come se fosse scansionato
        this.processBarcode(searchTerm);

        // Pulisci input
        inputEl.value = '';
        inputEl.focus();
    }

    renderInventory(searchTerm = '') {
        const container = document.getElementById('componentInventoryList');
        if (!container) return;

        const search = searchTerm.trim().toLowerCase();
        const components = this.allComponents.filter(component => !search ||
            component.nome?.toLowerCase().includes(search) ||
            component.codice?.toLowerCase().includes(search) ||
            component.barcode?.toLowerCase().includes(search)
        );

        if (!components.length) {
            container.innerHTML = '<p class="text-center text-gray-500 py-10">Nessun componente trovato</p>';
            return;
        }

        container.innerHTML = components.map(component => {
            const selected = this.componentiTrovati.has(component.id);
            const stock = component.giacenza ?? component.quantita_disponibile ?? 0;
            return `
                <button type="button" onclick="componentScanner.addFromInventory('${component.id}')"
                        class="w-full text-left p-3 border rounded-lg transition ${selected ? 'border-purple-500 bg-purple-50' : 'border-gray-200 bg-white hover:border-purple-300'}">
                    <div class="flex items-center justify-between gap-3">
                        <div class="min-w-0">
                            <p class="font-semibold text-gray-900 truncate">${component.nome}</p>
                            <p class="text-xs text-gray-500">${component.codice || 'Senza codice'}${component.barcode ? ` · ${component.barcode}` : ''}</p>
                        </div>
                        <span class="text-sm font-semibold whitespace-nowrap ${stock > 0 ? 'text-green-700' : 'text-red-600'}">${stock} ${component.unita_misura || 'pz'}</span>
                    </div>
                </button>`;
        }).join('');
    }

    addFromInventory(componentId) {
        const component = this.allComponents.find(item => item.id === componentId);
        if (!component) return;

        if (this.componentiTrovati.has(componentId)) {
            this.componentiTrovati.get(componentId).quantita++;
        } else {
            this.componentiTrovati.set(componentId, { component, quantita: 1 });
        }
        this.updateLists();
        this.updateStats();
    }

    // Aggiorna liste componenti
    updateLists() {
        this.updateListaTrovati();
        this.updateListaNonTrovati();
        const searchInput = document.getElementById('componentInventorySearch');
        this.renderInventory(searchInput?.value || '');
    }

    // Aggiorna lista componenti trovati
    updateListaTrovati() {
        const container = document.getElementById('componentListaTrovati');
        if (!container) return;

        if (this.componentiTrovati.size === 0) {
            container.innerHTML = `
                <div class="text-center text-gray-400 py-12">
                    <i class="fas fa-box-open text-6xl mb-4 opacity-30"></i>
                    <p class="text-lg">Nessun componente scansionato</p>
                    <p class="text-sm mt-2">Inizia a scansionare per vedere i componenti qui</p>
                </div>
            `;
            return;
        }

        const items = Array.from(this.componentiTrovati.values());
        container.innerHTML = items.map(item => `
            <div class="bg-white rounded-lg p-4 border-2 border-purple-300 hover:border-purple-400 transition">
                <div class="flex items-center justify-between">
                    <div class="flex-1">
                        <p class="font-bold text-gray-800">${item.component.nome}</p>
                        <div class="flex items-center space-x-3 text-sm text-gray-600 mt-1">
                            <span><i class="fas fa-barcode mr-1"></i>${item.component.barcode || 'N/A'}</span>
                            <span><i class="fas fa-tag mr-1"></i>${item.component.codice || 'N/A'}</span>
                            <span class="${(item.component.giacenza || 0) > 0 ? 'text-green-600' : 'text-red-600'} font-semibold">
                                Giacenza: ${item.component.giacenza || 0}
                            </span>
                        </div>
                    </div>
                    <div class="flex items-center space-x-3">
                        <div class="flex items-center gap-2">
                            <button onclick="componentScanner.decrementQuantity('${item.component.id}')"
                                    class="w-8 h-8 bg-gray-200 hover:bg-gray-300 rounded-lg font-bold">
                                <i class="fas fa-minus text-xs"></i>
                            </button>
                            <div class="bg-purple-100 border-2 border-purple-400 rounded-lg px-4 py-2">
                                <span class="text-2xl font-bold text-purple-700">${item.quantita}x</span>
                            </div>
                            <button onclick="componentScanner.incrementQuantity('${item.component.id}')"
                                    class="w-8 h-8 bg-gray-200 hover:bg-gray-300 rounded-lg font-bold">
                                <i class="fas fa-plus text-xs"></i>
                            </button>
                        </div>
                        <button onclick="componentScanner.removeFromTrovati('${item.component.id}')" 
                                class="bg-red-500 text-white p-2 rounded-lg hover:bg-red-600 transition">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
            </div>
        `).join('');
    }

    // Aggiorna lista componenti non trovati
    updateListaNonTrovati() {
        const container = document.getElementById('componentListaNonTrovati');
        if (!container) return;

        if (this.componentiNonTrovati.size === 0) {
            container.innerHTML = `
                <div class="text-center text-gray-400 py-12">
                    <i class="fas fa-question-circle text-6xl mb-4 opacity-30"></i>
                    <p class="text-lg">Nessun codice sconosciuto</p>
                    <p class="text-sm mt-2">I codici non trovati appariranno qui</p>
                </div>
            `;
            return;
        }

        const barcodes = Array.from(this.componentiNonTrovati.values());
        container.innerHTML = barcodes.map(barcode => `
            <div class="bg-white rounded-lg p-4 border-2 border-red-300">
                <div class="flex items-center justify-between">
                    <div class="flex-1">
                        <p class="font-mono text-lg font-bold text-gray-800">${barcode}</p>
                        <p class="text-sm text-gray-500 mt-1">Codice non trovato nel database</p>
                    </div>
                    <button onclick="componentScanner.removeFromNonTrovati('${barcode}')" 
                            class="bg-red-500 text-white p-2 rounded-lg hover:bg-red-600 transition">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        `).join('');
    }

    // Aggiorna statistiche
    updateStats() {
        const totaleTrovati = Array.from(this.componentiTrovati.values())
            .reduce((sum, item) => sum + item.quantita, 0);
        const totaleScansioni = totaleTrovati + this.componentiNonTrovati.size;
        const componentiUnici = this.componentiTrovati.size;

        const countTrovati = document.getElementById('componentCountTrovati');
        const countNonTrovati = document.getElementById('componentCountNonTrovati');
        const totalScan = document.getElementById('componentTotalScansioni');
        const unici = document.getElementById('componentUnici');
        
        if (countTrovati) countTrovati.textContent = this.componentiTrovati.size;
        if (countNonTrovati) countNonTrovati.textContent = this.componentiNonTrovati.size;
        if (totalScan) totalScan.textContent = totaleScansioni;
        if (unici) unici.textContent = componentiUnici;

        // Abilita/Disabilita pulsante conferma
        const btnConferma = document.getElementById('btnConfermaComponenti');
        if (btnConferma) {
            btnConferma.disabled = this.componentiTrovati.size === 0;
        }
    }

    // Incrementa quantità
    incrementQuantity(componentId) {
        if (this.componentiTrovati.has(componentId)) {
            this.componentiTrovati.get(componentId).quantita++;
            this.updateLists();
            this.updateStats();
        }
    }

    // Decrementa quantità
    decrementQuantity(componentId) {
        if (this.componentiTrovati.has(componentId)) {
            const item = this.componentiTrovati.get(componentId);
            if (item.quantita > 1) {
                item.quantita--;
                this.updateLists();
                this.updateStats();
            }
        }
    }

    // Rimuovi da trovati
    removeFromTrovati(componentId) {
        this.componentiTrovati.delete(componentId);
        this.updateLists();
        this.updateStats();
    }

    // Rimuovi da non trovati
    removeFromNonTrovati(barcode) {
        this.componentiNonTrovati.delete(barcode);
        this.updateLists();
        this.updateStats();
    }

    // Reset tutto
    reset() {
        this.componentiTrovati.clear();
        this.componentiNonTrovati.clear();
        this.updateLists();
        this.updateStats();
        this.updateScannerStatus('Scanner attivo - Pronto...', 'bg-green-500');
    }

    // Conferma selezione
    confirm() {
        const selected = Array.from(this.componentiTrovati.values()).map(item => ({
            id: item.component.id,
            quantita: item.quantita,
            component: item.component
        }));

        this.onComponentsSelected(selected);
        this.close();
    }
}

// Istanza globale
let componentScanner = null;

// Esporta per uso globale
if (typeof window !== 'undefined') {
    window.ComponentMultiScanner = ComponentMultiScanner;
}
