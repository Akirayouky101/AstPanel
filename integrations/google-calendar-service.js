/**
 * ================================================
 * GOOGLE CALENDAR INTEGRATION SERVICE
 * Data: 4 dicembre 2025
 * Descrizione: Sincronizza tasks con Google Calendar
 * ================================================
 */

class GoogleCalendarService {
    constructor() {
        this.CLIENT_ID = null; // Da configurare in settings
        this.API_KEY = null;   // Da configurare in settings
        this.CALENDAR_ID = 'primary';
        this.isInitialized = false;
        this.gapi = null;
    }

    /**
     * Initialize Google API
     */
    async init(clientId, apiKey) {
        try {
            this.CLIENT_ID = clientId;
            this.API_KEY = apiKey;

            // Load Google API
            await this.loadGoogleAPI();
            
            // Initialize gapi client
            await gapi.client.init({
                apiKey: this.API_KEY,
                clientId: this.CLIENT_ID,
                discoveryDocs: ['https://www.googleapis.com/discovery/v1/apis/calendar/v3/rest'],
                scope: 'https://www.googleapis.com/auth/calendar.events'
            });

            this.isInitialized = true;
            console.log('✅ Google Calendar API initialized');
            return true;
        } catch (error) {
            console.error('❌ Google Calendar init error:', error);
            return false;
        }
    }

    /**
     * Load Google API script
     */
    loadGoogleAPI() {
        return new Promise((resolve, reject) => {
            if (window.gapi) {
                resolve();
                return;
            }

            const script = document.createElement('script');
            script.src = 'https://apis.google.com/js/api.js';
            script.onload = () => {
                gapi.load('client:auth2', resolve);
            };
            script.onerror = reject;
            document.head.appendChild(script);
        });
    }

    /**
     * Sign in to Google
     */
    async signIn() {
        try {
            const auth = gapi.auth2.getAuthInstance();
            await auth.signIn();
            console.log('✅ Signed in to Google Calendar');
            return true;
        } catch (error) {
            console.error('❌ Sign in error:', error);
            return false;
        }
    }

    /**
     * Check if user is signed in
     */
    isSignedIn() {
        if (!this.isInitialized) return false;
        const auth = gapi.auth2.getAuthInstance();
        return auth && auth.isSignedIn.get();
    }

    /**
     * Create calendar event from task
     */
    async createEventFromTask(task) {
        if (!this.isSignedIn()) {
            await this.signIn();
        }

        try {
            const event = {
                summary: `🔧 ${task.titolo}`,
                description: this.buildEventDescription(task),
                location: task.cliente_indirizzo || '',
                start: {
                    dateTime: task.data_inizio || task.data_scadenza,
                    timeZone: 'Europe/Rome'
                },
                end: {
                    dateTime: task.data_scadenza,
                    timeZone: 'Europe/Rome'
                },
                attendees: await this.getTaskAttendees(task),
                reminders: {
                    useDefault: false,
                    overrides: [
                        { method: 'email', minutes: 24 * 60 },  // 1 day before
                        { method: 'popup', minutes: 60 }        // 1 hour before
                    ]
                },
                colorId: this.getColorByPriority(task.priorita),
                extendedProperties: {
                    private: {
                        astTaskId: task.id,
                        astClientId: task.cliente_id,
                        astStatus: task.stato
                    }
                }
            };

            const response = await gapi.client.calendar.events.insert({
                calendarId: this.CALENDAR_ID,
                resource: event
            });

            console.log('✅ Event created:', response.result);
            
            // Save calendar event ID to task
            await this.saveEventIdToTask(task.id, response.result.id);

            return response.result;
        } catch (error) {
            console.error('❌ Error creating calendar event:', error);
            throw error;
        }
    }

    /**
     * Update calendar event
     */
    async updateEventFromTask(task, eventId) {
        if (!this.isSignedIn()) {
            await this.signIn();
        }

        try {
            const event = {
                summary: `🔧 ${task.titolo}`,
                description: this.buildEventDescription(task),
                location: task.cliente_indirizzo || '',
                start: {
                    dateTime: task.data_inizio || task.data_scadenza,
                    timeZone: 'Europe/Rome'
                },
                end: {
                    dateTime: task.data_scadenza,
                    timeZone: 'Europe/Rome'
                },
                colorId: this.getColorByStatus(task.stato),
                extendedProperties: {
                    private: {
                        astTaskId: task.id,
                        astStatus: task.stato
                    }
                }
            };

            const response = await gapi.client.calendar.events.update({
                calendarId: this.CALENDAR_ID,
                eventId: eventId,
                resource: event
            });

            console.log('✅ Event updated:', response.result);
            return response.result;
        } catch (error) {
            console.error('❌ Error updating calendar event:', error);
            throw error;
        }
    }

