/**
 * ================================================
 * TASK CREATION WIZARD - Sistema Guidato Creazione Lavorazioni
 * ================================================
 * 4 Step workflow per creare lavorazioni complete
 */

class TaskWizard {
    constructor() {
        this.currentStep = 1;
        this.totalSteps = 4;
        this.wizardData = {
            // Step 1: Dati Base
            titolo: '',
            cliente_id: null,
            descrizione: '',
            priorita: 'media',
            scadenza: '',
            categoria: '',
            tags: [],
            
            // Step 2: Assegnazione
            assigned_user_id: null,
            assigned_team_id: null,
            assigned_users: [], // Array per multi-utente
            tipo_assegnazione: 'user', // 'user', 'multi' o 'team'
            
            // Step 3: Dettagli e Componenti
            ore_stimate: 0,
            costo_stimato: 0,
            indirizzo_lavoro: '',
            coordinate_gps: null,
            componenti: [], // {prodotto_id, quantita, note}
            
            // Step 4: Conferma (autogenerata)
        };
    }

    // ===================================
    // GESTIONE NAVIGAZIONE WIZARD
    // ===================================
    
    async iniziaWizard() {
        this.currentStep = 1;
        this.resetData();
        await this.renderWizard();
        this.showStep(1);
    }

    nextStep() {
        if (this.validateCurrentStep()) {
            if (this.currentStep < this.totalSteps) {
                this.currentStep++;
                this.showStep(this.currentStep);
            }
        }
    }

    prevStep() {
        if (this.currentStep > 1) {
            this.currentStep--;
            this.showStep(this.currentStep);
        }
    }

    goToStep(stepNumber) {
        if (stepNumber >= 1 && stepNumber <= this.totalSteps) {
            // Valida tutti i passaggi precedenti
            for (let i = 1; i < stepNumber; i++) {
                if (!this.validateStep(i)) {
                    alert(`Completa prima lo step ${i}`);
                    return;
                }
            }
            this.currentStep = stepNumber;
            this.showStep(stepNumber);
        }
    }

    showStep(stepNumber) {
        // Nascondi tutti gli step
        for (let i = 1; i <= this.totalSteps; i++) {
            const stepEl = document.getElementById(`wizard-step-${i}`);
            if (stepEl) {
                stepEl.classList.add('hidden');
            }
        }
        
        // Mostra step corrente
        const currentStepEl = document.getElementById(`wizard-step-${stepNumber}`);
        if (currentStepEl) {
            currentStepEl.classList.remove('hidden');
        }

        // Aggiorna progress bar
        this.updateProgressBar();
        
        // Aggiorna pulsanti navigazione
        this.updateNavigationButtons();
        
        // Carica dati specifici dello step
        this.loadStepData(stepNumber);
    }

    updateProgressBar() {
        const progressBar = document.getElementById('wizard-progress-bar');
        const progressText = document.getElementById('wizard-progress-text');
        const percentage = (this.currentStep / this.totalSteps) * 100;
        
        if (progressBar) {
            progressBar.style.width = `${percentage}%`;
        }
        
        if (progressText) {
            progressText.textContent = `Step ${this.currentStep} di ${this.totalSteps}`;
        }

        // Aggiorna step indicators
        for (let i = 1; i <= this.totalSteps; i++) {
            const indicator = document.getElementById(`step-indicator-${i}`);
            if (indicator) {
                indicator.classList.remove('active', 'completed');
                if (i < this.currentStep) {
                    indicator.classList.add('completed');
                } else if (i === this.currentStep) {
                    indicator.classList.add('active');
                }
            }
        }
    }

    updateNavigationButtons() {
        const prevBtn = document.getElementById('wizard-prev-btn');
        const nextBtn = document.getElementById('wizard-next-btn');
        const submitBtn = document.getElementById('wizard-submit-btn');

        if (prevBtn) {
            prevBtn.disabled = this.currentStep === 1;
        }

        if (nextBtn && submitBtn) {
            if (this.currentStep === this.totalSteps) {
                nextBtn.classList.add('hidden');
                submitBtn.classList.remove('hidden');
            } else {
                nextBtn.classList.remove('hidden');
                submitBtn.classList.add('hidden');
            }
        }
    }

    // ===================================
    // VALIDAZIONE STEP
    // ===================================

    validateCurrentStep() {
        return this.validateStep(this.currentStep);
    }

    validateStep(stepNumber) {
        switch(stepNumber) {
            case 1:
                return this.validateStep1();
            case 2:
                return this.validateStep2();
            case 3:
                return this.validateStep3();
            case 4:
                return this.validateStep4();
            case 5:
                return true; // Conferma sempre valida
            default:
                return false;
        }
    }

    validateStep1() {
        if (!this.wizardData.titolo || this.wizardData.titolo.trim() === '') {
            alert('⚠️ Inserisci un titolo per la lavorazione');
            return false;
        }
        if (!this.wizardData.cliente_id) {
            alert('⚠️ Seleziona un cliente');
            return false;
        }
        if (!this.wizardData.scadenza) {
            alert('⚠️ Inserisci una data di scadenza');
            return false;
        }
        return true;
    }

