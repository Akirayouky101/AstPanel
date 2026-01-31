/**
 * ================================================
 * COMPONENT MULTI SELECTOR - Selezione Multipla Componenti
 * ================================================
 * Sistema avanzato per selezionare componenti con:
 * - Checkbox multipli
 * - Scanner barcode/QR
 * - Input rapido quantità
 * - Filtri e ricerca
 * ================================================
 */

class ComponentMultiSelector {
    constructor(options = {}) {
        this.selectedComponents = new Map(); // Map<componentId, {component, quantita}>
        this.allComponents = [];
        this.onComponentsChanged = options.onComponentsChanged || (() => {});
        this.modalId = options.modalId || 'componentMultiSelectorModal';
        this.scannerActive = false;
        this.barcodeBuffer = '';
        this.barcodeTimeout = null;
    }

    // Inizializza il selettore
    async initialize() {
        await this.loadComponents();
        this.setupEventListeners();
    }

    // Carica tutti i componenti
    async loadComponents() {
        try {
            this.allComponents = await window.dataManager.getComponenti();
        } catch (error) {
            console.error('Errore caricamento componenti:', error);
            this.allComponents = [];
        }
    }

    // Apre il modal
    async open(preselectedComponents = []) {
        // Carica componenti preselezionati
        this.selectedComponents.clear();
        preselectedComponents.forEach(item => {
            const component = this.allComponents.find(c => c.id === item.id);
            if (component) {
                this.selectedComponents.set(item.id, {
                    component: component,
                    quantita: item.quantita || 1
                });
            }
        });

        // Mostra modal
        const modal = document.getElementById(this.modalId);
        if (modal) {
            modal.classList.remove('hidden');
            modal.classList.add('flex');
            await this.renderComponents();
            this.updateSelectionSummary();
        }
    }

    // Chiude il modal
    close() {
        const modal = document.getElementById(this.modalId);
        if (modal) {
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        }
        this.stopScanner();
    }

    // Conferma selezione
    confirm() {
        const selected = Array.from(this.selectedComponents.values()).map(item => ({
            id: item.component.id,
            quantita: item.quantita,
            component: item.component
        }));
        
        this.onComponentsChanged(selected);
        this.close();
    }

