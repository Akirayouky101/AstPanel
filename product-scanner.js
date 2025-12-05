/**
 * ================================================
 * PRODUCT SCANNER SYSTEM
 * ================================================
 * Sistema intelligente di selezione prodotti con:
 * - Scanner QR/Barcode
 * - Ricerca rapida
 * - Gestione quantità
 */

class ProductScanner {
    constructor() {
        this.selectedProducts = [];
        this.allProducts = [];
        this.scannerActive = false;
    }

    // ===================================
    // CARICAMENTO PRODOTTI
    // ===================================

    async loadProducts() {
        try {
            const { data, error } = await supabaseClient
                .from('warehouse_products')
                .select('*')
                .order('nome');

            if (error) throw error;
            this.allProducts = data || [];
            return this.allProducts;
        } catch (error) {
            console.error('Errore caricamento prodotti:', error);
            return [];
        }
    }

    // ===================================
    // MOSTRA INTERFACCIA SELEZIONE
    // ===================================

    async mostraSelezioneProdotti() {
        await this.loadProducts();

        const modal = document.createElement('div');
        modal.id = 'product-scanner-modal';
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4';
        modal.innerHTML = `
            <div class="bg-white rounded-2xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col">
                <!-- Header -->
                <div class="bg-gradient-to-r from-green-600 to-blue-600 text-white p-6">
                    <div class="flex items-center justify-between">
                        <div>
                            <h2 class="text-2xl font-bold mb-1">📦 Selezione Prodotti</h2>
                            <p class="text-white text-opacity-90">Cerca o scansiona per aggiungere materiali</p>
                        </div>
                        <button onclick="window.productScanner.chiudiModal()" class="text-white hover:text-gray-200">
                            <i data-lucide="x" class="w-6 h-6"></i>
                        </button>
                    </div>
                </div>

                <!-- Toolbar -->
                <div class="p-4 border-b bg-gray-50">
                    <div class="flex gap-2">
                        <!-- Ricerca -->
                        <div class="flex-1 relative">
                            <i data-lucide="search" class="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                            <input type="text" 
                                   id="product-search-input"
                                   onkeyup="window.productScanner.filtraProdotti(this.value)"
                                   class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                                   placeholder="Cerca prodotto per nome, codice, SKU...">
                        </div>
                        
                        <!-- Bottone Scanner -->
                        <button onclick="window.productScanner.attivaScanner()"
                                class="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 flex items-center gap-2 whitespace-nowrap">
                            <i data-lucide="scan-barcode" class="w-5 h-5"></i>
                            Scansiona
                        </button>
                    </div>
                </div>

                <!-- Area Scanner (nascosta inizialmente) -->
                <div id="scanner-area" class="hidden p-4 bg-gray-900">
                    <div class="relative">
                        <video id="scanner-video" class="w-full rounded-lg"></video>
                        <div class="absolute top-4 right-4">
                            <button onclick="window.productScanner.stopScanner()"
                                    class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">
                                Chiudi Scanner
                            </button>
                        </div>
                        <div id="scanner-result" class="mt-2 text-white text-center"></div>
                    </div>
                </div>

                <!-- Lista Prodotti -->
                <div class="flex-1 overflow-y-auto p-4">
                    <div id="products-list-container" class="space-y-2">
                        ${this.renderProductsList()}
                    </div>
                </div>

                <!-- Prodotti Selezionati -->
                <div id="selected-products-area" class="border-t bg-blue-50 p-4 ${this.selectedProducts.length === 0 ? 'hidden' : ''}">
                    <h3 class="font-bold text-gray-800 mb-3 flex items-center gap-2">
                        <i data-lucide="shopping-cart" class="w-5 h-5"></i>
                        Prodotti Selezionati (${this.selectedProducts.length})
                    </h3>
                    <div id="selected-products-list" class="space-y-2 mb-4">
                        ${this.renderSelectedProducts()}
                    </div>
                </div>

                <!-- Footer -->
                <div class="border-t p-4 flex justify-between items-center bg-gray-50">
                    <button onclick="window.productScanner.chiudiModal()" 
                            class="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100">
                        Annulla
                    </button>
                    <button onclick="window.productScanner.confermaSelezione()"
                            class="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center gap-2">
                        <i data-lucide="check" class="w-5 h-5"></i>
                        Conferma Selezione (${this.selectedProducts.length})
                    </button>
                </div>
            </div>
        `;

        document.body.appendChild(modal);
        lucide.createIcons();
    }

