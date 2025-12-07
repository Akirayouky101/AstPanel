/**
 * ⚡ TIMBRATURE SERVICE - Sistema Ottimizzato con Caching
 * 
 * Features:
 * - Caching localStorage per performance
 * - Feedback immediato
 * - Timer real-time con secondi
 * - Calcolo costi automatico
 * - Gestione offline
 */

class TimbratureService {
    constructor() {
        this.supabase = window.supabaseClient;
        this.currentUser = null;
        this.todayTimbratura = null;
        this.monthlyStats = null;
        this.timerInterval = null;
        this.CACHE_KEY = 'timbrature_cache';
        this.CACHE_DURATION = 5 * 60 * 1000; // 5 minuti
    }

    // ============================================
    // 🚀 CACHING & PERFORMANCE
    // ============================================

    /**
     * Carica dati con caching
     */
    async loadWithCache(key, fetchFunction) {
        const cache = this.getCache();
        const now = Date.now();

        if (cache[key] && (now - cache[key].timestamp) < this.CACHE_DURATION) {
            console.log(`📦 Cache hit for ${key}`);
            return cache[key].data;
        }

        console.log(`🔄 Cache miss for ${key}, fetching...`);
        const data = await fetchFunction();
        this.setCache(key, data);
        return data;
    }

    getCache() {
        try {
            return JSON.parse(localStorage.getItem(this.CACHE_KEY)) || {};
        } catch {
            return {};
        }
    }

    setCache(key, data) {
        const cache = this.getCache();
        cache[key] = {
            data: data,
            timestamp: Date.now()
        };
        localStorage.setItem(this.CACHE_KEY, JSON.stringify(cache));
    }

    clearCache(key = null) {
        if (key) {
            const cache = this.getCache();
            delete cache[key];
            localStorage.setItem(this.CACHE_KEY, JSON.stringify(cache));
        } else {
            localStorage.removeItem(this.CACHE_KEY);
        }
    }

    // ============================================
    // 📊 TIMBRATURA OGGI
    // ============================================

    /**
     * Carica timbratura di oggi
     */
    async loadTodayTimbratura(userId) {
        const today = new Date().toISOString().split('T')[0];
        
        const { data, error } = await this.supabase
            .from('timbrature')
            .select(`
                *,
                user:users!timbrature_user_id_fkey(costo_orario)
            `)
            .eq('user_id', userId)
            .eq('data', today)
            .maybeSingle();

        if (error && error.code !== 'PGRST116') throw error;

        this.todayTimbratura = data;
        return data;
    }

    /**
     * Timbra ingresso
     */
    async timbraIngresso(userId, gpsData = null) {
        const today = new Date().toISOString().split('T')[0];
        const now = new Date().toTimeString().split(' ')[0].substring(0, 5);

        // Feedback immediato (ottimistico)
        const optimisticData = {
            user_id: userId,
            data: today,
            ora_ingresso: now,
            ora_uscita: null,
            tipo: 'normale',
            posizione_gps: gpsData,
            stato: 'approved',
            ore_lavorate: null
        };

        const { data, error } = await this.supabase
            .from('timbrature')
            .insert(optimisticData)
            .select(`
                *,
                user:users!timbrature_user_id_fkey(costo_orario)
            `)
            .single();

        if (error) throw error;

        this.todayTimbratura = data;
        this.clearCache('today');
        
        // 🗺️ Mostra mappa GPS se disponibile
        if (gpsData && gpsData.latitude && gpsData.longitude && window.gpsMapModal) {
            window.gpsMapModal.showConfirmModal(gpsData.latitude, gpsData.longitude, 'ingresso');
        }
        
        return data;
    }

    /**
     * Timbra uscita
     */
    async timbraUscita(timbratureId) {
        const now = new Date().toTimeString().split(' ')[0].substring(0, 5);

        const { data, error } = await this.supabase
            .from('timbrature')
            .update({ ora_uscita: now })
            .eq('id', timbratureId)
            .select(`
                *,
                user:users!timbrature_user_id_fkey(costo_orario)
            `)
            .single();

        if (error) throw error;

        this.todayTimbratura = data;
        this.clearCache('today');
        
        // 🗺️ Mostra mappa GPS se disponibile
        if (data.posizione_gps && window.gpsMapModal) {
            const gps = data.posizione_gps;
            if (gps.latitude && gps.longitude) {
                window.gpsMapModal.showConfirmModal(gps.latitude, gps.longitude, 'uscita');
            }
        }
        
        return data;
    }

    // ============================================
    // ⏱️ TIMER REAL-TIME
    // ============================================

    /**
     * Calcola ore lavorate in tempo reale (con secondi!)
     */
    calculateLiveHours(oraIngresso) {
        if (!oraIngresso) return { hours: 0, minutes: 0, seconds: 0, total: 0 };

        const now = new Date();
        // Gestisci sia stringhe "HH:MM:SS" che oggetti Date
        const ingressoStr = typeof oraIngresso === 'string' ? oraIngresso : oraIngresso;
        const [hours, minutes] = ingressoStr.toString().split(':');
        const ingressoTime = new Date();
        ingressoTime.setHours(parseInt(hours), parseInt(minutes), 0);

        const diffMs = now - ingressoTime;
        const totalSeconds = Math.floor(diffMs / 1000);
        const totalMinutes = Math.floor(totalSeconds / 60);
        const totalHours = Math.floor(totalMinutes / 60);

        return {
            hours: totalHours,
            minutes: totalMinutes % 60,
            seconds: totalSeconds % 60,
            total: totalHours + (totalMinutes % 60) / 60,
            formatted: `${totalHours}:${String(totalMinutes % 60).padStart(2, '0')}:${String(totalSeconds % 60).padStart(2, '0')}`
        };
    }

