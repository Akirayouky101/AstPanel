/**
 * wizard-helpers.js
 * Shared helper functions for the Task Wizard modal.
 * Included by: gestione-lavorazioni.html, calendario-admin.html
 */

// ===== STATE VARIABLES =====
var _dpYear, _dpMonth, _dpSelectedDate, _dpTargetInput, _dpTargetLabel, _dpTargetColor, _dpMode;
var _wizardGiornate = [];
var _dpMonthNames = ['Gennaio','Febbraio','Marzo','Aprile','Maggio','Giugno','Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre'];
var _clientPickerAllClients = [];
var _wizardMultiAllUsers = [];
var _wizardMultiSelected = [];

// ===== PRIORITY PILLS =====
function setPriorityBtn(group, value) {
    document.querySelectorAll(`[data-priority-group="${group}"]`).forEach(btn => {
        const isActive = btn.dataset.priority === value;
        btn.dataset.active = isActive ? 'true' : 'false';
        btn.classList.remove(
            'border-green-400','bg-green-100','text-green-700',
            'border-yellow-400','bg-yellow-100','text-yellow-700',
            'border-red-400','bg-red-100','text-red-700',
            'border-gray-200','bg-white','text-gray-500'
        );
        if (isActive) {
            if (value === 'bassa')       btn.classList.add('border-green-400','bg-green-100','text-green-700');
            else if (value === 'media') btn.classList.add('border-yellow-400','bg-yellow-100','text-yellow-700');
            else if (value === 'alta')  btn.classList.add('border-red-400','bg-red-100','text-red-700');
        } else {
            btn.classList.add('border-gray-200','bg-white','text-gray-500');
        }
    });
    const sel = document.getElementById(group);
    if (sel) sel.value = value;
}

function syncPriorityBtns(group) {
    const sel = document.getElementById(group);
    if (sel) setPriorityBtn(group, sel.value);
}

// ===== CLIENT PICKER =====
async function openWizardClientPicker() {
    window._clientPickerCallback = function(id, nome) {
        document.getElementById('wizard-cliente-select').value = id;
        var lbl = document.getElementById('wizardClientPickerLabel');
        lbl.innerHTML = '<i data-lucide="building-2" class="w-4 h-4 inline mr-2 text-blue-600"></i><span class="text-gray-800 font-semibold">' + nome + '</span>';
        lbl.classList.remove('text-gray-400');
        document.getElementById('wizardClientPickerActions').classList.remove('hidden');
        lucide.createIcons();
        closeClientPicker();
    };
    document.getElementById('clientPickerModal').classList.remove('hidden');
    document.getElementById('clientPickerSearch').value = '';
    lucide.createIcons();
    try {
        _clientPickerAllClients = await window.dataManager.getClienti();
        window._wizardClientiCache = _clientPickerAllClients;
        renderClientPickerList(_clientPickerAllClients);
    } catch (e) {
        document.getElementById('clientPickerList').innerHTML =
            '<p class="p-6 text-center text-red-500 text-sm">Errore nel caricamento clienti</p>';
    }
}

function clearWizardClientPicker() {
    document.getElementById('wizard-cliente-select').value = '';
    var lbl = document.getElementById('wizardClientPickerLabel');
    lbl.innerHTML = '<i data-lucide="search" class="w-4 h-4 inline mr-2 text-blue-400"></i>Seleziona cliente...';
    lbl.classList.add('text-gray-400');
    document.getElementById('wizardClientPickerActions').classList.add('hidden');
    lucide.createIcons();
}

function closeClientPicker() {
    document.getElementById('clientPickerModal').classList.add('hidden');
    toggleAddClientForm(false);
}

function filterClientPickerList() {
    var q = document.getElementById('clientPickerSearch').value.toLowerCase().trim();
    if (!q) { renderClientPickerList(_clientPickerAllClients); return; }
    var filtered = _clientPickerAllClients.filter(function(c) {
        var nome = (c.ragione_sociale || ((c.nome || '') + ' ' + (c.cognome || ''))).toLowerCase();
        var email = (c.email || '').toLowerCase();
        return nome.includes(q) || email.includes(q);
    });
    renderClientPickerList(filtered);
}

