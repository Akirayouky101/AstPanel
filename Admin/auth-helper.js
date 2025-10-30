// =====================================================
// AUTH HELPER - Sistema di autenticazione semplificato
// =====================================================

window.AuthHelper = {
    STORAGE_KEY: 'ast_current_user',

    // Simula login (per sviluppo - seleziona utente da DB)
    async login(userId) {
        try {
            const user = await window.UsersAPI.getById(userId);
            sessionStorage.setItem(this.STORAGE_KEY, JSON.stringify(user));
            return user;
        } catch (error) {
            console.error('Errore login:', error);
            throw error;
        }
    },

    // Logout
    logout() {
        sessionStorage.removeItem(this.STORAGE_KEY);
        window.location.href = 'index.html';
    },

    // Get current user from session
    getCurrentUser() {
        const userData = sessionStorage.getItem(this.STORAGE_KEY);
        return userData ? JSON.parse(userData) : null;
    },

    // Check if user is logged in
    isLoggedIn() {
        return this.getCurrentUser() !== null;
    },

    // Check if user is admin
    isAdmin() {
        const user = this.getCurrentUser();
        return user && user.ruolo === 'admin';
    },

    // Require login (call in pages)
    requireLogin() {
        if (!this.isLoggedIn()) {
            window.location.href = 'index.html';
            return false;
        }
        return true;
    },

    // Require admin (call in admin pages)
    requireAdmin() {
        if (!this.requireLogin()) return false;
        
        if (!this.isAdmin()) {
            window.location.href = 'pannello-utente.html';
            return false;
        }
        return true;
    }
};

console.log('✅ Auth Helper loaded');