    /**
     * Avvia timer live
     */
    startLiveTimer(oraIngresso, updateCallback) {
        this.stopLiveTimer();
        
        updateCallback(this.calculateLiveHours(oraIngresso));
        
        this.timerInterval = setInterval(() => {
            const time = this.calculateLiveHours(oraIngresso);
            updateCallback(time);
        }, 1000); // Aggiorna ogni secondo!
    }

    /**
     * Ferma timer
     */
    stopLiveTimer() {
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
            this.timerInterval = null;
        }
    }

    // ============================================
    // 💰 CALCOLO COSTI
    // ============================================

    /**
     * Calcola costo giornaliero
     */
    calculateDailyCost(oreLavorate, costoOrario) {
        if (!oreLavorate || !costoOrario) return 0;
        return (parseFloat(oreLavorate) * parseFloat(costoOrario)).toFixed(2);
    }

    /**
     * Calcola costo in tempo reale
     */
    calculateLiveCost(oraIngresso, costoOrario) {
        const time = this.calculateLiveHours(oraIngresso);
        return this.calculateDailyCost(time.total, costoOrario);
    }

    // ============================================
    // 📈 STATISTICHE MENSILI
    // ============================================

    /**
     * Carica statistiche mese con caching
     */
    async loadMonthlyStats(userId) {
        return await this.loadWithCache(`monthly_${userId}`, async () => {
            const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0];
            const endOfMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).toISOString().split('T')[0];

            const { data, error } = await this.supabase
                .from('timbrature')
                .select(`
                    *,
                    user:users!timbrature_user_id_fkey(costo_orario)
                `)
                .eq('user_id', userId)
                .gte('data', startOfMonth)
                .lte('data', endOfMonth)
                .eq('stato', 'approved');

            if (error) throw error;

            // Calcola statistiche
            const stats = {
                oreOrdinarie: 0,
                oreStraordinarie: 0,
                giorniFerie: 0,
                giorniPermessi: 0,
                totaleOre: 0,
                costoTotale: 0,
                costoOrario: data[0]?.user?.costo_orario || 0,
                timbrature: data
            };

            data.forEach(t => {
                const ore = parseFloat(t.ore_lavorate) || 0;
                
                if (t.tipo === 'normale') {
                    stats.oreOrdinarie += ore;
                } else if (t.tipo === 'straordinario') {
                    stats.oreStraordinarie += ore;
                } else if (t.tipo === 'ferie') {
                    stats.giorniFerie++;
                } else if (t.tipo === 'permesso') {
                    stats.giorniPermessi++;
                }

                stats.totaleOre += ore;
                stats.costoTotale += parseFloat(this.calculateDailyCost(ore, stats.costoOrario));
            });

            this.monthlyStats = stats;
            return stats;
        });
    }

    // ============================================
    // 📍 GPS
    // ============================================

    /**
     * Ottieni posizione GPS
     */
    async getGPS() {
        return new Promise((resolve) => {
            if (!navigator.geolocation) {
                resolve(null);
                return;
            }

            navigator.geolocation.getCurrentPosition(
                (position) => {
                    resolve({
                        lat: position.coords.latitude,
                        lng: position.coords.longitude,
                        accuracy: position.coords.accuracy
                    });
                },
                () => resolve(null),
                { timeout: 5000, maximumAge: 0 }
            );
        });
    }

    // ============================================
    // 🔔 NOTIFICHE
    // ============================================

    /**
     * Richiedi permesso notifiche
     */
    async requestNotificationPermission() {
        if ('Notification' in window && Notification.permission === 'default') {
            await Notification.requestPermission();
        }
    }

    /**
     * Invia notifica browser
     */
    sendNotification(title, body) {
        if ('Notification' in window && Notification.permission === 'granted') {
            new Notification(title, {
                body: body,
                icon: '/icons/icon-192x192.png',
                badge: '/icons/icon-192x192.png'
            });
        }
    }

    /**
     * Alert promemoria uscita (dopo 8+ ore)
     */
    checkOvertimeAlert(oraIngresso) {
        const time = this.calculateLiveHours(oraIngresso);
        
        if (time.hours >= 8 && time.minutes === 0 && time.seconds === 0) {
            this.sendNotification(
                '⏰ Promemoria Uscita',
                `Hai lavorato ${time.hours} ore. Ricordati di timbrare l'uscita!`
            );
        }
    }

    // ============================================
    // 📊 STATISTICHE AVANZATE
    // ============================================

    /**
     * Ottieni trend settimanale
     */
    async getWeeklyTrend(userId) {
        const today = new Date();
        const startOfWeek = new Date(today.setDate(today.getDate() - today.getDay()));
        const startDate = startOfWeek.toISOString().split('T')[0];

        const { data, error } = await this.supabase
            .from('timbrature')
            .select('data, ore_lavorate')
            .eq('user_id', userId)
            .gte('data', startDate)
            .eq('stato', 'approved')
            .order('data', { ascending: true });

        if (error) throw error;

        return data.reduce((acc, t) => {
            const dayName = new Date(t.data).toLocaleDateString('it-IT', { weekday: 'short' });
            acc[dayName] = (acc[dayName] || 0) + (parseFloat(t.ore_lavorate) || 0);
            return acc;
        }, {});
    }
}

// Inizializza globalmente
window.TimbratureService = TimbratureService;

// Auto-init
document.addEventListener('DOMContentLoaded', () => {
    if (window.supabaseClient) {
        window.timbratureService = new TimbratureService();
        console.log('✅ TimbratureService initialized with caching & real-time timer');
    }
});
