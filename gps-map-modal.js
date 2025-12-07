/**
 * 🗺️ GPS MAP MODAL - Sistema Visualizzazione Mappa Timbrature
 * 
 * Features:
 * - Modal "Hai timbrato qui!" dopo timbratura
 * - Mappa Leaflet con marker posizione
 * - Visualizzazione storico posizioni timbrature
 * - Pulsante chiudi (X)
 */

class GPSMapModal {
    constructor() {
        this.map = null;
        this.marker = null;
        this.modalId = 'gpsMapModal';
    }

    /**
     * 📍 MOSTRA MODAL CONFERMA TIMBRATURA
     * Chiamata dopo che il dipendente timbra
     */
    showConfirmModal(latitude, longitude, tipo = 'ingresso') {
        const tipoLabel = tipo === 'ingresso' ? 'Ingresso' : 'Uscita';
        const icon = tipo === 'ingresso' ? '✅' : '🏁';
        
        const html = `
            <div class="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm flex items-center justify-center z-50 p-4" 
                 onclick="window.gpsMapModal.closeModal()">
                <div class="bg-white rounded-2xl shadow-2xl max-w-2xl w-full overflow-hidden animate-fadeIn" 
                     onclick="event.stopPropagation()">
                    
                    <!-- Header -->
                    <div class="bg-gradient-to-r from-green-500 to-emerald-600 text-white p-6">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center gap-3">
                                <span class="text-5xl">${icon}</span>
                                <div>
                                    <h3 class="text-2xl font-bold">Hai timbrato qui!</h3>
                                    <p class="text-green-100">Timbratura ${tipoLabel} registrata con successo</p>
                                </div>
                            </div>
                            <button onclick="window.gpsMapModal.closeModal()" 
                                    class="text-white hover:bg-white hover:bg-opacity-20 rounded-lg p-2 transition-colors">
                                <i data-lucide="x" class="w-6 h-6"></i>
                            </button>
                        </div>
                    </div>
                    
                    <!-- Map Container -->
                    <div id="timbratureMap" class="w-full h-96 bg-gray-100"></div>
                    
                    <!-- Footer -->
                    <div class="p-4 bg-gray-50 border-t flex items-center justify-between">
                        <div class="text-sm text-gray-600">
                            <span class="font-semibold">📍 Coordinate:</span>
                            <span class="ml-2">${latitude.toFixed(6)}, ${longitude.toFixed(6)}</span>
                        </div>
                        <button onclick="window.gpsMapModal.closeModal()" 
                                class="bg-green-600 hover:bg-green-700 text-white font-bold px-6 py-2 rounded-lg transition-colors">
                            ✓ Chiudi
                        </button>
                    </div>
                </div>
            </div>
        `;

        // Remove existing modal if present
        const existing = document.getElementById(this.modalId);
        if (existing) existing.remove();

        // Create modal
        const modal = document.createElement('div');
        modal.id = this.modalId;
        modal.innerHTML = html;
        document.body.appendChild(modal);

        // Initialize icons
        if (window.lucide) lucide.createIcons();

        // Initialize map after DOM is ready
        setTimeout(() => this.initMap(latitude, longitude), 100);
    }

    /**
     * 🗺️ MOSTRA MODAL STORICO TIMBRATURA
     * Chiamata quando si clicca "Vedi Mappa" nella lista
     */
    showHistoryModal(timbratura) {
        const { latitude, longitude, data_timbratura, tipo_timbratura, indirizzo } = timbratura;
        
        const dataFormatted = new Date(data_timbratura).toLocaleString('it-IT', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });

        const tipoLabel = tipo_timbratura === 'ingresso' ? '🟢 Ingresso' : '🔴 Uscita';
        
