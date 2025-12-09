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
            const { data: { session }, error: sessionError } = await window.supabase.auth.getSession();
            
            if (sessionError || !session) {
                this.currentUser = null;
                return null;
            }

            // Recupera dati utente dal database
            const { data: userData, error: userError } = await window.supabase
                .from('users')
                .select('*')
                .eq('auth_id', session.user.id)
                .single();

            if (userError) {
                console.error('Errore recupero utente:', userError);
                this.currentUser = null;
                return null;
            }

            this.currentUser = userData;
            sessionStorage.setItem(this.STORAGE_KEY, JSON.stringify(userData));
            return userData;
        } catch (error) {
            console.error('Errore loadCurrentUser:', error);
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
            
            // Timeout wrapper per evitare hang
            const updatePromise = window.supabase.auth.updateUser({
                password: newPassword
            });
            
            const timeoutPromise = new Promise((_, reject) => 
                setTimeout(() => reject(new Error('Timeout: updateUser took too long')), 10000)
            );
            
            const { error } = await Promise.race([updatePromise, timeoutPromise]);

            if (error) {
                console.error('❌ Errore updateUser:', error);
                throw error;
            }

            console.log('✅ Password Supabase Auth aggiornata');

            // Aggiorna flag first_login
            if (this.currentUser) {
                console.log('📝 Aggiornando flag first_login per user ID:', this.currentUser.id);
                
                const { error: updateError } = await window.supabase
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
            } else {
                console.warn('⚠️ currentUser is null, cannot update first_login');
            }

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
        if (!user) return false;
        
        const adminRoles = ['Tecnico', 'Segreteria', 'Titolare'];
        return adminRoles.includes(user.ruolo);
    },

    // Require login (call in pages)
    async requireLogin() {
        const loggedIn = await this.isLoggedIn();
        if (!loggedIn) {
            window.location.href = 'index.html';
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