    validateStep2() {
        if (this.wizardData.tipo_assegnazione === 'user' && !this.wizardData.assigned_user_id) {
            alert('⚠️ Seleziona un dipendente');
            return false;
        }
        if (this.wizardData.tipo_assegnazione === 'multi' && (!this.wizardData.assigned_users || this.wizardData.assigned_users.length === 0)) {
            alert('⚠️ Seleziona almeno un membro per la lavorazione');
            return false;
        }
        if (this.wizardData.tipo_assegnazione === 'team' && !this.wizardData.assigned_team_id) {
            alert('⚠️ Seleziona una squadra');
            return false;
        }
        return true;
    }

    validateStep3() {
        if (this.wizardData.ore_stimate <= 0) {
            const confirm = window.confirm('⚠️ Non hai inserito le ore stimate. Continuare?');
            return confirm;
        }
        return true;
    }

    validateStep4() {
        // Step disponibilità è opzionale
        return true;
    }

    // ===================================
    // CARICAMENTO DATI STEP
    // ===================================

    async loadStepData(stepNumber) {
        switch(stepNumber) {
            case 1:
                await this.loadClienti();
                this.populateStep1Form();
                break;
            case 2:
                await this.loadDipendentiESquadre();
                this.populateStep2Form();
                break;
            case 3:
                await this.loadProdottiMagazzino();
                this.populateStep3Form();
                break;
            case 4:
                // STEP 4: Riepilogo finale
                this.generaRiepilogo();
                break;
        }
    }

    async loadClienti() {
        try {
            const { data, error } = await supabaseClient
                .from('clients')
                .select('*')
                .order('ragione_sociale');
            
            if (error) throw error;
            
            const select = document.getElementById('wizard-cliente-select');
            if (select) {
                select.innerHTML = '<option value="">Seleziona cliente...</option>';
                data.forEach(cliente => {
                    const option = document.createElement('option');
                    option.value = cliente.id;
                    // Mostra ragione_sociale o nome+cognome se privato
                    const displayName = cliente.ragione_sociale || 
                                      (cliente.nome && cliente.cognome ? `${cliente.nome} ${cliente.cognome}` : cliente.nome || 'Cliente senza nome');
                    option.textContent = displayName;
                    select.appendChild(option);
                });
            }
        } catch (error) {
            console.error('Errore caricamento clienti:', error);
            // Mostra errore all'utente
            const select = document.getElementById('wizard-cliente-select');
            if (select) {
                select.innerHTML = '<option value="">⚠️ Errore caricamento clienti</option>';
            }
        }
    }

    async loadDipendentiESquadre() {
        try {
            // Carica dipendenti
            const { data: dipendenti, error: errDip } = await supabaseClient
                .from('users')
                .select('*')
                .in('ruolo', ['Dipendente', 'Tecnico', 'Titolare'])
                .order('nome');
            
            if (errDip) throw errDip;

            const selectDip = document.getElementById('wizard-dipendente-select');
            if (selectDip) {
                selectDip.innerHTML = '<option value="">Seleziona dipendente...</option>';
                dipendenti.forEach(dip => {
                    const option = document.createElement('option');
                    option.value = dip.id;
                    option.textContent = `${dip.nome} ${dip.cognome} (${dip.ruolo})`;
                    selectDip.appendChild(option);
                });
            }

            // Carica squadre
            const { data: squadre, error: errSq } = await supabaseClient
                .from('teams')
                .select('*')
                .order('nome');
            
            if (errSq) throw errSq;

            const selectSq = document.getElementById('wizard-squadra-select');
            if (selectSq) {
                selectSq.innerHTML = '<option value="">Seleziona squadra...</option>';
                squadre.forEach(sq => {
                    const option = document.createElement('option');
                    option.value = sq.id;
                    option.textContent = sq.nome;
                    selectSq.appendChild(option);
                });
            }
        } catch (error) {
            console.error('Errore caricamento dipendenti/squadre:', error);
        }
    }