        const html = `
            <div class="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm flex items-center justify-center z-50 p-4" 
                 onclick="window.gpsMapModal.closeModal()">
                <div class="bg-white rounded-2xl shadow-2xl max-w-2xl w-full overflow-hidden animate-fadeIn" 
                     onclick="event.stopPropagation()">
                    
                    <!-- Header -->
                    <div class="bg-gradient-to-r from-blue-500 to-indigo-600 text-white p-6">
                        <div class="flex items-center justify-between">
                            <div>
                                <h3 class="text-2xl font-bold mb-1">📍 Posizione Timbratura</h3>
                                <p class="text-blue-100">${dataFormatted} - ${tipoLabel}</p>
                            </div>
                            <button onclick="window.gpsMapModal.closeModal()" 
                                    class="text-white hover:bg-white hover:bg-opacity-20 rounded-lg p-2 transition-colors">
                                <i data-lucide="x" class="w-6 h-6"></i>
                            </button>
                        </div>
                    </div>
                    
                    <!-- Map Container -->
                    <div id="timbratureMap" class="w-full h-96 bg-gray-100"></div>
                    
                    <!-- Footer -->
                    <div class="p-4 bg-gray-50 border-t">
                        <div class="space-y-2 text-sm text-gray-700">
                            <div class="flex items-start gap-2">
                                <span class="font-semibold min-w-24">📍 Coordinate:</span>
                                <span>${latitude.toFixed(6)}, ${longitude.toFixed(6)}</span>
                            </div>
                            ${indirizzo ? `
                                <div class="flex items-start gap-2">
                                    <span class="font-semibold min-w-24">📮 Indirizzo:</span>
                                    <span>${indirizzo}</span>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Remove existing modal
        const existing = document.getElementById(this.modalId);
        if (existing) existing.remove();

        // Create modal
        const modal = document.createElement('div');
        modal.id = this.modalId;
        modal.innerHTML = html;
        document.body.appendChild(modal);

        // Initialize icons
        if (window.lucide) lucide.createIcons();

        // Initialize map
        setTimeout(() => this.initMap(latitude, longitude, tipo_timbratura), 100);
    }

    /**
     * 🗺️ INIZIALIZZA MAPPA LEAFLET
     */
    initMap(latitude, longitude, tipo = 'ingresso') {
        const container = document.getElementById('timbratureMap');
        if (!container) {
            console.error('Map container not found');
            return;
        }

        // Clear existing map
        if (this.map) {
            this.map.remove();
            this.map = null;
        }

        // Create map
        this.map = L.map('timbratureMap').setView([latitude, longitude], 16);

        // Add tile layer (OpenStreetMap)
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 19
        }).addTo(this.map);

        // Custom marker icon
        const iconColor = tipo === 'ingresso' ? 'green' : 'red';
        const iconHtml = tipo === 'ingresso' 
            ? '<div style="background: #10b981; width: 30px; height: 30px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 8px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; font-size: 16px;">🏢</div>'
            : '<div style="background: #ef4444; width: 30px; height: 30px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 8px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; font-size: 16px;">🏠</div>';

        const customIcon = L.divIcon({
            html: iconHtml,
            className: 'custom-marker',
            iconSize: [30, 30],
            iconAnchor: [15, 15]
        });

        // Add marker
        this.marker = L.marker([latitude, longitude], { icon: customIcon })
            .addTo(this.map)
            .bindPopup(`
                <div class="text-center">
                    <strong>${tipo === 'ingresso' ? '🟢 Ingresso' : '🔴 Uscita'}</strong><br>
                    <small>${latitude.toFixed(6)}, ${longitude.toFixed(6)}</small>
                </div>
            `)
            .openPopup();

        // Add circle radius (100m)
        L.circle([latitude, longitude], {
            color: iconColor,
            fillColor: iconColor,
            fillOpacity: 0.1,
            radius: 100
        }).addTo(this.map);

        // Invalidate size (fix for modal)
        setTimeout(() => {
            if (this.map) this.map.invalidateSize();
        }, 200);
    }

    /**
     * ❌ CHIUDI MODAL
     */
    closeModal() {
        const modal = document.getElementById(this.modalId);
        if (modal) {
            modal.remove();
        }
        
        // Cleanup map
        if (this.map) {
            this.map.remove();
            this.map = null;
            this.marker = null;
        }
    }

    /**
     * 🔄 REVERSE GEOCODING (opzionale)
     * Converte coordinate in indirizzo leggibile
     */
    async reverseGeocode(latitude, longitude) {
        try {
            const response = await fetch(
                `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json`
            );
            const data = await response.json();
            return data.display_name || 'Indirizzo non disponibile';
        } catch (error) {
            console.error('Errore reverse geocoding:', error);
            return null;
        }
    }
}

// Inizializza globalmente
window.GPSMapModal = GPSMapModal;

// Auto-init
document.addEventListener('DOMContentLoaded', () => {
    window.gpsMapModal = new GPSMapModal();
    console.log('✅ GPSMapModal initialized');
});

// CSS Animations
const style = document.createElement('style');
style.textContent = `
    @keyframes fadeIn {
        from { opacity: 0; transform: scale(0.95); }
        to { opacity: 1; transform: scale(1); }
    }
    .animate-fadeIn {
        animation: fadeIn 0.3s ease-out;
    }
    .custom-marker {
        background: transparent !important;
        border: none !important;
    }
`;
document.head.appendChild(style);
