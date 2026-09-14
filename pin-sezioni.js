// Accesso alle sezioni protette da PIN (flag "PIN Attivo" in Gestione utenti).
// Uso: const ok = await PinSezioni.proteggi({ sezione: 'Contabilità', ritorno: '/admin-functional.html' });
// Le RPC sono definite in add-pin-sezioni.sql; la verifica vale 30 minuti lato server.
(function () {
    const sb = () => window.supabase || window.supabaseClient;
    let timerScadenza = null;

    const escapeHtml = value => String(value ?? '').replace(/[&<>'"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[c]));
    const minuti = secondi => Math.max(1, Math.ceil(secondi / 60));

    function rimuovi(id) { document.getElementById(id)?.remove(); }

    function mostraBlocco({ sezione, ritorno, titolo, messaggio }) {
        rimuovi('pinSezioniOverlay');
        const overlay = document.createElement('div');
        overlay.id = 'pinSezioniOverlay';
        overlay.className = 'fixed inset-0 z-[100] bg-gray-950/80 backdrop-blur-sm flex items-center justify-center p-4';
        overlay.innerHTML = `
            <div class="bg-white w-full max-w-md rounded-2xl shadow-2xl overflow-hidden text-center" role="alertdialog" aria-modal="true">
                <div class="bg-red-600 text-white px-6 py-5"><i class="fas fa-user-lock text-3xl mb-2"></i><h2 class="text-xl font-bold">${escapeHtml(titolo)}</h2></div>
                <div class="p-6 space-y-4">
                    <p class="text-gray-700">${messaggio}</p>
                    <p class="text-sm text-gray-500">Sezione: <strong>${escapeHtml(sezione)}</strong></p>
                    <a href="${escapeHtml(ritorno)}" class="inline-block px-6 py-3 bg-indigo-700 hover:bg-indigo-800 text-white rounded-xl font-bold"><i class="fas fa-arrow-left mr-2"></i>Torna al menu</a>
                </div>
            </div>`;
        document.body.appendChild(overlay);
    }

    function chiediPin({ sezione, ritorno, nome }) {
        return new Promise(resolve => {
            rimuovi('pinSezioniOverlay');
            const overlay = document.createElement('div');
            overlay.id = 'pinSezioniOverlay';
            overlay.className = 'fixed inset-0 z-[100] bg-gray-950/80 backdrop-blur-sm flex items-center justify-center p-4';
            overlay.innerHTML = `
                <form id="pinSezioniForm" class="bg-white w-full max-w-md rounded-2xl shadow-2xl overflow-hidden" role="dialog" aria-modal="true" aria-labelledby="pinSezioniTitolo">
                    <div class="bg-indigo-700 text-white px-6 py-5 text-center"><i class="fas fa-lock text-3xl mb-2"></i><h2 id="pinSezioniTitolo" class="text-xl font-bold">Sezione protetta</h2><p class="text-indigo-100 text-sm">${escapeHtml(sezione)}${nome ? ` · ${escapeHtml(nome)}` : ''}</p></div>
                    <div class="p-6 space-y-4">
                        <label class="block text-center"><span class="block text-sm font-semibold text-gray-700 mb-2">Inserisci il tuo PIN</span>
                            <input id="pinSezioniInput" type="password" inputmode="numeric" autocomplete="one-time-code" pattern="\\d{4,8}" maxlength="8" required class="w-56 mx-auto block text-center tracking-[0.6em] text-3xl font-bold border-2 border-indigo-200 rounded-xl px-4 py-3 focus:border-indigo-600 focus:outline-none" placeholder="••••"></label>
                        <p id="pinSezioniErrore" class="hidden p-3 rounded-lg bg-red-100 text-red-800 text-sm font-semibold text-center"></p>
                        <div class="flex gap-3">
                            <a href="${escapeHtml(ritorno)}" class="flex-1 text-center px-4 py-3 border-2 border-gray-200 rounded-xl font-semibold text-gray-700 hover:bg-gray-50">Annulla</a>
                            <button id="pinSezioniConferma" type="submit" class="flex-1 px-4 py-3 bg-indigo-700 hover:bg-indigo-800 text-white rounded-xl font-bold"><i class="fas fa-unlock mr-2"></i>Sblocca</button>
                        </div>
                        <p class="text-xs text-gray-400 text-center">L'accesso resta attivo per 30 minuti. Dopo 5 tentativi errati il PIN viene bloccato per 10 minuti.</p>
                    </div>
                </form>`;
            document.body.appendChild(overlay);
            const input = overlay.querySelector('#pinSezioniInput');
            const errore = overlay.querySelector('#pinSezioniErrore');
            const bottone = overlay.querySelector('#pinSezioniConferma');
            setTimeout(() => input.focus(), 50);
            input.addEventListener('input', () => { input.value = input.value.replace(/\D/g, ''); });

            overlay.querySelector('#pinSezioniForm').addEventListener('submit', async event => {
                event.preventDefault();
                errore.classList.add('hidden');
                bottone.disabled = true;
                try {
                    const { data, error } = await sb().rpc('verifica_pin_sezioni', { p_pin: input.value });
                    if (error) throw error;
                    if (data?.ok) {
                        rimuovi('pinSezioniOverlay');
                        programmaScadenza(data.secondi_residui, { sezione, ritorno, nome });
                        return resolve(true);
                    }
                    const messaggi = {
                        errato: `PIN errato. Tentativi rimasti: ${data?.tentativi_residui ?? '-'}`,
                        bloccato: `PIN bloccato per troppi tentativi. Riprova tra ${minuti(data?.bloccato_secondi || 600)} minuti.`,
                        non_abilitato: 'Il tuo utente non è abilitato a questa sezione.',
                        pin_non_impostato: 'PIN non impostato: chiedi a un amministratore di configurarlo in Gestione utenti.'
                    };
                    errore.textContent = messaggi[data?.motivo] || 'Verifica non riuscita';
                    errore.classList.remove('hidden');
                    input.value = '';
                    input.focus();
                } catch (err) {
                    errore.textContent = err.message || 'Verifica non riuscita';
                    errore.classList.remove('hidden');
                } finally {
                    bottone.disabled = false;
                }
            });
        });
    }

    // Alla scadenza server-side richiede di nuovo il PIN, così le query non falliscono in silenzio.
    function programmaScadenza(secondi, opzioni) {
        clearTimeout(timerScadenza);
        if (!secondi) return;
        timerScadenza = setTimeout(async () => {
            const ok = await chiediPin(opzioni);
            if (ok && typeof opzioni.onRiapertura === 'function') opzioni.onRiapertura();
        }, Math.max(1000, (secondi - 5) * 1000));
    }

    window.PinSezioni = {
        // Risolve true se l'utente può usare la sezione (flag attivo + PIN verificato), altrimenti mostra il blocco e risolve false.
        async proteggi({ sezione = 'Sezione protetta', ritorno = '/admin-functional.html', nome = '', onRiapertura = null } = {}) {
            const { data, error } = await sb().rpc('pin_sezioni_stato');
            if (error) {
                mostraBlocco({ sezione, ritorno, titolo: 'Verifica non disponibile', messaggio: escapeHtml(error.message || 'Impossibile verificare i permessi.') });
                return false;
            }
            if (!data?.abilitato) {
                const messaggio = data?.motivo === 'pin_non_impostato'
                    ? 'Il tuo utente ha il PIN attivo ma nessun PIN impostato. Chiedi a un amministratore di impostarlo in <strong>Gestione utenti</strong>.'
                    : 'Il tuo utente non è abilitato a questa sezione. Un amministratore può attivare la spunta <strong>PIN Attivo</strong> in Gestione utenti.';
                mostraBlocco({ sezione, ritorno, titolo: 'Accesso non autorizzato', messaggio });
                return false;
            }
            const opzioni = { sezione, ritorno, nome, onRiapertura };
            if (data.verificato) {
                programmaScadenza(data.secondi_residui, opzioni);
                return true;
            }
            return chiediPin(opzioni);
        },

        async chiudi() {
            clearTimeout(timerScadenza);
            await sb().rpc('chiudi_pin_sezioni');
        }
    };
})();