    async loadProdottiMagazzino() {
        try {
            const { data, error } = await supabaseClient
                .from('components')
                .select('*')
                .gt('quantita_disponibile', 0)
                .order('nome');
            
            if (error) throw error;

            const container = document.getElementById('wizard-prodotti-container');
            if (!container) return;

            if (!data || data.length === 0) {
                container.innerHTML = `
                    <div class="text-center py-8 text-gray-500">
                        <i data-lucide="package-x" class="w-12 h-12 mx-auto mb-2 opacity-50"></i>
                        <p class="font-medium">Nessun prodotto disponibile in magazzino</p>
                        <p class="text-sm mt-1">Aggiungi prodotti dalla sezione Magazzino</p>
                    </div>
                `;
                lucide.createIcons();
                return;
            }

            // Suggerimenti intelligenti basati su categoria
            const categoriaSuggerimenti = this.getSuggerimentiPerCategoria();
            const prodottiSuggeriti = data.filter(p => 
                categoriaSuggerimenti.some(s => 
                    p.name.toLowerCase().includes(s.toLowerCase()) ||
                    (p.warehouse_categories && p.warehouse_categories.name && 
                     p.warehouse_categories.name.toLowerCase().includes(s.toLowerCase()))
                )
            );

            container.innerHTML = `
                ${prodottiSuggeriti.length > 0 ? `
                    <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                        <div class="flex items-center gap-2 mb-2">
                            <i data-lucide="sparkles" class="w-4 h-4 text-blue-600"></i>
                            <span class="text-sm font-semibold text-blue-900">Componenti Suggeriti per "${this.wizardData.categoria || 'questa categoria'}"</span>
                        </div>
                        <div class="space-y-2">
                            ${prodottiSuggeriti.map(prod => this.renderProdottoCard(prod, true)).join('')}
                        </div>
                    </div>
                    <div class="mb-2 text-sm font-medium text-gray-700">Altri Prodotti Disponibili:</div>
                ` : ''}
                <div class="space-y-2 max-h-60 overflow-y-auto">
                    ${data.filter(p => !prodottiSuggeriti.includes(p)).map(prod => this.renderProdottoCard(prod, false)).join('')}
                </div>
            `;
            lucide.createIcons();
        } catch (error) {
            console.error('Errore caricamento prodotti:', error);
            const container = document.getElementById('wizard-prodotti-container');
            if (container) {
                container.innerHTML = `
                    <div class="text-center py-8 text-red-500">
                        <i data-lucide="alert-circle" class="w-12 h-12 mx-auto mb-2"></i>
                        <p class="font-medium">Errore caricamento prodotti</p>
                        <p class="text-sm mt-1">${error.message}</p>
                    </div>
                `;
                lucide.createIcons();
            }
        }
    }

    renderProdottoCard(prod, isSuggerito) {
        const categoryName = prod.warehouse_categories ? prod.warehouse_categories.name : '';
        return `
            <div class="flex items-center gap-3 p-3 ${isSuggerito ? 'bg-blue-50 border-blue-300' : 'bg-gray-50'} rounded border hover:shadow-md transition-shadow">
                <input type="checkbox" 
                       id="prod-${prod.id}" 
                       class="w-4 h-4"
                       onchange="window.taskWizard.toggleProdotto('${prod.id}')">
                <label for="prod-${prod.id}" class="flex-1 cursor-pointer">
                    <div class="flex items-center gap-2">
                        <span class="font-medium">${prod.name}</span>
                        ${isSuggerito ? '<span class="text-xs bg-blue-600 text-white px-2 py-0.5 rounded-full">SUGGERITO</span>' : ''}
                        ${categoryName ? `<span class="text-xs text-gray-500">${categoryName}</span>` : ''}
                    </div>
                    <div class="text-sm text-gray-600">
                        Disponibili: ${prod.quantity} ${prod.unit || 'pz'}
                        ${prod.price ? ` • €${prod.price}/${prod.unit || 'pz'}` : ''}
                    </div>
                </label>
                <input type="number" 
                       id="qta-${prod.id}" 
                       min="1" 
                       max="${prod.quantity}"
                       value="1"
                       class="w-20 px-2 py-1 border rounded"
                       disabled>
            </div>
        `;
    }

    getSuggerimentiPerCategoria() {
        const categoria = (this.wizardData.categoria || '').toLowerCase();
        const mappingSuggerimenti = {
            'elettrico': ['cavo', 'filo', 'interruttore', 'presa', 'lampada', 'led', 'quadro'],
            'idraulico': ['tubo', 'raccordo', 'valvola', 'rubinetto', 'sifone', 'guarnizione'],
            'manutenzione': ['olio', 'filtro', 'cinghia', 'bullone', 'vite'],
            'termoidraulico': ['caldaia', 'radiatore', 'termostato', 'valvola'],
            'climatizzazione': ['condizionatore', 'filtro aria', 'gas refrigerante'],
            'edile': ['cemento', 'malta', 'mattone', 'intonaco', 'pittura'],
            'falegnameria': ['legno', 'compensato', 'vite', 'colla', 'vernice']
        };

        for (const [key, suggerimenti] of Object.entries(mappingSuggerimenti)) {
            if (categoria.includes(key)) {
                return suggerimenti;
            }
        }
        return [];
    }

    toggleProdotto(prodottoId) {
        const checkbox = document.getElementById(`prod-${prodottoId}`);
        const qtyInput = document.getElementById(`qta-${prodottoId}`);
        
        if (checkbox && qtyInput) {
            qtyInput.disabled = !checkbox.checked;
            
            if (checkbox.checked) {
                this.wizardData.componenti.push({
                    prodotto_id: prodottoId,
                    quantita: parseInt(qtyInput.value) || 1
                });
            } else {
                this.wizardData.componenti = this.wizardData.componenti.filter(
                    c => c.prodotto_id !== prodottoId
                );
            }
        }
    }