    /**
     * Delete calendar event
     */
    async deleteEvent(eventId) {
        if (!this.isSignedIn()) return;

        try {
            await gapi.client.calendar.events.delete({
                calendarId: this.CALENDAR_ID,
                eventId: eventId
            });

            console.log('✅ Event deleted:', eventId);
            return true;
        } catch (error) {
            console.error('❌ Error deleting calendar event:', error);
            return false;
        }
    }

    /**
     * Build event description with task details
     */
    buildEventDescription(task) {
        let description = `📋 Lavorazione: ${task.titolo}\n`;
        description += `📍 Cliente: ${task.cliente_nome || 'N/A'}\n`;
        description += `⚡ Priorità: ${task.priorita || 'normale'}\n`;
        description += `📊 Stato: ${task.stato || 'da_iniziare'}\n\n`;
        
        if (task.descrizione) {
            description += `📝 Descrizione:\n${task.descrizione}\n\n`;
        }

        if (task.squadra_membri && task.squadra_membri.length > 0) {
            description += `👥 Squadra:\n`;
            task.squadra_membri.forEach(m => {
                description += `  • ${m.nome} ${m.cognome} (${m.ruolo})\n`;
            });
            description += '\n';
        }

        description += `🔗 Link AST Panel: ${window.location.origin}/gestione-lavorazioni.html?task=${task.id}`;
        
        return description;
    }

    /**
     * Get attendees emails from task
     */
    async getTaskAttendees(task) {
        const attendees = [];

        // Add assigned users
        if (task.squadra_membri && task.squadra_membri.length > 0) {
            task.squadra_membri.forEach(member => {
                if (member.email) {
                    attendees.push({
                        email: member.email,
                        displayName: `${member.nome} ${member.cognome}`,
                        responseStatus: 'needsAction'
                    });
                }
            });
        }

        // Add client if has email
        if (task.cliente_email) {
            attendees.push({
                email: task.cliente_email,
                displayName: task.cliente_nome,
                optional: true
            });
        }

        return attendees;
    }

    /**
     * Get color ID based on priority
     */
    getColorByPriority(priority) {
        const colors = {
            'urgente': '11',     // Red
            'alta': '9',         // Blue
            'normale': '2',      // Green
            'bassa': '8'         // Gray
        };
        return colors[priority] || '2';
    }

    /**
     * Get color ID based on status
     */
    getColorByStatus(status) {
        const colors = {
            'completato': '10',      // Green
            'in_corso': '9',         // Blue
            'in_pausa': '4',         // Orange
            'annullato': '11',       // Red
            'da_iniziare': '2'       // Light green
        };
        return colors[status] || '2';
    }

    /**
     * Save calendar event ID to database
     */
    async saveEventIdToTask(taskId, eventId) {
        try {
            const { error } = await window.supabaseClient
                .from('tasks')
                .update({ google_calendar_event_id: eventId })
                .eq('id', taskId);

            if (error) throw error;
            console.log('✅ Calendar event ID saved to task');
        } catch (error) {
            console.error('❌ Error saving event ID:', error);
        }
    }

    /**
     * Sync task with calendar (create or update)
     */
    async syncTask(task) {
        try {
            if (task.google_calendar_event_id) {
                // Update existing event
                return await this.updateEventFromTask(task, task.google_calendar_event_id);
            } else {
                // Create new event
                return await this.createEventFromTask(task);
            }
        } catch (error) {
            console.error('❌ Error syncing task:', error);
            throw error;
        }
    }

    /**
     * Batch sync multiple tasks
     */
    async batchSyncTasks(tasks) {
        const results = {
            success: [],
            failed: []
        };

        for (const task of tasks) {
            try {
                await this.syncTask(task);
                results.success.push(task.id);
            } catch (error) {
                results.failed.push({ taskId: task.id, error: error.message });
            }
        }

        console.log('📊 Batch sync results:', results);
        return results;
    }
}

// Initialize global instance
window.GoogleCalendarService = new GoogleCalendarService();
