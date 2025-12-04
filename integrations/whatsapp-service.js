/**
 * ================================================
 * WHATSAPP BUSINESS API SERVICE
 * Data: 4 dicembre 2025
 * Descrizione: Invio messaggi WhatsApp automatici
 * ================================================
 */

class WhatsAppService {
    constructor() {
        this.PHONE_NUMBER_ID = null;
        this.ACCESS_TOKEN = null;
        this.API_VERSION = 'v18.0';
        this.BASE_URL = `https://graph.facebook.com/${this.API_VERSION}`;
        this.isConfigured = false;
    }

    /**
     * Initialize WhatsApp service
     */
    async init() {
        try {
            // Load settings from database
            const { data, error } = await window.supabaseClient
                .from('integration_settings')
                .select('settings, access_token, is_enabled')
                .eq('integration_name', 'whatsapp_business')
                .single();

            if (error) throw error;

            if (data && data.is_enabled) {
                this.PHONE_NUMBER_ID = data.settings.phone_number_id;
                this.ACCESS_TOKEN = data.access_token;
                this.isConfigured = true;
                console.log('✅ WhatsApp Business API configured');
            } else {
                console.warn('⚠️ WhatsApp Business API not enabled');
            }

            return this.isConfigured;
        } catch (error) {
            console.error('❌ WhatsApp init error:', error);
            return false;
        }
    }

