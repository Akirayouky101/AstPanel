/**
 * ================================================
 * EMAIL SERVICE
 * Data: 4 dicembre 2025
 * Descrizione: Invio email automatiche (SMTP/SendGrid)
 * ================================================
 */

class EmailService {
    constructor() {
        this.provider = null; // 'smtp' or 'sendgrid'
        this.settings = null;
        this.isConfigured = false;
    }

    /**
     * Initialize email service
     */
    async init() {
        try {
            const { data, error } = await window.supabaseClient
                .from('integration_settings')
                .select('settings, api_key, is_enabled')
                .eq('integration_name', 'email_smtp')
                .single();

            if (error) throw error;

            if (data && data.is_enabled) {
                this.settings = data.settings;
                this.provider = data.api_key ? 'sendgrid' : 'smtp';
                this.isConfigured = true;
                console.log('✅ Email service configured:', this.provider);
            } else {
                console.warn('⚠️ Email service not enabled');
            }

            return this.isConfigured;
        } catch (error) {
            console.error('❌ Email init error:', error);
            return false;
        }
    }

    /**
     * Send email via Supabase Edge Function (recommended)
     */
    async sendEmail(to, subject, htmlBody, textBody = null) {
        if (!this.isConfigured) {
            console.error('❌ Email service not configured');
            return { success: false, error: 'Service not configured' };
        }

        try {
            // Call Supabase Edge Function for email sending
            const response = await fetch(`${window.supabaseClient.supabaseUrl}/functions/v1/send-email`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${window.supabaseClient.supabaseKey}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    to,
                    subject,
                    html: htmlBody,
                    text: textBody || this.stripHtml(htmlBody),
                    from: this.settings.from_email,
                    fromName: this.settings.from_name || 'AST Panel'
                })
            });

            const result = await response.json();

            if (response.ok) {
                console.log('✅ Email sent successfully');
                return { success: true, messageId: result.messageId };
            } else {
                console.error('❌ Email send error:', result);
                return { success: false, error: result.error };
            }
        } catch (error) {
            console.error('❌ Email error:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Send task confirmation email
     */
    async sendTaskConfirmation(task, client) {
        const subject = `Conferma Lavorazione - ${task.titolo}`;
        const html = this.templates.taskConfirmation(task, client);
        
        const result = await this.sendEmail(client.email, subject, html);
        
        await this.logNotification(task.id, client.id, 'email', 'confirmation',
                                   client.email, subject, html, result);
        
        return result;
    }

    /**
     * Send task reminder email
     */
    async sendTaskReminder(task, client) {
        const subject = `Promemoria: Lavorazione di domani - ${task.titolo}`;
        const html = this.templates.taskReminder(task, client);
        
        const result = await this.sendEmail(client.email, subject, html);
        
        await this.logNotification(task.id, client.id, 'email', 'reminder',
                                   client.email, subject, html, result);
        
        return result;
    }

    /**
     * Send status update email
     */
    async sendStatusUpdate(task, client, newStatus) {
        const subject = `Aggiornamento Lavorazione - ${task.titolo}`;
        const html = this.templates.statusUpdate(task, client, newStatus);
        
        const result = await this.sendEmail(client.email, subject, html);
        
        await this.logNotification(task.id, client.id, 'email', 'status_update',
                                   client.email, subject, html, result);
        
        return result;
    }

    /**
     * Send task completion email
     */
    async sendTaskCompletion(task, client) {
        const subject = `Lavorazione Completata - ${task.titolo}`;
        const html = this.templates.taskCompletion(task, client);
        
        const result = await this.sendEmail(client.email, subject, html);
        
        await this.logNotification(task.id, client.id, 'email', 'completion',
                                   client.email, subject, html, result);
        
        return result;
    }

    /**
     * Send assignment notification to user
     */
    async sendUserAssignment(task, user) {
        const subject = `Nuova Lavorazione Assegnata - ${task.titolo}`;
        const html = this.templates.userAssignment(task, user);
        
        const result = await this.sendEmail(user.email, subject, html);
        
        await this.logNotification(task.id, null, 'email', 'assignment',
                                   user.email, subject, html, result);
        
        return result;
    }

    /**
     * Strip HTML tags
     */
    stripHtml(html) {
        const tmp = document.createElement('DIV');
        tmp.innerHTML = html;
        return tmp.textContent || tmp.innerText || '';
    }

    /**
     * Log notification
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
                        p_error_message: result.error
                    });
            }
        } catch (error) {
            console.error('Error logging notification:', error);
        }
    }

    /**
     * Email HTML templates
     */
    templates = {
        taskConfirmation: (task, client) => `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .info-box { background: white; padding: 20px; margin: 20px 0; border-left: 4px solid #667eea; border-radius: 5px; }
        .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
        .button { display: inline-block; padding: 12px 24px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 AST:ZG</h1>
            <h2>Conferma Lavorazione</h2>
        </div>
        <div class="content">
            <p>Gentile <strong>${client.ragione_sociale || client.nome}</strong>,</p>
            
            <p>La Sua richiesta di lavorazione è stata confermata con successo.</p>
            
            <div class="info-box">
                <h3>📋 Dettagli Intervento</h3>
                <p><strong>Lavorazione:</strong> ${task.titolo}</p>
                <p><strong>Data:</strong> ${new Date(task.data_scadenza).toLocaleDateString('it-IT', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
                <p><strong>Orario:</strong> ${task.ora_inizio || 'Da confermare'}</p>
                <p><strong>Indirizzo:</strong> ${client.indirizzo || 'Da definire'}</p>
                ${task.descrizione ? `<p><strong>Descrizione:</strong> ${task.descrizione}</p>` : ''}
            </div>
            
            <p>Il nostro team tecnico La contatterà nelle prossime ore per confermare l'orario esatto dell'intervento.</p>
            
            <p>Per qualsiasi informazione o modifica, non esiti a contattarci.</p>
            
            <p>Cordiali saluti,<br><strong>Il Team AST:ZG</strong></p>
        </div>
        <div class="footer">
            <p>Questa è un'email automatica. Per assistenza contattaci al numero di telefono indicato nella conferma.</p>
            <p>© ${new Date().getFullYear()} AST:ZG - Tutti i diritti riservati</p>
        </div>
    </div>
</body>
</html>
        `,

        taskReminder: (task, client) => `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .info-box { background: white; padding: 20px; margin: 20px 0; border-left: 4px solid #f5576c; border-radius: 5px; }
        .highlight { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #ffc107; }
        .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⏰ Promemoria Importante</h1>
            <h2>Intervento Programmato Domani</h2>
        </div>
        <div class="content">
            <p>Gentile <strong>${client.ragione_sociale || client.nome}</strong>,</p>
            
            <div class="highlight">
                <strong>⏰ Le ricordiamo che domani è programmato il seguente intervento:</strong>
            </div>
            
            <div class="info-box">
                <h3>📋 Dettagli</h3>
                <p><strong>Lavorazione:</strong> ${task.titolo}</p>
                <p><strong>Data:</strong> ${new Date(task.data_scadenza).toLocaleDateString('it-IT', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
                <p><strong>Orario:</strong> ${task.ora_inizio || 'Da confermare'}</p>
                <p><strong>Indirizzo:</strong> ${client.indirizzo}</p>
                <p><strong>Tecnico:</strong> ${task.squadra_membri?.[0]?.nome || 'Da assegnare'} ${task.squadra_membri?.[0]?.cognome || ''}</p>
            </div>
            
            <p>Ci assicureremo che tutto proceda come pianificato.</p>
            
            <p>A presto,<br><strong>Il Team AST:ZG</strong></p>
        </div>
        <div class="footer">
            <p>© ${new Date().getFullYear()} AST:ZG</p>
        </div>
    </div>
</body>
</html>
        `,

        statusUpdate: (task, client, newStatus) => {
            const statusConfig = {
                'in_corso': { emoji: '🔄', name: 'In Corso', color: '#3b82f6' },
                'in_pausa': { emoji: '⏸️', name: 'In Pausa', color: '#f59e0b' },
                'completato': { emoji: '✅', name: 'Completato', color: '#10b981' },
                'annullato': { emoji: '❌', name: 'Annullato', color: '#ef4444' }
            };
            
            const status = statusConfig[newStatus] || { emoji: '📊', name: newStatus, color: '#6b7280' };

            return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: ${status.color}; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .status-badge { display: inline-block; background: ${status.color}; color: white; padding: 10px 20px; border-radius: 20px; font-weight: bold; margin: 15px 0; }
        .info-box { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; }
        .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${status.emoji} Aggiornamento Stato</h1>
        </div>
        <div class="content">
            <p>Gentile <strong>${client.ragione_sociale || client.nome}</strong>,</p>
            
            <p>Lo stato della Sua lavorazione è stato aggiornato:</p>
            
            <div class="info-box">
                <p><strong>Lavorazione:</strong> ${task.titolo}</p>
                <p><strong>Nuovo Stato:</strong> <span class="status-badge">${status.emoji} ${status.name}</span></p>
            </div>
            
            ${newStatus === 'completato' ? '<p>✅ <strong>La lavorazione è stata completata con successo!</strong> Il team Le invierà una documentazione dettagliata a breve.</p>' : ''}
            ${newStatus === 'in_pausa' ? '<p>⏸️ La lavorazione è temporaneamente in pausa. Vi aggiorneremo non appena riprenderemo i lavori.</p>' : ''}
            ${newStatus === 'in_corso' ? '<p>🔄 Il nostro team ha iniziato i lavori. Vi terremo aggiornati sull\'avanzamento.</p>' : ''}
            
            <p>Cordiali saluti,<br><strong>Il Team AST:ZG</strong></p>
        </div>
        <div class="footer">
            <p>© ${new Date().getFullYear()} AST:ZG</p>
        </div>
    </div>
</body>
</html>
            `;
        },

        taskCompletion: (task, client) => `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .success-box { background: #d1fae5; padding: 20px; margin: 20px 0; border-left: 4px solid #10b981; border-radius: 5px; }
        .info-box { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; }
        .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>✅ Lavorazione Completata!</h1>
        </div>
        <div class="content">
            <p>Gentile <strong>${client.ragione_sociale || client.nome}</strong>,</p>
            
            <div class="success-box">
                <h3>✅ Ottima Notizia!</h3>
                <p>Siamo lieti di comunicarLe che la lavorazione è stata completata con successo.</p>
            </div>
            
            <div class="info-box">
                <p><strong>Lavorazione:</strong> ${task.titolo}</p>
                <p><strong>Completata il:</strong> ${new Date().toLocaleDateString('it-IT', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
                ${task.note_completamento ? `<p><strong>Note:</strong> ${task.note_completamento}</p>` : ''}
            </div>
            
            <p>Grazie per averci scelto! La Sua soddisfazione è la nostra priorità.</p>
            
            <p>Per qualsiasi necessità o per richiedere nuovi interventi, non esiti a contattarci.</p>
            
            <p>Cordiali saluti,<br><strong>Il Team AST:ZG</strong></p>
        </div>
        <div class="footer">
            <p>© ${new Date().getFullYear()} AST:ZG - Grazie per la fiducia!</p>
        </div>
    </div>
</body>
</html>
        `,

        userAssignment: (task, user) => `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .task-box { background: white; padding: 20px; margin: 20px 0; border-left: 4px solid #667eea; border-radius: 5px; }
        .button { display: inline-block; padding: 12px 24px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0; }
        .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📋 Nuova Lavorazione Assegnata</h1>
        </div>
        <div class="content">
            <p>Ciao <strong>${user.nome} ${user.cognome}</strong>,</p>
            
            <p>Ti è stata assegnata una nuova lavorazione:</p>
            
            <div class="task-box">
                <h3>${task.titolo}</h3>
                <p><strong>Cliente:</strong> ${task.cliente_nome}</p>
                <p><strong>Data scadenza:</strong> ${new Date(task.data_scadenza).toLocaleDateString('it-IT')}</p>
                <p><strong>Priorità:</strong> ${task.priorita || 'normale'}</p>
                ${task.descrizione ? `<p><strong>Descrizione:</strong> ${task.descrizione}</p>` : ''}
            </div>
            
            <p style="text-align: center;">
                <a href="${window.location.origin}/pannello-utente.html" class="button">Visualizza nel Pannello</a>
            </p>
            
            <p>Buon lavoro!<br><strong>AST:ZG</strong></p>
        </div>
        <div class="footer">
            <p>© ${new Date().getFullYear()} AST:ZG</p>
        </div>
    </div>
</body>
</html>
        `
    };
}

// Initialize global instance
window.EmailService = new EmailService();