    // Renderizza lista componenti
    async renderComponents(filter = {}) {
        const container = document.getElementById('multiSelectorComponentsList');
        if (!container) return;

        let components = [...this.allComponents];

        // Applica filtri
        if (filter.category) {
            components = components.filter(c => c.categoria === filter.category);
        }
        if (filter.search) {
            const search = filter.search.toLowerCase();
            components = components.filter(c => 
                c.nome?.toLowerCase().includes(search) ||
                c.codice?.toLowerCase().includes(search) ||
                c.barcode?.toLowerCase().includes(search) ||
                c.descrizione?.toLowerCase().includes(search)
            );
        }

        if (components.length === 0) {
            container.innerHTML = `
                <div class="col-span-full text-center py-12 text-gray-500">
                    <i class="fas fa-search text-5xl mb-3"></i>
                    <p>Nessun componente trovato</p>
                </div>
            `;
            return;
        }

        container.innerHTML = components.map(component => {
            const isSelected = this.selectedComponents.has(component.id);
            const currentQty = isSelected ? this.selectedComponents.get(component.id).quantita : 1;
            const giacenza = component.giacenza || component.quantita_disponibile || 0;

            return `
                <div class="bg-white rounded-xl border-2 ${isSelected ? 'border-purple-500 shadow-lg' : 'border-gray-200'} p-4 transition-all hover:shadow-md">
                    <!-- Header con checkbox -->
                    <div class="flex items-start gap-3 mb-3">
                        <input type="checkbox" 
                               id="check-${component.id}"
                               ${isSelected ? 'checked' : ''}
                               onchange="componentSelector.toggleComponent('${component.id}')"
                               class="w-5 h-5 text-purple-600 rounded focus:ring-2 focus:ring-purple-500 mt-1 cursor-pointer">
                        <div class="flex-1">
                            <h4 class="font-bold text-gray-900 text-lg">${component.nome}</h4>
                            <div class="flex items-center gap-2 text-sm text-gray-500 mt-1">
                                <span><i class="fas fa-tag"></i> ${component.codice || 'N/A'}</span>
                                ${component.barcode ? `<span><i class="fas fa-barcode"></i> ${component.barcode}</span>` : ''}
                            </div>
                        </div>
                        <span class="px-3 py-1 text-xs font-bold rounded-full ${this.getCategoryColor(component.categoria)}">
                            ${component.categoria || 'Altro'}
                        </span>
                    </div>

                    <!-- Descrizione -->
                    ${component.descrizione ? `
                        <p class="text-sm text-gray-600 mb-3">${component.descrizione}</p>
                    ` : ''}

                    <!-- Info giacenza e prezzo -->
                    <div class="flex justify-between items-center text-sm mb-3 pb-3 border-b border-gray-200">
                        <span class="flex items-center gap-2">
                            <i class="fas fa-warehouse text-blue-600"></i>
                            <span class="font-semibold ${giacenza > 0 ? 'text-green-600' : 'text-red-600'}">
                                ${giacenza} ${component.unita_misura || 'pz'}
                            </span>
                        </span>
                        <span class="text-gray-700 font-medium">
                            €${(component.prezzo_unitario || 0).toFixed(2)}/${component.unita_misura || 'pz'}
                        </span>
                    </div>

                    <!-- Input quantità (visibile solo se selezionato) -->
                    ${isSelected ? `
                        <div class="flex items-center gap-2">
                            <label class="text-sm font-semibold text-gray-700">Quantità:</label>
                            <div class="flex items-center gap-2 flex-1">
                                <button onclick="componentSelector.decrementQuantity('${component.id}')"
                                        class="w-8 h-8 bg-gray-200 hover:bg-gray-300 rounded-lg font-bold transition">
                                    <i class="fas fa-minus text-xs"></i>
                                </button>
                                <input type="number" 
                                       id="qty-${component.id}"
                                       value="${currentQty}"
                                       min="1"
                                       onchange="componentSelector.updateQuantity('${component.id}', this.value)"
                                       class="w-20 px-3 py-2 border-2 border-purple-300 rounded-lg text-center font-bold focus:ring-2 focus:ring-purple-500">
                                <button onclick="componentSelector.incrementQuantity('${component.id}')"
                                        class="w-8 h-8 bg-gray-200 hover:bg-gray-300 rounded-lg font-bold transition">
                                    <i class="fas fa-plus text-xs"></i>
                                </button>
                                <span class="text-sm text-gray-600">${component.unita_misura || 'pz'}</span>
                            </div>
                        </div>
                    ` : `
                        <button onclick="componentSelector.toggleComponent('${component.id}')"
                                class="w-full py-2 bg-gradient-to-r from-purple-500 to-blue-500 text-white rounded-lg font-semibold hover:from-purple-600 hover:to-blue-600 transition">
                            <i class="fas fa-plus mr-2"></i>Seleziona
                        </button>
                    `}
                </div>
            `;
        }).join('');
    }

    // Toggle selezione componente
    toggleComponent(componentId) {
        if (this.selectedComponents.has(componentId)) {
            this.selectedComponents.delete(componentId);
        } else {
            const component = this.allComponents.find(c => c.id === componentId);
            if (component) {
                this.selectedComponents.set(componentId, {
                    component: component,
                    quantita: 1
                });
            }
        }
        this.renderComponents(this.getCurrentFilters());
        this.updateSelectionSummary();
    }

    // Aggiorna quantità
    updateQuantity(componentId, value) {
        const qty = parseInt(value) || 1;
        if (this.selectedComponents.has(componentId)) {
            this.selectedComponents.get(componentId).quantita = Math.max(1, qty);
            this.updateSelectionSummary();
        }
    }

    // Incrementa quantità
    incrementQuantity(componentId) {
        if (this.selectedComponents.has(componentId)) {
            const item = this.selectedComponents.get(componentId);
            item.quantita++;
            document.getElementById(`qty-${componentId}`).value = item.quantita;
            this.updateSelectionSummary();
        }
    }

    // Decrementa quantità
    decrementQuantity(componentId) {
        if (this.selectedComponents.has(componentId)) {
            const item = this.selectedComponents.get(componentId);
            if (item.quantita > 1) {
                item.quantita--;
                document.getElementById(`qty-${componentId}`).value = item.quantita;
                this.updateSelectionSummary();
            }
        }
    }

