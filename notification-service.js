// ================================================
// AST PANEL - Notification Service v1.0
// Gestione Notifiche Push + Supabase Realtime
// ================================================

class NotificationService {
  constructor() {
    this.supabase = window.supabaseClient;
    this.channels = [];
    this.isInitialized = false;
    this.currentUserId = null;
  }

  // ========== INIT SERVICE ==========
  async init(userId) {
    if (this.isInitialized) {
      console.log('[NotificationService] Already initialized');
      return;
    }

    this.currentUserId = userId;
    console.log('[NotificationService] Initializing for user:', userId);

    try {
      // Setup Realtime listeners
      await this.setupRealtimeListeners();
      this.isInitialized = true;
      console.log('[NotificationService] Initialized successfully');
    } catch (error) {
      console.error('[NotificationService] Initialization error:', error);
    }
  }

  // ========== SETUP REALTIME LISTENERS ==========
  async setupRealtimeListeners() {
    const userId = this.currentUserId;

    // 1. NUOVE LAVORAZIONI ASSEGNATE
    const lavorazioniChannel = this.supabase
      .channel('lavorazioni-notifications')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'lavorazioni',
        filter: `assigned_user_id=eq.${userId}`
      }, (payload) => {
        console.log('[NotificationService] Nuova lavorazione:', payload);
        this.sendNotification({
          title: '🆕 Nuova Lavorazione Assegnata',
          body: `Cliente: ${payload.new.cliente_nome || 'N/A'}`,
          tag: 'lavorazione-new',
          data: {
            url: '/pannello-utente.html?section=tasks',
            type: 'lavorazione',
            id: payload.new.id
          },
          requireInteraction: true
        });
      })
      .subscribe();

    // 2. LAVORAZIONI MODIFICATE (cambio stato, note, etc)
    const lavorazioniUpdateChannel = this.supabase
      .channel('lavorazioni-updates')
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'lavorazioni',
        filter: `assigned_user_id=eq.${userId}`
      }, (payload) => {
        console.log('[NotificationService] Lavorazione aggiornata:', payload);
        
        // Solo notifica se cambio stato significativo
        const oldStatus = payload.old.stato;
        const newStatus = payload.new.stato;
        
        if (oldStatus !== newStatus) {
          this.sendNotification({
            title: '📝 Lavorazione Aggiornata',
            body: `Stato cambiato: ${oldStatus} → ${newStatus}`,
            tag: 'lavorazione-update',
            data: {
              url: '/pannello-utente.html?section=tasks',
              type: 'lavorazione',
              id: payload.new.id
            }
          });
        }
      })
      .subscribe();

    // 3. RICHIESTE PERMESSI APPROVATE/RIFIUTATE
    const richiesteChannel = this.supabase
      .channel('richieste-notifications')
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'richieste_permessi',
        filter: `user_id=eq.${userId}`
      }, (payload) => {
        console.log('[NotificationService] Richiesta aggiornata:', payload);
        
        const status = payload.new.stato;
        const oldStatus = payload.old.stato;
        
        // Solo se stato cambia
        if (status !== oldStatus && status !== 'in_attesa') {
          const icon = status === 'approvata' ? '✅' : '❌';
          const emoji = status === 'approvata' ? '🎉' : '😔';
          
          this.sendNotification({
            title: `${icon} Richiesta ${status.toUpperCase()}`,
            body: `${emoji} La tua richiesta è stata ${status}`,
            tag: 'richiesta-status',
            data: {
              url: '/pannello-utente.html?section=requests',
              type: 'richiesta',
              id: payload.new.id
            },
            requireInteraction: true,
            vibrate: status === 'approvata' ? [200, 100, 200, 100, 200] : [500]
          });
        }
      })
      .subscribe();

    // 4. NUOVE COMUNICAZIONI (broadcast o personali)
    const comunicazioniChannel = this.supabase
      .channel('comunicazioni-notifications')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'comunicazioni'
      }, (payload) => {
        console.log('[NotificationService] Nuova comunicazione:', payload);
        
        // Check se è per questo utente (broadcast o specifico)
        const destinatario = payload.new.destinatario_id;
        if (!destinatario || destinatario === userId) {
          this.sendNotification({
            title: '💬 Nuova Comunicazione',
            body: payload.new.messaggio?.substring(0, 80) + '...',
            tag: 'comunicazione-new',
            data: {
              url: '/pannello-utente.html?section=communications',
              type: 'comunicazione',
              id: payload.new.id
            }
          });
        }
      })
      .subscribe();

    // 5. SCADENZE IMMINENTI (check giornaliero tramite function)
    // Questo richiederebbe una Supabase Edge Function o cron job
    // Per ora lo gestiamo client-side

    this.channels.push(
      lavorazioniChannel,
      lavorazioniUpdateChannel,
      richiesteChannel,
      comunicazioniChannel
    );

    console.log('[NotificationService] Realtime listeners setup complete');
  }

  // ========== SEND NOTIFICATION ==========
  async sendNotification(options) {
    const defaultOptions = {
      icon: '/icons/icon-192x192.png',
      badge: '/icons/badge-72x72.png',
      vibrate: [200, 100, 200],
      requireInteraction: false,
      actions: [
        { action: 'open', title: '👀 Apri' },
        { action: 'close', title: '❌ Chiudi' }
      ]
    };

    const notificationOptions = { ...defaultOptions, ...options };

    try {
      // PRIMA: Emetti evento per notifiche in-app (Safari compatibile)
      window.dispatchEvent(new CustomEvent('realtimeNotification', {
        detail: {
          title: notificationOptions.title,
          body: notificationOptions.body,
          type: notificationOptions.data?.type || 'general',
          icon: this.getIconForType(notificationOptions.data?.type),
          data: notificationOptions.data
        }
      }));
      console.log('[NotificationService] In-app notification dispatched');
      
      // SECONDA: Se disponibile, invia anche push nativo (Chrome/Firefox)
      if ('serviceWorker' in navigator && 'PushManager' in window) {
        // Check se app è in background
        if (document.hidden) {
          // Usa Service Worker per notifica persistente
          const registration = await navigator.serviceWorker.ready;
          await registration.showNotification(notificationOptions.title, {
            body: notificationOptions.body,
            icon: notificationOptions.icon,
            badge: notificationOptions.badge,
            tag: notificationOptions.tag,
            vibrate: notificationOptions.vibrate,
            data: notificationOptions.data,
            actions: notificationOptions.actions,
            requireInteraction: notificationOptions.requireInteraction
          });
          
          console.log('[NotificationService] Push notification sent:', notificationOptions.title);
        }
      }

      // Salva in history
      await this.saveToHistory(notificationOptions);
      
    } catch (error) {
      console.error('[NotificationService] Send notification error:', error);
    }
  }

  // ========== GET ICON FOR TYPE ==========
  getIconForType(type) {
    const icons = {
      'lavorazione': 'briefcase',
      'task': 'briefcase',
      'richiesta': 'calendar',
      'comunicazione': 'message-circle',
      'scadenza': 'alert-triangle',
      'general': 'bell'
    };
    return icons[type] || 'bell';
  }

  // ========== SAVE TO HISTORY ==========
  async saveToHistory(notification) {
    try {
      await this.supabase
        .from('notification_history')
        .insert({
          user_id: this.currentUserId,
          title: notification.title,
          body: notification.body,
          type: notification.data?.type,
          related_id: notification.data?.id
        });
    } catch (error) {
      console.error('[NotificationService] Save history error:', error);
    }
  }

  // ========== GET NOTIFICATION HISTORY ==========
  async getHistory(limit = 50) {
    try {
      const { data, error } = await this.supabase
        .from('notification_history')
        .select('*')
        .eq('user_id', this.currentUserId)
        .order('sent_at', { ascending: false })
        .limit(limit);

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('[NotificationService] Get history error:', error);
      return [];
    }
  }

  // ========== MARK AS READ ==========
  async markAsRead(notificationId) {
    try {
      await this.supabase
        .from('notification_history')
        .update({ read_at: new Date().toISOString() })
        .eq('id', notificationId);
    } catch (error) {
      console.error('[NotificationService] Mark as read error:', error);
    }
  }

  // ========== CHECK SCADENZE ==========
  async checkScadenzeImminenti() {
    try {
      const { data: tasks } = await this.supabase
        .from('lavorazioni')
        .select('*')
        .eq('assigned_user_id', this.currentUserId)
        .gte('scadenza', new Date().toISOString())
        .lte('scadenza', new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()) // 24h
        .neq('stato', 'completata');

      if (tasks && tasks.length > 0) {
        tasks.forEach(task => {
          const hoursLeft = Math.round((new Date(task.scadenza) - new Date()) / 1000 / 60 / 60);
          
          this.sendNotification({
            title: '⏰ Scadenza Imminente',
            body: `"${task.titolo}" scade tra ${hoursLeft} ore`,
            tag: 'scadenza-imminente',
            data: {
              url: '/pannello-utente.html?section=tasks',
              type: 'lavorazione',
              id: task.id
            },
            requireInteraction: true
          });
        });
      }
    } catch (error) {
      console.error('[NotificationService] Check scadenze error:', error);
    }
  }

  // ========== DESTROY ==========
  destroy() {
    console.log('[NotificationService] Destroying...');
    this.channels.forEach(channel => {
      channel.unsubscribe();
    });
    this.channels = [];
    this.isInitialized = false;
  }
}

// Esporta globalmente
window.NotificationService = NotificationService;
console.log('[NotificationService] Class loaded');
