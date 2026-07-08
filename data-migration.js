// =====================================================
// DATA MIGRATION LAYER
// Sostituisce shared-data.js con chiamate a Supabase
// =====================================================

window.dataManager = {
    // ==================== CLIENTS ====================
    async getClienti() {
        try {
            return await window.ClientsAPI.getAll();
        } catch (error) {
            console.error('Errore caricamento clienti:', error);
            return [];
        }
    },

    async getAziende() {
        try {
            const { data, error } = await window.supabase
                .from('clients')
                .select('id, nome, ragione_sociale, partita_iva, telefono, email, pec, tipo_cliente')
                .eq('tipo_cliente', 'azienda')
                .order('ragione_sociale', { ascending: true });
            if (error) throw error;
            // Normalizza: usa ragione_sociale come "nome" se nome è vuoto
            return (data || []).map(a => ({
                ...a,
                nome: a.nome || a.ragione_sociale || ''
            }));
        } catch (error) {
            console.error('Errore caricamento aziende:', error);
            return [];
        }
    },

    async saveCliente(cliente) {
        try {
            if (cliente.id) {
                return await window.ClientsAPI.update(cliente.id, cliente);
            } else {
                return await window.ClientsAPI.create(cliente);
            }
        } catch (error) {
            console.error('Errore salvataggio cliente:', error);
            throw error;
        }
    },

    async deleteCliente(id) {
        try {
            await window.ClientsAPI.delete(id);
        } catch (error) {
            console.error('Errore eliminazione cliente:', error);
            throw error;
        }
    },

    // ==================== USERS ====================
    async getUtenti() {
        try {
            return await window.UsersAPI.getAll();
        } catch (error) {
            console.error('Errore caricamento utenti:', error);
            return [];
        }
    },

    async saveUtente(utente) {
        try {
            if (utente.id) {
                return await window.UsersAPI.update(utente.id, utente);
            } else {
                return await window.UsersAPI.create(utente);
            }
        } catch (error) {
            console.error('Errore salvataggio utente:', error);
            throw error;
        }
    },

    async deleteUtente(id) {
        try {
            await window.UsersAPI.delete(id);
        } catch (error) {
            console.error('Errore eliminazione utente:', error);
            throw error;
        }
    },

    // ==================== TEAMS ====================
    async getSquadre() {
        try {
            return await window.TeamsAPI.getAll();
        } catch (error) {
            console.error('Errore caricamento squadre:', error);
            return [];
        }
    },

    async saveSquadra(squadra, memberIds) {
        try {
            if (squadra.id) {
                return await window.TeamsAPI.update(squadra.id, squadra, memberIds);
            } else {
                return await window.TeamsAPI.create(squadra, memberIds);
            }
        } catch (error) {
            console.error('Errore salvataggio squadra:', error);
            throw error;
        }
    },

    async deleteSquadra(id) {
        try {
            await window.TeamsAPI.delete(id);
        } catch (error) {
            console.error('Errore eliminazione squadra:', error);
            throw error;
        }
    },

    // ==================== TASKS ====================
    async getLavorazioni() {
        try {
            const tasks = await window.TasksAPI.getAll();
            
            // Fetch components for each task
            for (const task of tasks) {
                try {
                    const components = await window.TasksAPI.getComponents(task.id);
                    task.componenti = components.map(tc => ({
                        id: tc.component_id,
                        quantita: tc.quantita,
                        note: tc.note,
                        ...tc.component
                    }));
                } catch (err) {
                    console.warn(`Could not load components for task ${task.id}:`, err);
                    task.componenti = [];
                }
            }
            
            return tasks;
        } catch (error) {
            console.error('Errore caricamento lavorazioni:', error);
            return [];
        }
    },

    async saveLavorazione(lavorazione) {
        try {
            // Validate UUIDs
            const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
            
            // Validate and clean UUIDs
            if (lavorazione.created_by && !uuidRegex.test(lavorazione.created_by)) {
                console.warn('Invalid created_by UUID, removing:', lavorazione.created_by);
                delete lavorazione.created_by;
            }
            
            // For assigned_user_id and assigned_team_id, we need at least one valid
            const hasValidUserId = lavorazione.assigned_user_id && uuidRegex.test(lavorazione.assigned_user_id);
            const hasValidTeamId = lavorazione.assigned_team_id && uuidRegex.test(lavorazione.assigned_team_id);
            
            if (!hasValidUserId && !hasValidTeamId) {
                throw new Error('Devi assegnare la lavorazione a un dipendente o a una squadra');
            }
            
            // Remove invalid UUIDs
            if (lavorazione.assigned_user_id && !hasValidUserId) {
                console.warn('Invalid assigned_user_id UUID, removing:', lavorazione.assigned_user_id);
                delete lavorazione.assigned_user_id;
            }
            
            if (lavorazione.assigned_team_id && !hasValidTeamId) {
                console.warn('Invalid assigned_team_id UUID, removing:', lavorazione.assigned_team_id);
                delete lavorazione.assigned_team_id;
            }
            
            if (lavorazione.client_id && !uuidRegex.test(lavorazione.client_id)) {
                console.warn('Invalid client_id UUID, removing:', lavorazione.client_id);
                delete lavorazione.client_id;
            }
            
            // Extract only valid task table fields (remove view-only fields)
            const validFields = [
                'id', 'titolo', 'descrizione', 'stato', 'priorita',
                'scadenza', 'progresso', 'note_progresso', 'client_id', 'assigned_user_id',
                'assigned_team_id', 'created_by', 'created_at', 'updated_at',
                'ora_inizio', 'ora_fine', 'ore_stimate', 'costo_stimato',
                'data_inizio', 'data_completamento', 'preventivo_id', 'parent_task_id',
                'indirizzo_lavoro', 'note_interne', 'visibile', 'wizard_completed'
            ];
            
            const cleanedTask = {};
            validFields.forEach(field => {
                if (lavorazione[field] !== undefined) {
                    cleanedTask[field] = lavorazione[field];
                }
            });
            
            // Debug log per verificare salvataggio note
            if (lavorazione.note_progresso !== undefined) {
                console.log('💾 Salvando note_progresso:', lavorazione.note_progresso);
            }
            
            console.log('📤 cleanedTask da salvare:', cleanedTask);
            
            // Save componenti separately
            const componenti = lavorazione.componenti || lavorazione.components || [];
            
            let savedTask;
            if (cleanedTask.id) {
                // Check if status is changing to 'completata'
                const previousTask = await window.TasksAPI.getById(cleanedTask.id);
                const isBeingCompleted = previousTask.stato !== 'completato' && cleanedTask.stato === 'completato';
                
                savedTask = await window.TasksAPI.update(cleanedTask.id, cleanedTask);
                
                // Deduct components when task is completed
                if (isBeingCompleted) {
                    try {
                        await window.TasksAPI.deductComponentsOnCompletion(cleanedTask.id);
                        console.log('✅ Componenti scalati dal magazzino per task completata');
                    } catch (error) {
                        console.error('Errore nello scalare i componenti:', error);
                        throw new Error('Errore nello scalare i componenti dal magazzino: ' + error.message);
                    }
                }
                
                // Update components if present
                if (componenti.length > 0) {
                    // First, get existing components for this task
                    const existingComponents = await window.TasksAPI.getComponents(cleanedTask.id);
                    
                    // Remove old components
                    for (const existing of existingComponents) {
                        await window.TasksAPI.removeComponent(existing.id);
                    }
                    
                    // Add new components — supporta sia comp.id che comp.prodotto_id
                    for (const comp of componenti) {
                        const compId = comp.id || comp.prodotto_id || comp.component_id;
                        if (!compId) continue;
                        await window.TasksAPI.addComponent(cleanedTask.id, compId, comp.quantita || 1, comp.note || null);
                    }
                }

                // Sincronizza progresso madre se questo è un figlio
                if (cleanedTask.parent_task_id) {
                    await this._syncParentProgress(cleanedTask.parent_task_id);
                }
            } else {
                savedTask = await window.TasksAPI.create(cleanedTask);
                
                // Add components if present — supporta sia comp.id che comp.prodotto_id
                if (componenti.length > 0) {
                    for (const comp of componenti) {
                        const compId = comp.id || comp.prodotto_id || comp.component_id;
                        if (!compId) continue;
                        await window.TasksAPI.addComponent(savedTask.id, compId, comp.quantita || 1, comp.note || null);
                    }
                }

                // Sincronizza progresso madre se questo è un figlio
                if (cleanedTask.parent_task_id) {
                    await this._syncParentProgress(cleanedTask.parent_task_id);
                }
            }
            
            return savedTask;
        } catch (error) {
            console.error('Errore salvataggio lavorazione:', error);
            throw error;
        }
    },

    // ── Aggiorna il progresso della madre come media dei figli ──
    async _syncParentProgress(parentId) {
        try {
            const client = window.supabaseAdmin || window.supabase;
            const { data: siblings } = await client
                .from('tasks')
                .select('progresso')
                .eq('parent_task_id', parentId)
                .neq('stato', 'annullato');

            if (!siblings || siblings.length === 0) return;

            const avg = Math.round(
                siblings.reduce((sum, t) => sum + (t.progresso || 0), 0) / siblings.length
            );

            await client
                .from('tasks')
                .update({ progresso: avg, updated_at: new Date().toISOString() })
                .eq('id', parentId);

            console.log(`🔗 Progresso madre aggiornato a ${avg}% (media ${siblings.length} figli)`);
        } catch (e) {
            console.warn('[_syncParentProgress] Errore:', e);
        }
    },

    async deleteLavorazione(id) {
        try {
            const client = window.supabaseAdmin || window.supabase;
            // 1. Elimina task_assignments (libera dipendenti/squadra)
            await client.from('task_assignments').delete().eq('task_id', id).catch(() => {});
            // 2. Elimina task_components
            await client.from('task_components').delete().eq('task_id', id).catch(() => {});
            // 3. Elimina la lavorazione
            await window.TasksAPI.delete(id);
            // 4. Notifica tutti i calendari aperti di aggiornarsi
            window.dispatchEvent(new CustomEvent('lavorazione-deleted', { detail: { id } }));
        } catch (error) {
            console.error('Errore eliminazione lavorazione:', error);
            throw error;
        }
    },

    // ==================== COMPONENTS ====================
    async getComponenti() {
        try {
            return await window.ComponentsAPI.getAll();
        } catch (error) {
            console.error('Errore caricamento componenti:', error);
            return [];
        }
    },

    async saveComponente(componente) {
        try {
            if (componente.id) {
                return await window.ComponentsAPI.update(componente.id, componente);
            } else {
                return await window.ComponentsAPI.create(componente);
            }
        } catch (error) {
            console.error('Errore salvataggio componente:', error);
            throw error;
        }
    },

    async deleteComponente(id) {
        try {
            return await window.ComponentsAPI.delete(id);
        } catch (error) {
            console.error('Errore eliminazione componente:', error);
            throw error;
        }
    },

    // ==================== REQUESTS ====================
    async getRichieste() {
        try {
            return await window.RequestsAPI.getAll();
        } catch (error) {
            console.error('Errore caricamento richieste:', error);
            return [];
        }
    },

    async saveRichiesta(richiesta) {
        try {
            const currentUser = window.AuthHelper.getCurrentUser();
            
            if (richiesta.id) {
                return await window.RequestsAPI.update(richiesta.id, richiesta);
            } else {
                richiesta.user_id = currentUser?.id;
                return await window.RequestsAPI.create(richiesta);
            }
        } catch (error) {
            console.error('Errore salvataggio richiesta:', error);
            throw error;
        }
    },

    async updateRichiesta(id, updates) {
        try {
            return await window.RequestsAPI.update(id, updates);
        } catch (error) {
            console.error('Errore aggiornamento richiesta:', error);
            throw error;
        }
    },

    async deleteRichiesta(id) {
        try {
            return await window.RequestsAPI.delete(id);
        } catch (error) {
            console.error('Errore eliminazione richiesta:', error);
            throw error;
        }
    },

    // ==================== COMMUNICATIONS ====================
    async getComunicazioni() {
        try {
            return await window.CommunicationsAPI.getAll();
        } catch (error) {
            console.error('Errore caricamento comunicazioni:', error);
            return [];
        }
    },

    async saveComunicazione(comunicazione) {
        try {
            const currentUser = window.AuthHelper.getCurrentUser();
            comunicazione.pubblicato_da = currentUser?.id;
            return await window.CommunicationsAPI.create(comunicazione);
        } catch (error) {
            console.error('❌ Errore salvataggio comunicazione:', error);
            throw error;
        }
    },

    // ==================== CALENDAR SYNC ====================
    async syncCalendarFromTasks() {
        try {
            const lavorazioni = await this.getLavorazioni();
            const events = [];

            // Helper: split a date range into contiguous weekday-only segments
            function splitWeekdaySegments(startStr, endStr) {
                const start = new Date(startStr + 'T00:00:00');
                const end   = new Date(endStr   + 'T00:00:00');
                const segs  = [];
                let segStart = null, segEnd = null;
                let cur = new Date(start);
                while (cur <= end) {
                    const dow = cur.getDay();
                    if (dow !== 0 && dow !== 6) { // Mon–Fri
                        if (!segStart) segStart = new Date(cur);
                        segEnd = new Date(cur);
                    } else {
                        if (segStart) {
                            const excEnd = new Date(segEnd);
                            excEnd.setDate(excEnd.getDate() + 1);
                            segs.push({ start: segStart.toISOString().split('T')[0], end: excEnd.toISOString().split('T')[0], allDay: true });
                            segStart = null; segEnd = null;
                        }
                    }
                    cur.setDate(cur.getDate() + 1);
                }
                if (segStart) {
                    const excEnd = new Date(segEnd);
                    excEnd.setDate(excEnd.getDate() + 1);
                    segs.push({ start: segStart.toISOString().split('T')[0], end: excEnd.toISOString().split('T')[0], allDay: true });
                }
                return segs;
            }

            // Returns array of {start,end,allDay} — may be >1 if task spans weekends
            function buildEventTimes(task) {
                const startDate = task.data_inizio || task.scadenza;
                const endDate   = task.scadenza    || startDate;
                if (!startDate) return [];

                if (task.ora_inizio) {
                    // Timed task: one event per weekday in the range (skip weekends)
                    if (endDate && endDate !== startDate) {
                        const segments = [];
                        let cur = new Date(startDate + 'T12:00:00');
                        const end = new Date(endDate + 'T12:00:00');
                        while (cur <= end) {
                            const dow = cur.getDay();
                            if (dow !== 0 && dow !== 6) {
                                const iso = cur.toISOString().split('T')[0];
                                segments.push({
                                    start: `${iso}T${task.ora_inizio}`,
                                    end: task.ora_fine ? `${iso}T${task.ora_fine}` : null,
                                    allDay: false
                                });
                            }
                            cur.setDate(cur.getDate() + 1);
                        }
                        if (segments.length > 0) return segments;
                    }
                    // Single day
                    const s = `${startDate}T${task.ora_inizio}`;
                    const e = task.ora_fine ? `${endDate}T${task.ora_fine}` : null;
                    return [{ start: s, end: e, allDay: false }];
                }

                // All-day: split into weekday-only segments
                if (endDate && endDate !== startDate) {
                    const segs = splitWeekdaySegments(startDate, endDate);
                    if (segs.length > 0) return segs;
                    // fallback if entirely on weekend (rare)
                    const excEnd = new Date(endDate + 'T00:00:00');
                    excEnd.setDate(excEnd.getDate() + 1);
                    return [{ start: startDate, end: excEnd.toISOString().split('T')[0], allDay: true }];
                }
                return [{ start: startDate, end: null, allDay: true }];
            }

            for (const task of lavorazioni) {
                if (!task.scadenza) continue;
                if (task.visibile === false) continue; // Escludi standby dal calendario

                const timeSegments = buildEventTimes(task);

                for (let si = 0; si < timeSegments.length; si++) {
                    const times = timeSegments[si];
                    const segSuffix = timeSegments.length > 1 ? `-s${si}` : '';

                // Se assegnato a squadra, crea evento per ogni membro
                if (task.assigned_team_id) {
                    let teamMembers = [];
                    let teamNome = task.team_name || 'Squadra';
                    let teamColore = '#3b82f6';
                    try {
                        // Query diretta a team_members (più affidabile di teams_with_members)
                        const { data: membersData } = await supabase
                            .from('team_members')
                            .select('user_id, users(id, nome, cognome)')
                            .eq('team_id', task.assigned_team_id);
                        if (membersData && membersData.length > 0) {
                            teamMembers = membersData.map(m => m.users).filter(Boolean);
                        }
                        // Prendi colore e nome dalla vista se non in cache
                        const team = await window.TeamsAPI.getById(task.assigned_team_id);
                        if (team) {
                            teamNome = team.nome || teamNome;
                            teamColore = team.colore || teamColore;
                            // Fallback: usa membri dalla vista se query diretta è vuota
                            if (teamMembers.length === 0 && team.membri) {
                                teamMembers = team.membri.filter(m => m && m.id);
                            }
                        }
                    } catch(e) { console.warn('Team load error:', e); }

                    teamMembers.forEach(member => {
                        if (!member || !member.id) return;
                        const evt = {
                            id: `task-${task.id}-member-${member.id}${segSuffix}`,
                            title: `${task.titolo} (${teamNome})`,
                            start: times.start,
                            allDay: times.allDay,
                            backgroundColor: teamColore,
                            borderColor: teamColore,
                            extendedProps: {
                                taskId: task.id,
                                teamId: task.assigned_team_id,
                                teamName: teamNome,
                                userId: member.id,
                                userName: `${member.nome} ${member.cognome}`,
                                stato: task.stato,
                                priorita: task.priorita
                            }
                        };
                        if (times.end) evt.end = times.end;
                        events.push(evt);
                    });

                    // Se la squadra non ha membri, crea comunque un evento per il task
                    if (teamMembers.length === 0) {
                        const evt = {
                            id: `task-${task.id}-team${segSuffix}`,
                            title: `${task.titolo} (${teamNome})`,
                            start: times.start,
                            allDay: times.allDay,
                            backgroundColor: teamColore,
                            borderColor: teamColore,
                            extendedProps: {
                                taskId: task.id,
                                teamId: task.assigned_team_id,
                                teamName: teamNome,
                                userId: null,
                                userName: `👥 ${teamNome}`,
                                stato: task.stato,
                                priorita: task.priorita
                            }
                        };
                        if (times.end) evt.end = times.end;
                        events.push(evt);
                    }
                }
                // Se multi-assegnazione (task_assignments)
                else if (task.task_assignments && task.task_assignments.length > 0) {
                    task.task_assignments.forEach(a => {
                        const userId = a.user_id;
                        if (!userId) return;
                        const u = a.users;
                        const assigneeName = u ? `${u.nome} ${u.cognome}` : userId;
                        const userColor = (window.USER_COLORS && window.USER_COLORS[userId]) || '#6366f1';
                        const evt = {
                            id: `task-${task.id}-user-${userId}${segSuffix}`,
                            title: `${task.titolo} (${assigneeName})`,
                            start: times.start,
                            allDay: times.allDay,
                            assignee: userId,
                            assigneeName: assigneeName,
                            backgroundColor: userColor,
                            borderColor: userColor,
                            extendedProps: {
                                taskId: task.id,
                                assignee: userId,
                                userId: userId,
                                assigneeName: assigneeName,
                                userName: assigneeName,
                                clientName: task.client_name,
                                stato: task.stato,
                                priorita: task.priorita
                            }
                        };
                        if (times.end) evt.end = times.end;
                        events.push(evt);
                    });
                }
                // Se assegnato a singolo utente
                else if (task.assigned_user_id) {
                    const userColor = (window.USER_COLORS && window.USER_COLORS[task.assigned_user_id]) || '#3b82f6';

                    const evt = {
                        id: `task-${task.id}${segSuffix}`,
                        title: task.titolo,
                        start: times.start,
                        allDay: times.allDay,
                        backgroundColor: userColor,
                        borderColor: userColor,
                        extendedProps: {
                            taskId: task.id,
                            userId: task.assigned_user_id,
                            userName: task.assigned_user_name,
                            clientName: task.client_name,
                            stato: task.stato,
                            priorita: task.priorita
                        }
                    };
                    if (times.end) evt.end = times.end;
                    events.push(evt);
                }
                } // end segment loop
            }

            return events;
        } catch (error) {
            console.error('Errore sync calendario:', error);
            return [];
        }
    }
};

console.log('✅ Data Migration Layer loaded');
