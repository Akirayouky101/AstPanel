// Shared data between Admin Panel and User Panel
// This file contains the data models and synchronization logic

// Shared Tasks Data
window.sharedData = {
    // Clients database with detailed information
    clients: [
        {
            id: 'techcorp',
            ragioneSociale: 'TechCorp srl',
            nome: 'Marco',
            cognome: 'Bianchi',
            tipoCliente: 'azienda',
            indirizzo: 'Via Roma 123, 20100 Milano MI',
            ubicazione: {
                lat: 45.4642,
                lng: 9.1900,
                address: 'Via Roma 123, 20100 Milano MI'
            },
            telefono: '+39 02 1234567',
            email: 'info@techcorp.it',
            pec: 'techcorp@pec.it',
            partitaIva: 'IT12345678901',
            settore: 'Tecnologia',
            note: 'Cliente premium - Alta priorità',
            dataInizioRapporto: '2023-01-15'
        },
        {
            id: 'datacorp',
            ragioneSociale: 'DataCorp ltd',
            nome: 'Laura',
            cognome: 'Verdi',
            tipoCliente: 'azienda',
            indirizzo: 'Corso Italia 45, 00100 Roma RM',
            ubicazione: {
                lat: 41.9028,
                lng: 12.4964,
                address: 'Corso Italia 45, 00100 Roma RM'
            },
            telefono: '+39 06 9876543',
            email: 'contatti@datacorp.com',
            pec: 'datacorp@pec.com',
            partitaIva: 'IT98765432109',
            settore: 'Big Data',
            note: 'Richiede reportistica mensile',
            dataInizioRapporto: '2023-05-20'
        },
        {
            id: 'securecorp',
            ragioneSociale: 'SecureCorp spa',
            nome: 'Giovanni',
            cognome: 'Russo',
            tipoCliente: 'azienda',
            indirizzo: 'Via Torino 78, 10100 Torino TO',
            ubicazione: {
                lat: 45.0703,
                lng: 7.6869,
                address: 'Via Torino 78, 10100 Torino TO'
            },
            telefono: '+39 011 5554321',
            email: 'info@securecorp.it',
            pec: 'securecorp@legalmail.it',
            partitaIva: 'IT11223344556',
            settore: 'Cyber Security',
            note: 'Contratti annuali - NDA firmato',
            dataInizioRapporto: '2022-11-10'
        },
        {
            id: 'webcorp',
            ragioneSociale: 'WebCorp inc',
            nome: 'Francesca',
            cognome: 'Neri',
            tipoCliente: 'privato',
            indirizzo: 'Via Napoli 234, 80100 Napoli NA',
            ubicazione: {
                lat: 40.8518,
                lng: 14.2681,
                address: 'Via Napoli 234, 80100 Napoli NA'
            },
            telefono: '+39 081 7778899',
            email: 'f.neri@webcorp.it',
            partitaIva: 'IT66778899001',
            settore: 'Web Design',
            note: 'Lavori su progetto',
            dataInizioRapporto: '2024-01-05'
        }
    ],

    tasks: [
        {
            id: 1,
            titolo: 'Sviluppo Frontend App Mobile',
            descrizione: 'Implementazione interfaccia utente per applicazione mobile iOS/Android',
            assegnatario: 'mario',
            nomeAssegnatario: 'Mario Rossi',
            avatar: 'https://i.pravatar.cc/40?img=1',
            stato: 'in_corso',
            priorita: 'alta',
            scadenza: '2024-02-15',
            clienteId: 'techcorp',
            cliente: 'TechCorp srl',
            dataCreazione: '2024-01-10',
            progresso: 65,
            componenti: [
                { id: 'comp-001', quantita: 8 },
                { id: 'comp-002', quantita: 1 },
                { id: 'comp-003', quantita: 1 },
                { id: 'comp-004', quantita: 4 }
            ],
            ultimoAggiornamento: new Date().toISOString()
        },
        {
            id: 2,
            titolo: 'Database Optimization',
            descrizione: 'Ottimizzazione performance query database principale',
            assegnatario: 'anna',
            nomeAssegnatario: 'Anna Verdi',
            avatar: 'https://i.pravatar.cc/40?img=2',
            stato: 'da_fare',
            priorita: 'media',
            scadenza: '2024-02-20',
            clienteId: 'datacorp',
            cliente: 'DataCorp ltd',
            dataCreazione: '2024-01-12',
            progresso: 0,
            componenti: [],
            ultimoAggiornamento: new Date().toISOString()
        },
        {
            id: 3,
            titolo: 'Security Audit',
            descrizione: 'Audit completo sicurezza sistema aziendale',
            assegnatario: 'giuseppe',
            nomeAssegnatario: 'Giuseppe Neri',
            avatar: 'https://i.pravatar.cc/40?img=3',
            stato: 'revisione',
            priorita: 'alta',
            scadenza: '2024-02-10',
            clienteId: 'securecorp',
            cliente: 'SecureCorp spa',
            dataCreazione: '2024-01-08',
            progresso: 90,
            ultimoAggiornamento: new Date().toISOString()
        },
        {
            id: 4,
            titolo: 'Website Redesign',
            descrizione: 'Redesign completo sito web aziendale',
            assegnatario: 'laura',
            nomeAssegnatario: 'Laura Blu',
            avatar: 'https://i.pravatar.cc/40?img=4',
            stato: 'completato',
            priorita: 'bassa',
            scadenza: '2024-01-30',
            clienteId: 'webcorp',
            cliente: 'WebCorp inc',
            dataCreazione: '2024-01-05',
            progresso: 100,
            ultimoAggiornamento: new Date().toISOString()
        },
        {
            id: 5,
            titolo: 'Ottimizzazione Performance',
            descrizione: 'Miglioramento velocità caricamento pagine',
            assegnatario: 'mario',
            nomeAssegnatario: 'Mario Rossi',
            avatar: 'https://i.pravatar.cc/40?img=1',
            stato: 'da_fare',
            priorita: 'media',
            scadenza: '2024-02-20',
            clienteId: 'webcorp',
            cliente: 'WebCorp inc',
            dataCreazione: '2024-01-15',
            progresso: 0,
            ultimoAggiornamento: new Date().toISOString()
        },
        {
            id: 6,
            titolo: 'Bug Fix Dashboard',
            descrizione: 'Correzione problemi visualizzazione dashboard',
            assegnatario: 'mario',
            nomeAssegnatario: 'Mario Rossi',
            avatar: 'https://i.pravatar.cc/40?img=1',
            stato: 'completato',
            priorita: 'alta',
            scadenza: '2024-02-05',
            clienteId: 'datacorp',
            cliente: 'DataCorp ltd',
            dataCreazione: '2024-01-20',
            progresso: 100,
            ultimoAggiornamento: new Date().toISOString()
        }
    ],

    users: [
        {
            id: 'mario',
            nome: 'Mario',
            cognome: 'Rossi',
            email: 'mario.rossi@azienda.com',
            ruolo: 'manager',
            stato: 'attivo',
            telefono: '+39 340 1234567',
            ultimoAccesso: '2024-01-20',
            avatar: 'https://i.pravatar.cc/40?img=1'
        },
        {
            id: 'anna',
            nome: 'Anna',
            cognome: 'Verdi',
            email: 'anna.verdi@azienda.com',
            ruolo: 'dipendente',
            stato: 'attivo',
            telefono: '+39 340 2345678',
            ultimoAccesso: '2024-01-19',
            avatar: 'https://i.pravatar.cc/40?img=2'
        },
        {
            id: 'giuseppe',
            nome: 'Giuseppe',
            cognome: 'Neri',
            email: 'giuseppe.neri@azienda.com',
            ruolo: 'dipendente',
            stato: 'attivo',
            telefono: '+39 340 3456789',
            ultimoAccesso: '2024-01-18',
            avatar: 'https://i.pravatar.cc/40?img=3'
        },
        {
            id: 'laura',
            nome: 'Laura',
            cognome: 'Blu',
            email: 'laura.blu@azienda.com',
            ruolo: 'admin',
            stato: 'attivo',
            telefono: '+39 340 4567890',
            ultimoAccesso: '2024-01-20',
            avatar: 'https://i.pravatar.cc/40?img=4'
        }
    ],

    requests: [
        {
            id: 1,
            tipo: 'ferie',
            titolo: 'Richiesta Ferie Estive',
            descrizione: 'Richiesta di 15 giorni di ferie dal 15 al 30 agosto per vacanze estive.',
            dipendente: { 
                id: 'mario',
                nome: 'Mario Rossi', 
                email: 'mario.rossi@azienda.com', 
                avatar: 'https://i.pravatar.cc/40?img=1' 
            },
            dataRichiesta: '2024-01-15',
            dataInizio: '2024-08-15',
            dataFine: '2024-08-30',
            stato: 'in_attesa',
            priorita: 'media',
            urgente: false,
            dettagli: {
                motivazione: 'Vacanze estive pianificate da tempo',
                sostituto: 'Luca Bianchi',
                progetti_affidati: ['Progetto Alpha', 'Manutenzione Sistema']
            }
        },
        {
            id: 2,
            tipo: 'materiali',
            titolo: 'Richiesta Laptop Nuovo',
            descrizione: 'Il laptop attuale è troppo lento per le attività di sviluppo.',
            dipendente: { 
                id: 'anna',
                nome: 'Anna Verdi', 
                email: 'anna.verdi@azienda.com', 
                avatar: 'https://i.pravatar.cc/40?img=2' 
            },
            dataRichiesta: '2024-01-16',
            stato: 'in_attesa',
            priorita: 'alta',
            urgente: true,
            dettagli: {
                specifiche: 'Intel i7, 16GB RAM, SSD 512GB',
                budget_stimato: '€1,200',
                fornitore_suggerito: 'TechStore srl'
            }
        },
        {
            id: 3,
            tipo: 'permessi',
            titolo: 'Permesso Medico',
            descrizione: 'Visita specialistica programmata.',
            dipendente: { 
                id: 'giuseppe',
                nome: 'Giuseppe Neri', 
                email: 'giuseppe.neri@azienda.com', 
                avatar: 'https://i.pravatar.cc/40?img=3' 
            },
            dataRichiesta: '2024-01-17',
            dataInizio: '2024-01-20',
            stato: 'approvata',
            priorita: 'alta',
            urgente: true,
            dettagli: {
                ore_richieste: '4',
                motivazione: 'Visita cardiologica di controllo'
            }
        }
    ],

    communications: [
        {
            id: 1,
            titolo: 'Nuove Procedure di Sicurezza',
            tipo: 'procedura',
            contenuto: 'È obbligatorio l\'uso delle mascherine in tutti gli spazi comuni aziendali...',
            priorita: 'alta',
            stato: 'inviata',
            dataCreazione: '2024-01-20',
            dataInvio: '2024-01-20',
            destinatari: ['Tutti i Dipendenti'],
            autore: 'Admin',
            visualizzazioni: 45,
            allegati: ['sicurezza_covid.pdf']
        },
        {
            id: 2,
            titolo: 'Meeting Trimestrale Q1 2024',
            tipo: 'evento',
            contenuto: 'Vi invitiamo al meeting trimestrale che si terrà venerdì 26 gennaio...',
            priorita: 'media',
            stato: 'programmata',
            dataCreazione: '2024-01-18',
            dataProgrammata: '2024-01-25',
            destinatari: ['Tutti i Dipendenti'],
            autore: 'Admin',
            allegati: ['agenda_meeting.pdf']
        },
        {
            id: 3,
            titolo: 'Aggiornamento Sistema ERP',
            tipo: 'annuncio',
            contenuto: 'Il sistema ERP sarà aggiornato domenica 28 gennaio dalle 02:00 alle 06:00...',
            priorita: 'alta',
            stato: 'inviata',
            dataCreazione: '2024-01-19',
            dataInvio: '2024-01-19',
            destinatari: ['Tutti i Dipendenti'],
            autore: 'IT Team',
            visualizzazioni: 38,
            urgente: true
        }
    ],

    // Warehouse components inventory
    componenti: [
        {
            id: 'comp-001',
            codice: 'ANT-SENS-001',
            nome: 'Sensore Apertura Porte/Finestre',
            categoria: 'Antifurto',
            descrizione: 'Sensore magnetico wireless per rilevamento apertura',
            quantitaDisponibile: 45,
            unitaMisura: 'pz',
            prezzo: 12.50,
            fornitore: 'SecurityTech srl',
            note: 'Compatibile con centrali Serie X'
        },
        {
            id: 'comp-002',
            codice: 'ANT-CENT-001',
            nome: 'Centrale Antifurto 8 Zone',
            categoria: 'Antifurto',
            descrizione: 'Centrale antifurto wireless con GSM integrato',
            quantitaDisponibile: 12,
            unitaMisura: 'pz',
            prezzo: 189.00,
            fornitore: 'SecurityTech srl',
            note: 'Include alimentatore e batteria tampone'
        },
        {
            id: 'comp-003',
            codice: 'ANT-SIR-001',
            nome: 'Sirena Esterna Wireless',
            categoria: 'Antifurto',
            descrizione: 'Sirena autoalimentata con lampeggiante LED',
            quantitaDisponibile: 28,
            unitaMisura: 'pz',
            prezzo: 65.00,
            fornitore: 'SecurityTech srl',
            note: 'IP65 - Resistente alle intemperie'
        },
        {
            id: 'comp-004',
            codice: 'ANT-PIR-001',
            nome: 'Rilevatore Movimento PIR',
            categoria: 'Antifurto',
            descrizione: 'Sensore PIR wireless con immunità animali',
            quantitaDisponibile: 33,
            unitaMisura: 'pz',
            prezzo: 28.50,
            fornitore: 'SecurityTech srl',
            note: 'Portata 12m, angolo 90°'
        },
        {
            id: 'comp-005',
            codice: 'VID-CAM-001',
            nome: 'Telecamera IP PoE 4MP',
            categoria: 'Videosorveglianza',
            descrizione: 'Telecamera IP dome con visione notturna',
            quantitaDisponibile: 18,
            unitaMisura: 'pz',
            prezzo: 145.00,
            fornitore: 'VisionPro ltd',
            note: 'IR 30m, WDR, H.265'
        },
        {
            id: 'comp-006',
            codice: 'VID-NVR-001',
            nome: 'NVR 8 Canali PoE',
            categoria: 'Videosorveglianza',
            descrizione: 'Network Video Recorder con PoE integrato',
            quantitaDisponibile: 8,
            unitaMisura: 'pz',
            prezzo: 320.00,
            fornitore: 'VisionPro ltd',
            note: 'Include HDD 2TB'
        },
        {
            id: 'comp-007',
            codice: 'NET-CAV-100',
            nome: 'Cavo Cat6 FTP',
            categoria: 'Rete',
            descrizione: 'Cavo di rete schermato Cat6',
            quantitaDisponibile: 500,
            unitaMisura: 'm',
            prezzo: 0.85,
            fornitore: 'NetSupply srl',
            note: 'Bobina 305m disponibile'
        },
        {
            id: 'comp-008',
            codice: 'NET-CONN-RJ45',
            nome: 'Connettore RJ45 Schermato',
            categoria: 'Rete',
            descrizione: 'Connettore modulare RJ45 FTP',
            quantitaDisponibile: 200,
            unitaMisura: 'pz',
            prezzo: 0.45,
            fornitore: 'NetSupply srl',
            note: 'Confezione da 100pz disponibile'
        },
        {
            id: 'comp-009',
            codice: 'ACC-STAF-001',
            nome: 'Staffa Universale',
            categoria: 'Accessori',
            descrizione: 'Staffa regolabile per telecamere',
            quantitaDisponibile: 52,
            unitaMisura: 'pz',
            prezzo: 8.50,
            fornitore: 'VisionPro ltd',
            note: 'Alluminio, rotazione 360°'
        },
        {
            id: 'comp-010',
            codice: 'ACC-ALIM-12V',
            nome: 'Alimentatore 12V 2A',
            categoria: 'Accessori',
            descrizione: 'Alimentatore switching 12V DC',
            quantitaDisponibile: 40,
            unitaMisura: 'pz',
            prezzo: 6.50,
            fornitore: 'TechPower spa',
            note: 'Certificato CE'
        }
    ],

    // Squadre (teams)
    squadre: [],

    // Calendar events (auto-generated from tasks)
    calendarEvents: []
};

