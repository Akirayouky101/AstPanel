/**
 * ================================================
 * TASK CREATION WIZARD - Sistema Guidato Creazione Lavorazioni
 * ================================================
 * 5 Step workflow per creare lavorazioni complete
 */

class TaskWizard {
    constructor() {
        this.currentStep = 1;
        this.totalSteps = 5;
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
            assigned_users: [], // NUOVO: Array per multi-utente
            tipo_assegnazione: 'user', // 'user', 'multi' o 'team'
            
            // Step 3: Dettagli e Componenti
            ore_stimate: 0,
            costo_stimato: 0,
            indirizzo_lavoro: '',
            coordinate_gps: null,
            componenti: [], // {prodotto_id, quantita, note}
            
            // Step 4: Disponibilità verificata
            disponibilita_verificata: false,
            suggerimento_accettato: false,
            
            // Step 5: Conferma (autogenerata)
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
                await this.verificaDisponibilita();
                break;
            case 5:
                this.generaRiepilogo();
                break;
        }
    }

    async loadClienti() {
        try {
            const { data, error } = await supabaseClient
                .from('clients')
                .select('*')
                .order('nome');
            
            if (error) throw error;
            
            const select = document.getElementById('wizard-cliente-select');
            if (select) {
                select.innerHTML = '<option value="">Seleziona cliente...</option>';
                data.forEach(cliente => {
                    const option = document.createElement('option');
                    option.value = cliente.id;
                    option.textContent = cliente.nome;
                    select.appendChild(option);
                });
            }
        } catch (error) {
            console.error('Errore caricamento clienti:', error);
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
                .from('warehouse_products')
                .select('*')
                .gt('quantita_disponibile', 0)
                .order('nome');
            
            if (error) throw error;

            const container = document.getElementById('wizard-prodotti-container');
            if (container) {
                container.innerHTML = data.map(prod => `
                    <div class="flex items-center gap-3 p-3 bg-gray-50 rounded border">
                        <input type="checkbox" 
                               id="prod-${prod.id}" 
                               class="w-4 h-4"
                               onchange="window.taskWizard.toggleProdotto('${prod.id}')">
                        <label for="prod-${prod.id}" class="flex-1">
                            <div class="font-medium">${prod.nome}</div>
                            <div class="text-sm text-gray-600">Disponibili: ${prod.quantita_disponibile}</div>
                        </label>
                        <input type="number" 
                               id="qta-${prod.id}" 
                               min="1" 
                               max="${prod.quantita_disponibile}"
                               value="1"
                               class="w-20 px-2 py-1 border rounded"
                               disabled>
                    </div>
                `).join('');
            }
        } catch (error) {
            console.error('Errore caricamento prodotti:', error);
        }
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

            if (result.success && result.dipendenti.length > 0) {
                container.innerHTML = `
                    <div class="space-y-4">
                        <h4 class="font-semibold text-lg">✅ Dipendenti disponibili trovati</h4>
                        ${result.dipendenti.map((dip, index) => `
                            <div class="p-4 border rounded ${index === 0 ? 'bg-green-50 border-green-300' : 'bg-gray-50'}">
                                <div class="flex items-center justify-between">
                                    <div>
                                        <div class="font-medium">${dip.nome_completo}</div>
                                        <div class="text-sm text-gray-600">
                                            ${dip.task_attivi} task attivi • ${dip.ore_disponibili} ore libere
                                        </div>
                                    </div>
                                    <button onclick="window.taskWizard.applicaSuggerimentoDisponibilita('${dip.user_id}')"
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

    generaRiepilogo() {
        const container = document.getElementById('wizard-riepilogo-container');
        if (!container) return;

        const clienteNome = document.getElementById('wizard-cliente-select')?.selectedOptions[0]?.text || 'N/D';
        const dipendenteNome = document.getElementById('wizard-dipendente-select')?.selectedOptions[0]?.text || 'N/D';

        container.innerHTML = `
            <div class="space-y-6">
                <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <h4 class="font-semibold text-lg mb-3">📋 Dati Lavorazione</h4>
                    <div class="space-y-2 text-sm">
                        <div><span class="font-medium">Titolo:</span> ${this.wizardData.titolo}</div>
                        <div><span class="font-medium">Cliente:</span> ${clienteNome}</div>
                        <div><span class="font-medium">Priorità:</span> ${this.wizardData.priorita}</div>
                        <div><span class="font-medium">Scadenza:</span> ${new Date(this.wizardData.scadenza).toLocaleDateString('it-IT')}</div>
                        ${this.wizardData.categoria ? `<div><span class="font-medium">Categoria:</span> ${this.wizardData.categoria}</div>` : ''}
                    </div>
                </div>

                <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                    <h4 class="font-semibold text-lg mb-3">👤 Assegnazione</h4>
                    <div class="space-y-2 text-sm">
                        <div><span class="font-medium">Tipo:</span> ${this.wizardData.tipo_assegnazione === 'user' ? 'Dipendente' : 'Squadra'}</div>
                        <div><span class="font-medium">Assegnato a:</span> ${dipendenteNome}</div>
                        ${this.wizardData.suggerimento_accettato ? '<div class="text-green-600">✅ Suggerimento automatico applicato</div>' : ''}
                    </div>
                </div>

                <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
                    <h4 class="font-semibold text-lg mb-3">⚙️ Dettagli Tecnici</h4>
                    <div class="space-y-2 text-sm">
                        <div><span class="font-medium">Ore stimate:</span> ${this.wizardData.ore_stimate} h</div>
                        <div><span class="font-medium">Costo stimato:</span> €${this.wizardData.costo_stimato}</div>
                        ${this.wizardData.indirizzo_lavoro ? `<div><span class="font-medium">Indirizzo:</span> ${this.wizardData.indirizzo_lavoro}</div>` : ''}
                        ${this.wizardData.componenti.length > 0 ? `<div><span class="font-medium">Componenti:</span> ${this.wizardData.componenti.length} prodotti</div>` : ''}
                    </div>
                </div>
            </div>
        `;
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
        try {
            this.saveCurrentStepData();

            // Crea la lavorazione
            const taskData = {
                titolo: this.wizardData.titolo,
                descrizione: this.wizardData.descrizione,
                cliente_id: this.wizardData.cliente_id,
                assigned_user_id: this.wizardData.tipo_assegnazione === 'user' ? this.wizardData.assigned_user_id : null,
                assigned_team_id: this.wizardData.tipo_assegnazione === 'team' ? this.wizardData.assigned_team_id : null,
                priorita: this.wizardData.priorita,
                scadenza: this.wizardData.scadenza,
                categoria: this.wizardData.categoria,
                ore_stimate: this.wizardData.ore_stimate,
                costo_stimato: this.wizardData.costo_stimato,
                indirizzo_lavoro: this.wizardData.indirizzo_lavoro,
                stato: 'da_iniziare',
                wizard_completed: true
            };

            const { data: task, error: taskError } = await supabaseClient
                .from('tasks')
                .insert([taskData])
                .select()
                .single();

            if (taskError) throw taskError;

            // Salva assegnazioni multiple se tipo 'multi'
            if (this.wizardData.tipo_assegnazione === 'multi' && this.wizardData.assigned_users && this.wizardData.assigned_users.length > 0) {
                const assignResult = await window.multiUserAssignment.salvaAssegnazioni(
                    task.id,
                    this.wizardData.assigned_users
                );
                
                if (!assignResult.success) {
                    console.error('Errore salvataggio assegnazioni:', assignResult.error);
                }
            }

            // Associa componenti se presenti
            if (this.wizardData.componenti.length > 0) {
                const componentiData = this.wizardData.componenti.map(c => ({
                    task_id: task.id,
                    prodotto_id: c.prodotto_id,
                    quantita_richiesta: c.quantita
                }));

                const { error: compError } = await supabaseClient
                    .from('task_components')
                    .insert(componentiData);

                if (compError) console.error('Errore componenti:', compError);
            }

            alert('✅ Lavorazione creata con successo!');
            this.closeWizard();
            
            // Ricarica lista lavorazioni
            if (typeof loadTasks === 'function') {
                loadTasks();
            }

        } catch (error) {
            console.error('Errore creazione lavorazione:', error);
            alert('❌ Errore durante la creazione della lavorazione');
        }
    }

    closeWizard() {
        const modal = document.getElementById('task-wizard-modal');
        if (modal) {
            modal.classList.add('hidden');
        }
        this.resetData();
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
            tipo_assegnazione: 'user',
            ore_stimate: 0,
            costo_stimato: 0,
            indirizzo_lavoro: '',
            coordinate_gps: null,
            componenti: [],
            disponibilita_verificata: false,
            suggerimento_accettato: false
        };
    }

    async renderWizard() {
        // Questa funzione verrà chiamata per creare l'HTML del wizard
        // Verrà implementata nel file HTML
    }
}

// Inizializza wizard globale
window.taskWizard = new TaskWizard();
