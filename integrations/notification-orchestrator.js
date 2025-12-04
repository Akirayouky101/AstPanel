/**
 * ================================================
 * NOTIFICATION ORCHESTRATOR
 * Data: 4 dicembre 2025
 * Descrizione: Coordina invio notifiche multi-canale
 * ================================================
 */

class NotificationOrchestrator {
    constructor() {
        this.services = {
            email: window.EmailService,
            whatsapp: window.WhatsAppService,
            calendar: window.GoogleCalendarService
        };
    }

    /**
     * Initialize all services
     */
    async init() {
        console.log('🚀 Initializing notification services...');
        
        const results = await Promise.allSettled([
            this.services.email.init(),
            this.services.whatsapp.init(),
            this.services.calendar.init()
        ]);

        console.log('📊 Services status:', {
            email: results[0].status === 'fulfilled' && results[0].value,
            whatsapp: results[1].status === 'fulfilled' && results[1].value,
            calendar: results[2].status === 'fulfilled' && results[2].value
        });
    }

    /**
     * Send task confirmation (email + WhatsApp)
     */
    async sendTaskConfirmation(task, client) {
        const promises = [];

        // Email
        if (client.email && client.email_notifications_enabled !== false) {
            promises.push(
                this.services.email.sendTaskConfirmation(task, client)
                    .then(r => ({ channel: 'email', ...r }))
                    .catch(e => ({ channel: 'email', success: false, error: e.message }))
            );
        }

        // WhatsApp
        if (client.whatsapp_number && client.whatsapp_notifications_enabled) {
            promises.push(
                this.services.whatsapp.sendTaskConfirmation(task, client)
                    .then(r => ({ channel: 'whatsapp', ...r }))
                    .catch(e => ({ channel: 'whatsapp', success: false, error: e.message }))
            );
        }

        // Google Calendar
        if (this.services.calendar.isConfigured) {
            promises.push(
                this.services.calendar.syncTask(task)
                    .then(r => ({ channel: 'calendar', success: true, event: r }))
                    .catch(e => ({ channel: 'calendar', success: false, error: e.message }))
            );
        }

        const results = await Promise.all(promises);
        console.log('📤 Task confirmation sent:', results);
        
        return results;
    }

    /**
     * Send task reminder (24h before)
     */
    async sendTaskReminder(task, client) {
        const promises = [];

        if (client.email && client.email_notifications_enabled !== false) {
            promises.push(this.services.email.sendTaskReminder(task, client));
        }

        if (client.whatsapp_number && client.whatsapp_notifications_enabled) {
            promises.push(this.services.whatsapp.sendTaskReminder(task, client));
        }

        const results = await Promise.allSettled(promises);
        console.log('⏰ Task reminder sent:', results);
        
        return results;
    }

    /**
     * Send status update
     */
    async sendStatusUpdate(task, client, newStatus) {
        const promises = [];

        if (client.email && client.email_notifications_enabled !== false) {
            promises.push(this.services.email.sendStatusUpdate(task, client, newStatus));
        }

        if (client.whatsapp_number && client.whatsapp_notifications_enabled) {
            promises.push(this.services.whatsapp.sendStatusUpdate(task, client, newStatus));
        }

        // Update calendar event
        if (task.google_calendar_event_id && this.services.calendar.isConfigured) {
            promises.push(this.services.calendar.updateEventFromTask(task, task.google_calendar_event_id));
        }

        const results = await Promise.allSettled(promises);
        console.log('📊 Status update sent:', results);
        
        return results;
    }

    /**
     * Send task completion
     */
    async sendTaskCompletion(task, client) {
        const promises = [];

        if (client.email && client.email_notifications_enabled !== false) {
            promises.push(this.services.email.sendTaskCompletion(task, client));
        }

        if (client.whatsapp_number && client.whatsapp_notifications_enabled) {
            promises.push(this.services.whatsapp.sendTaskCompletion(task, client));
        }

        // Update calendar event color to green (completed)
        if (task.google_calendar_event_id && this.services.calendar.isConfigured) {
            promises.push(this.services.calendar.updateEventFromTask(task, task.google_calendar_event_id));
        }

        const results = await Promise.allSettled(promises);
        console.log('✅ Task completion sent:', results);
        
        return results;
    }

    /**
     * Send user assignment notification
     */
    async sendUserAssignment(task, user) {
        if (!user.email) return null;

        const result = await this.services.email.sendUserAssignment(task, user);
        console.log('👤 User assignment sent:', result);
        
        return result;
    }

    /**
     * Delete calendar event
     */
    async deleteCalendarEvent(eventId) {
        if (eventId && this.services.calendar.isConfigured) {
            return await this.services.calendar.deleteEvent(eventId);
        }
        return false;
    }

    /**
     * Check and send daily reminders
     * Call this from a cron job or scheduled task
     */
    async sendDailyReminders() {
        try {
            // Get tasks for tomorrow
            const tomorrow = new Date();
            tomorrow.setDate(tomorrow.getDate() + 1);
            tomorrow.setHours(0, 0, 0, 0);

            const tomorrowEnd = new Date(tomorrow);
            tomorrowEnd.setHours(23, 59, 59, 999);

            const { data: tasks, error } = await window.supabaseClient
                .from('tasks')
                .select(`
                    *,
                    clients:cliente_id (*)
                `)
                .gte('data_scadenza', tomorrow.toISOString())
                .lt('data_scadenza', tomorrowEnd.toISOString())
                .neq('stato', 'completato')
                .neq('stato', 'annullato');

            if (error) throw error;

            console.log(`📅 Found ${tasks.length} tasks for tomorrow`);

            for (const task of tasks) {
                if (task.clients) {
                    await this.sendTaskReminder(task, task.clients);
                    // Wait 2 seconds between sends to avoid rate limits
                    await new Promise(resolve => setTimeout(resolve, 2000));
                }
            }

            return { success: true, count: tasks.length };
        } catch (error) {
            console.error('❌ Error sending daily reminders:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Get notification statistics
     */
    async getStatistics(days = 30) {
        try {
            const { data, error } = await window.supabaseClient
                .from('notification_stats')
                .select('*');

            if (error) throw error;

            return data;
        } catch (error) {
            console.error('❌ Error getting statistics:', error);
            return [];
        }
    }
}

// Initialize global instance
window.NotificationOrchestrator = new NotificationOrchestrator();

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    window.NotificationOrchestrator.init();
});
