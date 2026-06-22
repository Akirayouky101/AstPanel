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

        // Carica condomini se tipo è amministratore_condominio
        let condominiiSection = '';
        if (client.tipoCliente === 'amministratore_condominio') {
            try {
                const allCl = await window.dataManager.getClienti();
                console.log('🏢 [ClientModal] Tutti i clienti:', allCl.length, '— cerca amministratore_id ===', clientId);
                const conds = allCl.filter(c => {
                    if (c.amministratore_id) console.log('  cliente:', c.ragione_sociale, 'amm_id:', c.amministratore_id);
                    return String(c.amministratore_id) === String(clientId);
                });
                condominiiSection = '<div style="background:linear-gradient(135deg,#eef2ff,#e0e7ff);border:2px solid #a5b4fc;border-radius:12px;padding:12px;margin-bottom:4px">'
                    + '<div style="display:flex;align-items:center;gap:8px;margin-bottom:10px">'
                    + '<div style="width:30px;height:30px;background:linear-gradient(135deg,#4f46e5,#7c3aed);border-radius:8px;display:flex;align-items:center;justify-content:center">'
                    + '<i class="fas fa-building-user" style="color:white;font-size:11px"></i></div>'
                    + '<p style="font-weight:700;color:#1f2937;font-size:13px">Condomini Gestiti (' + conds.length + ')</p></div>'
                    + (conds.length === 0 ? '<p style="color:#6b7280;font-size:12px;padding:0 4px">Nessun condominio associato</p>' :
                       conds.map(function(c) {
                           return '<div style="background:#fff;border-radius:8px;padding:8px 10px;margin-bottom:6px;border:1px solid #e0e7ff">'
                               + '<div style="font-weight:600;color:#1f2937;font-size:13px">' + (c.ragione_sociale || 'N/A') + '</div>'
                               + (c.indirizzo ? '<div style="font-size:11px;color:#6b7280">' + c.indirizzo + '</div>' : '')
                               + '</div>';
                       }).join(''))
                    + '</div>';
            } catch(e) { console.error('❌ [ClientModal] Errore caricamento condomini:', e); }
        }

        // Carica scuole se tipo è comune
        let scuoleSection = '';
        if (client.tipoCliente === 'comune') {
            try {
                const allCl = await window.dataManager.getClienti();
                const scuole = allCl.filter(c => String(c.comune_id) === String(clientId));
                scuoleSection = '<div style="background:linear-gradient(135deg,#fefce8,#fef9c3);border:2px solid #fde047;border-radius:12px;padding:12px;margin-bottom:4px">'
                    + '<div style="display:flex;align-items:center;gap:8px;margin-bottom:10px">'
                    + '<div style="width:30px;height:30px;background:linear-gradient(135deg,#ca8a04,#d97706);border-radius:8px;display:flex;align-items:center;justify-content:center">'
                    + '<i class="fas fa-school" style="color:white;font-size:11px"></i></div>'
                    + '<p style="font-weight:700;color:#1f2937;font-size:13px">Scuole (' + scuole.length + ')</p></div>'
                    + (scuole.length === 0 ? '<p style="color:#6b7280;font-size:12px;padding:0 4px">Nessuna scuola associata a questo comune</p>' :
                       scuole.map(function(c) {
                           return '<div style="background:#fff;border-radius:8px;padding:8px 10px;margin-bottom:6px;border:1px solid #fde047">'
                               + '<div style="font-weight:600;color:#1f2937;font-size:13px">' + (c.ragione_sociale || 'N/A') + '</div>'
                               + (c.indirizzo ? '<div style="font-size:11px;color:#6b7280">' + c.indirizzo + '</div>' : '')
                               + '</div>';
                       }).join(''))
                    + '</div>';
            } catch(e) { console.error('❌ [ClientModal] Errore caricamento scuole:', e); }
        }

        let aziendaSection = '';
        if (client.tipoCliente === 'struttura') {
            try {
                const aziende = await window.dataManager.getAziende();
                const azienda = aziende.find(a => String(a.id) === String(clientData.azienda_id));
                aziendaSection = '<div style="background:linear-gradient(135deg,#ecfeff,#ccfbf1);border:2px solid #2dd4bf;border-radius:12px;padding:12px;margin-bottom:4px">'
                    + '<div style="display:flex;align-items:center;gap:8px;margin-bottom:10px">'
                    + '<div style="width:30px;height:30px;background:linear-gradient(135deg,#0d9488,#14b8a6);border-radius:8px;display:flex;align-items:center;justify-content:center">'
                    + '<i class="fas fa-building" style="color:white;font-size:11px"></i></div>'
                    + '<p style="font-weight:700;color:#134e4a;font-size:13px">Azienda di riferimento</p></div>'
                    + '<div style="background:#fff;border-radius:8px;padding:10px 12px;border:1px solid #d1fae5">'
                    + '<div style="font-weight:600;color:#0f766e;font-size:13px">' + (azienda ? (azienda.nome || azienda.ragione_sociale) : 'Azienda non trovata') + '</div>'
                    + (azienda && azienda.indirizzo ? '<div style="font-size:11px;color:#4b5563">' + azienda.indirizzo + '</div>' : '')
                    + (azienda && azienda.telefono ? '<div style="font-size:11px;color:#4b5563">Telefono: ' + azienda.telefono + '</div>' : '')
                    + (azienda && azienda.email ? '<div style="font-size:11px;color:#4b5563">Email: ' + azienda.email + '</div>' : '')
                    + '</div></div>';
            } catch(e) { console.error('❌ [ClientModal] Errore caricamento azienda collegata:', e); }
        }

        // Strutture collegate (mostrate quando il tipo è 'azienda')
        let struttureSection = '';
        if (client.tipoCliente === 'azienda') {
            try {
                const allCl = await window.dataManager.getClienti();
                const strutture = allCl.filter(c => String(c.azienda_id) === String(clientId));
                struttureSection = '<div style="background:linear-gradient(135deg,#ecfdf5,#d1fae5);border:2px solid #6ee7b7;border-radius:12px;padding:12px;margin-bottom:4px">'
                    + '<div style="display:flex;align-items:center;gap:8px;margin-bottom:10px">'
                    + '<div style="width:30px;height:30px;background:linear-gradient(135deg,#059669,#10b981);border-radius:8px;display:flex;align-items:center;justify-content:center">'
                    + '<i class="fas fa-sitemap" style="color:white;font-size:11px"></i></div>'
                    + '<p style="font-weight:700;color:#064e3b;font-size:13px">Strutture Collegate (' + strutture.length + ')</p></div>'
                    + (strutture.length === 0
                        ? '<p style="color:#6b7280;font-size:12px;padding:0 4px">Nessuna struttura collegata</p>'
                        : strutture.map(function(s) {
                            const nome = s.ragione_sociale || s.nome || 'N/A';
                            const sub = [s.indirizzo, s.citta].filter(Boolean).join(', ');
                            const tel = s.telefono ? '<div style="font-size:11px;color:#6b7280">📞 ' + s.telefono + '</div>' : '';
                            return '<div style="background:#fff;border-radius:8px;padding:9px 11px;margin-bottom:6px;border:1px solid #a7f3d0;display:flex;align-items:center;gap:10px">'
                                + '<div style="width:28px;height:28px;background:linear-gradient(135deg,#059669,#10b981);border-radius:50%;display:flex;align-items:center;justify-content:center;flex-shrink:0">'
                                + '<i class="fas fa-building" style="color:white;font-size:10px"></i></div>'
                                + '<div style="flex:1;min-width:0">'
                                + '<div style="font-weight:600;color:#1f2937;font-size:13px">' + nome + '</div>'
                                + (sub ? '<div style="font-size:11px;color:#6b7280;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' + sub + '</div>' : '')
                                + tel
                                + '</div></div>';
                        }).join(''))
                    + '</div>';
            } catch(e) { console.error('❌ [ClientModal] Errore caricamento strutture collegate:', e); }
        }

        // Create modal HTML
        const modalHTML = `
            <div id="clientModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-[9999] p-4" onclick="if(event.target === this) window.ClientModal.close()">
                <div class="bg-white rounded-xl shadow-2xl max-w-lg max-h-[90vh] overflow-hidden flex flex-col">
                    <!-- Header -->
                    <div class="bg-gradient-to-r from-blue-600 to-purple-600 p-4">
                        <div class="flex items-center justify-between">
                            <h3 class="font-bold text-lg text-white">${client.ragioneSociale}</h3>
                            <button onclick="window.ClientModal.close()" class="text-white hover:bg-white/20 rounded-lg p-2">
                                <i class="fas fa-times"></i>
                            </button>
                        </div>
                    </div>

                    <!-- Content -->
                    <div class="p-4 overflow-y-auto flex-1 space-y-3">
                        <!-- Contact Information - AZZURRO -->
                        <div class="bg-gradient-to-br from-sky-50 to-blue-100 border-2 border-sky-200 rounded-lg p-3">
                            <div class="flex items-center gap-2 mb-2">
                                <div class="w-8 h-8 bg-gradient-to-br from-sky-500 to-blue-600 rounded-lg flex items-center justify-center">
                                    <i class="fas fa-address-book text-white text-sm"></i>
                                </div>
                                <p class="font-bold text-gray-900 text-sm">Contatti</p>
                            </div>
                            <div class="space-y-2">
                                <div class="flex items-start gap-3">
                                    <i class="fas fa-phone text-sky-600 mt-0.5 w-5"></i>
                                    <div class="flex-1 min-w-0">
                                        <p class="text-xs text-sky-700 font-medium">Telefono</p>
                                        <a href="tel:${client.telefono}" class="text-sm text-gray-900 hover:text-sky-700 font-bold break-all">
                                            ${client.telefono}
                                        </a>
                                    </div>
                                </div>
                                <div class="flex items-start gap-3">
                                    <i class="fas fa-envelope text-sky-600 mt-0.5 w-5"></i>
                                    <div class="flex-1 min-w-0">
                                        <p class="text-xs text-sky-700 font-medium">Email</p>
                                        <a href="mailto:${client.email}" class="text-sm text-gray-900 hover:text-sky-700 font-bold break-all">
                                            ${client.email}
                                        </a>
                                    </div>
                                </div>
                                ${client.pec ? `
                                <div class="flex items-start gap-3">
                                    <i class="fas fa-certificate text-sky-600 mt-0.5 w-5"></i>
                                    <div class="flex-1 min-w-0">
                                        <p class="text-xs text-sky-700 font-medium">PEC</p>
                                        <a href="mailto:${client.pec}" class="text-sm text-gray-900 hover:text-sky-700 font-bold break-all">
                                            ${client.pec}
                                        </a>
                                    </div>
                                </div>
                                ` : ''}
                            </div>
                        </div>

                        <!-- Business Information - GIALLO -->
                        <div class="bg-gradient-to-br from-yellow-50 to-amber-100 border-2 border-yellow-200 rounded-lg p-3">
                            <div class="flex items-center gap-2 mb-2">
                                <div class="w-8 h-8 bg-gradient-to-br from-yellow-500 to-amber-600 rounded-lg flex items-center justify-center">
                                    <i class="fas fa-building text-white text-sm"></i>
                                </div>
                                <p class="font-bold text-gray-900 text-sm">Informazioni Aziendali</p>
                            </div>
                            <div class="grid grid-cols-2 gap-3">
                                <div>
                                    <p class="text-xs text-yellow-700 font-medium mb-1">Partita IVA</p>
                                    <p class="text-sm text-gray-900 font-bold">${client.partitaIva || 'N/A'}</p>
                                </div>
                                <div>
                                    <p class="text-xs text-yellow-700 font-medium mb-1">Codice Fiscale</p>
                                    <p class="text-sm text-gray-900 font-bold">${client.codiceFiscale || 'N/A'}</p>
                                </div>
                            </div>
                        </div>

                        <!-- Location - BLU CHIARO -->
                        <div class="bg-gradient-to-br from-blue-50 to-sky-100 border-2 border-blue-200 rounded-lg p-3">
                            <div class="flex items-center gap-2 mb-2">
                                <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-sky-600 rounded-lg flex items-center justify-center">
                                    <i class="fas fa-map-marker-alt text-white text-sm"></i>
                                </div>
                                <div class="flex-1">
                                    <p class="text-xs text-blue-700 font-medium">Ubicazione</p>
                                    <p class="text-sm text-gray-900 font-bold break-words">${client.indirizzo}</p>
                                </div>
                            </div>
                            
                            <!-- Pulsante Google Maps -->
                            <a href="https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(client.indirizzo)}" 
                               target="_blank"
                               class="w-full mt-2 py-2 px-3 bg-white border-2 border-blue-300 rounded-lg hover:bg-blue-50 flex items-center justify-center gap-2 text-blue-700 font-medium text-sm">
                                <i class="fas fa-map"></i>
                                Visualizza su Mappa
                            </a>
                        </div>

                        <!-- Notes - GIALLO CHIARO -->
                        ${client.note ? `
                        <div class="bg-gradient-to-br from-yellow-50 to-amber-100 border-2 border-yellow-200 rounded-lg p-3">
                            <div class="flex items-start gap-2">
                                <div class="w-8 h-8 bg-gradient-to-br from-yellow-500 to-amber-600 rounded-lg flex items-center justify-center">
                                    <i class="fas fa-sticky-note text-white text-sm"></i>
                                </div>
                                <div class="flex-1">
                                    <p class="text-xs text-yellow-700 font-medium mb-1">Note</p>
                                    <p class="text-sm text-gray-700 break-words">${client.note}</p>
                                </div>
                            </div>
                        </div>
                        ` : ''}

                        ${clientData.rif_preventivo ? `
                        <div style="background:linear-gradient(135deg,#fffbeb,#fef3c7);border:2px solid #f59e0b;border-radius:10px;padding:10px 12px">
                            <div style="display:flex;align-items:center;gap:8px">
                                <div style="width:28px;height:28px;background:linear-gradient(135deg,#d97706,#b45309);border-radius:6px;display:flex;align-items:center;justify-content:center;flex-shrink:0">
                                    <i class="fas fa-lock" style="color:white;font-size:10px"></i>
                                </div>
                                <div>
                                    <p style="font-size:10px;color:#92400e;font-weight:600;text-transform:uppercase;letter-spacing:.5px">Rif. Preventivo (interno)</p>
                                    <p style="font-size:14px;color:#1f2937;font-weight:700">${clientData.rif_preventivo}</p>
                                </div>
                            </div>
                        </div>
                        ` : ''}

                        ${aziendaSection}

                        ${struttureSection}

                        ${condominiiSection}

                        ${scuoleSection}
                    </div>

                    <!-- Footer -->
                    <div class="p-4 bg-gray-50 border-t flex gap-2">
                        <a href="tel:${client.telefono}" class="flex-1 px-3 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 text-center text-sm font-medium">
                            <i class="fas fa-phone mr-1"></i>Chiama
                        </a>
                        <a href="https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(client.indirizzo)}" 
                           target="_blank"
                           class="flex-1 px-3 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 text-center text-sm font-medium">
                            <i class="fas fa-route mr-1"></i>Indicazioni
                        </a>
                        <button onclick="window.ClientModal.close()" class="px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-lg text-gray-800 text-sm font-medium">
                            Chiudi
                        </button>
                    </div>
                </div>
            </div>
        `;

        // Add modal to body
        const modalContainer = document.createElement('div');
        modalContainer.innerHTML = modalHTML;
        document.body.appendChild(modalContainer.firstElementChild);
        
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
                        <h4 class="font-medium text-gray-900 text-sm flex-1">${task.title || task.titolo || 'Senza titolo'}</h4>
                        <span class="ml-2 px-2 py-0.5 text-xs rounded-full ${this.getStatusBadgeClass(task.status || task.stato)}">
                            ${this.getStatusLabel(task.status || task.stato)}
                        </span>
                    </div>
                    
                    ${task.description || task.descrizione ? `
                        <p class="text-xs text-gray-600 mb-2 line-clamp-2">${task.description || task.descrizione}</p>
                    ` : ''}
                    
                    <div class="flex flex-wrap gap-2 text-xs text-gray-500">
                        ${task.priority || task.priorita ? `
                            <span class="inline-flex items-center px-2 py-0.5 rounded ${this.getPriorityBadgeClass(task.priority || task.priorita)}">
                                <i class="fas fa-flag mr-1"></i>
                                ${this.getPriorityLabel(task.priority || task.priorita)}
                            </span>
                        ` : ''}
                        
                        ${task.due_date || task.scadenza || task.deadline ? `
                            <span class="inline-flex items-center">
                                <i class="fas fa-calendar mr-1"></i>
                                ${new Date(task.due_date || task.scadenza || task.deadline).toLocaleDateString('it-IT')}
                            </span>
                        ` : ''}
                        
                        ${task.assigned_user_id || task.assegnatario ? `
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