function renderClientPickerList(clients) {
    var container = document.getElementById('clientPickerList');
    if (!clients || clients.length === 0) {
        container.innerHTML = '<p class="p-8 text-center text-gray-400 text-sm">Nessun cliente trovato</p>';
        return;
    }
    container.innerHTML = clients.map(function(c) {
        var nome = c.ragione_sociale || ((c.nome || '') + ' ' + (c.cognome || '')).trim() || 'Cliente';
        var tipo = c.tipo_cliente || '';
        var email = c.email || '';
        return '<button type="button" onclick="selectClientFromPickerById(\'' + c.id + '\')"' +
            ' class="w-full flex items-center gap-3 px-4 py-3 hover:bg-green-50 transition-colors text-left">' +
            '<div class="w-9 h-9 rounded-full bg-green-100 flex items-center justify-center text-green-700 font-bold text-sm flex-shrink-0">' +
            nome.charAt(0).toUpperCase() + '</div>' +
            '<div class="flex-1 min-w-0"><p class="font-semibold text-gray-900 text-sm truncate">' + nome + '</p>' +
            '<p class="text-xs text-gray-500 truncate">' + [tipo, email].filter(Boolean).join(' \u2022 ') + '</p></div>' +
            '<i data-lucide="chevron-right" class="w-4 h-4 text-gray-300 flex-shrink-0"></i></button>';
    }).join('');
    lucide.createIcons();
}

function selectClientFromPickerById(id) {
    var c = _clientPickerAllClients.find(function(x) { return x.id === id; });
    var nome = c ? (c.ragione_sociale || ((c.nome || '') + ' ' + (c.cognome || '')).trim() || 'Cliente') : 'Cliente';
    selectClientFromPicker(id, nome);
}

function selectClientFromPicker(id, nome) {
    if (typeof window._clientPickerCallback === 'function') {
        var cb = window._clientPickerCallback;
        window._clientPickerCallback = null;
        cb(id, nome);
        return;
    }
    // Fallback for non-wizard context
    var taskClient = document.getElementById('taskClient');
    if (taskClient) taskClient.value = id;
    var label = document.getElementById('clientPickerLabel');
    if (label) {
        label.innerHTML = '<i data-lucide="building-2" class="w-4 h-4 inline mr-2 text-green-600"></i><span class="text-gray-800 font-semibold">' + nome + '</span>';
        document.getElementById('clientPickerActions').classList.remove('hidden');
    }
    closeClientPicker();
    lucide.createIcons();
}

function toggleAddClientForm(show) {
    var form = document.getElementById('addClientForm');
    if (!form) return;
    if (show === undefined) show = form.classList.contains('hidden');
    if (show) {
        form.classList.remove('hidden');
        var el = document.getElementById('newClientRagioneSociale');
        if (el) el.focus();
    } else {
        form.classList.add('hidden');
        ['newClientRagioneSociale','newClientTelefono','newClientEmail'].forEach(function(id) {
            var el = document.getElementById(id);
            if (el) el.value = '';
        });
    }
    lucide.createIcons();
}

async function saveNewClientFromPicker() {
    var ragioneSociale = (document.getElementById('newClientRagioneSociale').value || '').trim();
    if (!ragioneSociale) {
        document.getElementById('newClientRagioneSociale').focus();
        document.getElementById('newClientRagioneSociale').classList.add('border-red-400');
        return;
    }
    document.getElementById('newClientRagioneSociale').classList.remove('border-red-400');
    try {
        var tipoEl = document.getElementById('newClientTipo');
        var result = await (window.supabaseAdmin || window.supabaseClient)
            .from('clients')
            .insert([{
                ragione_sociale: ragioneSociale,
                telefono: (document.getElementById('newClientTelefono').value || '').trim() || null,
                email: (document.getElementById('newClientEmail').value || '').trim() || null,
                tipo_cliente: tipoEl ? tipoEl.value : 'azienda',
                stato: 'attivo'
            }])
            .select()
            .single();
        if (result.error) throw result.error;
        _clientPickerAllClients.unshift(result.data);
        selectClientFromPicker(result.data.id, result.data.ragione_sociale);
        if (typeof showNotification === 'function') showNotification('\u2705 Cliente "' + ragioneSociale + '" creato e selezionato!', 'success');
    } catch (e) {
        if (typeof showNotification === 'function') showNotification('\u274C Errore creazione cliente: ' + e.message, 'error');
    }
}