    // Aggiorna summary della selezione
    updateSelectionSummary() {
        const summaryContainer = document.getElementById('multiSelectorSummary');
        if (!summaryContainer) return;

        const count = this.selectedComponents.size;
        const totalQty = Array.from(this.selectedComponents.values())
            .reduce((sum, item) => sum + item.quantita, 0);

        summaryContainer.innerHTML = `
            <div class="flex items-center justify-between">
                <div>
                    <span class="text-lg font-bold text-purple-700">${count} componenti selezionati</span>
                    <span class="text-sm text-gray-600 ml-3">(${totalQty} unità totali)</span>
                </div>
                ${count > 0 ? `
                    <button onclick="componentSelector.clearSelection()"
                            class="px-4 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition font-semibold text-sm">
                        <i class="fas fa-times mr-2"></i>Deseleziona Tutto
                    </button>
                ` : ''}
            </div>
        `;
    }

    // Pulisce selezione
    clearSelection() {
        this.selectedComponents.clear();
        this.renderComponents(this.getCurrentFilters());
        this.updateSelectionSummary();
    }

    // Ottiene filtri correnti
    getCurrentFilters() {
        return {
            category: document.getElementById('multiSelectorCategoryFilter')?.value || '',
            search: document.getElementById('multiSelectorSearch')?.value || ''
        };
    }

    // Applica filtri
    applyFilters() {
        this.renderComponents(this.getCurrentFilters());
    }

    // Scanner barcode
    startScanner() {
        this.scannerActive = true;
        document.getElementById('multiSelectorScannerModal')?.classList.remove('hidden');
        document.addEventListener('keypress', this.handleScannerInput.bind(this));
    }

    stopScanner() {
        this.scannerActive = false;
        document.getElementById('multiSelectorScannerModal')?.classList.add('hidden');
        document.removeEventListener('keypress', this.handleScannerInput.bind(this));
        this.barcodeBuffer = '';
    }

    handleScannerInput(event) {
        if (!this.scannerActive) return;

        clearTimeout(this.barcodeTimeout);

        if (event.key === 'Enter') {
            this.processScannedBarcode(this.barcodeBuffer);
            this.barcodeBuffer = '';
        } else {
            this.barcodeBuffer += event.key;
            this.barcodeTimeout = setTimeout(() => {
                this.barcodeBuffer = '';
            }, 100);
        }
    }

    async processScannedBarcode(barcode) {
        if (!barcode) return;

        const component = this.allComponents.find(c => 
            c.barcode === barcode || c.codice === barcode
        );

        if (component) {
            if (this.selectedComponents.has(component.id)) {
                // Incrementa quantità se già selezionato
                this.incrementQuantity(component.id);
            } else {
                // Aggiungi alla selezione
                this.toggleComponent(component.id);
            }
            
            this.showScanFeedback(`✅ ${component.nome} aggiunto!`, 'success');
        } else {
            this.showScanFeedback(`❌ Componente non trovato: ${barcode}`, 'error');
        }
    }

    showScanFeedback(message, type) {
        const feedbackEl = document.getElementById('multiSelectorScanFeedback');
        if (feedbackEl) {
            feedbackEl.textContent = message;
            feedbackEl.className = `text-center py-2 px-4 rounded-lg font-semibold ${
                type === 'success' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
            }`;
            
            setTimeout(() => {
                feedbackEl.textContent = '';
                feedbackEl.className = '';
            }, 2000);
        }
    }

    // Colori categoria
    getCategoryColor(categoria) {
        const colors = {
            'Elettrico': 'bg-yellow-100 text-yellow-700',
            'Idraulico': 'bg-blue-100 text-blue-700',
            'Meccanico': 'bg-gray-100 text-gray-700',
            'Edile': 'bg-orange-100 text-orange-700',
            'Ferramenta': 'bg-green-100 text-green-700',
            'Altro': 'bg-purple-100 text-purple-700'
        };
        return colors[categoria] || colors['Altro'];
    }

    // Setup event listeners
    setupEventListeners() {
        // Filtro categoria
        const categoryFilter = document.getElementById('multiSelectorCategoryFilter');
        if (categoryFilter) {
            categoryFilter.addEventListener('change', () => this.applyFilters());
        }

        // Ricerca
        const searchInput = document.getElementById('multiSelectorSearch');
        if (searchInput) {
            searchInput.addEventListener('input', () => this.applyFilters());
        }
    }
}

// Istanza globale
let componentSelector = null;

// Inizializza quando il DOM è pronto
if (typeof window !== 'undefined') {
    window.ComponentMultiSelector = ComponentMultiSelector;
}
