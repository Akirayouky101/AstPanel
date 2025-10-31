// Client Details Modal Component
// Reusable modal for displaying client information with map

window.ClientModal = {
    // Open modal with client details
    show: async function(clientId) {
        try {
            const clients = await window.dataManager.getClienti();
            const clientData = clients.find(c => c.id === clientId);
            
            if (!clientData) {
                console.error('Client not found:', clientId);
                return;
            }

            // Normalize field names (support both snake_case and camelCase)
            const client = {
                ...clientData,
                ragioneSociale: clientData.ragione_sociale || clientData.ragioneSociale || 'N/A',
                nome: clientData.nome || '',
                cognome: clientData.cognome || '',
                telefono: clientData.telefono || 'N/A',
                email: clientData.email || 'N/A',
                pec: clientData.pec || '',
                partitaIva: clientData.partita_iva || clientData.partitaIva || '',
                codiceFiscale: clientData.codice_fiscale || clientData.codiceFiscale || '',
                indirizzo: clientData.indirizzo || 'N/A',
                citta: clientData.citta || '',
                cap: clientData.cap || '',
                provincia: clientData.provincia || '',
                settore: clientData.settore || 'N/A',
                tipoCliente: clientData.tipo_cliente || clientData.tipoCliente || 'privato',
                // Build ubicazione from lat/lng fields or use default
                ubicazione: (clientData.latitudine && clientData.longitudine) ? {
                    lat: parseFloat(clientData.latitudine),
                    lng: parseFloat(clientData.longitudine),
                    address: `${clientData.indirizzo || ''}, ${clientData.citta || ''}, ${clientData.provincia || ''}`.trim()
                } : (clientData.ubicazione || { lat: 41.9028, lng: 12.4964, address: 'Roma, Italia' }),
                note: clientData.note || ''
            };

        // Create modal HTML
        const modalHTML = `
            <div id="clientModal" class="fixed inset-0 bg-black bg-opacity-50 z-[9999] flex items-center justify-center p-4 fade-in overflow-y-auto" onclick="if(event.target.id === 'clientModal') window.ClientModal.close()">
                <div class="bg-white rounded-xl shadow-2xl w-full max-w-md my-4 max-h-[80vh] flex flex-col" onclick="event.stopPropagation()">
                    <!-- Header -->
                    <div class="bg-gradient-to-r from-blue-600 to-purple-600 text-white p-3 sm:p-4 rounded-t-xl">
                        <div class="flex justify-between items-start gap-3">
                            <div class="flex-1 min-w-0">
                                <h2 class="text-lg sm:text-xl font-bold mb-1 truncate">${client.ragioneSociale}</h2>
                                <p class="text-blue-100 text-xs sm:text-sm truncate">
                                    <i class="fas fa-user mr-2"></i>
                                    ${client.nome} ${client.cognome}
                                </p>
                            </div>
                            <button onclick="window.ClientModal.close()" class="text-white hover:text-gray-200 transition-colors flex-shrink-0" title="Chiudi">
                                <i class="fas fa-times text-lg sm:text-xl"></i>
                            </button>
                        </div>
                    </div>

                    <!-- Content (Scrollable) -->
                    <div class="flex-1 overflow-y-auto">
                        <div class="p-3 space-y-2">
                        <!-- Info Grid -->
                        <div class="space-y-3">
                            <!-- Contact Information -->
                            <div class="bg-gray-50 rounded-lg p-2 sm:p-3">
                                <h3 class="text-sm sm:text-base font-semibold text-gray-800 mb-2 flex items-center">
                                    <i class="fas fa-address-book text-blue-600 mr-2 text-sm"></i>
                                    Contatti
                                </h3>
                                <div class="space-y-2">
                                    <div class="flex items-start">
                                        <i class="fas fa-phone text-gray-400 mt-1 mr-3 w-4 flex-shrink-0"></i>
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs text-gray-500">Telefono</p>
                                            <a href="tel:${client.telefono}" class="text-sm text-gray-900 hover:text-blue-600 font-medium break-all">
                                                ${client.telefono}
                                            </a>
                                        </div>
                                    </div>
                                    <div class="flex items-start">
                                        <i class="fas fa-envelope text-gray-400 mt-1 mr-3 w-4 flex-shrink-0"></i>
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs text-gray-500">Email</p>
                                            <a href="mailto:${client.email}" class="text-sm text-gray-900 hover:text-blue-600 font-medium break-all">
                                                ${client.email}
                                            </a>
                                        </div>
                                    </div>
                                    ${client.pec ? `
                                    <div class="flex items-start">
                                        <i class="fas fa-certificate text-gray-400 mt-1 mr-3 w-4 flex-shrink-0"></i>
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs text-gray-500">PEC</p>
                                            <a href="mailto:${client.pec}" class="text-sm text-gray-900 hover:text-blue-600 font-medium break-all">
                                                ${client.pec}
                                            </a>
                                        </div>
                                    </div>
                                    ` : ''}
                                </div>
                            </div>

                            <!-- Business Information -->
                            <div class="bg-gray-50 rounded-lg p-2 sm:p-3">
                                <h3 class="text-sm sm:text-base font-semibold text-gray-800 mb-2 flex items-center">
                                    <i class="fas fa-building text-blue-600 mr-2 text-sm"></i>
                                    Info Aziendali
                                </h3>
                                <div class="space-y-2">
                                    ${client.partitaIva ? `
                                    <div class="flex items-start">
                                        <i class="fas fa-file-invoice text-gray-400 mt-1 mr-3 w-4 flex-shrink-0"></i>
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs text-gray-500">P. IVA</p>
                                            <p class="text-sm text-gray-900 font-medium">${client.partitaIva}</p>
                                        </div>
                                    </div>
                                    ` : ''}
                                    ${client.settore ? `
                                    <div class="flex items-start">
                                        <i class="fas fa-industry text-gray-400 mt-1 mr-3 w-4 flex-shrink-0"></i>
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs text-gray-500">Settore</p>
                                            <p class="text-sm text-gray-900 font-medium">${client.settore}</p>
                                        </div>
                                    </div>
                                    ` : ''}
                                    <div class="flex items-start">
                                        <i class="fas fa-calendar text-gray-400 mt-1 mr-3 w-4 flex-shrink-0"></i>
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs text-gray-500">Cliente dal</p>
                                            <p class="text-sm text-gray-900 font-medium">${new Date(client.dataInizioRapporto).toLocaleDateString('it-IT')}</p>
                                        </div>
                                    </div>
                                    <div class="flex items-start">
                                        <i class="fas fa-tag text-gray-400 mt-1 mr-3 w-4 flex-shrink-0"></i>
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs text-gray-500">Tipo</p>
                                            <span class="inline-block px-2 py-1 text-xs rounded ${client.tipoCliente === 'azienda' ? 'bg-blue-100 text-blue-700' : 'bg-green-100 text-green-700'}">
                                                ${client.tipoCliente.charAt(0).toUpperCase() + client.tipoCliente.slice(1)}
                                            </span>
                                        </div>
                                    </div>
                            </div>
                        </div>

                        <!-- Location -->
                        <div class="bg-gray-50 rounded-lg p-2 sm:p-3">
                            <h3 class="text-sm sm:text-base font-semibold text-gray-800 mb-2 flex items-center">
                                <i class="fas fa-map-marker-alt text-blue-600 mr-2 text-sm"></i>
                                Ubicazione
                            </h3>
                            <div class="flex items-start mb-2">
                                <i class="fas fa-location-dot text-gray-400 mt-1 mr-3 w-4 flex-shrink-0"></i>
                                <div class="min-w-0 flex-1">
                                    <p class="text-sm text-gray-900 font-medium break-words">${client.indirizzo}</p>
                                    <a href="https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(client.indirizzo)}" 
                                       target="_blank"
                                       class="text-blue-600 hover:text-blue-700 text-xs mt-1 inline-flex items-center">
                                        Apri in Google Maps
                                        <i class="fas fa-external-link-alt ml-1 text-xs"></i>
                                    </a>
                                </div>
                            </div>
                            
                            <!-- Map Container -->
                            <div id="clientMap" class="w-full h-40 sm:h-48 rounded-lg border border-gray-200 overflow-hidden">
                                <!-- Map will be loaded here -->
                            </div>
                        </div>

                        <!-- Notes -->
                        ${client.note ? `
                        <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-2 sm:p-3">
                            <h3 class="text-sm sm:text-base font-semibold text-gray-800 mb-2 flex items-center">
                                <i class="fas fa-sticky-note text-yellow-600 mr-2 text-sm"></i>
                                Note
                            </h3>
                            <p class="text-sm text-gray-700 break-words">${client.note}</p>
                        </div>
                        ` : ''}
                        </div>
                    </div>

                    <!-- Footer Actions -->
                    <div class="bg-gray-50 px-3 py-2 sm:py-3 rounded-b-xl border-t border-gray-200">
                        <div class="flex flex-col sm:flex-row gap-2 justify-between items-stretch sm:items-center">
                            <div class="flex flex-wrap gap-2">
                                <a href="tel:${client.telefono}" class="flex-1 sm:flex-initial px-3 sm:px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-center text-sm">
                                    <i class="fas fa-phone mr-1 sm:mr-2"></i>Chiama
                                </a>
                                <a href="mailto:${client.email}" class="flex-1 sm:flex-initial px-3 sm:px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors text-center text-sm">
                                    <i class="fas fa-envelope mr-1 sm:mr-2"></i>Email
                                </a>
                                <a href="https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(client.indirizzo)}" 
                                   target="_blank"
                                   class="flex-1 sm:flex-initial px-3 sm:px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 transition-colors text-center text-sm">
                                    <i class="fas fa-route mr-1 sm:mr-2"></i>Indicazioni
                                </a>
                            </div>
                            <button onclick="window.ClientModal.close()" class="w-full sm:w-auto px-4 sm:px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors text-sm font-medium">
                                Chiudi
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Add modal to body
        const modalContainer = document.createElement('div');
        modalContainer.innerHTML = modalHTML;
        document.body.appendChild(modalContainer.firstElementChild);

        // Load map
        this.loadMap(client.ubicazione);
        } catch (error) {
            console.error('Errore apertura modal cliente:', error);
        }
    },

    // Load map with marker
    loadMap: function(ubicazione) {
        const mapContainer = document.getElementById('clientMap');
        
        if (!mapContainer) return;

        // Using OpenStreetMap with Leaflet (lightweight alternative to Google Maps)
        // First check if Leaflet is available, otherwise use static map
        if (typeof L !== 'undefined') {
            // Leaflet is available
            const map = L.map('clientMap').setView([ubicazione.lat, ubicazione.lng], 15);
            
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap contributors'
            }).addTo(map);
            
            L.marker([ubicazione.lat, ubicazione.lng]).addTo(map)
                .bindPopup(ubicazione.address)
                .openPopup();
        } else {
            // Fallback to static Google Maps image
            mapContainer.innerHTML = `
                <img src="https://maps.googleapis.com/maps/api/staticmap?center=${ubicazione.lat},${ubicazione.lng}&zoom=15&size=600x400&markers=color:red%7C${ubicazione.lat},${ubicazione.lng}&key=YOUR_API_KEY" 
                     alt="Map" 
                     class="w-full h-full object-cover"
                     onerror="this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22600%22 height=%22400%22%3E%3Crect width=%22600%22 height=%22400%22 fill=%22%23e5e7eb%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 dominant-baseline=%22middle%22 text-anchor=%22middle%22 font-family=%22Arial%22 font-size=%2218%22 fill=%22%236b7280%22%3EMappa non disponibile%3C/text%3E%3C/svg%3E'">
                <div class="absolute inset-0 flex items-center justify-center">
                    <a href="https://www.google.com/maps/search/?api=1&query=${ubicazione.lat},${ubicazione.lng}" 
                       target="_blank"
                       class="bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600">
                        Visualizza su Google Maps
                    </a>
                </div>
            `;
        }
    },

    // Close modal
    close: function() {
        const modal = document.getElementById('clientModal');
        if (modal) {
            modal.classList.add('fade-out');
            setTimeout(() => {
                modal.remove();
            }, 300);
        }
    }
};

// Add CSS for animations
if (!document.getElementById('client-modal-styles')) {
    const style = document.createElement('style');
    style.id = 'client-modal-styles';
    style.textContent = `
        .fade-in {
            animation: fadeIn 0.3s ease-in;
        }
        .fade-out {
            animation: fadeOut 0.3s ease-out;
        }
        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: scale(0.95);
            }
            to {
                opacity: 1;
                transform: scale(1);
            }
        }
        @keyframes fadeOut {
            from {
                opacity: 1;
                transform: scale(1);
            }
            to {
                opacity: 0;
                transform: scale(0.95);
            }
        }
        /* Ensure modal content is scrollable and visible */
        #clientModal {
            overflow-y: auto !important;
            overflow-x: hidden !important;
        }
        #clientModal > div {
            max-width: 100% !important;
            overflow-x: hidden !important;
        }
        #clientModal * {
            box-sizing: border-box !important;
        }
    `;
    document.head.appendChild(style);
}

console.log('Client Modal Component loaded');