// ===== MULTI USER PICKER =====
async function openWizardMultiUserPicker() {
    if (window.taskWizard && window.taskWizard.wizardData.assigned_users.length > 0 && _wizardMultiSelected.length === 0) {
        _wizardMultiSelected = window.taskWizard.wizardData.assigned_users.map(function(u) {
            return { id: u.user_id || u.id, nome: u.nome || '', cognome: u.cognome || '', ruolo: u.ruolo_assegnazione || u.ruolo || '' };
        });
    }
    document.getElementById('wizardMultiUserPickerModal').classList.remove('hidden');
    document.getElementById('wizardMultiUserSearch').value = '';
    updateWizardMultiPreview();
    try {
        if (window._wizardDipendentiCache && window._wizardDipendentiCache.length > 0) {
            _wizardMultiAllUsers = window._wizardDipendentiCache;
        } else {
            var result = await (window.supabaseAdmin || window.supabaseClient)
                .from('users').select('*')
                .in('ruolo', ['dipendente','tecnico','titolare','segreteria'])
                .order('nome');
            _wizardMultiAllUsers = result.data || [];
            window._wizardDipendentiCache = _wizardMultiAllUsers;
        }
        renderWizardMultiUserList(_wizardMultiAllUsers);
    } catch (e) {
        document.getElementById('wizardMultiUserPickerList').innerHTML =
            '<p class="p-8 text-center text-red-500 text-sm">Errore nel caricamento</p>';
    }
}

function closeWizardMultiUserPicker() {
    document.getElementById('wizardMultiUserPickerModal').classList.add('hidden');
}

function renderWizardMultiUserList(users) {
    var container = document.getElementById('wizardMultiUserPickerList');
    if (!users || !users.length) {
        container.innerHTML = '<p class="p-8 text-center text-gray-400 text-sm">Nessun dipendente trovato</p>';
        return;
    }
    var roleBadge = { tecnico: 'bg-blue-100 text-blue-700', dipendente: 'bg-gray-100 text-gray-700', titolare: 'bg-purple-100 text-purple-700', segreteria: 'bg-pink-100 text-pink-700' };
    container.innerHTML = '';
    users.forEach(function(u) {
        var nome = ((u.nome || '') + ' ' + (u.cognome || '')).trim() || 'Utente';
        var isChecked = _wizardMultiSelected.some(function(s) { return s.id === u.id; });
        var badge = roleBadge[u.ruolo] || 'bg-gray-100 text-gray-700';
        var row = document.createElement('label');
        row.style.cssText = 'display:flex;align-items:center;gap:12px;padding:12px 16px;cursor:pointer;transition:background 0.1s;' + (isChecked ? 'background:#f5f3ff;' : '');
        row.onmouseover = function() { if (!row.querySelector('input').checked) row.style.background = '#f9fafb'; };
        row.onmouseout = function() { if (!row.querySelector('input').checked) row.style.background = ''; };
        row.innerHTML =
            '<input type="checkbox" value="' + u.id + '" ' + (isChecked ? 'checked' : '') +
            ' style="width:18px;height:18px;accent-color:#7c3aed;cursor:pointer;flex-shrink:0;">' +
            '<div style="width:38px;height:38px;border-radius:50%;background:linear-gradient(135deg,#8b5cf6,#6366f1);display:flex;align-items:center;justify-content:center;color:white;font-weight:700;font-size:15px;flex-shrink:0;">' + nome.charAt(0).toUpperCase() + '</div>' +
            '<div style="flex:1;min-width:0;"><div style="font-weight:600;font-size:14px;color:#111827;">' + nome + '</div>' +
            '<span style="font-size:11px;font-weight:600;padding:2px 8px;border-radius:999px;" class="' + badge + '">' + (u.ruolo || '') + '</span></div>';
        row.querySelector('input').addEventListener('change', function(e) {
            if (e.target.checked) {
                if (!_wizardMultiSelected.some(function(s) { return s.id === u.id; }))
                    _wizardMultiSelected.push({ id: u.id, nome: u.nome || '', cognome: u.cognome || '', ruolo: u.ruolo });
                row.style.background = '#f5f3ff';
            } else {
                _wizardMultiSelected = _wizardMultiSelected.filter(function(s) { return s.id !== u.id; });
                row.style.background = '';
            }
            updateWizardMultiPreview();
        });
        container.appendChild(row);
    });
}

function filterWizardMultiUserList() {
    var q = document.getElementById('wizardMultiUserSearch').value.toLowerCase().trim();
    if (!q) { renderWizardMultiUserList(_wizardMultiAllUsers); return; }
    renderWizardMultiUserList(_wizardMultiAllUsers.filter(function(u) {
        return ((u.nome || '') + ' ' + (u.cognome || '')).toLowerCase().includes(q) || (u.ruolo || '').includes(q);
    }));
}