// Data synchronization functions
window.syncData = {
    // Update task from user panel
    updateTask: function(taskId, updates) {
        const task = window.sharedData.tasks.find(t => t.id === taskId);
        if (task) {
            Object.assign(task, updates);
            task.ultimoAggiornamento = new Date().toISOString();
            
            // Trigger update events for any listening panels
            window.dispatchEvent(new CustomEvent('taskUpdated', { 
                detail: { taskId, task, updates } 
            }));
            
            return true;
        }
        return false;
    },

    // Add new task from admin panel
    addTask: function(taskData) {
        const newId = Math.max(...window.sharedData.tasks.map(t => t.id)) + 1;
        const task = {
            ...taskData,
            id: newId,
            dataCreazione: new Date().toISOString().split('T')[0],
            ultimoAggiornamento: new Date().toISOString()
        };
        
        window.sharedData.tasks.push(task);
        
        window.dispatchEvent(new CustomEvent('taskAdded', { 
            detail: { task } 
        }));
        
        return task;
    },

    // Delete task
    deleteTask: function(taskId) {
        const index = window.sharedData.tasks.findIndex(t => t.id === taskId);
        if (index > -1) {
            const task = window.sharedData.tasks[index];
            window.sharedData.tasks.splice(index, 1);
            
            window.dispatchEvent(new CustomEvent('taskDeleted', { 
                detail: { taskId, task } 
            }));
            
            return true;
        }
        return false;
    },

    // Get tasks for specific user
    getUserTasks: function(userId) {
        return window.sharedData.tasks.filter(task => task.assegnatario === userId);
    },

    // Get tasks by status
    getTasksByStatus: function(status) {
        return window.sharedData.tasks.filter(task => task.stato === status);
    },

    // Add new request
    addRequest: function(requestData) {
        const newId = Math.max(...window.sharedData.requests.map(r => r.id)) + 1;
        const request = {
            ...requestData,
            id: newId,
            dataRichiesta: new Date().toISOString().split('T')[0],
            stato: 'in_attesa'
        };
        
        window.sharedData.requests.push(request);
        
        window.dispatchEvent(new CustomEvent('requestAdded', { 
            detail: { request } 
        }));
        
        return request;
    },

    // Update request status (from admin)
    updateRequest: function(requestId, updates) {
        const request = window.sharedData.requests.find(r => r.id === requestId);
        if (request) {
            Object.assign(request, updates);
            
            window.dispatchEvent(new CustomEvent('requestUpdated', { 
                detail: { requestId, request, updates } 
            }));
            
            return true;
        }
        return false;
    },

    // Get requests for specific user
    getUserRequests: function(userId) {
        return window.sharedData.requests.filter(request => 
            request.dipendente.id === userId
        );
    },

    // Add new communication
    addCommunication: function(commData) {
        const newId = Math.max(...window.sharedData.communications.map(c => c.id)) + 1;
        const communication = {
            ...commData,
            id: newId,
            dataCreazione: new Date().toISOString().split('T')[0],
            stato: commData.dataProgrammata ? 'programmata' : 'inviata',
            dataInvio: commData.dataProgrammata ? null : new Date().toISOString().split('T')[0]
        };
        
        window.sharedData.communications.push(communication);
        
        window.dispatchEvent(new CustomEvent('communicationAdded', { 
            detail: { communication } 
        }));
        
        return communication;
    },

    // Get statistics
    getStats: function() {
        const tasks = window.sharedData.tasks;
        const requests = window.sharedData.requests;
        const users = window.sharedData.users;
        const communications = window.sharedData.communications;

        return {
            tasks: {
                total: tasks.length,
                byStatus: {
                    da_fare: tasks.filter(t => t.stato === 'da_fare').length,
                    in_corso: tasks.filter(t => t.stato === 'in_corso').length,
                    revisione: tasks.filter(t => t.stato === 'revisione').length,
                    completato: tasks.filter(t => t.stato === 'completato').length
                },
                overdue: tasks.filter(t => 
                    new Date(t.scadenza) < new Date() && t.stato !== 'completato'
                ).length
            },
            users: {
                total: users.length,
                active: users.filter(u => u.stato === 'attivo').length,
                managers: users.filter(u => u.ruolo === 'manager' || u.ruolo === 'admin').length
            },
            requests: {
                total: requests.length,
                pending: requests.filter(r => r.stato === 'in_attesa').length,
                approved: requests.filter(r => r.stato === 'approvata').length,
                rejected: requests.filter(r => r.stato === 'rifiutata').length
            },
            communications: {
                total: communications.length,
                sent: communications.filter(c => c.stato === 'inviata').length,
                scheduled: communications.filter(c => c.stato === 'programmata').length,
                drafts: communications.filter(c => c.stato === 'bozza').length
            }
        };
    },

    // Get client by ID
    getClient: function(clientId) {
        return window.sharedData.clients.find(c => c.id === clientId);
    },

    // Get all clients
    getAllClients: function() {
        return window.sharedData.clients;
    },

    // Add new client
    addClient: function(clientData) {
        const newId = clientData.ragioneSociale.toLowerCase().replace(/[^a-z0-9]/g, '');
        const client = {
            ...clientData,
            id: newId,
            dataInizioRapporto: new Date().toISOString().split('T')[0]
        };
        
        window.sharedData.clients.push(client);
        
        window.dispatchEvent(new CustomEvent('clientAdded', { 
            detail: { client } 
        }));
        
        return client;
    },

    // Get component by ID
    getComponent: function(componentId) {
        return window.sharedData.componenti.find(c => c.id === componentId);
    },

    // Get all components
    getAllComponents: function() {
        return window.sharedData.componenti;
    },

    // Get components by category
    getComponentsByCategory: function(category) {
        return window.sharedData.componenti.filter(c => c.categoria === category);
    },

    // Add component to task
    addComponentToTask: function(taskId, componentId, quantita) {
        const task = window.sharedData.tasks.find(t => t.id === taskId);
        const component = this.getComponent(componentId);
        
        if (!task || !component) return false;
        
        // Initialize componenti array if not exists
        if (!task.componenti) {
            task.componenti = [];
        }
        
        // Check if component already exists in task
        const existing = task.componenti.find(c => c.id === componentId);
        if (existing) {
            existing.quantita += quantita;
        } else {
            task.componenti.push({ id: componentId, quantita });
        }
        
        task.ultimoAggiornamento = new Date().toISOString();
        
        window.dispatchEvent(new CustomEvent('taskComponentAdded', { 
            detail: { taskId, componentId, quantita, task } 
        }));
        
        return true;
    },

    // Remove component from task
    removeComponentFromTask: function(taskId, componentId) {
        const task = window.sharedData.tasks.find(t => t.id === taskId);
        
        if (!task || !task.componenti) return false;
        
        const index = task.componenti.findIndex(c => c.id === componentId);
        if (index !== -1) {
            task.componenti.splice(index, 1);
            task.ultimoAggiornamento = new Date().toISOString();
            
            window.dispatchEvent(new CustomEvent('taskComponentRemoved', { 
                detail: { taskId, componentId, task } 
            }));
            
            return true;
        }
        
        return false;
    },

    // Update component quantity in task
    updateComponentQuantity: function(taskId, componentId, quantita) {
        const task = window.sharedData.tasks.find(t => t.id === taskId);
        
        if (!task || !task.componenti) return false;
        
        const component = task.componenti.find(c => c.id === componentId);
        if (component) {
            component.quantita = quantita;
            task.ultimoAggiornamento = new Date().toISOString();
            
            window.dispatchEvent(new CustomEvent('taskComponentUpdated', { 
                detail: { taskId, componentId, quantita, task } 
            }));
            
            return true;
        }
        
        return false;
    },

    // Get task components with details
    getTaskComponents: function(taskId) {
        const task = window.sharedData.tasks.find(t => t.id === taskId);
        
        if (!task || !task.componenti) return [];
        
        return task.componenti.map(tc => {
            const component = this.getComponent(tc.id);
            return {
                ...component,
                quantitaAssegnata: tc.quantita,
                disponibile: component.quantitaDisponibile >= tc.quantita
            };
        });
    },

    // Sync calendar events from tasks
    syncCalendarFromTasks: function() {
        const events = [];
        
        window.sharedData.tasks.forEach(task => {
            // Check if task is assigned to a team
            if (task.squadra) {
                const team = window.sharedData.squadre?.find(s => s.id === task.squadra);
                if (team) {
                    // Create an event for each team member
                    team.membri.forEach(memberId => {
                        const user = window.sharedData.users.find(u => u.id === memberId);
                        events.push({
                            id: `task-${task.id}-member-${memberId}`,
                            title: `${task.titolo} (${team.nome})`,
                            start: task.scadenza,
                            end: task.scadenza,
                            taskId: task.id,
                            assignee: memberId,
                            assigneeName: user?.nome || memberId,
                            teamId: team.id,
                            teamName: team.nome,
                            status: task.stato,
                            priority: task.priorita,
                            client: task.cliente,
                            description: task.descrizione,
                            backgroundColor: team.colore || this.getTaskColor(task),
                            borderColor: team.colore || this.getTaskColor(task),
                            textColor: '#ffffff',
                            extendedProps: {
                                taskId: task.id,
                                assignee: memberId,
                                teamId: team.id,
                                teamName: team.nome,
                                priority: task.priorita,
                                status: task.stato,
                                client: task.cliente
                            }
                        });
                    });
                }
            } else if (task.assegnatario) {
                // Single assignment (no team)
                events.push({
                    id: `task-${task.id}`,
                    title: task.titolo,
                    start: task.scadenza,
                    end: task.scadenza,
                    taskId: task.id,
                    assignee: task.assegnatario,
                    assigneeName: task.nomeAssegnatario,
                    status: task.stato,
                    priority: task.priorita,
                    client: task.cliente,
                    description: task.descrizione,
                    backgroundColor: this.getTaskColor(task),
                    borderColor: this.getTaskColor(task),
                    textColor: '#ffffff',
                    extendedProps: {
                        taskId: task.id,
                        assignee: task.assegnatario,
                        priority: task.priorita,
                        status: task.stato,
                        client: task.cliente
                    }
                });
            }
        });
        
        window.sharedData.calendarEvents = events;
        
        window.dispatchEvent(new CustomEvent('calendarSynced', { 
            detail: { events: window.sharedData.calendarEvents } 
        }));
    },

    // Get calendar color based on task
    getTaskColor: function(task) {
        // Priority colors
        if (task.priorita === 'alta') return '#ef4444'; // red
        if (task.priorita === 'media') return '#f59e0b'; // orange
        if (task.priorita === 'bassa') return '#10b981'; // green
        
        // Default
        return '#3b82f6'; // blue
    },

    // Get calendar events for specific user
    getCalendarEventsForUser: function(userId) {
        this.syncCalendarFromTasks();
        return window.sharedData.calendarEvents.filter(event => 
            event.assignee === userId
        );
    },

    // Get all calendar events
    getAllCalendarEvents: function() {
        this.syncCalendarFromTasks();
        return window.sharedData.calendarEvents;
    }
};

