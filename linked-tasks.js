/**
 * ============================================================
 * LINKED-TASKS.JS — Gestione Interventi Collegati
 * ============================================================
 * Modulo condiviso per collegare lavorazioni correlate.
 * Una lavorazione "madre" (parent_task_id IS NULL) può avere
 * più interventi figli che la referenziano tramite parent_task_id.
 * Tutti i figli puntano sempre alla madre, mai ad altri figli.
 * ============================================================
 */

(function () {
    'use strict';

    // ── STATO INTERNO ──────────────────────────────────────────
    let _parentId   = null;  // UUID della lavorazione madre selezionata
    let _parentData = null;  // { id, titolo, stato, progresso, cliente }
    let _siblings   = [];
    let _ctx        = 'wizard'; // 'wizard' | 'form'

    // Helper ID in base al contesto
    function _inputId()   { return _ctx === 'form' ? 'form-parent-task-id' : 'wizard-parent-task-id'; }
    function _displayId() { return _ctx === 'form' ? 'form-linked-display'  : 'wizard-linked-tasks-display'; }

    // ── HELPER INTERNI ─────────────────────────────────────────
    const _statoConf = {
        da_fare:    { cls: 'bg-gray-100 text-gray-600',   color: '#6b7280', label: 'Da fare',    icon: '○' },
        in_corso:   { cls: 'bg-blue-100 text-blue-700',   color: '#2563eb', label: 'In corso',   icon: '◎' },
        revisione:  { cls: 'bg-yellow-100 text-yellow-700', color: '#d97706', label: 'Revisione', icon: '△' },
        completato: { cls: 'bg-green-100 text-green-700', color: '#059669', label: 'Completato', icon: '✓' },
        annullato:  { cls: 'bg-red-100 text-red-600',     color: '#dc2626', label: 'Annullato',  icon: '✕' }
    };

    function _progColor(p) {
        return p >= 80 ? '#10b981' : p >= 40 ? '#f59e0b' : '#6366f1';
    }

    function _svgLink() {
        return `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                     fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/>
                  <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>
                </svg>`;
    }

    // ── MODAL (creata una sola volta su richiesta) ─────────────
    function _ensureModal() {
        if (document.getElementById('linkedTaskPickerModal')) return;
        const modal = document.createElement('div');
        modal.id = 'linkedTaskPickerModal';
        modal.className = 'hidden fixed inset-0 z-[9999] flex items-center justify-center p-4';
        modal.style.background = 'rgba(0,0,0,0.6)';
        modal.style.backdropFilter = 'blur(4px)';
        modal.innerHTML = `
            <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md flex flex-col overflow-hidden" style="max-height:85vh">
                <!-- Header -->
                <div style="background:linear-gradient(135deg,#7c3aed,#6d28d9);padding:16px 20px;display:flex;align-items:center;justify-content:space-between;flex-shrink:0">
                    <div style="display:flex;align-items:center;gap:12px">
                        <div style="width:36px;height:36px;background:rgba(255,255,255,0.2);border-radius:10px;display:flex;align-items:center;justify-content:center">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
                        </div>
                        <div>
                            <p style="color:white;font-weight:700;font-size:14px;margin:0">Collega Intervento</p>
                            <p style="color:rgba(255,255,255,0.75);font-size:12px;margin:0">Solo lavorazioni aperte — stesso cliente</p>
                        </div>
                    </div>
                    <button onclick="window.LinkedTasks.closePicker()"
                            style="width:32px;height:32px;background:rgba(255,255,255,0.2);border:none;border-radius:10px;cursor:pointer;display:flex;align-items:center;justify-content:center;color:white"
                            onmouseover="this.style.background='rgba(255,255,255,0.3)'"
                            onmouseout="this.style.background='rgba(255,255,255,0.2)'">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
                    </button>
                </div>
                <!-- Ricerca -->
                <div style="padding:12px;border-bottom:1px solid #f3f4f6;flex-shrink:0">
                    <div style="position:relative">
                        <svg style="position:absolute;left:12px;top:50%;transform:translateY(-50%);width:16px;height:16px;color:#9ca3af;pointer-events:none" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
                        <input id="linkedPickerSearch" type="text" placeholder="Cerca per titolo..."
                               oninput="window.LinkedTasks._filterPicker(this.value)"
                               style="width:100%;padding:10px 16px 10px 38px;background:#f9fafb;border:1px solid #e5e7eb;border-radius:12px;font-size:13px;outline:none;box-sizing:border-box"
                               onfocus="this.style.borderColor='#a78bfa';this.style.boxShadow='0 0 0 3px rgba(167,139,250,0.2)'"
                               onblur="this.style.borderColor='#e5e7eb';this.style.boxShadow='none'">
                    </div>
                </div>
                <!-- Lista -->
                <div id="linkedPickerList" style="overflow-y:auto;flex:1;padding:8px"></div>
                <div id="linkedPickerEmpty" class="hidden" style="padding:40px 20px;text-align:center">
                    <div style="width:48px;height:48px;background:#f5f3ff;border-radius:14px;display:flex;align-items:center;justify-content:center;margin:0 auto 12px">
                        <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
                    </div>
                    <p style="font-size:14px;font-weight:600;color:#4b5563;margin:0 0 4px">Nessuna lavorazione aperta</p>
                    <p style="font-size:12px;color:#9ca3af;margin:0">Prova a cambiare cliente o titolo</p>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
        // Chiudi cliccando backdrop
        modal.addEventListener('click', function (e) {
            if (e.target === modal) window.LinkedTasks.closePicker();
        });
    }

    // ── ELENCO TASK NEL PICKER ─────────────────────────────────
    function _renderPickerList(tasks) {
        const listEl  = document.getElementById('linkedPickerList');
        const emptyEl = document.getElementById('linkedPickerEmpty');
        if (!listEl) return;

        if (!tasks || tasks.length === 0) {
            listEl.innerHTML = '';
            emptyEl && emptyEl.classList.remove('hidden');
            return;
        }
        emptyEl && emptyEl.classList.add('hidden');

        listEl.innerHTML = tasks.map(t => {
            const sc   = _statoConf[t.stato] || _statoConf.da_fare;
            const prog = t.progresso || 0;
            const pc   = _progColor(prog);
            const cliente = t.clients?.ragione_sociale || '';
            const tEsc = t.titolo.replace(/\\/g,'\\\\').replace(/'/g,"\\'").replace(/"/g,'&quot;');
            const cEsc = cliente.replace(/\\/g,'\\\\').replace(/'/g,"\\'").replace(/"/g,'&quot;');
            return `
                <button onclick="window.LinkedTasks.selectTask('${t.id}','${tEsc}','${t.stato}',${prog},'${cEsc}')"
                        style="width:100%;text-align:left;display:flex;align-items:center;gap:12px;padding:10px 12px;background:none;border:none;border-radius:12px;cursor:pointer;border-bottom:1px solid #f9fafb;transition:background .15s"
                        onmouseover="this.style.background='#f5f3ff'"
                        onmouseout="this.style.background='none'">
                    <div style="width:36px;height:36px;background:#f5f3ff;border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
                    </div>
                    <div style="flex:1;min-width:0">
                        <p style="font-size:13px;font-weight:600;color:#111827;margin:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${t.titolo}</p>
                        <div style="display:flex;align-items:center;gap:6px;margin-top:4px;flex-wrap:wrap">
                            <span style="font-size:11px;${sc.cls.includes('blue')?'background:#dbeafe;color:#1d4ed8':sc.cls.includes('yellow')?'background:#fef3c7;color:#92400e':'background:#f3f4f6;color:#4b5563'};padding:2px 8px;border-radius:20px;font-weight:600">${sc.label}</span>
                            <div style="display:flex;align-items:center;gap:4px">
                                <div style="width:36px;height:4px;background:#f3f4f6;border-radius:2px"><div style="height:4px;border-radius:2px;width:${prog}%;background:${pc}"></div></div>
                                <span style="font-size:11px;color:#6b7280;font-weight:600">${prog}%</span>
                            </div>
                            ${cliente ? `<span style="font-size:11px;color:#9ca3af;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:120px">• ${cliente}</span>` : ''}
                        </div>
                    </div>
                    <div style="width:26px;height:26px;background:#7c3aed;border-radius:8px;display:flex;align-items:center;justify-content:center;flex-shrink:0">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
                    </div>
                </button>
            `;
        }).join('');
    }

    // ── API PUBBLICA ───────────────────────────────────────────
    window.LinkedTasks = {

        /** Resetta lo stato (nuovo wizard) */
        reset() {
            _ctx = 'wizard';
            _parentId   = null;
            _parentData = null;
            _siblings   = [];
            const inp = document.getElementById('wizard-parent-task-id');
            if (inp) inp.value = '';
            if (window.taskWizard) window.taskWizard.wizardData.parent_task_id = null;
            this.renderDisplay();
        },

        /** Resetta per il form modal */
        resetForm() {
            _ctx = 'form';
            _parentId   = null;
            _parentData = null;
            _siblings   = [];
            const inp = document.getElementById('form-parent-task-id');
            if (inp) inp.value = '';
            this.renderDisplay();
        },

        /** Carica i dati collegati per una task in modifica */
        async loadForEdit(task) {
            _ctx = 'wizard';
            return this._loadLinked(task, 'wizard-parent-task-id');
        },

        /** Carica i dati collegati per il form modal di modifica */
        async loadForForm(task) {
            _ctx = 'form';
            return this._loadLinked(task, 'form-parent-task-id');
        },

        async _loadLinked(task, inputId) {
            if (!task || !task.parent_task_id) {
                _parentId = null; _parentData = null; _siblings = [];
                const i = document.getElementById(inputId); if (i) i.value = '';
                if (inputId === 'wizard-parent-task-id' && window.taskWizard) window.taskWizard.wizardData.parent_task_id = null;
                this.renderDisplay(); return;
            }

            _parentId = task.parent_task_id;
            const inp = document.getElementById(inputId);
            if (inp) inp.value = task.parent_task_id;
            if (inputId === 'wizard-parent-task-id' && window.taskWizard) window.taskWizard.wizardData.parent_task_id = task.parent_task_id;

            try {
                const { data: parent } = await supabaseClient
                    .from('tasks')
                    .select('id, titolo, stato, progresso, clients:client_id(ragione_sociale)')
                    .eq('id', task.parent_task_id)
                    .single();

                if (parent) {
                    _parentData = {
                        id:       parent.id,
                        titolo:   parent.titolo,
                        stato:    parent.stato,
                        progresso: parent.progresso || 0,
                        cliente:  parent.clients?.ragione_sociale || ''
                    };

                    const { data: siblings } = await supabaseClient
                        .from('tasks')
                        .select('id, titolo, stato, progresso, scadenza')
                        .eq('parent_task_id', task.parent_task_id)
                        .neq('id', task.id)
                        .order('created_at', { ascending: true });

                    _siblings = siblings || [];
                }
            } catch (e) {
                console.warn('[LinkedTasks] Errore caricamento collegamento:', e);
            }

            this.renderDisplay();
        },

        /** Apre il picker delle lavorazioni da collegare (contesto wizard) */
        async openPicker() {
            _ctx = 'wizard';
            const clientId  = document.getElementById('wizard-cliente-select')?.value || '';
            const currentId = window.taskWizard?.wizardData?.id || null;
            return this._openPickerCore(clientId, currentId);
        },

        /** Apre il picker per il form modal di modifica */
        async openPickerForForm(currentTaskId) {
            _ctx = 'form';
            const clientId = document.getElementById('formClient')?.value || '';
            return this._openPickerCore(clientId, currentTaskId);
        },

        /** Picker per il wizard del calendario (evita conflitti di ID con il wizard condiviso) */
        async _calWizardOpenPicker(clientId, titolo) {
            _ctx = 'wizard';
            return this._openPickerCore(clientId || '', null);
        },

        async _openPickerCore(clientId, currentId) {
            _ensureModal();
            const searchEl = document.getElementById('linkedPickerSearch');
            if (searchEl) searchEl.value = '';

            let query = supabaseClient
                .from('tasks')
                .select('id, titolo, stato, progresso, scadenza, clients:client_id(ragione_sociale)')
                .not('stato', 'in', '("completato","annullato")')
                .is('parent_task_id', null);  // Solo madri — mai figli

            if (clientId)  query = query.eq('client_id', clientId);
            if (currentId) query = query.neq('id', currentId);
            if (_parentId) query = query.neq('id', _parentId);

            query = query.order('updated_at', { ascending: false }).limit(40);

            const { data: tasks, error } = await query;
            if (error) console.warn('[LinkedTasks] Errore picker:', error);

            _renderPickerList(tasks || []);
            document.getElementById('linkedTaskPickerModal').classList.remove('hidden');
        },

        /** Chiude il picker */
        closePicker() {
            const m = document.getElementById('linkedTaskPickerModal');
            if (m) m.classList.add('hidden');
        },

        /** Seleziona una task come madre */
        selectTask(id, titolo, stato, progresso, cliente) {
            _parentId   = id;
            _parentData = { id, titolo, stato, progresso: parseInt(progresso) || 0, cliente };
            _siblings   = [];
            const inp = document.getElementById(_inputId());
            if (inp) inp.value = id;
            if (_ctx === 'wizard' && window.taskWizard) window.taskWizard.wizardData.parent_task_id = id;
            this.renderDisplay();
            this.closePicker();
        },

        /** Rimuove il collegamento (wizard) */
        clearLink() {
            _ctx = 'wizard';
            _parentId = null; _parentData = null; _siblings = [];
            const inp = document.getElementById('wizard-parent-task-id');
            if (inp) inp.value = '';
            if (window.taskWizard) window.taskWizard.wizardData.parent_task_id = null;
            this.renderDisplay();
        },

        /** Rimuove il collegamento (form modal) */
        clearLinkForm() {
            _ctx = 'form';
            _parentId = null; _parentData = null; _siblings = [];
            const inp = document.getElementById('form-parent-task-id');
            if (inp) inp.value = '';
            this.renderDisplay();
        },

        getParentId() { return _parentId; },

        /** Renderizza il blocco nel contesto attivo */
        renderDisplay() {
            const container = document.getElementById(_displayId());
            if (!container) return;

            if (!_parentId || !_parentData) {
                if (_ctx === 'form') {
                    // Nel form mostra badge "Principale" + opzione per collegare
                    container.innerHTML = `
                        <div style="display:flex;align-items:center;gap:10px;background:white;border:1.5px solid #c4b5fd;border-radius:12px;padding:10px 12px">
                            <div style="width:32px;height:32px;background:#f5f3ff;border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                            </div>
                            <div style="flex:1">
                                <p style="font-size:12px;font-weight:700;color:#5b21b6;margin:0 0 1px">Lavorazione Principale</p>
                                <p style="font-size:11px;color:#8b5cf6;margin:0">Questa è la lavorazione madre — altri interventi possono essere collegati ad essa</p>
                            </div>
                            <span style="font-size:10px;background:#ede9fe;color:#6d28d9;padding:3px 8px;border-radius:20px;font-weight:700;white-space:nowrap">MADRE</span>
                        </div>`;
                } else {
                    container.innerHTML = `
                        <p style="font-size:12px;color:#a78bfa;text-align:center;padding:10px 0;margin:0">
                            Nessun intervento collegato — lavorazione indipendente
                        </p>`;
                }
                return;
            }

            const t    = _parentData;
            const prog = t.progresso || 0;
            const pc   = _progColor(prog);
            const sc   = _statoConf[t.stato] || _statoConf.da_fare;

            container.innerHTML = `
                <div style="display:flex;align-items:center;gap:10px;background:white;border:1.5px solid #ddd6fe;border-radius:14px;padding:10px 12px">
                    <div style="width:34px;height:34px;background:#f5f3ff;border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0;color:#7c3aed">
                        ${_svgLink()}
                    </div>
                    <div style="flex:1;min-width:0">
                        <p style="font-size:13px;font-weight:600;color:#111827;margin:0 0 4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${t.titolo}</p>
                        <div style="display:flex;align-items:center;gap:6px">
                            <span style="font-size:11px;background:${sc.cls.includes('blue')?'#dbeafe':sc.cls.includes('yellow')?'#fef3c7':'#f3f4f6'};color:${sc.color};padding:2px 7px;border-radius:20px;font-weight:600">${sc.label}</span>
                            <div style="display:flex;align-items:center;gap:3px">
                                <div style="width:32px;height:4px;background:#e5e7eb;border-radius:2px"><div style="height:4px;border-radius:2px;width:${prog}%;background:${pc}"></div></div>
                                <span style="font-size:11px;color:#6b7280;font-weight:600">${prog}%</span>
                            </div>
                        </div>
                    </div>
                    <button onclick="_ctx==='form'?window.LinkedTasks.clearLinkForm():window.LinkedTasks.clearLink()"
                            style="width:28px;height:28px;background:#fef2f2;border:none;border-radius:8px;cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0;color:#f87171"
                            onmouseover="this.style.background='#fee2e2';this.style.color='#dc2626'"
                            onmouseout="this.style.background='#fef2f2';this.style.color='#f87171'"
                            title="Rimuovi collegamento">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
                    </button>
                </div>
                ${_siblings.length > 0 ? `
                <p style="font-size:11px;color:#7c3aed;margin:6px 0 0 4px;display:flex;align-items:center;gap:4px">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="6" y1="3" x2="6" y2="15"/><circle cx="18" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M18 9a9 9 0 0 1-9 9"/></svg>
                    Altri ${_siblings.length} intervento${_siblings.length > 1 ? 'i' : ''} in questo cantiere
                </p>` : ''}
            `;
        },

        /** Filtra la lista nel picker (chiamato da oninput) */
        _filterPicker(q) {
            const rows = document.querySelectorAll('#linkedPickerList button');
            const lq = q.toLowerCase();
            rows.forEach(row => { row.style.display = row.textContent.toLowerCase().includes(lq) ? '' : 'none'; });
        },

        /**
         * Costruisce l'HTML della timeline per il modal di dettaglio.
         * Restituisce '' se non ci sono interventi collegati.
         */
        async buildTimelineForTask(task) {
            if (!task) return '';

            let allLinked = [];
            try {
                if (task.parent_task_id) {
                    // Figlio → mostra madre + tutti i fratelli
                    const { data } = await supabaseClient
                        .from('tasks')
                        .select('id, titolo, stato, progresso, scadenza, data_inizio, created_at')
                        .or(`id.eq.${task.parent_task_id},parent_task_id.eq.${task.parent_task_id}`)
                        .neq('id', task.id)
                        .order('created_at', { ascending: true });
                    allLinked = data || [];
                } else {
                    // Madre → mostra tutti i figli
                    const { data } = await supabaseClient
                        .from('tasks')
                        .select('id, titolo, stato, progresso, scadenza, data_inizio, created_at')
                        .eq('parent_task_id', task.id)
                        .order('created_at', { ascending: true });
                    allLinked = data || [];
                }
            } catch (e) {
                console.warn('[LinkedTasks] Errore timeline:', e);
                return '';
            }

            if (allLinked.length === 0) return '';

            const isRoot  = !task.parent_task_id;
            const rootId  = task.parent_task_id || task.id;
            const total   = allLinked.length + 1;  // +1 per la task corrente

            const allItems = isRoot
                ? [...allLinked]                         // figli
                : allLinked.filter(t => t.id === rootId)   // madre in cima
                    .concat(allLinked.filter(t => t.id !== rootId));  // poi fratelli

            return `
                <div style="border-top:2px solid #f3f4f6;padding-top:20px;margin-top:4px">
                    <h3 style="display:flex;align-items:center;gap:8px;font-size:15px;font-weight:700;color:#1f2937;margin:0 0 16px">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
                        Storico Interventi Collegati
                        <span style="margin-left:auto;font-size:11px;font-weight:600;color:#7c3aed;background:#f5f3ff;border:1px solid #ddd6fe;padding:3px 10px;border-radius:20px">${total} interventi</span>
                    </h3>

                    <div style="position:relative">
                        <!-- Task corrente -->
                        <div style="display:flex;gap:14px;margin-bottom:0">
                            <div style="display:flex;flex-direction:column;align-items:center;flex-shrink:0">
                                <div style="width:32px;height:32px;background:linear-gradient(135deg,#7c3aed,#ec4899);border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-size:13px;font-weight:800;flex-shrink:0">★</div>
                                ${allItems.length > 0 ? '<div style="width:2px;background:#e9d5ff;flex:1;margin:4px 0;min-height:16px"></div>' : ''}
                            </div>
                            <div style="flex:1;padding-bottom:${allItems.length > 0 ? 16 : 0}px">
                                <div style="background:linear-gradient(135deg,#f5f3ff,#fdf4ff);border:2px solid #c4b5fd;border-radius:14px;padding:12px 14px">
                                    <span style="font-size:10px;font-weight:700;color:#7c3aed;text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:3px">◀ Lavorazione corrente</span>
                                    <div style="display:flex;align-items:center;justify-content:space-between;gap:8px">
                                        <p style="font-size:13px;font-weight:600;color:#1f2937;margin:0;flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${task.titolo}</p>
                                        <span style="font-size:20px;font-weight:900;color:#7c3aed;flex-shrink:0">${task.progresso || 0}%</span>
                                    </div>
                                    <div style="margin-top:6px;width:100%;height:6px;background:#ddd6fe;border-radius:3px">
                                        <div style="height:6px;border-radius:3px;background:linear-gradient(to right,#7c3aed,#a855f7);width:${task.progresso || 0}%;transition:width .3s"></div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        ${allItems.map((t, i) => {
                            const sc   = _statoConf[t.stato] || _statoConf.da_fare;
                            const prog = t.progresso || 0;
                            const pc   = _progColor(prog);
                            const isLast = i === allItems.length - 1;
                            const isMother = t.id === rootId && !isRoot;
                            const dateStr  = t.scadenza
                                ? new Date(t.scadenza + 'T00:00:00').toLocaleDateString('it-IT', { day: 'numeric', month: 'short', year: '2-digit' })
                                : '';
                            return `
                                <div style="display:flex;gap:14px">
                                    <div style="display:flex;flex-direction:column;align-items:center;flex-shrink:0">
                                        <div style="width:32px;height:32px;background:${sc.color};border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-size:13px;font-weight:700;flex-shrink:0;border:2px solid white;box-shadow:0 0 0 2px ${sc.color}">${sc.icon}</div>
                                        ${!isLast ? '<div style="width:2px;background:#e5e7eb;flex:1;margin:4px 0;min-height:16px"></div>' : ''}
                                    </div>
                                    <div style="flex:1;padding-bottom:${!isLast ? 14 : 0}px">
                                        <div style="background:white;border:1.5px solid #e5e7eb;border-radius:14px;padding:11px 14px;transition:all .2s"
                                             onmouseover="this.style.borderColor='#c4b5fd';this.style.boxShadow='0 2px 8px rgba(124,58,237,.08)'"
                                             onmouseout="this.style.borderColor='#e5e7eb';this.style.boxShadow='none'">
                                            ${isMother ? '<span style="font-size:10px;font-weight:700;color:#f59e0b;text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:2px">⭐ Lavorazione principale</span>' : ''}
                                            <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px">
                                                <div style="flex:1;min-width:0">
                                                    <p style="font-size:13px;font-weight:600;color:#1f2937;margin:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${t.titolo}</p>
                                                    ${dateStr ? `<span style="font-size:11px;color:#9ca3af;display:block;margin-top:2px">${dateStr}</span>` : ''}
                                                </div>
                                                <div style="text-align:right;flex-shrink:0">
                                                    <span style="font-size:15px;font-weight:800;color:${sc.color}">${prog}%</span>
                                                    <span style="display:block;font-size:10px;font-weight:600;color:${sc.color};background:${sc.cls.includes('blue')?'#dbeafe':sc.cls.includes('yellow')?'#fef3c7':sc.cls.includes('green')?'#d1fae5':sc.cls.includes('red')?'#fee2e2':'#f3f4f6'};padding:2px 7px;border-radius:8px;margin-top:2px">${sc.label}</span>
                                                </div>
                                            </div>
                                            <div style="margin-top:7px;width:100%;height:4px;background:#f3f4f6;border-radius:2px">
                                                <div style="height:4px;border-radius:2px;width:${prog}%;background:${pc};transition:width .3s"></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            `;
                        }).join('')}
                    </div>
                </div>
            `;
        }
    };

})();