function updateWizardMultiPreview() {
    var preview = document.getElementById('wizardMultiUserSelectionPreview');
    if (!_wizardMultiSelected.length) { preview.textContent = 'Nessun utente selezionato'; return; }
    preview.innerHTML = '<span style="font-weight:600;color:#6d28d9;">' + _wizardMultiSelected.length + ' selezionati:</span> ' +
        _wizardMultiSelected.map(function(u) {
            return '<span style="background:#ede9fe;color:#5b21b6;padding:2px 8px;border-radius:999px;font-size:12px;margin:2px;">' + ((u.nome || '') + (u.cognome ? ' ' + u.cognome : '')) + '</span>';
        }).join('');
}

function applyWizardMultiUserSelection() {
    if (!_wizardMultiSelected.length) return;
    if (window._editMultiPickerConfirm) {
        window._editMultiPickerConfirm(_wizardMultiSelected);
        window._editMultiPickerConfirm = null;
        closeWizardMultiUserPicker();
        return;
    }
    if (window.taskWizard) {
        window.taskWizard.wizardData.assigned_users = _wizardMultiSelected.map(function(u) {
            return { user_id: u.id, nome: u.nome, cognome: u.cognome || '', ruolo_assegnazione: 'membro' };
        });
    }
    var container = document.getElementById('wizard-multi-users-container');
    container.innerHTML =
        '<div style="background:white;border:1px solid #ddd6fe;border-radius:12px;padding:12px;">' +
        '<p style="font-size:13px;font-weight:700;color:#6d28d9;margin-bottom:8px;">' + _wizardMultiSelected.length + ' dipendenti selezionati:</p>' +
        '<div style="display:flex;flex-wrap:wrap;gap:8px;">' +
        _wizardMultiSelected.map(function(u) {
            var nomeCompleto = (u.nome || '') + (u.cognome ? ' ' + u.cognome : '');
            return '<span style="display:flex;align-items:center;gap:6px;background:#ede9fe;color:#5b21b6;padding:4px 10px;border-radius:999px;font-size:13px;font-weight:600;">' +
                '<span style="width:22px;height:22px;border-radius:50%;background:linear-gradient(135deg,#8b5cf6,#6366f1);display:flex;align-items:center;justify-content:center;color:white;font-size:11px;font-weight:700;">' + ((u.nome || '?').charAt(0).toUpperCase()) + '</span>' +
                nomeCompleto + '</span>';
        }).join('') + '</div>' +
        '<button onclick="openWizardMultiUserPicker()" style="margin-top:10px;font-size:12px;color:#7c3aed;font-weight:600;text-decoration:underline;background:none;border:none;cursor:pointer;">Modifica selezione</button>' +
        '</div>';
    closeWizardMultiUserPicker();
}

// ===== DATE PICKER =====
function openDatePicker(mode) {
    _dpMode = 'single';
    _dpTargetInput = 'wizard-scadenza';
    _dpTargetLabel = 'datePickerLabel';
    _dpTargetColor = 'orange';
    _openDatePickerCore();
}

function openEditScadenzaPicker() {
    _dpMode = 'single';
    _dpTargetInput = 'edit-scadenza';
    _dpTargetLabel = 'editScadenzaLabel';
    _dpTargetColor = 'orange';
    _openDatePickerCore();
}

function openCalEditScadenzaPicker() {
    _dpMode = 'single';
    _dpTargetInput = 'calEditScadenza';
    _dpTargetLabel = 'calEditScadenzaLabel';
    _dpTargetColor = 'orange';
    _openDatePickerCore();
}

function _openDatePickerCore() {
    var today = new Date();
    var existing = document.getElementById(_dpTargetInput) ? document.getElementById(_dpTargetInput).value : '';
    if (existing && _dpMode !== 'giornata') {
        var d = new Date(existing);
        _dpYear = d.getFullYear(); _dpMonth = d.getMonth();
        _dpSelectedDate = new Date(existing + 'T12:00:00');
    } else {
        _dpYear = today.getFullYear(); _dpMonth = today.getMonth();
        _dpSelectedDate = null;
    }
    var confermaBtn = document.getElementById('dpConfermaBtn');
    if (confermaBtn) confermaBtn.style.display = _dpMode === 'giornata' ? '' : 'none';
    document.getElementById('datePickerModal').classList.remove('hidden');
    dpRender();
    lucide.createIcons();
}