    renderProductsList() {
        if (this.allProducts.length === 0) {
            return `
                <div class="text-center py-12">
                    <i data-lucide="package-x" class="w-16 h-16 mx-auto mb-4 text-gray-400"></i>
                    <p class="text-gray-500">Nessun prodotto disponibile in magazzino</p>
                    <p class="text-sm text-gray-400 mt-1">Aggiungi prodotti dalla sezione Magazzino</p>
                </div>
            `;
        }

        return this.allProducts.map(product => {
            const isSelected = this.selectedProducts.some(p => p.prodotto_id === product.id);
            const borderColor = isSelected ? 'border-green-500 bg-green-50' : 'border-gray-200 hover:border-blue-300';
            
            return `
                <div class="border-2 ${borderColor} rounded-lg p-3 transition-all cursor-pointer product-item"
                     data-product-id="${product.id}"
                     onclick="window.productScanner.toggleProduct('${product.id}')">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center gap-3 flex-1">
                            <div class="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                                <i data-lucide="package" class="w-5 h-5 text-blue-600"></i>
                            </div>
                            <div class="flex-1">
                                <div class="font-semibold text-gray-800">${product.nome}</div>
                                <div class="text-xs text-gray-500">
                                    ${product.sku ? `SKU: ${product.sku}` : ''}
                                    ${product.codice ? ` • Codice: ${product.codice}` : ''}
                                </div>
                                <div class="text-xs ${product.quantita > 0 ? 'text-green-600' : 'text-red-600'}">
                                    Disponibili: ${product.quantita || 0} ${product.unita_misura || 'pz'}
                                </div>
                            </div>
                        </div>
                        <div class="flex items-center gap-2">
                            ${isSelected ? `
                                <i data-lucide="check-circle" class="w-6 h-6 text-green-600"></i>
                            ` : `
                                <i data-lucide="plus-circle" class="w-6 h-6 text-gray-400"></i>
                            `}
                        </div>
                    </div>
                </div>
            `;
        }).join('');
    }

    renderSelectedProducts() {
        return this.selectedProducts.map(item => {
            const product = this.allProducts.find(p => p.id === item.prodotto_id);
            if (!product) return '';

            return `
                <div class="bg-white border border-green-300 rounded-lg p-3">
                    <div class="flex items-center justify-between">
                        <div class="flex-1">
                            <div class="font-medium text-gray-800">${product.nome}</div>
                            <div class="text-xs text-gray-500">${product.sku || product.codice || ''}</div>
                        </div>
                        <div class="flex items-center gap-3">
                            <div class="flex items-center gap-2">
                                <label class="text-sm text-gray-600">Quantità:</label>
                                <input type="number" 
                                       value="${item.quantita}"
                                       min="1"
                                       max="${product.quantita}"
                                       class="w-20 px-2 py-1 border border-gray-300 rounded text-center"
                                       onchange="window.productScanner.updateQuantita('${product.id}', this.value)">
                                <span class="text-xs text-gray-500">${product.unita_misura || 'pz'}</span>
                            </div>
                            <button onclick="window.productScanner.rimuoviProdotto('${product.id}')"
                                    class="text-red-600 hover:text-red-800">
                                <i data-lucide="trash-2" class="w-4 h-4"></i>
                            </button>
                        </div>
                    </div>
                </div>
            `;
        }).join('');
    }

    // ===================================
    // GESTIONE SELEZIONE PRODOTTI
    // ===================================

    toggleProduct(productId) {
        const index = this.selectedProducts.findIndex(p => p.prodotto_id === productId);
        
        if (index === -1) {
            // Aggiungi
            this.selectedProducts.push({
                prodotto_id: productId,
                quantita: 1
            });
        } else {
            // Rimuovi
            this.selectedProducts.splice(index, 1);
        }

        this.aggiornaUI();
    }

    rimuoviProdotto(productId) {
        this.selectedProducts = this.selectedProducts.filter(p => p.prodotto_id !== productId);
        this.aggiornaUI();
    }

    updateQuantita(productId, quantita) {
        const product = this.selectedProducts.find(p => p.prodotto_id === productId);
        if (product) {
            product.quantita = parseInt(quantita) || 1;
        }
    }

