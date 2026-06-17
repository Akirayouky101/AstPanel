// =====================================================
// AUTH HELPER - Supabase Auth Ufficiale
// =====================================================

window.AuthHelper = {
    STORAGE_KEY: 'ast_current_user',
    currentUser: null,

    // Inizializza session listener
    async init() {
        if (!window.supabase) {
            console.error('❌ Supabase client non trovato!');
            return;
        }

        // Ascolta cambiamenti auth
        window.supabase.auth.onAuthStateChange(async (event, session) => {
            console.log('🔐 Auth state changed:', event);
            
            if (event === 'SIGNED_IN' && session) {
                await this.loadCurrentUser();
            } else if (event === 'SIGNED_OUT') {
                this.currentUser = null;
                sessionStorage.removeItem(this.STORAGE_KEY);
            }
        });

        // Carica utente corrente all'avvio
        await this.loadCurrentUser();
    },

    // Carica dati utente da database usando auth.uid()
    async loadCurrentUser() {
        try {
            console.log('📥 loadCurrentUser() chiamato');
            
            // Timeout per debug
            const timeoutPromise = new Promise((_, reject) => 
                setTimeout(() => reject(new Error('TIMEOUT dopo 5 secondi')), 5000)
            );
            
            const sessionPromise = window.supabase.auth.getSession();
            
            const { data: { session }, error: sessionError } = await Promise.race([
                sessionPromise,
                timeoutPromise
            ]);
            
            console.log('Session:', session ? '✅ Presente' : '❌ Assente');
            
            if (sessionError || !session) {
                console.log('⚠️ Nessuna sessione valida');
                this.currentUser = null;
                return null;
            }

            console.log('🔍 Cercando utente con auth_id:', session.user.id);
            
            // Recupera dati utente dal database
            console.log('⏳ Eseguendo query users...');
            const { data: userData, error: userError } = await window.supabase
                .from('users')
                .select('*')
                .eq('auth_id', session.user.id)
                .single();

            console.log('📊 Query completata. Data:', userData, 'Error:', userError);

            if (userError) {
                console.error('❌ Errore recupero utente:', userError);
                // Se l'utente non esiste nel DB ma ha una sessione valida, fai logout
                if (userError.code === 'PGRST116') { // No rows returned
                    console.warn('⚠️ Utente non trovato nel database, eseguo logout...');
                    await this.logout();
                }
                this.currentUser = null;
                return null;
            }

            // Se non ci sono dati utente (null), fai logout
            if (!userData) {
                console.warn('⚠️ Dati utente nulli, eseguo logout...');
                await this.logout();
                this.currentUser = null;
                return null;
            }

            console.log('✅ Utente caricato:', userData);
            this.currentUser = userData;
            sessionStorage.setItem(this.STORAGE_KEY, JSON.stringify(userData));
            return userData;
        } catch (error) {
            console.error('❌ Errore loadCurrentUser:', error);
            return null;
        }
    },

    // Login con email e password
    async login(email, password) {
        try {
            const { data, error } = await window.supabase.auth.signInWithPassword({
                email: email,
                password: password
            });

            if (error) throw error;

            // Carica dati utente
            await this.loadCurrentUser();

            // ✨ VERIFICA PIN se richiesto
            if (this.currentUser && window.pinVerification && window.pinVerification.requiresPin(this.currentUser)) {
                console.log('🔐 PIN richiesto per questo utente');
                try {
                    await window.pinVerification.requestPin(this.currentUser);
                    console.log('✅ PIN verificato con successo');
                } catch (pinError) {
                    console.error('❌ Verifica PIN fallita:', pinError);
                    // Logout se PIN non verificato
                    await this.logout();
                    throw new Error('Verifica PIN fallita');
                }
            }

            // Controlla se è primo login
            if (this.currentUser && this.currentUser.first_login) {
                return { user: this.currentUser, requirePasswordChange: true };
            }

            return { user: this.currentUser, requirePasswordChange: false };
        } catch (error) {
            console.error('Errore login:', error);
            throw error;
        }
    },

    // Cambia password
    async changePassword(newPassword) {
        try {
            console.log('🔐 Cambiando password...');
            
            if (!this.currentUser || !this.currentUser.auth_id) {
                throw new Error('Utente non trovato o auth_id mancante');
            }

            console.log('👤 User auth_id:', this.currentUser.auth_id);
            
            // Usa Service Role Key per aggiornare password (bypassa sessione)
            const { data, error } = await window.supabaseAdmin.auth.admin.updateUserById(
                this.currentUser.auth_id,
                { password: newPassword }
            );

            if (error) {
                console.error('❌ Errore updateUserById:', error);
                throw error;
            }

            console.log('✅ Password Supabase Auth aggiornata via admin API');

            // Aggiorna flag first_login (usa admin per bypassare RLS)
            console.log('📝 Aggiornando flag first_login per user ID:', this.currentUser.id);
            
            const { error: updateError } = await window.supabaseAdmin
                .from('users')
                .update({ first_login: false })
                .eq('id', this.currentUser.id);

            if (updateError) {
                console.error('❌ Errore update first_login:', updateError);
                throw updateError;
            }

            console.log('✅ Flag first_login aggiornato');
            
            this.currentUser.first_login = false;
            sessionStorage.setItem(this.STORAGE_KEY, JSON.stringify(this.currentUser));

            console.log('✅ Cambio password completato con successo!');
            return true;
        } catch (error) {
            console.error('❌ Errore cambio password:', error);
            throw error;
        }
    },

    // Logout
    async logout() {
        try {
            const { error } = await window.supabase.auth.signOut();
            if (error) throw error;

            this.currentUser = null;
            sessionStorage.removeItem(this.STORAGE_KEY);
            localStorage.removeItem('currentUser');
            localStorage.removeItem('ast_current_user');
            sessionStorage.clear();
        } catch (error) {
            console.error('Errore logout:', error);
            // Pulisci comunque la sessione locale
            this.currentUser = null;
            sessionStorage.clear();
        }
    },

    // Get current user from cache
    getCurrentUser() {
        if (this.currentUser) return this.currentUser;
        
        const userData = sessionStorage.getItem(this.STORAGE_KEY);
        if (userData) {
            this.currentUser = JSON.parse(userData);
            return this.currentUser;
        }
        
        return null;
    },

    // Check if user is logged in
    async isLoggedIn() {
        try {
            const { data: { session } } = await window.supabase.auth.getSession();
            return session !== null;
        } catch (error) {
            return false;
        }
    },

    // Check if user is admin
    isAdmin() {
        const user = this.getCurrentUser();
        if (!user) {
            console.log('❌ isAdmin() - No user found');
            return false;
        }
        
        console.log('🔍 isAdmin() check - User role:', user.ruolo);
        
        // Ruoli con permessi admin: titolare, segreteria, tecnico
        // Dipendente NON è admin
        const adminRoles = ['titolare', 'segreteria', 'tecnico'];
        const isAdminUser = adminRoles.includes(user.ruolo.toLowerCase());
        
        console.log('✅ Is admin?', isAdminUser, '- Role checked:', user.ruolo);
        return isAdminUser;
    },

    // Require login (call in pages)
    async requireLogin() {
        const loggedIn = await this.isLoggedIn();
        if (!loggedIn) {
            window.location.href = '/';
            return false;
        }
        
        // Assicurati che currentUser sia caricato
        if (!this.currentUser) {
            await this.loadCurrentUser();
        }
        
        return true;
    },

    // Require admin (call in admin pages)
    async requireAdmin() {
        if (!await this.requireLogin()) return false;
        
        if (!this.isAdmin()) {
            window.location.href = '../pannello-utente.html';
            return false;
        }
        return true;
    },

    // Crea nuovo utente in Supabase Auth (solo per admin)
    async createUser(email, temporaryPassword, userData) {
        try {
            // Verifica che chi chiama sia admin
            if (!this.isAdmin()) {
                throw new Error('Solo admin possono creare utenti');
            }

            // NOTA: Questa operazione richiede chiamata API lato server
            // Per ora usiamo Admin API di Supabase (richiede service_role_key)
            // In produzione, creare una Edge Function protetta

            const response = await fetch(window.supabase.supabaseUrl + '/auth/v1/admin/users', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'apikey': window.supabase.supabaseKey,
                    'Authorization': `Bearer ${window.supabase.supabaseKey}`
                },
                body: JSON.stringify({
                    email: email,
                    password: temporaryPassword,
                    email_confirm: true,
                    user_metadata: userData
                })
            });

            if (!response.ok) {
                const error = await response.json();
                throw new Error(error.message || 'Errore creazione utente Auth');
            }

            const { data } = await response.json();
            return data.user;
        } catch (error) {
            console.error('Errore createUser:', error);
            throw error;
        }
    }
};

// Inizializza auth helper quando il DOM è pronto
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => window.AuthHelper.init());
} else {
    window.AuthHelper.init();
}

console.log('✅ Auth Helper (Supabase Auth) loaded');
