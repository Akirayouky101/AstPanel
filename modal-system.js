// Sistema di modale personalizzate per sostituire alert() e confirm()

// Modale Alert
function showAlert(title, message, type = 'info') {
    return new Promise((resolve) => {
        // Rimuovi modale esistente se presente
        const existingModal = document.getElementById('customAlertModal');
        if (existingModal) existingModal.remove();

        // Icone e colori per tipo
        const icons = {
            success: '<i class="fas fa-check-circle text-green-500 text-5xl mb-4"></i>',
            error: '<i class="fas fa-exclamation-circle text-red-500 text-5xl mb-4"></i>',
            warning: '<i class="fas fa-exclamation-triangle text-yellow-500 text-5xl mb-4"></i>',
            info: '<i class="fas fa-info-circle text-blue-500 text-5xl mb-4"></i>'
        };

        const buttonColors = {
            success: 'bg-green-600 hover:bg-green-700',
            error: 'bg-red-600 hover:bg-red-700',
            warning: 'bg-yellow-600 hover:bg-yellow-700',
            info: 'bg-blue-600 hover:bg-blue-700'
        };

        const modal = document.createElement('div');
        modal.id = 'customAlertModal';
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[9999] animate-fadeIn';
        modal.innerHTML = `
            <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 transform animate-scaleIn">
                <div class="p-8 text-center">
                    ${icons[type]}
                    <h3 class="text-2xl font-bold text-gray-800 mb-3">${title}</h3>
                    <p class="text-gray-600 mb-6 whitespace-pre-line">${message}</p>
                    <button onclick="closeCustomAlert()" class="px-8 py-3 ${buttonColors[type]} text-white rounded-lg font-semibold transition-all transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2">
                        OK
                    </button>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        // Funzione per chiudere
        window.closeCustomAlert = () => {
            modal.classList.add('animate-fadeOut');
            setTimeout(() => {
                modal.remove();
                delete window.closeCustomAlert;
                resolve();
            }, 200);
        };

        // Chiudi con ESC
        const escHandler = (e) => {
            if (e.key === 'Escape') {
                window.closeCustomAlert();
                document.removeEventListener('keydown', escHandler);
            }
        };
        document.addEventListener('keydown', escHandler);
    });
}

// Modale Confirm
function showConfirm(title, message, confirmText = 'Conferma', cancelText = 'Annulla', type = 'warning') {
    return new Promise((resolve) => {
        // Rimuovi modale esistente se presente
        const existingModal = document.getElementById('customConfirmModal');
        if (existingModal) existingModal.remove();

        const icons = {
            success: '<i class="fas fa-check-circle text-green-500 text-5xl mb-4"></i>',
            error: '<i class="fas fa-exclamation-circle text-red-500 text-5xl mb-4"></i>',
            warning: '<i class="fas fa-exclamation-triangle text-yellow-500 text-5xl mb-4"></i>',
            info: '<i class="fas fa-info-circle text-blue-500 text-5xl mb-4"></i>',
            danger: '<i class="fas fa-trash-alt text-red-500 text-5xl mb-4"></i>'
        };

        const modal = document.createElement('div');
        modal.id = 'customConfirmModal';
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[9999] animate-fadeIn';
        modal.innerHTML = `
            <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 transform animate-scaleIn">
                <div class="p-8 text-center">
                    ${icons[type]}
                    <h3 class="text-2xl font-bold text-gray-800 mb-3">${title}</h3>
                    <p class="text-gray-600 mb-6 whitespace-pre-line">${message}</p>
                    <div class="flex gap-3 justify-center">
                        <button onclick="resolveCustomConfirm(false)" class="px-6 py-3 bg-gray-200 hover:bg-gray-300 text-gray-800 rounded-lg font-semibold transition-all transform hover:scale-105 focus:outline-none">
                            ${cancelText}
                        </button>
                        <button onclick="resolveCustomConfirm(true)" class="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition-all transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                            ${confirmText}
                        </button>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        // Funzione per risolvere
        window.resolveCustomConfirm = (result) => {
            modal.classList.add('animate-fadeOut');
            setTimeout(() => {
                modal.remove();
                delete window.resolveCustomConfirm;
                resolve(result);
            }, 200);
        };

        // Chiudi con ESC (annulla)
        const escHandler = (e) => {
            if (e.key === 'Escape') {
                window.resolveCustomConfirm(false);
                document.removeEventListener('keydown', escHandler);
            }
        };
        document.addEventListener('keydown', escHandler);
    });
}

// Modale Prompt
function showPrompt(title, message, defaultValue = '', placeholder = '') {
    return new Promise((resolve) => {
        const existingModal = document.getElementById('customPromptModal');
        if (existingModal) existingModal.remove();

        const modal = document.createElement('div');
        modal.id = 'customPromptModal';
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[9999] animate-fadeIn';
        modal.innerHTML = `
            <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 transform animate-scaleIn">
                <div class="p-8">
                    <div class="text-center mb-6">
                        <i class="fas fa-edit text-blue-500 text-5xl mb-4"></i>
                        <h3 class="text-2xl font-bold text-gray-800 mb-3">${title}</h3>
                        <p class="text-gray-600 mb-4">${message}</p>
                    </div>
                    <input type="text" id="promptInput" value="${defaultValue}" placeholder="${placeholder}" 
                           class="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none mb-6 text-lg">
                    <div class="flex gap-3">
                        <button onclick="resolveCustomPrompt(null)" class="flex-1 px-6 py-3 bg-gray-200 hover:bg-gray-300 text-gray-800 rounded-lg font-semibold transition-all">
                            Annulla
                        </button>
                        <button onclick="resolveCustomPrompt(document.getElementById('promptInput').value)" class="flex-1 px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition-all">
                            Conferma
                        </button>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);
        
        // Focus sull'input
        setTimeout(() => {
            const input = document.getElementById('promptInput');
            input.focus();
            input.select();
        }, 100);

        window.resolveCustomPrompt = (result) => {
            modal.classList.add('animate-fadeOut');
            setTimeout(() => {
                modal.remove();
                delete window.resolveCustomPrompt;
                resolve(result);
            }, 200);
        };

        // Submit con Enter
        const input = document.getElementById('promptInput');
        input.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                window.resolveCustomPrompt(input.value);
            }
        });

        // Chiudi con ESC
        const escHandler = (e) => {
            if (e.key === 'Escape') {
                window.resolveCustomPrompt(null);
                document.removeEventListener('keydown', escHandler);
            }
        };
        document.addEventListener('keydown', escHandler);
    });
}

// Aggiungi animazioni CSS
const style = document.createElement('style');
style.textContent = `
    @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
    }
    @keyframes fadeOut {
        from { opacity: 1; }
        to { opacity: 0; }
    }
    @keyframes scaleIn {
        from { transform: scale(0.9); opacity: 0; }
        to { transform: scale(1); opacity: 1; }
    }
    .animate-fadeIn {
        animation: fadeIn 0.2s ease-out;
    }
    .animate-fadeOut {
        animation: fadeOut 0.2s ease-out;
    }
    .animate-scaleIn {
        animation: scaleIn 0.3s ease-out;
    }
`;
document.head.appendChild(style);
