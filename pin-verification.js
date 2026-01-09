// =====================================================
// PIN VERIFICATION SYSTEM - Super Admin Security
// =====================================================

class PinVerification {
    constructor() {
        this.maxAttempts = 3;
        this.attempts = 0;
        this.lockoutTime = 5 * 60 * 1000; // 5 minuti
    }

    /**
     * Verifica se l'utente richiede PIN
     */
    requiresPin(user) {
        return user && user.pin_code && user.pin_code.trim() !== '';
    }

    /**
     * Mostra modal di richiesta PIN
     */
    async requestPin(user) {
        return new Promise((resolve, reject) => {
            // Controlla se ci sono troppi tentativi
            const lockoutData = this.checkLockout(user.id);
            if (lockoutData.isLocked) {
                const remainingTime = Math.ceil(lockoutData.remainingTime / 1000 / 60);
                alert(`🔒 Troppi tentativi errati. Riprova tra ${remainingTime} minuti.`);
                reject(new Error('Account temporaneamente bloccato'));
                return;
            }

            // Crea modal PIN
            const modal = this.createPinModal(user);
            document.body.appendChild(modal);

            // Focus sul primo input
            setTimeout(() => {
                modal.querySelector('.pin-input').focus();
            }, 100);

            // Gestisci conferma
            const confirmBtn = modal.querySelector('#confirmPinBtn');
            confirmBtn.addEventListener('click', () => {
                const enteredPin = this.getPinValue(modal);
                
                if (this.verifyPin(user, enteredPin)) {
                    this.resetAttempts(user.id);
                    document.body.removeChild(modal);
                    resolve(true);
                } else {
                    this.handleFailedAttempt(user.id);
                    const attemptsLeft = this.maxAttempts - this.attempts;
                    
                    if (attemptsLeft > 0) {
                        this.showError(modal, `❌ PIN errato! Tentativi rimasti: ${attemptsLeft}`);
                        this.clearPinInputs(modal);
                    } else {
                        this.lockAccount(user.id);
                        document.body.removeChild(modal);
                        alert('🔒 Troppi tentativi errati. Account bloccato per 5 minuti.');
                        reject(new Error('Troppi tentativi errati'));
                    }
                }
            });

            // Gestisci annullamento
            const cancelBtn = modal.querySelector('#cancelPinBtn');
            cancelBtn.addEventListener('click', () => {
                document.body.removeChild(modal);
                reject(new Error('PIN verification cancelled'));
            });

            // Gestisci Enter
            modal.querySelectorAll('.pin-input').forEach(input => {
                input.addEventListener('keypress', (e) => {
                    if (e.key === 'Enter') {
                        confirmBtn.click();
                    }
                });
            });
        });
    }