    async verificaDisponibilita() {
        const container = document.getElementById('wizard-disponibilita-container');
        if (!container) return;

        container.innerHTML = '<div class="text-center py-8"><i data-lucide="loader" class="animate-spin mx-auto"></i></div>';
        lucide.createIcons();

        try {
            const result = await window.availabilityChecker.trovaDipendenteDisponibile(
                new Date(),
                new Date(this.wizardData.scadenza),
                this.wizardData.ore_stimate || 8
            );

            if (result.success && result.candidati && result.candidati.length > 0) {
                container.innerHTML = `
                    <div class="space-y-4">
                        <h4 class="font-semibold text-lg">✅ Dipendenti disponibili trovati</h4>
                        ${result.candidati.map((dip, index) => `
                            <div class="p-4 border rounded ${index === 0 ? 'bg-green-50 border-green-300' : 'bg-gray-50'}">
                                <div class="flex items-center justify-between">
                                    <div>
                                        <div class="font-medium">${dip.nome}</div>
                                        <div class="text-sm text-gray-600">
                                            ${dip.taskAttivi} task attivi • ${dip.oreDisponibili}h libere
                                        </div>
                                        <div class="text-xs text-green-600 font-medium mt-1">
                                            Score: ${dip.score}% ${dip.raccomandato ? '⭐' : ''}
                                        </div>
                                    </div>
                                    <button onclick="window.taskWizard.applicaSuggerimentoDisponibilita('${dip.userId}')"
                                            class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
                                        ${index === 0 ? '⭐ Consigliato' : 'Seleziona'}
                                    </button>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                `;
            } else {
                container.innerHTML = `
                    <div class="text-center py-8 text-gray-500">
                        <i data-lucide="alert-circle" class="w-12 h-12 mx-auto mb-2"></i>
                        <p>Nessun dipendente disponibile nel periodo richiesto</p>
                    </div>
                `;
            }
            
            lucide.createIcons();
        } catch (error) {
            console.error('Errore verifica disponibilità:', error);
            container.innerHTML = `
                <div class="text-center py-8 text-red-600">
                    <i data-lucide="x-circle" class="w-12 h-12 mx-auto mb-2"></i>
                    <p>Errore verifica disponibilità</p>
                </div>
            `;
            lucide.createIcons();
        }
    }

    applicaSuggerimentoDisponibilita(userId) {
        this.wizardData.assigned_user_id = userId;
        this.wizardData.tipo_assegnazione = 'user';
        this.wizardData.disponibilita_verificata = true;
        this.wizardData.suggerimento_accettato = true;
        
        alert('✅ Dipendente selezionato! Procedi alla conferma.');
        this.nextStep();
    }

    async generaRiepilogo() {
        console.log('📋 [WIZARD] generaRiepilogo() chiamato');
        
        const container = document.getElementById('wizard-riepilogo-container');
        if (!container) {
            console.error('❌ [WIZARD] Container wizard-riepilogo-container non trovato!');
            return;
        }

        console.log('📊 [WIZARD] Dati wizard per riepilogo:', this.wizardData);

        // Carica dati cliente, utenti e team
        const clienteNome = document.getElementById('wizard-cliente-select')?.selectedOptions[0]?.text || 'N/D';
        console.log('👤 [WIZARD] Cliente selezionato:', clienteNome);
        
        let assegnazioneHTML = '';
        
        // ASSEGNAZIONE SINGOLA
        if (this.wizardData.tipo_assegnazione === 'user' && this.wizardData.assigned_user_id) {
            console.log('👤 [WIZARD] Caricando utente singolo:', this.wizardData.assigned_user_id);
            
            const { data: user } = await supabaseClient
                .from('users')
                .select('nome, cognome, ruolo, email')
                .eq('id', this.wizardData.assigned_user_id)
                .single();
            
            console.log('✅ [WIZARD] Utente caricato:', user);
            
            if (user) {
                assegnazioneHTML = `
                    <div class="bg-white border border-green-300 rounded-lg p-3">
                        <div class="flex items-center gap-3">
                            <div class="w-10 h-10 rounded-full bg-green-600 text-white flex items-center justify-center font-bold">
                                ${user.nome[0]}${user.cognome[0]}
                            </div>
                            <div class="flex-1">
                                <div class="font-semibold">${user.nome} ${user.cognome}</div>
                                <div class="text-xs text-gray-500">${user.email}</div>
                                <div class="text-xs font-medium text-green-700">${user.ruolo}</div>
                            </div>
                        </div>
                    </div>
                `;
            }
        }
        
        // ASSEGNAZIONE MULTIPLA
        else if (this.wizardData.tipo_assegnazione === 'multi' && this.wizardData.assigned_users?.length > 0) {
            console.log('👥 [WIZARD] Caricando utenti multipli:', this.wizardData.assigned_users.length);
            
            const userIds = this.wizardData.assigned_users.map(u => u.user_id);
            console.log('📋 [WIZARD] IDs utenti:', userIds);
            
            const { data: users } = await supabaseClient
                .from('users')
                .select('id, nome, cognome, ruolo, email')
                .in('id', userIds);
            
            console.log('✅ [WIZARD] Utenti caricati:', users);
            
            assegnazioneHTML = `
                <div class="space-y-2">
                    ${this.wizardData.assigned_users.map(assignment => {
                        const user = users?.find(u => u.id === assignment.user_id);
                        if (!user) return '';
                        return `
                            <div class="bg-white border border-blue-300 rounded-lg p-3">
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-3 flex-1">
                                        <div class="w-10 h-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold">
                                            ${user.nome[0]}${user.cognome[0]}
                                        </div>
                                        <div class="flex-1">
                                            <div class="font-semibold">${user.nome} ${user.cognome}</div>
                                            <div class="text-xs text-gray-500">${user.email}</div>
                                            <div class="text-xs font-medium text-blue-700">${user.ruolo}</div>
                                        </div>
                                    </div>
                                    <div class="text-sm text-gray-600">
                                        ${assignment.ore_assegnate || 0}h
                                    </div>
                                </div>
                            </div>
                        `;
                    }).join('')}
                </div>
            `;
        }
        
        // ASSEGNAZIONE SQUADRA
        else if (this.wizardData.tipo_assegnazione === 'team' && this.wizardData.assigned_team_id) {
            const { data: team } = await supabaseClient
                .from('teams')
                .select('nome, descrizione')
                .eq('id', this.wizardData.assigned_team_id)
                .single();
            
            const { data: members } = await supabaseClient
                .from('team_members')
                .select(`
                    ruolo_team,
                    users:user_id (
                        nome,
                        cognome,
                        ruolo,
                        email
                    )
                `)
                .eq('team_id', this.wizardData.assigned_team_id);
            
            assegnazioneHTML = `
                <div class="bg-purple-50 border border-purple-300 rounded-lg p-4 mb-3">
                    <div class="flex items-center gap-2 mb-2">
                        <i data-lucide="users" class="w-5 h-5 text-purple-600"></i>
                        <span class="font-bold text-purple-900">${team?.nome || 'Squadra'}</span>
                    </div>
                    ${team?.descrizione ? `<p class="text-sm text-gray-600 mb-3">${team.descrizione}</p>` : ''}
                </div>
                <div class="space-y-2">
                    ${members?.map(member => {
                        const user = member.users;
                        return `
                            <div class="bg-white border border-purple-200 rounded-lg p-3">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-full bg-purple-600 text-white flex items-center justify-center font-bold">
                                        ${user.nome[0]}${user.cognome[0]}
                                    </div>
                                    <div class="flex-1">
                                        <div class="font-semibold">${user.nome} ${user.cognome}</div>
                                        <div class="text-xs text-gray-500">${user.email}</div>
                                        <div class="text-xs font-medium text-purple-700">${user.ruolo} • ${member.ruolo_team}</div>
                                    </div>
                                </div>
                            </div>
                        `;
                    }).join('') || '<p class="text-gray-500 text-sm">Nessun membro</p>'}
                </div>
            `;
        }

        // COMPONENTI/PRODOTTI
        let prodottiHTML = '';
        if (this.wizardData.componenti?.length > 0) {
            const productIds = this.wizardData.componenti.map(c => c.prodotto_id);
            const { data: products } = await supabaseClient
                .from('components')
                .select('*')
                .in('id', productIds);
            
            prodottiHTML = `
                <div class="space-y-2">
                    ${this.wizardData.componenti.map(comp => {
                        const product = products?.find(p => p.id === comp.prodotto_id);
                        if (!product) return '';
                        return `
                            <div class="bg-white border border-green-200 rounded-lg p-3 flex items-center justify-between">
                                <div class="flex items-center gap-3">
                                    <div class="w-8 h-8 bg-green-100 rounded flex items-center justify-center">
                                        <i data-lucide="package" class="w-4 h-4 text-green-600"></i>
                                    </div>
                                    <div>
                                        <div class="font-medium text-sm">${product.nome}</div>
                                        <div class="text-xs text-gray-500">${product.sku || product.codice || ''}</div>
                                    </div>
                                </div>
                                <div class="text-sm font-semibold text-green-700">
                                    x${comp.quantita} ${product.unita_misura || 'pz'}
                                </div>
                            </div>
                        `;
                    }).join('')}
                </div>
            `;
        }

        container.innerHTML = `
            <div class="space-y-6">
                <!-- Dati Base -->
                <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <h4 class="font-semibold text-lg mb-3 flex items-center gap-2">
                        <i data-lucide="file-text" class="w-5 h-5"></i>
                        Dati Lavorazione
                    </h4>
                    <div class="space-y-2 text-sm">
                        <div class="flex justify-between">
                            <span class="font-medium">Titolo:</span> 
                            <span class="text-gray-700">${this.wizardData.titolo}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="font-medium">Cliente:</span> 
                            <span class="text-gray-700">${clienteNome}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="font-medium">Priorità:</span> 
                            <span class="text-gray-700">${this.getPrioritaIcon(this.wizardData.priorita)} ${this.wizardData.priorita.toUpperCase()}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="font-medium">Scadenza:</span> 
                            <span class="text-gray-700">${new Date(this.wizardData.scadenza).toLocaleDateString('it-IT')}</span>
                        </div>
                        ${this.wizardData.categoria ? `
                            <div class="flex justify-between">
                                <span class="font-medium">Categoria:</span> 
                                <span class="text-gray-700">${this.wizardData.categoria}</span>
                            </div>
                        ` : ''}
                        ${this.wizardData.descrizione ? `
                            <div class="mt-2 pt-2 border-t">
                                <span class="font-medium block mb-1">Descrizione:</span>
                                <p class="text-gray-600 text-xs">${this.wizardData.descrizione}</p>
                            </div>
                        ` : ''}
                    </div>
                </div>

                <!-- Assegnazione -->
                <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                    <h4 class="font-semibold text-lg mb-3 flex items-center gap-2">
                        <i data-lucide="users" class="w-5 h-5"></i>
                        Assegnazione
                        ${this.wizardData.tipo_assegnazione === 'multi' ? 
                            `<span class="text-xs bg-blue-500 text-white px-2 py-1 rounded-full">${this.wizardData.assigned_users?.length || 0} membri</span>` : ''}
                    </h4>
                    ${assegnazioneHTML || '<p class="text-gray-500 text-sm">Nessuna assegnazione</p>'}
                </div>

                <!-- Dettagli Tecnici -->
                <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
                    <h4 class="font-semibold text-lg mb-3 flex items-center gap-2">
                        <i data-lucide="wrench" class="w-5 h-5"></i>
                        Dettagli Tecnici
                    </h4>
                    <div class="space-y-2 text-sm">
                        <div class="flex justify-between">
                            <span class="font-medium">Ore stimate:</span> 
                            <span class="text-gray-700">${this.wizardData.ore_stimate || 0} h</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="font-medium">Costo stimato:</span> 
                            <span class="text-gray-700">€${this.wizardData.costo_stimato || 0}</span>
                        </div>
                        ${this.wizardData.indirizzo_lavoro ? `
                            <div class="flex justify-between">
                                <span class="font-medium">Indirizzo:</span> 
                                <span class="text-gray-700">${this.wizardData.indirizzo_lavoro}</span>
                            </div>
                        ` : ''}
                    </div>
                </div>

                <!-- Componenti/Prodotti -->
                ${this.wizardData.componenti?.length > 0 ? `
                    <div class="bg-amber-50 border border-amber-200 rounded-lg p-4">
                        <h4 class="font-semibold text-lg mb-3 flex items-center gap-2">
                            <i data-lucide="package" class="w-5 h-5"></i>
                            Materiali Necessari
                            <span class="text-xs bg-amber-500 text-white px-2 py-1 rounded-full">${this.wizardData.componenti.length}</span>
                        </h4>
                        ${prodottiHTML}
                    </div>
                ` : ''}
            </div>
        `;

        lucide.createIcons();
        console.log('✅ [WIZARD] Riepilogo generato con successo');
    }

    getPrioritaIcon(priorita) {
        const icons = {
            'bassa': '🟢',
            'media': '🟡',
            'alta': '🔴'
        };
        return icons[priorita] || '⚪';
    }

    // ===================================
    // POPOLAMENTO FORM
    // ===================================

    populateStep1Form() {
        document.getElementById('wizard-titolo').value = this.wizardData.titolo || '';
        document.getElementById('wizard-cliente-select').value = this.wizardData.cliente_id || '';
        document.getElementById('wizard-descrizione').value = this.wizardData.descrizione || '';
        document.getElementById('wizard-priorita').value = this.wizardData.priorita || 'media';
        document.getElementById('wizard-scadenza').value = this.wizardData.scadenza || '';
        document.getElementById('wizard-categoria').value = this.wizardData.categoria || '';
    }

    populateStep2Form() {
        const radioUser = document.getElementById('wizard-tipo-user');
        const radioTeam = document.getElementById('wizard-tipo-team');
        
        if (this.wizardData.tipo_assegnazione === 'user') {
            radioUser.checked = true;
            document.getElementById('wizard-dipendente-container').classList.remove('hidden');
            document.getElementById('wizard-squadra-container').classList.add('hidden');
        } else {
            radioTeam.checked = true;
            document.getElementById('wizard-dipendente-container').classList.add('hidden');
            document.getElementById('wizard-squadra-container').classList.remove('hidden');
        }
        
        document.getElementById('wizard-dipendente-select').value = this.wizardData.assigned_user_id || '';
        document.getElementById('wizard-squadra-select').value = this.wizardData.assigned_team_id || '';
    }

    populateStep3Form() {
        document.getElementById('wizard-ore-stimate').value = this.wizardData.ore_stimate || '';
        document.getElementById('wizard-costo-stimato').value = this.wizardData.costo_stimato || '';
        document.getElementById('wizard-indirizzo').value = this.wizardData.indirizzo_lavoro || '';
    }

    // ===================================
    // SALVATAGGIO DATI FORM
    // ===================================

    saveStep1Data() {
        this.wizardData.titolo = document.getElementById('wizard-titolo').value;
        this.wizardData.cliente_id = document.getElementById('wizard-cliente-select').value;
        this.wizardData.descrizione = document.getElementById('wizard-descrizione').value;
        this.wizardData.priorita = document.getElementById('wizard-priorita').value;
        this.wizardData.scadenza = document.getElementById('wizard-scadenza').value;
        this.wizardData.categoria = document.getElementById('wizard-categoria').value;
    }

    saveStep2Data() {
        this.wizardData.tipo_assegnazione = document.querySelector('input[name="tipo-assegnazione"]:checked').value;
        this.wizardData.assigned_user_id = document.getElementById('wizard-dipendente-select').value;
        this.wizardData.assigned_team_id = document.getElementById('wizard-squadra-select').value;
    }

    saveStep3Data() {
        this.wizardData.ore_stimate = parseFloat(document.getElementById('wizard-ore-stimate').value) || 0;
        this.wizardData.costo_stimato = parseFloat(document.getElementById('wizard-costo-stimato').value) || 0;
        this.wizardData.indirizzo_lavoro = document.getElementById('wizard-indirizzo').value;
    }

    saveCurrentStepData() {
        switch(this.currentStep) {
            case 1: this.saveStep1Data(); break;
            case 2: this.saveStep2Data(); break;
            case 3: this.saveStep3Data(); break;
        }
    }

    // ===================================
    // SUBMIT FINALE
    // ===================================

    async submitWizard() {
        console.log('🚀 [WIZARD] submitWizard() chiamato');
        
        try {
            console.log('📝 [WIZARD] Salvando dati step corrente...');
            this.saveCurrentStepData();
            
            console.log('📊 [WIZARD] wizardData completo:', JSON.stringify(this.wizardData, null, 2));

            // Crea la lavorazione
            // Per tipo_assegnazione === 'multi', assegniamo al primo utente della lista
            let assignedUserId = null;
            let assignedTeamId = null;
            
            console.log('👥 [WIZARD] Tipo assegnazione:', this.wizardData.tipo_assegnazione);
            
            if (this.wizardData.tipo_assegnazione === 'user') {
                assignedUserId = this.wizardData.assigned_user_id;
                console.log('✅ [WIZARD] Assegnazione singola:', assignedUserId);
            } else if (this.wizardData.tipo_assegnazione === 'team') {
                assignedTeamId = this.wizardData.assigned_team_id;
                console.log('✅ [WIZARD] Assegnazione team:', assignedTeamId);
            } else if (this.wizardData.tipo_assegnazione === 'multi' && this.wizardData.assigned_users && this.wizardData.assigned_users.length > 0) {
                // Per multi-user, assegna al primo utente (required dal constraint)
                // assigned_users può contenere oggetti o solo IDs
                const firstUser = this.wizardData.assigned_users[0];
                assignedUserId = typeof firstUser === 'object' ? firstUser.user_id : firstUser;
                console.log('✅ [WIZARD] Assegnazione multi-utente. Primo utente:', assignedUserId);
                console.log('📋 [WIZARD] Totale utenti assegnati:', this.wizardData.assigned_users.length);
            }
            
            const taskData = {
                titolo: this.wizardData.titolo,
                descrizione: this.wizardData.descrizione,
                client_id: this.wizardData.cliente_id,  // ✅ FIX: client_id non cliente_id
                assigned_user_id: assignedUserId,
                assigned_team_id: assignedTeamId,
                priorita: this.wizardData.priorita,
                scadenza: this.wizardData.scadenza,
                categoria: this.wizardData.categoria,
                ore_stimate: this.wizardData.ore_stimate,
                costo_stimato: this.wizardData.costo_stimato,
                stato: this.wizardData.stato || 'da_fare',
                wizard_completed: true
            };

            let task;
            
            // CHECK se è UPDATE o INSERT
            if (this.wizardData.id) {
                console.log('🔄 [WIZARD] UPDATE task esistente, ID:', this.wizardData.id);
                
                // Prima elimina assegnazioni vecchie
                if (this.wizardData.tipo_assegnazione === 'multi') {
                    await supabaseClient
                        .from('task_assignments')
                        .delete()
                        .eq('task_id', this.wizardData.id);
                    console.log('🗑️ [WIZARD] Assegnazioni vecchie eliminate');
                }
                
                const { data: updatedTask, error: updateError } = await supabaseClient
                    .from('tasks')
                    .update(taskData)
                    .eq('id', this.wizardData.id)
                    .select()
                    .single();

                if (updateError) {
                    console.error('❌ [WIZARD] Errore update task:', updateError);
                    throw updateError;
                }
                
                task = updatedTask;
                console.log('✅ [WIZARD] Task aggiornato con ID:', task.id);
                
            } else {
                console.log('💾 [WIZARD] INSERT nuovo task');
                
                const { data: newTask, error: insertError } = await supabaseClient
                    .from('tasks')
                    .insert([taskData])
                    .select()
                    .single();

                if (insertError) {
                    console.error('❌ [WIZARD] Errore inserimento task:', insertError);
                    throw insertError;
                }
                
                task = newTask;
                console.log('✅ [WIZARD] Task creato con ID:', task.id);
            }

            // Salva assegnazioni multiple se tipo 'multi'
            if (this.wizardData.tipo_assegnazione === 'multi' && this.wizardData.assigned_users && this.wizardData.assigned_users.length > 0) {
                console.log('👥 [WIZARD] Salvando assegnazioni multiple...');
                console.log('📊 [WIZARD] Utenti da assegnare:', this.wizardData.assigned_users);
                
                const assignResult = await window.multiUserAssignment.salvaAssegnazioni(
                    task.id,
                    this.wizardData.assigned_users
                );
                
                if (!assignResult.success) {
                    console.error('❌ [WIZARD] Errore salvataggio assegnazioni:', assignResult.error);
                } else {
                    console.log('✅ [WIZARD] Assegnazioni multiple salvate con successo');
                }
            }

            // Associa componenti se presenti
            if (this.wizardData.componenti.length > 0) {
                console.log('📦 [WIZARD] Salvando', this.wizardData.componenti.length, 'componenti...');
                
                const componentiData = this.wizardData.componenti.map(c => ({
                    task_id: task.id,
                    component_id: c.prodotto_id,
                    quantita: c.quantita
                }));

                const { error: compError } = await supabaseClient
                    .from('task_components')
                    .insert(componentiData);

                if (compError) {
                    console.error('❌ [WIZARD] Errore componenti:', compError);
                } else {
                    console.log('✅ [WIZARD] Componenti salvati con successo');
                }
            }

            console.log('🎉 [WIZARD] Lavorazione completata! Mostrando alert...');
            alert(this.wizardData.id ? '✅ Lavorazione aggiornata con successo!' : '✅ Lavorazione creata con successo!');
            
            console.log('🔄 [WIZARD] Chiudendo wizard...');
            this.closeWizard();
            
            console.log('📋 [WIZARD] Ricaricando lista lavorazioni...');
            // Ricarica lista lavorazioni
            if (typeof loadTasks === 'function') {
                loadTasks();
            }
            
            console.log('✅ [WIZARD] submitWizard() completato con successo');

        } catch (error) {
            console.error('❌ [WIZARD] Errore critico in submitWizard():', error);
            console.error('❌ [WIZARD] Stack trace:', error.stack);
            alert('❌ Errore durante la creazione della lavorazione: ' + error.message);
        }
    }

    closeWizard() {
        const modal = document.getElementById('task-wizard-modal');
        if (modal) {
            modal.classList.add('hidden');
        }
        this.resetData();
    }

    // ===================================
    // RENDER COMPONENTI SELEZIONATI
    // ===================================

    async renderComponentiSelezionati() {
        const container = document.getElementById('wizard-componenti-selezionati');
        if (!container) return;

        if (!this.wizardData.componenti || this.wizardData.componenti.length === 0) {
            container.innerHTML = `
                <div class="text-center text-gray-400 py-8 border-2 border-dashed border-gray-300 rounded-lg">
                    <i data-lucide="package-open" class="w-12 h-12 mx-auto mb-2 opacity-50"></i>
                    <p class="text-sm">Nessun prodotto selezionato</p>
                    <p class="text-xs mt-1">Clicca il bottone sopra per aggiungere materiali</p>
                </div>
            `;
            lucide.createIcons();
            return;
        }

        // Carica dettagli prodotti
        const productIds = this.wizardData.componenti.map(c => c.prodotto_id);
        const { data: products, error } = await supabaseClient
            .from('components')
            .select('*')
            .in('id', productIds);

        if (error) {
            console.error('Errore caricamento dettagli prodotti:', error);
            return;
        }

        container.innerHTML = `
            <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                <div class="flex items-center justify-between mb-3">
                    <h4 class="font-semibold text-green-900 flex items-center gap-2">
                        <i data-lucide="check-circle" class="w-5 h-5"></i>
                        ${this.wizardData.componenti.length} Prodotti Selezionati
                    </h4>
                    <button onclick="window.productScanner.mostraSelezioneProdotti()"
                            class="text-sm text-blue-600 hover:text-blue-800 font-medium">
                        Modifica
                    </button>
                </div>
                <div class="space-y-2">
                    ${this.wizardData.componenti.map(comp => {
                        const product = products.find(p => p.id === comp.prodotto_id);
                        if (!product) return '';
                        return `
                            <div class="bg-white rounded-lg p-3 flex items-center justify-between">
                                <div class="flex items-center gap-3">
                                    <div class="w-8 h-8 bg-blue-100 rounded flex items-center justify-center">
                                        <i data-lucide="package" class="w-4 h-4 text-blue-600"></i>
                                    </div>
                                    <div>
                                        <div class="font-medium text-sm">${product.nome}</div>
                                        <div class="text-xs text-gray-500">${product.sku || product.codice || ''}</div>
                                    </div>
                                </div>
                                <div class="text-sm font-semibold text-green-700">
                                    x${comp.quantita} ${product.unita_misura || 'pz'}
                                </div>
                            </div>
                        `;
                    }).join('')}
                </div>
            </div>
        `;

        lucide.createIcons();
    }

    resetData() {
        this.wizardData = {
            titolo: '',
            cliente_id: null,
            descrizione: '',
            priorita: 'media',
            scadenza: '',
            categoria: '',
            tags: [],
            assigned_user_id: null,
            assigned_team_id: null,
            assigned_users: [],
            tipo_assegnazione: 'user',
            ore_stimate: 0,
            costo_stimato: 0,
            indirizzo_lavoro: '',
            coordinate_gps: null,
            componenti: []
        };
        
        // Reset product scanner
        if (window.productScanner) {
            window.productScanner.reset();
        }
    }

    async renderWizard() {
        // Questa funzione verrà chiamata per creare l'HTML del wizard
        // Verrà implementata nel file HTML
    }
}

// Inizializza wizard globale
window.taskWizard = new TaskWizard();
