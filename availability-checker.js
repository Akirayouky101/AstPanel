/**
 * ⚡ AVAILABILITY CHECKER - Sistema Intelligente Disponibilità
 * 
 * Features:
 * - Check veloce dipendente più disponibile
 * - Dashboard disponibilità settimana corrente
 * - Suggerimento automatico nel wizard lavorazioni
 * - Calcolo carico lavoro real-time
 */

class AvailabilityChecker {
    constructor() {
        this.supabase = window.supabaseClient;
    }

    /**
     * 🚀 CHECK VELOCE URGENZE
     * Restituisce IL dipendente più disponibile ADESSO
     */
    async checkUrgenzaVeloce() {
        try {
            const { data, error } = await this.supabase
                .rpc('check_urgenza_veloce');

            if (error) throw error;

            if (data && data.length > 0) {
                const consigliato = data[0];
                return {
                    success: true,
                    consigliato: {
                        userId: consigliato.consigliato_user_id,
                        nome: consigliato.consigliato_nome,
                        motivo: consigliato.motivo,
                        oreDisponibili: consigliato.ore_disponibili,
                        taskAttivi: consigliato.task_attivi
                    }
                };
            }

            return {
                success: false,
                message: '❌ Nessun dipendente disponibile al momento'
            };
        } catch (error) {
            console.error('❌ Errore check urgenza:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * 📊 DASHBOARD DISPONIBILITÀ
     * Mostra tutti i dipendenti con stato disponibilità
     */
    async getDashboardDisponibilita() {
        try {
            // Usa la funzione invece della VIEW per bypassare RLS
            const { data, error } = await this.supabase
                .rpc('get_dashboard_disponibilita');

            if (error) throw error;

            return {
                success: true,
                dipendenti: data.map(d => ({
                    userId: d.user_id,
                    nome: d.nome_completo,
                    email: d.email,
                    ruolo: d.ruolo,
                    taskAttivi: d.task_attivi,
                    oreImpegnate: d.ore_impegnate,
                    oreDisponibili: d.ore_disponibili,
                    stato: d.stato_disponibilita,
                    priorita: d.priorita,
                    icona: this.getStatoIcon(d.stato_disponibilita),
                    colore: this.getStatoColor(d.stato_disponibilita)
                }))
            };
        } catch (error) {
            console.error('❌ Errore dashboard:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * 🔍 TROVA DIPENDENTE DISPONIBILE
     * Con parametri personalizzati
     */
    async trovaDipendenteDisponibile(dataInizio, dataFine, oreNecessarie = 8, ruolo = null) {
        try {
            const { data, error } = await this.supabase
                .rpc('trova_dipendente_disponibile', {
                    p_data_inizio: dataInizio,
                    p_data_fine: dataFine,
                    p_ore_necessarie: oreNecessarie,
                    p_ruolo: ruolo
                });

            if (error) throw error;

            return {
                success: true,
                candidati: data.map(d => ({
                    userId: d.user_id,
                    nome: d.nome_completo,
                    email: d.email,
                    ruolo: d.ruolo,
                    taskAttivi: d.task_attivi,
                    oreImpegnate: d.ore_impegnate,
                    oreDisponibili: d.ore_disponibili,
                    percentualeDisponibilita: d.percentuale_disponibilita,
                    score: d.score,
                    raccomandato: d.score >= 80
                }))
            };
        } catch (error) {
            console.error('❌ Errore ricerca disponibile:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * 📈 CALCOLA CARICO LAVORO
     * Per un singolo dipendente
     */
    async calcolaCaricοLavoro(userId, dataInizio, dataFine) {
        try {
            const { data, error } = await this.supabase
                .rpc('calcola_carico_lavoro', {
                    p_user_id: userId,
                    p_data_inizio: dataInizio,
                    p_data_fine: dataFine
                });

            if (error) throw error;

            if (data && data.length > 0) {
                const carico = data[0];
                return {
                    success: true,
                    carico: {
                        userId: carico.user_id,
                        taskAttivi: carico.task_attivi,
                        oreImpegnate: carico.ore_impegnate,
                        percentualeCarico: carico.percentuale_carico,
                        stato: this.getStatoFromPercentuale(carico.percentuale_carico)
                    }
                };
            }

            return {
                success: true,
                carico: {
                    userId: userId,
                    taskAttivi: 0,
                    oreImpegnate: 0,
                    percentualeCarico: 0,
                    stato: 'molto_disponibile'
                }
            };
        } catch (error) {
            console.error('❌ Errore calcolo carico:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * 🎨 Helper: Icona per stato
     */
    getStatoIcon(stato) {
        const icons = {
            'molto_disponibile': '✅',
            'disponibile': '🟢',
            'quasi_pieno': '🟡',
            'occupato': '🔴'
        };
        return icons[stato] || '⚪';
    }

    /**
     * 🎨 Helper: Colore per stato
     */
    getStatoColor(stato) {
        const colors = {
            'molto_disponibile': 'green',
            'disponibile': 'blue',
            'quasi_pieno': 'orange',
            'occupato': 'red'
        };
        return colors[stato] || 'gray';
    }

    /**
     * 🎨 Helper: Stato da percentuale
     */
    getStatoFromPercentuale(percentuale) {
        if (percentuale >= 100) return 'occupato';
        if (percentuale >= 75) return 'quasi_pieno';
        if (percentuale >= 40) return 'disponibile';
        return 'molto_disponibile';
    }

    /**
     * 🚨 MOSTRA ALERT CHECK VELOCE
     * UI rapida per urgenze
     */
    async mostraCheckVeloce() {
        const result = await this.checkUrgenzaVeloce();

        if (result.success) {
            const c = result.consigliato;
            const html = `
                <div class="bg-white rounded-xl shadow-2xl p-6 max-w-md">
                    <div class="text-center mb-4">
                        <div class="text-6xl mb-3">⚡</div>
                        <h3 class="text-2xl font-bold text-gray-800 mb-2">Check Veloce Disponibilità</h3>
                        <p class="text-gray-600">Dipendente più disponibile ADESSO</p>
                    </div>
                    
                    <div class="bg-gradient-to-r from-green-50 to-emerald-100 rounded-xl p-5 mb-4 border-2 border-green-200">
                        <div class="flex items-center justify-between mb-3">
                            <div class="text-3xl">👤</div>
                            <span class="bg-green-500 text-white text-xs font-bold px-3 py-1 rounded-full">CONSIGLIATO</span>
                        </div>
                        <h4 class="text-xl font-bold text-gray-800 mb-2">${c.nome}</h4>
                        <p class="text-sm text-gray-700 mb-3">${c.motivo}</p>
                        
                        <div class="grid grid-cols-2 gap-3 text-sm">
                            <div class="bg-white rounded-lg p-3 text-center">
                                <div class="text-2xl font-bold text-green-600">${c.oreDisponibili}h</div>
                                <div class="text-xs text-gray-600">Ore Disponibili</div>
                            </div>
                            <div class="bg-white rounded-lg p-3 text-center">
                                <div class="text-2xl font-bold text-blue-600">${c.taskAttivi}</div>
                                <div class="text-xs text-gray-600">Task Attivi</div>
                            </div>
                        </div>
                    </div>
                    
                    <button onclick="window.availabilityChecker.closeCheckVeloce()" 
                            class="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-3 rounded-xl transition-colors">
                        ✓ Perfetto!
                    </button>
                </div>
            `;

            this.showModal(html);
        } else {
            alert(result.message || 'Errore nel controllo disponibilità');
        }
    }

    /**
     * 📊 MOSTRA DASHBOARD COMPLETA
     */
    async mostraDashboardCompleta() {
        const result = await this.getDashboardDisponibilita();

        if (!result.success) {
            alert('Errore nel caricamento della dashboard');
            return;
        }

        const rows = result.dipendenti.map(d => `
            <tr class="hover:bg-gray-50 transition-colors">
                <td class="px-4 py-3 border-b">
                    <div class="flex items-center gap-3">
                        <span class="text-2xl">${d.icona}</span>
                        <div>
                            <div class="font-semibold text-gray-800">${d.nome}</div>
                            <div class="text-xs text-gray-500">${d.email}</div>
                        </div>
                    </div>
                </td>
                <td class="px-4 py-3 border-b text-center">
                    <span class="px-3 py-1 rounded-full text-xs font-bold ${this.getStatoBadgeClass(d.stato)}">
                        ${this.getStatoLabel(d.stato)}
                    </span>
                </td>
                <td class="px-4 py-3 border-b text-center font-semibold text-gray-700">${d.taskAttivi}</td>
                <td class="px-4 py-3 border-b text-center font-semibold text-orange-600">${d.oreImpegnate}h</td>
                <td class="px-4 py-3 border-b text-center font-semibold text-green-600">${d.oreDisponibili}h</td>
            </tr>
        `).join('');

        const html = `
            <div class="bg-white rounded-xl shadow-2xl max-w-4xl w-full max-h-[80vh] overflow-hidden flex flex-col">
                <div class="bg-gradient-to-r from-blue-600 to-purple-600 text-white p-6">
                    <div class="flex items-center justify-between">
                        <div>
                            <h3 class="text-2xl font-bold mb-2">📊 Dashboard Disponibilità</h3>
                            <p class="text-blue-100">Panoramica completa prossimi 7 giorni</p>
                        </div>
                        <button onclick="window.availabilityChecker.closeDashboard()" 
                                class="text-white hover:bg-white hover:bg-opacity-20 rounded-lg p-2 transition-colors">
                            <i data-lucide="x" class="w-6 h-6"></i>
                        </button>
                    </div>
                </div>
                
                <div class="overflow-y-auto flex-1 p-6">
                    <table class="w-full">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-4 py-3 text-left text-xs font-bold text-gray-600 uppercase">Dipendente</th>
                                <th class="px-4 py-3 text-center text-xs font-bold text-gray-600 uppercase">Stato</th>
                                <th class="px-4 py-3 text-center text-xs font-bold text-gray-600 uppercase">Task Attivi</th>
                                <th class="px-4 py-3 text-center text-xs font-bold text-gray-600 uppercase">Ore Impegnate</th>
                                <th class="px-4 py-3 text-center text-xs font-bold text-gray-600 uppercase">Ore Disponibili</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${rows}
                        </tbody>
                    </table>
                </div>
            </div>
        `;

        this.showModal(html);
        lucide.createIcons(); // Re-render icons
    }

    getStatoBadgeClass(stato) {
        const classes = {
            'molto_disponibile': 'bg-green-100 text-green-800',
            'disponibile': 'bg-blue-100 text-blue-800',
            'quasi_pieno': 'bg-orange-100 text-orange-800',
            'occupato': 'bg-red-100 text-red-800'
        };
        return classes[stato] || 'bg-gray-100 text-gray-800';
    }

    getStatoLabel(stato) {
        const labels = {
            'molto_disponibile': 'Molto Disponibile',
            'disponibile': 'Disponibile',
            'quasi_pieno': 'Quasi Pieno',
            'occupato': 'Occupato'
        };
        return labels[stato] || 'Sconosciuto';
    }

    showModal(html) {
        const overlay = document.createElement('div');
        overlay.id = 'availabilityModal';
        overlay.className = 'fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm flex items-center justify-center z-50 p-4';
        overlay.innerHTML = html;
        document.body.appendChild(overlay);
    }

    closeCheckVeloce() {
        const modal = document.getElementById('availabilityModal');
        if (modal) modal.remove();
    }

    closeDashboard() {
        const modal = document.getElementById('availabilityModal');
        if (modal) modal.remove();
    }
}

// Inizializza globalmente
window.AvailabilityChecker = AvailabilityChecker;

// Auto-init
document.addEventListener('DOMContentLoaded', () => {
    if (window.supabaseClient) {
        window.availabilityChecker = new AvailabilityChecker();
        console.log('✅ AvailabilityChecker initialized');
    }
});