    /**
     * Crea modal per inserimento PIN
     */
    createPinModal(user) {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
        modal.innerHTML = `
            <div class="bg-white rounded-lg shadow-xl p-8 max-w-md w-full mx-4">
                <div class="text-center mb-6">
                    <div class="mx-auto w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-4">
                        <i class="fas fa-lock text-3xl text-blue-600"></i>
                    </div>
                    <h2 class="text-2xl font-bold text-gray-800 mb-2">Verifica Identità</h2>
                    <p class="text-gray-600">Ciao ${user.nome}, inserisci il tuo PIN per continuare</p>
                </div>

                <div class="mb-6">
                    <div class="flex justify-center gap-3 mb-4">
                        <input type="password" maxlength="1" class="pin-input w-12 h-14 text-center text-2xl font-bold border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" />
                        <input type="password" maxlength="1" class="pin-input w-12 h-14 text-center text-2xl font-bold border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" />
                        <input type="password" maxlength="1" class="pin-input w-12 h-14 text-center text-2xl font-bold border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" />
                        <input type="password" maxlength="1" class="pin-input w-12 h-14 text-center text-2xl font-bold border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" />
                        <input type="password" maxlength="1" class="pin-input w-12 h-14 text-center text-2xl font-bold border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" />
                        <input type="password" maxlength="1" class="pin-input w-12 h-14 text-center text-2xl font-bold border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" />
                        <input type="password" maxlength="1" class="pin-input w-12 h-14 text-center text-2xl font-bold border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" />
                    </div>
                    
                    <div id="pinError" class="text-red-600 text-sm text-center hidden"></div>
                </div>

                <div class="flex gap-3">
                    <button id="cancelPinBtn" class="flex-1 px-4 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 font-medium transition-colors">
                        <i class="fas fa-times mr-2"></i>Annulla
                    </button>
                    <button id="confirmPinBtn" class="flex-1 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium transition-colors">
                        <i class="fas fa-check mr-2"></i>Conferma
                    </button>
                </div>

                <div class="mt-4 text-center text-xs text-gray-500">
                    <i class="fas fa-shield-alt mr-1"></i>
                    Il PIN è criptato e protetto
                </div>
            </div>
        `;

        // Auto-focus sul prossimo input
        modal.querySelectorAll('.pin-input').forEach((input, index) => {
            input.addEventListener('input', (e) => {
                if (e.target.value.length === 1 && index < 6) {
                    modal.querySelectorAll('.pin-input')[index + 1]?.focus();
                }
            });

            input.addEventListener('keydown', (e) => {
                if (e.key === 'Backspace' && e.target.value === '' && index > 0) {
                    modal.querySelectorAll('.pin-input')[index - 1]?.focus();
                }
            });
        });

        return modal;
    }

    /**
     * Ottieni valore PIN dagli input
     */
    getPinValue(modal) {
        const inputs = modal.querySelectorAll('.pin-input');
        return Array.from(inputs).map(input => input.value).join('');
    }

    /**
     * Verifica PIN
     */
    verifyPin(user, enteredPin) {
        return user.pin_code === enteredPin;
    }

    /**
     * Pulisci input PIN
     */
    clearPinInputs(modal) {
        modal.querySelectorAll('.pin-input').forEach(input => {
            input.value = '';
        });
        modal.querySelector('.pin-input').focus();
    }

    /**
     * Mostra errore
     */
    showError(modal, message) {
        const errorDiv = modal.querySelector('#pinError');
        errorDiv.textContent = message;
        errorDiv.classList.remove('hidden');
        
        setTimeout(() => {
            errorDiv.classList.add('hidden');
        }, 3000);
    }

    /**
     * Gestisci tentativo fallito
     */
    handleFailedAttempt(userId) {
        this.attempts++;
        const attemptsData = {
            count: this.attempts,
            timestamp: Date.now()
        };
        localStorage.setItem(`pin_attempts_${userId}`, JSON.stringify(attemptsData));
    }

    /**
     * Reset tentativi
     */
    resetAttempts(userId) {
        this.attempts = 0;
        localStorage.removeItem(`pin_attempts_${userId}`);
        localStorage.removeItem(`pin_lockout_${userId}`);
    }

    /**
     * Blocca account
     */
    lockAccount(userId) {
        const lockoutData = {
            lockedAt: Date.now(),
            unlockAt: Date.now() + this.lockoutTime
        };
        localStorage.setItem(`pin_lockout_${userId}`, JSON.stringify(lockoutData));
    }

    /**
     * Controlla se account è bloccato
     */
    checkLockout(userId) {
        const lockoutData = localStorage.getItem(`pin_lockout_${userId}`);
        if (!lockoutData) {
            return { isLocked: false, remainingTime: 0 };
        }

        const data = JSON.parse(lockoutData);
        const now = Date.now();

        if (now < data.unlockAt) {
            return {
                isLocked: true,
                remainingTime: data.unlockAt - now
            };
        } else {
            // Lockout scaduto, rimuovi
            this.resetAttempts(userId);
            return { isLocked: false, remainingTime: 0 };
        }
    }
}

// Esporta istanza globale
window.pinVerification = new PinVerification();

console.log('✅ PIN Verification System loaded');