// Initialize localStorage persistence
window.dataManager = {
    save: function() {
        try {
            localStorage.setItem('astPanelData', JSON.stringify(window.sharedData));
            return true;
        } catch (e) {
            console.error('Error saving data to localStorage:', e);
            return false;
        }
    },

    load: function() {
        try {
            const saved = localStorage.getItem('astPanelData');
            if (saved) {
                const data = JSON.parse(saved);
                // Merge with default data, keeping any new properties
                Object.keys(data).forEach(key => {
                    if (window.sharedData[key]) {
                        window.sharedData[key] = data[key];
                    }
                });
                return true;
            }
        } catch (e) {
            console.error('Error loading data from localStorage:', e);
        }
        return false;
    },

    clear: function() {
        localStorage.removeItem('astPanelData');
    }
};

// Auto-save on data changes
['taskUpdated', 'taskAdded', 'taskDeleted', 'requestAdded', 'requestUpdated', 'communicationAdded', 'taskComponentAdded', 'taskComponentRemoved', 'taskComponentUpdated'].forEach(eventType => {
    window.addEventListener(eventType, () => {
        window.dataManager.save();
        // Sync calendar when tasks change
        if (eventType.includes('task')) {
            window.syncData.syncCalendarFromTasks();
        }
    });
});

// Load saved data on initialization
document.addEventListener('DOMContentLoaded', function() {
    window.dataManager.load();
});

console.log('AST Panel Shared Data System initialized');