    /**
     * Send text message
     */
    async sendMessage(to, message) {
        if (!this.isConfigured) {
            console.error('❌ WhatsApp not configured');
            return false;
        }

        try {
            // Clean phone number (remove spaces, dashes, etc)
            const cleanNumber = this.cleanPhoneNumber(to);

            const response = await fetch(`${this.BASE_URL}/${this.PHONE_NUMBER_ID}/messages`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.ACCESS_TOKEN}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    messaging_product: 'whatsapp',
                    recipient_type: 'individual',
                    to: cleanNumber,
                    type: 'text',
                    text: {
                        preview_url: true,
                        body: message
                    }
                })
            });

            const result = await response.json();

            if (response.ok) {
                console.log('✅ WhatsApp message sent:', result);
                return { success: true, messageId: result.messages[0].id };
            } else {
                console.error('❌ WhatsApp error:', result);
                return { success: false, error: result.error };
            }
        } catch (error) {
            console.error('❌ WhatsApp send error:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Send template message
     */
    async sendTemplate(to, templateName, parameters = []) {
        if (!this.isConfigured) return false;

        try {
            const cleanNumber = this.cleanPhoneNumber(to);

            const response = await fetch(`${this.BASE_URL}/${this.PHONE_NUMBER_ID}/messages`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.ACCESS_TOKEN}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    messaging_product: 'whatsapp',
                    to: cleanNumber,
                    type: 'template',
                    template: {
                        name: templateName,
                        language: {
                            code: 'it'
                        },
                        components: parameters.length > 0 ? [{
                            type: 'body',
                            parameters: parameters.map(p => ({ type: 'text', text: p }))
                        }] : []
                    }
                })
            });

            const result = await response.json();

            if (response.ok) {
                console.log('✅ WhatsApp template sent:', result);
                return { success: true, messageId: result.messages[0].id };
            } else {
                console.error('❌ WhatsApp template error:', result);
                return { success: false, error: result.error };
            }
        } catch (error) {
            console.error('❌ WhatsApp template error:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Send task confirmation
     */
    async sendTaskConfirmation(task, client) {
        const message = this.templates.taskConfirmation(task, client);
        const result = await this.sendMessage(client.whatsapp_number, message);
        
        // Log notification
        await this.logNotification(task.id, client.id, 'whatsapp', 'confirmation', 
                                   client.whatsapp_number, null, message, result);
        
        return result;
    }

    /**
     * Send task reminder
     */
    async sendTaskReminder(task, client) {
        const message = this.templates.taskReminder(task, client);
        const result = await this.sendMessage(client.whatsapp_number, message);
        
        await this.logNotification(task.id, client.id, 'whatsapp', 'reminder', 
                                   client.whatsapp_number, null, message, result);
        
        return result;
    }

    /**
     * Send status update
     */
    async sendStatusUpdate(task, client, newStatus) {
        const message = this.templates.statusUpdate(task, client, newStatus);
        const result = await this.sendMessage(client.whatsapp_number, message);
        
        await this.logNotification(task.id, client.id, 'whatsapp', 'status_update', 
                                   client.whatsapp_number, null, message, result);
        
        return result;
    }

    /**
     * Send task completion
     */
    async sendTaskCompletion(task, client) {
        const message = this.templates.taskCompletion(task, client);
        const result = await this.sendMessage(client.whatsapp_number, message);
        
        await this.logNotification(task.id, client.id, 'whatsapp', 'completion', 
                                   client.whatsapp_number, null, message, result);
        
        return result;
    }

    /**
     * Clean phone number to international format
     */
    cleanPhoneNumber(phone) {
        // Remove all non-numeric characters
        let clean = phone.replace(/\D/g, '');
        
        // Add country code if missing (assume Italy +39)
        if (!clean.startsWith('39') && clean.length === 10) {
            clean = '39' + clean;
        }
        
        return clean;
    }

    /**
     * Log notification to database
     */
    async logNotification(taskId, clientId, type, channel, recipient, subject, message, result) {
        try {
            const { data: logId } = await window.supabaseClient
                .rpc('log_notification', {
                    p_task_id: taskId,
                    p_client_id: clientId,
                    p_type: type,
                    p_channel: channel,
                    p_recipient: recipient,
                    p_subject: subject,
                    p_message: message
                });

            if (logId && result.success) {
                await window.supabaseClient
                    .rpc('update_notification_status', {
                        p_log_id: logId,
                        p_status: 'sent',
                        p_external_id: result.messageId
                    });
            } else if (logId && !result.success) {
                await window.supabaseClient
                    .rpc('update_notification_status', {
                        p_log_id: logId,
                        p_status: 'failed',
                        p_error_message: result.error?.message || 'Unknown error'
                    });
            }
        } catch (error) {
            console.error('Error logging notification:', error);
        }
    }

    /**
     * Message templates
     */
    templates = {
        taskConfirmation: (task, client) => `
🔧 *AST:ZG - Conferma Lavorazione*

Gentile ${client.ragione_sociale || client.nome},

La Sua richiesta di lavorazione è stata confermata:

📋 *Intervento:* ${task.titolo}
📅 *Data:* ${new Date(task.data_scadenza).toLocaleDateString('it-IT')}
📍 *Indirizzo:* ${client.indirizzo || 'Da definire'}
⏰ *Orario previsto:* ${task.ora_inizio || 'Da confermare'}

Il nostro team tecnico La contatterà per confermare l'orario esatto.

Per qualsiasi informazione: 📞 ${task.referente_telefono || 'Ufficio'}

Cordiali saluti,
AST:ZG Team
        `.trim(),

        taskReminder: (task, client) => `
⏰ *Promemoria Lavorazione - AST:ZG*

Gentile ${client.ragione_sociale || client.nome},

Le ricordiamo l'intervento programmato per domani:

📋 ${task.titolo}
📅 ${new Date(task.data_scadenza).toLocaleDateString('it-IT')}
⏰ ${task.ora_inizio || 'Orario da confermare'}
📍 ${client.indirizzo}

👥 Tecnico assegnato: ${task.squadra_membri?.[0]?.nome || 'Da assegnare'}

A domani!
AST:ZG Team
        `.trim(),

        statusUpdate: (task, client, newStatus) => {
            const statusEmojis = {
                'in_corso': '🔄',
                'in_pausa': '⏸️',
                'completato': '✅',
                'annullato': '❌'
            };

            const statusNames = {
                'in_corso': 'In Corso',
                'in_pausa': 'In Pausa',
                'completato': 'Completato',
                'annullato': 'Annullato'
            };

            return `
${statusEmojis[newStatus] || '📊'} *Aggiornamento Lavorazione*

Gentile ${client.ragione_sociale || client.nome},

Lo stato della lavorazione è stato aggiornato:

📋 *Intervento:* ${task.titolo}
📊 *Nuovo stato:* ${statusNames[newStatus] || newStatus}

${newStatus === 'completato' ? '✅ La lavorazione è stata completata con successo!' : ''}
${newStatus === 'in_pausa' ? '⏸️ La lavorazione è temporaneamente in pausa. Vi aggiorneremo presto.' : ''}

Per informazioni: 📞 ${task.referente_telefono || 'Ufficio'}

AST:ZG Team
            `.trim();
        },

        taskCompletion: (task, client) => `
✅ *Lavorazione Completata - AST:ZG*

Gentile ${client.ragione_sociale || client.nome},

Siamo lieti di comunicarLe che la lavorazione è stata completata:

📋 *Intervento:* ${task.titolo}
📅 *Completato il:* ${new Date().toLocaleDateString('it-IT')}
✅ *Stato:* Concluso con successo

${task.note_completamento ? `📝 *Note:* ${task.note_completamento}` : ''}

Grazie per averci scelto!
Per qualsiasi necessità siamo a Sua disposizione.

Cordiali saluti,
AST:ZG Team
        `.trim()
    };
}

// Initialize global instance
window.WhatsAppService = new WhatsAppService();
