/**
 * ================================================
 * MULTI-USER ASSIGNMENT SYSTEM
 * ================================================
 * Gestione assegnazione multipla utenti alle lavorazioni
 */

class MultiUserAssignment {
    constructor() {
        this.selectedUsers = [];
        this.suggestedUsers = [];
    }

    // ===================================
    // SUGGERIMENTO AUTOMATICO
    // ===================================

    async mostraSuggerimentoMultiUtente() {
        // Chiedi numero membri
        const numeroMembri = await this.chiediNumeroMembri();
        if (!numeroMembri || numeroMembri < 1) return;

        // Mostra modal con suggerimenti
        await this.mostraModalSuggerimenti(numeroMembri);
    }

    async chiediNumeroMembri() {
        return new Promise((resolve) => {
            const modal = document.createElement('div');
            modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4';
            modal.innerHTML = `
                <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8">
                    <div class="text-center mb-6">
                        <i data-lucide="users" class="w-16 h-16 mx-auto mb-4 text-blue-600"></i>
                        <h3 class="text-2xl font-bold text-gray-800 mb-2">Suggerimento Automatico</h3>
                        <p class="text-gray-600">Quanti membri servono per questa lavorazione?</p>
                    </div>

                    <div class="mb-6">
                        <label class="block text-sm font-medium text-gray-700 mb-2">Numero membri richiesti</label>
                        <input type="number" id="numero-membri-input" min="1" max="10" value="2"
                               class="w-full px-4 py-3 border border-gray-300 rounded-lg text-center text-2xl font-bold focus:ring-2 focus:ring-blue-500">
                    </div>

                    <div class="flex gap-3">
                        <button onclick="this.closest('.fixed').remove()" 
                                class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100">
                            Annulla
                        </button>
                        <button id="conferma-numero-btn"
                                class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                            Suggerisci →
                        </button>
                    </div>
                </div>
            `;

            document.body.appendChild(modal);
            lucide.createIcons();

            // Focus su input
            const input = document.getElementById('numero-membri-input');
            input.focus();
            input.select();

            // Handler conferma
            document.getElementById('conferma-numero-btn').addEventListener('click', () => {
                const numero = parseInt(input.value) || 0;
                modal.remove();
                resolve(numero);
            });

            // Enter key
            input.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    document.getElementById('conferma-numero-btn').click();
                }
            });
        });
    }

    async mostraModalSuggerimenti(numeroMembri) {
        // Crea modal
        const modal = document.createElement('div');
        modal.id = 'multi-user-suggestion-modal';
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4';
        modal.innerHTML = `
            <div class="bg-white rounded-2xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
                <div class="sticky top-0 bg-gradient-to-r from-blue-600 to-purple-600 text-white p-6 rounded-t-2xl">
                    <div class="flex items-center justify-between">
                        <div>
                            <h2 class="text-2xl font-bold mb-1">🤖 Suggerimenti AI - ${numeroMembri} Membri</h2>
                            <p class="text-white text-opacity-90">Dipendenti più disponibili ordinati per score</p>
                        </div>
                        <button onclick="this.closest('.fixed').remove()" class="text-white hover:text-gray-200">
                            <i data-lucide="x" class="w-6 h-6"></i>
                        </button>
                    </div>
                </div>

                <div class="p-8">
                    <div id="suggerimenti-loading" class="text-center py-12">
                        <i data-lucide="loader" class="w-12 h-12 mx-auto mb-4 animate-spin text-blue-600"></i>
                        <p class="text-gray-600">Analizzando disponibilità...</p>
                    </div>

                    <div id="suggerimenti-container" class="hidden space-y-3">
                        <!-- Qui verranno inseriti i suggerimenti -->
                    </div>

                    <div class="mt-8 pt-6 border-t flex justify-between items-center">
                        <div>
                            <span id="selected-count" class="text-sm text-gray-600">0 membri selezionati</span>
                        </div>
                        <div class="flex gap-3">
                            <button onclick="this.closest('.fixed').remove()" 
                                    class="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100">
                                Annulla
                            </button>
                            <button id="applica-selezione-btn"
                                    class="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
                                    disabled>
                                Applica Selezione
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);
        lucide.createIcons();

        // Carica suggerimenti
        await this.caricaSuggerimenti(numeroMembri);
    }

    async caricaSuggerimenti(numeroMembri) {
        try {
            const { data, error } = await supabaseClient.rpc('trova_n_dipendenti_disponibili', {
                p_data_inizio: new Date().toISOString().split('T')[0],
                p_data_fine: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                p_ore_necessarie: 8,
                p_numero_dipendenti: Math.max(numeroMembri + 3, 10) // Mostra più opzioni
            });

            if (error) throw error;

            this.suggestedUsers = data || [];
            this.renderSuggerimenti(numeroMembri);

        } catch (error) {
            console.error('Errore caricamento suggerimenti:', error);
            document.getElementById('suggerimenti-loading').innerHTML = `
                <i data-lucide="alert-circle" class="w-12 h-12 mx-auto mb-4 text-red-600"></i>
                <p class="text-red-600">Errore caricamento suggerimenti</p>
            `;
            lucide.createIcons();
        }
    }

    renderSuggerimenti(numeroConsigliato) {
        const container = document.getElementById('suggerimenti-container');
        const loading = document.getElementById('suggerimenti-loading');

        if (this.suggestedUsers.length === 0) {
            loading.innerHTML = `
                <i data-lucide="users-x" class="w-12 h-12 mx-auto mb-4 text-gray-400"></i>
                <p class="text-gray-600">Nessun dipendente disponibile</p>
            `;
            lucide.createIcons();
            return;
        }

        loading.classList.add('hidden');
        container.classList.remove('hidden');

        container.innerHTML = this.suggestedUsers.map((user, index) => {
            const isConsigliato = index < numeroConsigliato;
            const badgeColor = isConsigliato ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600';
            const borderColor = isConsigliato ? 'border-green-300 bg-green-50' : 'border-gray-200';

            return `
                <div class="border-2 ${borderColor} rounded-xl p-4 hover:shadow-lg transition-all cursor-pointer user-suggestion-card"
                     data-user-id="${user.user_id}"
                     onclick="window.multiUserAssignment.toggleUserSelection('${user.user_id}', this)">
                    <div class="flex items-center gap-4">
                        <!-- Checkbox -->
                        <input type="checkbox" 
                               class="w-5 h-5 text-blue-600 rounded user-checkbox"
                               data-user-id="${user.user_id}"
                               ${isConsigliato ? 'checked' : ''}
                               onclick="event.stopPropagation();"
                               onchange="window.multiUserAssignment.handleCheckboxChange('${user.user_id}', this)">

                        <!-- Badge Posizione -->
                        <div class="flex-shrink-0">
                            <div class="w-12 h-12 rounded-full ${isConsigliato ? 'bg-green-600' : 'bg-gray-400'} text-white flex items-center justify-center font-bold text-lg">
                                ${index + 1}°
                            </div>
                        </div>

                        <!-- Info Utente -->
                        <div class="flex-1">
                            <div class="flex items-center gap-2 mb-1">
                                <h4 class="font-bold text-lg">${user.nome_completo}</h4>
                                ${isConsigliato ? '<span class="' + badgeColor + ' text-xs font-semibold px-2 py-1 rounded-full">⭐ CONSIGLIATO</span>' : ''}
                            </div>
                            <p class="text-sm text-gray-600">${user.email} • ${user.ruolo}</p>
                        </div>

                        <!-- Stats -->
                        <div class="text-right">
                            <div class="text-2xl font-bold ${user.score >= 75 ? 'text-green-600' : user.score >= 50 ? 'text-yellow-600' : 'text-red-600'}">
                                ${user.score}%
                            </div>
                            <div class="text-xs text-gray-500">Score</div>
                        </div>

                        <div class="text-right">
                            <div class="text-lg font-bold text-blue-600">${user.ore_disponibili}h</div>
                            <div class="text-xs text-gray-500">Disponibili</div>
                        </div>

                        <div class="text-right">
                            <div class="text-lg font-bold text-gray-600">${user.task_attivi}</div>
                            <div class="text-xs text-gray-500">Task attivi</div>
                        </div>
                    </div>
                </div>
            `;
        }).join('');

        lucide.createIcons();

        // Pre-seleziona i consigliati
        this.selectedUsers = this.suggestedUsers
            .slice(0, numeroConsigliato)
            .map(u => u.user_id);
        
        this.updateSelectedCount();
    }

    toggleUserSelection(userId, cardElement) {
        const checkbox = cardElement.querySelector('.user-checkbox');
        checkbox.checked = !checkbox.checked;
        this.handleCheckboxChange(userId, checkbox);
    }

    handleCheckboxChange(userId, checkbox) {
        if (checkbox.checked) {
            if (!this.selectedUsers.includes(userId)) {
                this.selectedUsers.push(userId);
            }
        } else {
            this.selectedUsers = this.selectedUsers.filter(id => id !== userId);
        }

        this.updateSelectedCount();
    }

    updateSelectedCount() {
        const countEl = document.getElementById('selected-count');
        const applyBtn = document.getElementById('applica-selezione-btn');

        if (countEl) {
            countEl.textContent = `${this.selectedUsers.length} membri selezionati`;
        }

        if (applyBtn) {
            applyBtn.disabled = this.selectedUsers.length === 0;
        }
    }

    applicaSelezione() {
        const selectedUsersData = this.suggestedUsers.filter(u => 
            this.selectedUsers.includes(u.user_id)
        );

        // Chiudi modal
        document.getElementById('multi-user-suggestion-modal')?.remove();

        // Applica selezione al form/wizard
        this.popolaListaUtentiSelezionati(selectedUsersData);

        // Mostra notifica
        this.mostraNotifica(`✅ ${selectedUsersData.length} membri selezionati!`);
    }

    popolaListaUtentiSelezionati(users) {
        // Per wizard
        const wizardContainer = document.getElementById('wizard-multi-users-container');
        if (wizardContainer) {
            this.renderListaUtenti(wizardContainer, users);
        }

        // Per form classico
        const classicContainer = document.getElementById('classic-multi-users-container');
        if (classicContainer) {
            this.renderListaUtenti(classicContainer, users);
        }

        // Salva in wizard data se esiste
        if (window.taskWizard) {
            window.taskWizard.wizardData.assigned_users = users.map(u => ({
                user_id: u.user_id,
                nome_completo: u.nome_completo,
                ruolo_assegnazione: 'membro'
            }));
        }
    }

    renderListaUtenti(container, users) {
        if (!container) return;

        container.innerHTML = `
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
                <div class="flex items-center justify-between mb-3">
                    <h4 class="font-semibold text-blue-900">👥 ${users.length} Membri Assegnati</h4>
                    <button onclick="window.multiUserAssignment.mostraSuggerimentoMultiUtente()"
                            class="text-sm text-blue-600 hover:text-blue-800 font-medium">
                        🔄 Modifica
                    </button>
                </div>
                <div class="space-y-2">
                    ${users.map((user, index) => `
                        <div class="bg-white rounded-lg p-3 flex items-center justify-between">
                            <div class="flex items-center gap-3">
                                <div class="w-8 h-8 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold text-sm">
                                    ${index + 1}
                                </div>
                                <div>
                                    <div class="font-medium">${user.nome_completo}</div>
                                    <div class="text-xs text-gray-500">${user.email}</div>
                                </div>
                            </div>
                            <div class="flex items-center gap-2">
                                <select class="text-sm border rounded px-2 py-1" 
                                        onchange="window.multiUserAssignment.updateUserRole('${user.user_id}', this.value)">
                                    <option value="membro">Membro</option>
                                    <option value="responsabile">Responsabile</option>
                                    <option value="supporto">Supporto</option>
                                </select>
                                <button onclick="window.multiUserAssignment.rimuoviUtente('${user.user_id}')"
                                        class="text-red-600 hover:text-red-800">
                                    <i data-lucide="x" class="w-4 h-4"></i>
                                </button>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
        lucide.createIcons();
    }

    updateUserRole(userId, ruolo) {
        if (window.taskWizard && window.taskWizard.wizardData.assigned_users) {
            const user = window.taskWizard.wizardData.assigned_users.find(u => u.user_id === userId);
            if (user) {
                user.ruolo_assegnazione = ruolo;
            }
        }
    }

    rimuoviUtente(userId) {
        if (window.taskWizard && window.taskWizard.wizardData.assigned_users) {
            window.taskWizard.wizardData.assigned_users = 
                window.taskWizard.wizardData.assigned_users.filter(u => u.user_id !== userId);
            
            const wizardContainer = document.getElementById('wizard-multi-users-container');
            if (wizardContainer) {
                this.renderListaUtenti(wizardContainer, window.taskWizard.wizardData.assigned_users);
            }
        }
    }

    mostraNotifica(messaggio) {
        const notifica = document.createElement('div');
        notifica.className = 'fixed top-4 right-4 bg-green-600 text-white px-6 py-3 rounded-lg shadow-lg z-50 animate-slide-in';
        notifica.textContent = messaggio;
        document.body.appendChild(notifica);

        setTimeout(() => {
            notifica.remove();
        }, 3000);
    }

    async salvaAssegnazioni(taskId, users) {
        try {
            const assignments = users.map(user => ({
                task_id: taskId,
                user_id: user.user_id,
                ruolo_assegnazione: user.ruolo_assegnazione || 'membro',
                ore_assegnate: 0
            }));

            const { error } = await supabaseClient
                .from('task_assignments')
                .insert(assignments);

            if (error) throw error;

            return { success: true };
        } catch (error) {
            console.error('Errore salvataggio assegnazioni:', error);
            return { success: false, error };
        }
    }
}

// Inizializza globalmente
window.multiUserAssignment = new MultiUserAssignment();

// Setup event handler per apply button
document.addEventListener('click', (e) => {
    if (e.target.id === 'applica-selezione-btn') {
        window.multiUserAssignment.applicaSelezione();
    }
});