    aggiornaUI() {
        const listContainer = document.getElementById('products-list-container');
        const selectedArea = document.getElementById('selected-products-area');
        const selectedList = document.getElementById('selected-products-list');

        if (listContainer) {
            listContainer.innerHTML = this.renderProductsList();
            lucide.createIcons();
        }

        if (selectedArea) {
            if (this.selectedProducts.length > 0) {
                selectedArea.classList.remove('hidden');
            } else {
                selectedArea.classList.add('hidden');
            }
        }

        if (selectedList) {
            selectedList.innerHTML = this.renderSelectedProducts();
            lucide.createIcons();
        }

        // Aggiorna contatori
        const buttons = document.querySelectorAll('button');
        buttons.forEach(btn => {
            if (btn.textContent.includes('Conferma Selezione')) {
                btn.innerHTML = `
                    <i data-lucide="check" class="w-5 h-5"></i>
                    Conferma Selezione (${this.selectedProducts.length})
                `;
                lucide.createIcons();
            }
        });
    }

    // ===================================
    // RICERCA PRODOTTI
    // ===================================

    filtraProdotti(query) {
        query = query.toLowerCase().trim();
        
        const filteredProducts = this.allProducts.filter(product => {
            return product.nome.toLowerCase().includes(query) ||
                   (product.sku && product.sku.toLowerCase().includes(query)) ||
                   (product.codice && product.codice.toLowerCase().includes(query)) ||
                   (product.descrizione && product.descrizione.toLowerCase().includes(query));
        });

        const listContainer = document.getElementById('products-list-container');
        if (listContainer) {
            if (filteredProducts.length === 0) {
                listContainer.innerHTML = `
                    <div class="text-center py-12">
                        <i data-lucide="search-x" class="w-16 h-16 mx-auto mb-4 text-gray-400"></i>
                        <p class="text-gray-500">Nessun prodotto trovato per "${query}"</p>
                    </div>
                `;
            } else {
                const originalProducts = this.allProducts;
                this.allProducts = filteredProducts;
                listContainer.innerHTML = this.renderProductsList();
                this.allProducts = originalProducts;
            }
            lucide.createIcons();
        }
    }

    // ===================================
    // SCANNER QR/BARCODE
    // ===================================

    async attivaScanner() {
        const scannerArea = document.getElementById('scanner-area');
        const video = document.getElementById('scanner-video');

        try {
            scannerArea.classList.remove('hidden');
            this.scannerActive = true;

            const stream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: 'environment' }
            });

            video.srcObject = stream;
            video.play();

            // TODO: Integrare libreria scanner (es: jsQR, QuaggaJS)
            // Per ora mostra messaggio placeholder
            document.getElementById('scanner-result').innerHTML = `
                <div class="bg-yellow-600 text-white px-4 py-2 rounded-lg inline-block">
                    🚧 Scanner in sviluppo - Usa la ricerca manuale
                </div>
            `;

        } catch (error) {
            console.error('Errore scanner:', error);
            alert('Impossibile accedere alla fotocamera');
            this.stopScanner();
        }
    }

    stopScanner() {
        const video = document.getElementById('scanner-video');
        const scannerArea = document.getElementById('scanner-area');

        if (video && video.srcObject) {
            video.srcObject.getTracks().forEach(track => track.stop());
        }

        if (scannerArea) {
            scannerArea.classList.add('hidden');
        }

        this.scannerActive = false;
    }

    // ===================================
    // CONFERMA E CHIUSURA
    // ===================================

    confermaSelezione() {
        if (this.selectedProducts.length === 0) {
            alert('Seleziona almeno un prodotto');
            return;
        }

        // Passa i prodotti al wizard
        if (window.taskWizard) {
            window.taskWizard.wizardData.componenti = this.selectedProducts;
            window.taskWizard.renderComponentiSelezionati();
        }

        this.chiudiModal();
    }

    chiudiModal() {
        this.stopScanner();
        const modal = document.getElementById('product-scanner-modal');
        if (modal) {
            modal.remove();
        }
    }

    // Reset per nuova selezione
    reset() {
        this.selectedProducts = [];
        this.stopScanner();
    }
}

// Inizializza globalmente
window.productScanner = new ProductScanner();
