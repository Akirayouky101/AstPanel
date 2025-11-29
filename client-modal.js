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
            <div id="clientModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-[9999] fade-in p-4" onclick="if(event.target === this) window.ClientModal.close()">
                <div class="bg-white rounded-xl shadow-2xl w-full max-w-5xl h-[85vh] flex flex-col">
                    <!-- Header -->
                    <div class="bg-gradient-to-r from-blue-500 to-blue-600 text-white px-6 py-4 flex justify-between items-center flex-shrink-0 rounded-t-xl">
                        <div class="flex items-center gap-3">
                            <i class="fas fa-building text-xl"></i>
                            <h3 class="font-bold text-xl">${client.ragioneSociale}</h3>
                        </div>
                        <button onclick="window.ClientModal.close()" class="text-white/90 hover:text-white transition-colors text-xl">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>

                    <!-- Content: Split Layout -->
                    <div class="flex-1 flex overflow-hidden">
                        <!-- LEFT: Information Panel -->
                        <div class="w-1/2 overflow-y-auto p-6 space-y-4 border-r border-gray-200">
                            <!-- Contact Information -->
                            <div class="bg-gray-50 rounded-lg p-4">
                                <h3 class="text-sm font-semibold text-gray-800 mb-3 flex items-center">
                                    <i class="fas fa-address-book text-blue-600 mr-2"></i>
                                    Contatti
                                </h3>
                                <div class="space-y-3">
                                    <div class="flex items-start">
                                        <i class="fas fa-phone text-gray-400 mt-1 mr-3 w-5"></i>
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs text-gray-500">Telefono</p>
                                            <a href="tel:${client.telefono}" class="text-sm text-gray-900 hover:text-blue-600 font-medium">
                                                ${client.telefono}
                                            </a>
                                        </div>
                                    </div>
                                    <div class="flex items-start">
                                        <i class="fas fa-envelope text-gray-400 mt-1 mr-3 w-5"></i>
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs text-gray-500">Email</p>
                                            <a href="mailto:${client.email}" class="text-sm text-gray-900 hover:text-blue-600 font-medium break-all">
                                                ${client.email}
                                            </a>
                                        </div>
                                    </div>
                                    ${client.pec ? `
                                    <div class="flex items-start">
                                        <i class="fas fa-certificate text-gray-400 mt-1 mr-3 w-5"></i>
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
                            <div class="bg-gray-50 rounded-lg p-4">
                                <h3 class="text-sm font-semibold text-gray-800 mb-3 flex items-center">
                                    <i class="fas fa-building text-blue-600 mr-2"></i>
                                    Informazioni Aziendali
                                </h3>
                                <div class="grid grid-cols-2 gap-3">
                                    <div>
                                        <p class="text-xs text-gray-500 mb-1">Partita IVA</p>
                                        <p class="text-sm text-gray-900 font-medium">${client.partitaIva || 'N/A'}</p>
                                    </div>
                                    <div>
                                        <p class="text-xs text-gray-500 mb-1">Codice Fiscale</p>
                                        <p class="text-sm text-gray-900 font-medium">${client.codiceFiscale || 'N/A'}</p>
                                    </div>
                                </div>
                            </div>

                            <!-- Location Info -->
                            <div class="bg-gray-50 rounded-lg p-4">
                                <h3 class="text-sm font-semibold text-gray-800 mb-3 flex items-center">
                                    <i class="fas fa-map-marker-alt text-blue-600 mr-2"></i>
                                    Ubicazione
                                </h3>
                                <div class="flex items-start">
                                    <i class="fas fa-location-dot text-gray-400 mt-1 mr-3 w-5"></i>
                                    <div class="min-w-0 flex-1">
                                        <p class="text-sm text-gray-900 font-medium break-words">${client.indirizzo}</p>
                                        <a href="https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(client.indirizzo)}" 
                                           target="_blank"
                                           class="text-blue-600 hover:text-blue-700 text-xs mt-1 inline-flex items-center">
                                            Apri in Google Maps
                                            <i class="fas fa-external-link-alt ml-1"></i>
                                        </a>
                                    </div>
                                </div>
                            </div>

                            <!-- Notes -->
                            ${client.note ? `
                            <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                                <h3 class="text-sm font-semibold text-gray-800 mb-2 flex items-center">
                                    <i class="fas fa-sticky-note text-yellow-600 mr-2"></i>
                                    Note
                                </h3>
                                <p class="text-sm text-gray-700 break-words">${client.note}</p>
                            </div>
                            ` : ''}

                            <!-- Tasks List -->
                            <div class="bg-gray-50 rounded-lg p-4" id="clientTasksSection">
                                <h3 class="text-sm font-semibold text-gray-800 mb-3 flex items-center">
                                    <i class="fas fa-tasks text-blue-600 mr-2"></i>
                                    Lavorazioni Associate
                                    <span id="clientTasksCount" class="ml-2 px-2 py-1 bg-blue-100 text-blue-700 rounded-full text-xs font-medium">0</span>
                                </h3>
                                <div id="clientTasksList" class="space-y-2">
                                    <div class="text-center py-4 text-gray-500 text-sm">
                                        <i class="fas fa-spinner fa-spin mr-2"></i>Caricamento...
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- RIGHT: Map Panel -->
                        <div class="w-1/2 flex flex-col bg-gray-100">
                            <div id="clientMap" class="w-full h-full">
                                <!-- Map will be loaded here -->
                            </div>
                        </div>
                    </div>

                    <!-- Footer Actions -->
                    <div class="px-6 py-4 bg-gray-50 border-t flex-shrink-0 rounded-b-xl">
                        <div class="flex gap-3 justify-between items-center">
                            <div class="flex gap-2">
                                <a href="tel:${client.telefono}" class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm font-medium">
                                    <i class="fas fa-phone mr-2"></i>Chiama
                                </a>
                                <a href="mailto:${client.email}" class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors text-sm font-medium">
                                    <i class="fas fa-envelope mr-2"></i>Email
                                </a>
                                <a href="https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(client.indirizzo)}" 
                                   target="_blank"
                                   class="px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 transition-colors text-sm font-medium">
                                    <i class="fas fa-route mr-2"></i>Indicazioni
                                </a>
                            </div>
                            <button onclick="window.ClientModal.close()" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors text-sm font-medium">
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
        
        // Load tasks
        this.loadTasks(client.id);
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

    // Load tasks for client
    loadTasks: async function(clientId) {
        const tasksList = document.getElementById('clientTasksList');
        const tasksCount = document.getElementById('clientTasksCount');
        
        if (!tasksList || !tasksCount) return;
        
        try {
            // Get all tasks and filter by client_id
            const allTasks = await window.TasksAPI.getAll();
            const tasks = allTasks.filter(task => task.client_id === clientId);
            
            // Update count
            tasksCount.textContent = tasks.length;
            
            if (tasks.length === 0) {
                tasksList.innerHTML = `
                    <div class="text-center py-6 text-gray-400">
                        <i class="fas fa-inbox text-3xl mb-2"></i>
                        <p class="text-sm">Nessuna lavorazione associata</p>
                    </div>
                `;
                return;
            }
            
            // Render tasks
            tasksList.innerHTML = tasks.map(task => `
                <div class="bg-white border border-gray-200 rounded-lg p-3 hover:shadow-sm transition-shadow">
                    <div class="flex items-start justify-between mb-2">
                        <h4 class="font-medium text-gray-900 text-sm flex-1">${task.title || 'Senza titolo'}</h4>
                        <span class="ml-2 px-2 py-0.5 text-xs rounded-full ${this.getStatusBadgeClass(task.status)}">
                            ${this.getStatusLabel(task.status)}
                        </span>
                    </div>
                    
                    ${task.description ? `
                        <p class="text-xs text-gray-600 mb-2 line-clamp-2">${task.description}</p>
                    ` : ''}
                    
                    <div class="flex flex-wrap gap-2 text-xs text-gray-500">
                        ${task.priority ? `
                            <span class="inline-flex items-center px-2 py-0.5 rounded ${this.getPriorityBadgeClass(task.priority)}">
                                <i class="fas fa-flag mr-1"></i>
                                ${this.getPriorityLabel(task.priority)}
                            </span>
                        ` : ''}
                        
                        ${task.due_date ? `
                            <span class="inline-flex items-center">
                                <i class="fas fa-calendar mr-1"></i>
                                ${new Date(task.due_date).toLocaleDateString('it-IT')}
                            </span>
                        ` : ''}
                        
                        ${task.assigned_user_id ? `
                            <span class="inline-flex items-center">
                                <i class="fas fa-user mr-1"></i>
                                Assegnato
                            </span>
                        ` : ''}
                    </div>
                </div>
            `).join('');
            
        } catch (error) {
            console.error('Errore caricamento lavorazioni:', error);
            tasksList.innerHTML = `
                <div class="text-center py-4 text-red-500 text-sm">
                    <i class="fas fa-exclamation-triangle mr-1"></i>
                    Errore caricamento lavorazioni
                </div>
            `;
        }
    },
    
    // Helper functions for task display
    getStatusLabel: function(status) {
        const labels = {
            'pending': 'In Attesa',
            'in_progress': 'In Corso',
            'completed': 'Completata',
            'suspended': 'Sospesa'
        };
        return labels[status] || status;
    },
    
    getStatusBadgeClass: function(status) {
        const classes = {
            'pending': 'bg-yellow-100 text-yellow-800',
            'in_progress': 'bg-blue-100 text-blue-800',
            'completed': 'bg-green-100 text-green-800',
            'suspended': 'bg-gray-100 text-gray-800'
        };
        return classes[status] || 'bg-gray-100 text-gray-800';
    },
    
    getPriorityLabel: function(priority) {
        const labels = {
            'low': 'Bassa',
            'medium': 'Media',
            'high': 'Alta',
            'urgent': 'Urgente'
        };
        return labels[priority] || priority;
    },
    
    getPriorityBadgeClass: function(priority) {
        const classes = {
            'low': 'bg-gray-100 text-gray-700',
            'medium': 'bg-blue-100 text-blue-700',
            'high': 'bg-orange-100 text-orange-700',
            'urgent': 'bg-red-100 text-red-700'
        };
        return classes[priority] || 'bg-gray-100 text-gray-700';
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