function closeDatePicker() {
    document.getElementById('datePickerModal').classList.add('hidden');
}

function dpRender() {
    document.getElementById('dpMonthYear').textContent = _dpMonthNames[_dpMonth] + ' ' + _dpYear;
    if (_dpSelectedDate && _dpMode !== 'giornata') {
        document.getElementById('dpSelectedLabel').textContent =
            _dpSelectedDate.toLocaleDateString('it-IT', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
    } else if (_dpMode === 'giornata') {
        var n = _wizardGiornate.length;
        document.getElementById('dpSelectedLabel').textContent = n > 0 ? (n + ' giornata/e selezionata/e') : '';
    } else {
        document.getElementById('dpSelectedLabel').textContent = '';
    }
    var grid = document.getElementById('dpGrid');
    var today = new Date(); today.setHours(0,0,0,0);
    var firstDay = new Date(_dpYear, _dpMonth, 1);
    var startDow = firstDay.getDay();
    startDow = startDow === 0 ? 6 : startDow - 1;
    var daysInMonth = new Date(_dpYear, _dpMonth + 1, 0).getDate();
    var html = '';
    for (var i = 0; i < startDow; i++) html += '<div style="width:36px;height:36px"></div>';
    for (var day = 1; day <= daysInMonth; day++) {
        var date = new Date(_dpYear, _dpMonth, day);
        var isToday = date.getTime() === today.getTime();
        var isSel = _dpSelectedDate && date.getTime() === _dpSelectedDate.getTime();
        var mm = String(_dpMonth + 1).padStart(2,'0');
        var dd = String(day).padStart(2,'0');
        var iso = _dpYear + '-' + mm + '-' + dd;
        var isInGiornate = _wizardGiornate.includes(iso);
        var isPast = date < today;
        var dow = date.getDay();
        var isWeekend = dow === 0 || dow === 6;
        var cls = 'flex items-center justify-center text-sm rounded-xl font-medium transition-all cursor-pointer select-none ';
        if (isInGiornate) cls += 'bg-orange-500 text-white shadow-lg ';
        else if (isSel) cls += 'bg-purple-600 text-white shadow-lg ';
        else if (isToday) cls += 'ring-2 ring-purple-400 text-purple-700 font-bold ';
        else if (isPast) cls += 'text-gray-400 hover:bg-gray-100 hover:text-gray-600 ';
        else if (isWeekend) cls += 'text-orange-400 hover:bg-orange-50 hover:text-orange-600 ';
        else cls += 'text-gray-700 hover:bg-purple-50 hover:text-purple-700 ';
        html += '<div class="' + cls + '" style="width:36px;height:36px" onclick="dpSelectDay(' + day + ')">' + day + '</div>';
    }
    grid.innerHTML = html;
}

function dpPrevMonth() {
    _dpMonth--; if (_dpMonth < 0) { _dpMonth = 11; _dpYear--; } dpRender();
}

function dpNextMonth() {
    _dpMonth++; if (_dpMonth > 11) { _dpMonth = 0; _dpYear++; } dpRender();
}

function dpSelectDay(d) {
    _dpSelectedDate = new Date(_dpYear, _dpMonth, d);
    var yyyy = _dpYear;
    var mm = String(_dpMonth + 1).padStart(2, '0');
    var dd = String(d).padStart(2, '0');
    var iso = yyyy + '-' + mm + '-' + dd;

    if (_dpMode === 'giornata') {
        if (!_wizardGiornate.includes(iso)) {
            _wizardGiornate.push(iso);
        }
        _renderGiornateChips();
        dpRender();
        return;
    }

    document.getElementById(_dpTargetInput).value = iso;
    // If targeting wizard-scadenza, also set wizard-data-inizio for single date
    if (_dpTargetInput === 'wizard-scadenza') {
        var diEl = document.getElementById('wizard-data-inizio');
        if (diEl) diEl.value = iso;
        if (typeof _updateWizardDateDisplay === 'function') _updateWizardDateDisplay();
    }
    var label = _dpSelectedDate.toLocaleDateString('it-IT', { day: 'numeric', month: 'long', year: 'numeric' });
    var lbl = document.getElementById(_dpTargetLabel);
    var iconColor = _dpTargetColor === 'orange' ? 'text-orange-600' : 'text-purple-600';
    var textColor = _dpTargetColor === 'orange' ? 'text-orange-800' : 'text-gray-800';
    lbl.innerHTML = '<i data-lucide="calendar-check" class="w-4 h-4 inline mr-2 ' + iconColor + '"></i><span class="' + textColor + ' font-semibold">' + label + '</span>';
    lbl.classList.remove('text-gray-400', 'text-orange-400', 'text-purple-400');
    lucide.createIcons();
    dpRender();
    setTimeout(closeDatePicker, 200);
}

function dpSelectToday() {
    var today = new Date();
    _dpYear = today.getFullYear();
    _dpMonth = today.getMonth();
    dpSelectDay(today.getDate());
}

function _renderGiornateChips() {
    // Stub mantenuto per retrocompatibilità — delega a _updateWizardDateDisplay
    if (typeof _updateWizardDateDisplay === 'function') _updateWizardDateDisplay();
}
function _removeGiornata(iso) { /* non usato */ }

// ===== WIZARD RANGE DATE PICKER (shared with calendario-admin) =====
var _wpStartDate = null, _wpEndDate = null, _wpHoverDate = null;
var _wpRangeStep = 'start';
var _wpCalYear = new Date().getFullYear(), _wpCalMonth = new Date().getMonth();
var _WP_MESI = ['Gennaio','Febbraio','Marzo','Aprile','Maggio','Giugno','Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre'];

function openRangePicker() {
    var existingStart = (document.getElementById('wizard-data-inizio') || {}).value || '';
    var existingEnd = (document.getElementById('wizard-scadenza') || {}).value || '';
    if (existingStart && existingEnd && existingStart !== existingEnd) {
        _wpStartDate = existingStart; _wpEndDate = existingEnd;
        var d = new Date(existingStart + 'T00:00:00');
        _wpCalYear = d.getFullYear(); _wpCalMonth = d.getMonth();
    } else {
        _wpStartDate = null; _wpEndDate = null;
        _wpCalYear = new Date().getFullYear(); _wpCalMonth = new Date().getMonth();
    }
    _wpHoverDate = null; _wpRangeStep = 'start';
    document.getElementById('wizard-range-picker-modal').classList.remove('hidden');
    _wpRenderMiniCal();
    if (typeof lucide !== 'undefined') lucide.createIcons();
}
window.openRangePicker = openRangePicker;

function closeRangePicker() { document.getElementById('wizard-range-picker-modal').classList.add('hidden'); }
window.closeRangePicker = closeRangePicker;

function _wpRenderMiniCal() {
    var grid = document.getElementById('wpCalGrid');
    var title = document.getElementById('wpCalTitle');
    if (!grid) return;
    title.textContent = _WP_MESI[_wpCalMonth] + ' ' + _wpCalYear;
    var firstDay = new Date(_wpCalYear, _wpCalMonth, 1);
    var offset = firstDay.getDay() - 1; if (offset < 0) offset = 6;
    var daysInMonth = new Date(_wpCalYear, _wpCalMonth + 1, 0).getDate();
    var today = new Date().toISOString().split('T')[0];
    var html = '';
    for (var i = 0; i < offset; i++) html += '<div></div>';
    for (var d = 1; d <= daysInMonth; d++) {
        var iso = _wpCalYear + '-' + String(_wpCalMonth+1).padStart(2,'0') + '-' + String(d).padStart(2,'0');
        var dow = new Date(_wpCalYear, _wpCalMonth, d).getDay();
        var isWeekend = dow === 0 || dow === 6;
        var isToday = iso === today, isStart = iso === _wpStartDate, isEnd = iso === _wpEndDate;
        var inRange = _wpStartDate && _wpEndDate && iso > _wpStartDate && iso < _wpEndDate;
        var inHover = _wpStartDate && !_wpEndDate && _wpHoverDate && iso > _wpStartDate && iso <= _wpHoverDate;
        var cellBg = 'transparent';
        if ((inRange || inHover) && !isStart && !isEnd) cellBg = '#ffedd5';
        if (isStart && (_wpEndDate || _wpHoverDate)) cellBg = 'linear-gradient(to right,transparent 50%,#ffedd5 50%)';
        if (isEnd && _wpStartDate) cellBg = 'linear-gradient(to left,transparent 50%,#ffedd5 50%)';
        var numBg = 'transparent', numColor = isWeekend ? '#f97316' : '#374151';
        var numBorder = 'none', numWeight = '500';
        if (isStart || isEnd) { numBg = '#f97316'; numColor = 'white'; numWeight = '700'; }
        else if (inRange || inHover) { numColor = '#c2410c'; }
        else if (isToday) { numBorder = '2px solid #f97316'; numColor = '#f97316'; numWeight = '700'; }
        html += '<div style="text-align:center;cursor:pointer;user-select:none;background:' + cellBg + '" onmouseover="_wpHover(\'' + iso + '\')" onmouseout="_wpHoverOut()" onclick="_wpClickDay(\'' + iso + '\')"><span style="display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;border-radius:50%;font-size:12px;font-weight:' + numWeight + ';background:' + numBg + ';color:' + numColor + ';border:' + numBorder + ';box-sizing:border-box">' + d + '</span></div>';
    }
    grid.innerHTML = html;
    var dalEl = document.getElementById('wpRangeDalText'), alEl = document.getElementById('wpRangeAlText');
    var dalDisp = document.getElementById('wpRangeDalDisplay'), alDisp = document.getElementById('wpRangeAlDisplay');
    if (dalEl) dalEl.textContent = _wpStartDate ? _wpFmtDate(_wpStartDate) : '—';
    if (alEl) alEl.textContent = _wpEndDate ? _wpFmtDate(_wpEndDate) : '—';
    if (dalDisp && alDisp) {
        if (_wpRangeStep === 'start') { dalDisp.style.borderColor='#f97316';dalDisp.style.background='#fff7ed';alDisp.style.borderColor='#e5e7eb';alDisp.style.background='#f9fafb'; }
        else { alDisp.style.borderColor='#f97316';alDisp.style.background='#fff7ed';dalDisp.style.borderColor='#e5e7eb';dalDisp.style.background='#f9fafb'; }
    }
    var confirmBtn = document.getElementById('wpConfirmBtn');
    if (confirmBtn) confirmBtn.disabled = !_wpStartDate;
}
window._wpRenderMiniCal = _wpRenderMiniCal;

function _wpFmtDate(iso) { var p = iso.split('-'); return p[2] + ' ' + _WP_MESI[parseInt(p[1])-1].slice(0,3) + ' ' + p[0]; }
function _wpClickDay(iso) {
    if (_wpRangeStep === 'start') { _wpStartDate = iso; _wpEndDate = null; _wpRangeStep = 'end'; }
    else { if (iso < _wpStartDate) { _wpStartDate = iso; _wpRangeStep = 'end'; } else { _wpEndDate = iso; _wpRangeStep = 'start'; } }
    _wpRenderMiniCal();
}
function _wpHover(iso) { _wpHoverDate = iso; _wpRenderMiniCal(); }
function _wpHoverOut() { _wpHoverDate = null; _wpRenderMiniCal(); }
function _wpCalPrev() { _wpCalMonth--; if (_wpCalMonth < 0) { _wpCalMonth = 11; _wpCalYear--; } _wpRenderMiniCal(); }
function _wpCalNext() { _wpCalMonth++; if (_wpCalMonth > 11) { _wpCalMonth = 0; _wpCalYear++; } _wpRenderMiniCal(); }
function _wpShortcut(days, startOff) {
    var s = new Date(); s.setDate(s.getDate() + startOff);
    var e = new Date(s); e.setDate(e.getDate() + days);
    _wpStartDate = s.toISOString().split('T')[0]; _wpEndDate = e.toISOString().split('T')[0];
    _wpCalYear = s.getFullYear(); _wpCalMonth = s.getMonth(); _wpRangeStep = 'start';
    _wpRenderMiniCal();
}
function _wpReset() { _wpStartDate = null; _wpEndDate = null; _wpRangeStep = 'start'; _wpRenderMiniCal(); }

function confirmRangePicker() {
    if (!_wpStartDate) return;
    var end = _wpEndDate || _wpStartDate;
    document.getElementById('wizard-data-inizio').value = _wpStartDate;
    document.getElementById('wizard-scadenza').value = end;
    _updateWizardDateDisplay();
    closeRangePicker();
}
window.confirmRangePicker = confirmRangePicker;

function _clearWizardRange() {
    document.getElementById('wizard-data-inizio').value = '';
    document.getElementById('wizard-scadenza').value = '';
    var lbl = document.getElementById('datePickerLabel');
    if (lbl) { lbl.innerHTML = 'Scegli data...'; lbl.classList.add('text-gray-400'); }
    _updateWizardDateDisplay();
}
window._clearWizardRange = _clearWizardRange;

function _updateWizardDateDisplay() {
    var start = (document.getElementById('wizard-data-inizio') || {}).value || '';
    var end = (document.getElementById('wizard-scadenza') || {}).value || '';
    var displayEl = document.getElementById('wizard-date-display');
    var singleBtn = document.getElementById('wizard-single-date-btn');
    var rangeBtn = document.getElementById('wizard-range-btn');
    if (start && end && start !== end) {
        if (singleBtn) singleBtn.classList.add('hidden');
        var s = new Date(start + 'T12:00:00'), e = new Date(end + 'T12:00:00');
        var days = Math.round((e - s) / 86400000) + 1;
        var fStr = s.toLocaleDateString('it-IT', { day: 'numeric', month: 'short' });
        var lStr = e.toLocaleDateString('it-IT', { day: 'numeric', month: 'short', year: 'numeric' });
        if (displayEl) displayEl.innerHTML = '<div style="display:flex;align-items:center;gap:8px;padding:10px 14px;background:linear-gradient(to right,#f97316,#f59e0b);color:white;border-radius:12px;margin-bottom:8px;font-weight:600;font-size:14px"><i data-lucide="calendar-range" style="width:16px;height:16px;flex-shrink:0"></i><span style="flex:1">' + fStr + ' → ' + lStr + '</span><span style="font-size:11px;background:rgba(255,255,255,0.25);padding:2px 7px;border-radius:999px;font-weight:700">' + days + 'gg</span><button type="button" onclick="_clearWizardRange()" style="background:none;border:none;color:rgba(255,255,255,0.75);cursor:pointer;font-size:18px;line-height:1;padding:0;margin-left:2px" title="Rimuovi intervallo">&times;</button></div>';
        if (rangeBtn) rangeBtn.innerHTML = '<i data-lucide="calendar-range" class="w-4 h-4 inline mr-1"></i>Modifica intervallo';
        if (typeof lucide !== 'undefined') lucide.createIcons();
    } else {
        if (singleBtn) singleBtn.classList.remove('hidden');
        if (displayEl) displayEl.innerHTML = '';
        if (rangeBtn) rangeBtn.innerHTML = '<i data-lucide="calendar-range" class="w-4 h-4 inline mr-1"></i>Scegli intervallo Date';
        if (typeof lucide !== 'undefined') lucide.createIcons();
    }
}
window._updateWizardDateDisplay = _updateWizardDateDisplay;
window._wpClickDay = _wpClickDay; window._wpHover = _wpHover; window._wpHoverOut = _wpHoverOut;
window._wpCalPrev = _wpCalPrev; window._wpCalNext = _wpCalNext;
window._wpShortcut = _wpShortcut; window._wpReset = _wpReset;

// Helper: reset wizard state between uses
function resetWizardHelperState() {
    _wizardGiornate = [];
    _wizardMultiSelected = [];
    _clientPickerAllClients = [];
}

// Export globals for onclick attributes
window.openWizardClientPicker = openWizardClientPicker;
window.clearWizardClientPicker = clearWizardClientPicker;
window.closeClientPicker = closeClientPicker;
window.filterClientPickerList = filterClientPickerList;
window.renderClientPickerList = renderClientPickerList;
window.selectClientFromPickerById = selectClientFromPickerById;
window.selectClientFromPicker = selectClientFromPicker;
window.toggleAddClientForm = toggleAddClientForm;
window.saveNewClientFromPicker = saveNewClientFromPicker;
window.openWizardMultiUserPicker = openWizardMultiUserPicker;
window.closeWizardMultiUserPicker = closeWizardMultiUserPicker;
window.renderWizardMultiUserList = renderWizardMultiUserList;
window.filterWizardMultiUserList = filterWizardMultiUserList;
window.updateWizardMultiPreview = updateWizardMultiPreview;
window.applyWizardMultiUserSelection = applyWizardMultiUserSelection;
window.openDatePicker = openDatePicker;
window.openEditScadenzaPicker = openEditScadenzaPicker;
window._openDatePickerCore = _openDatePickerCore;
window.closeDatePicker = closeDatePicker;
window.dpRender = dpRender;
window.dpPrevMonth = dpPrevMonth;
window.dpNextMonth = dpNextMonth;
window.dpSelectDay = dpSelectDay;
window.dpSelectToday = dpSelectToday;
window._renderGiornateChips = _renderGiornateChips;
window._removeGiornata = _removeGiornata;
window.setPriorityBtn = setPriorityBtn;
window.syncPriorityBtns = syncPriorityBtns;
window.resetWizardHelperState = resetWizardHelperState;
