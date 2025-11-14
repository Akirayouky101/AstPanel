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
            return await window.TasksAPI.getAll();
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
                'scadenza', 'progresso', 'client_id', 'assigned_user_id', 
                'assigned_team_id', 'created_by', 'created_at', 'updated_at'
            ];
            
            const cleanedTask = {};
            validFields.forEach(field => {
                if (lavorazione[field] !== undefined) {
                    cleanedTask[field] = lavorazione[field];
                }
            });
            
            if (cleanedTask.id) {
                return await window.TasksAPI.update(cleanedTask.id, cleanedTask);
            } else {
                return await window.TasksAPI.create(cleanedTask);
            }
        } catch (error) {
            console.error('Errore salvataggio lavorazione:', error);
            throw error;
        }
    },

    async deleteLavorazione(id) {
        try {
            await window.TasksAPI.delete(id);
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
            console.log('🔍 Current User:', currentUser);
            console.log('🔍 User Role:', currentUser?.ruolo);
            console.log('🔍 Comunicazione Data:', comunicazione);
            
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

            for (const task of lavorazioni) {
                if (!task.scadenza) continue;

                // Se assegnato a squadra, crea evento per ogni membro
                if (task.assigned_team_id && task.assigned_team_id) {
                    const team = await window.TeamsAPI.getById(task.assigned_team_id);
                    
                    if (team && team.membri) {
                        team.membri.forEach(member => {
                            events.push({
                                id: `task-${task.id}-member-${member.id}`,
                                title: `${task.titolo} (${team.nome})`,
                                start: task.scadenza,
                                backgroundColor: team.colore || '#3b82f6',
                                borderColor: team.colore || '#3b82f6',
                                extendedProps: {
                                    taskId: task.id,
                                    teamId: team.id,
                                    teamName: team.nome,
                                    userId: member.id,
                                    userName: `${member.nome} ${member.cognome}`,
                                    stato: task.stato,
                                    priorita: task.priorita
                                }
                            });
                        });
                    }
                }
                // Se assegnato a singolo utente
                else if (task.assigned_user_id) {
                    const priorityColors = {
                        'alta': '#ef4444',
                        'media': '#f59e0b',
                        'bassa': '#10b981'
                    };

                    events.push({
                        id: `task-${task.id}`,
                        title: task.titolo,
                        start: task.scadenza,
                        backgroundColor: priorityColors[task.priorita] || '#3b82f6',
                        borderColor: priorityColors[task.priorita] || '#3b82f6',
                        extendedProps: {
                            taskId: task.id,
                            userId: task.assigned_user_id,
                            userName: task.assigned_user_name,
                            clientName: task.client_name,
                            stato: task.stato,
                            priorita: task.priorita
                        }
                    });
                }
            }

            return events;
        } catch (error) {
            console.error('Errore sync calendario:', error);
            return [];
        }
    }
};

console.log('✅ Data Migration Layer loaded');
