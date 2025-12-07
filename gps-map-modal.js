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
     * Con supporto ENTRATA + USCITA
     */
    showHistoryModal(timbratura) {
        // Estrai GPS ingresso e uscita
        const gpsIngresso = timbratura.posizione_gps || {};
        const latIngresso = gpsIngresso.latitude;
        const lngIngresso = gpsIngresso.longitude;
        const indirizzoIngresso = gpsIngresso.indirizzo || null;
        
        // Dati uscita (se presente)
        const gpsUscita = timbratura.posizione_gps_uscita || null;
        const hasUscita = gpsUscita && gpsUscita.latitude && gpsUscita.longitude;
        const hasOraUscita = timbratura.ora_uscita !== null && timbratura.ora_uscita !== undefined;
        
        const dataFormatted = new Date(timbratura.data).toLocaleDateString('it-IT', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        });

        const html = `
            <div class="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm flex items-center justify-center z-50 p-4" 
                 onclick="window.gpsMapModal.closeModal()">
                <div class="bg-white rounded-2xl shadow-2xl max-w-3xl w-full overflow-hidden animate-fadeIn" 
                     onclick="event.stopPropagation()">
                    
                    <!-- Header -->
                    <div class="bg-gradient-to-r from-blue-500 to-indigo-600 text-white p-6">
                        <div class="flex items-center justify-between">
                            <div>
                                <h3 class="text-2xl font-bold mb-1">📍 Posizioni Timbratura</h3>
                                <p class="text-blue-100">${dataFormatted} - ${timbratura.ora_ingresso || ''}${timbratura.ora_uscita ? ' → ' + timbratura.ora_uscita : ''}</p>
                            </div>
                            <button onclick="window.gpsMapModal.closeModal()" 
                                    class="text-white hover:bg-white hover:bg-opacity-20 rounded-lg p-2 transition-colors">
                                <i data-lucide="x" class="w-6 h-6"></i>
                            </button>
                        </div>
                    </div>
                    
                    <!-- Toggle Buttons -->
                    <div class="bg-gray-100 p-4 flex gap-3 border-b">
                        <button id="btnShowIngresso" onclick="window.gpsMapModal.switchToPosition('ingresso', ${latIngresso}, ${lngIngresso})" 
                                class="flex-1 bg-green-600 hover:bg-green-700 text-white font-bold py-3 px-4 rounded-lg transition-all flex items-center justify-center gap-2 shadow-md">
                            <span class="w-3 h-3 rounded-full bg-white"></span>
                            🟢 Ingresso ${timbratura.ora_ingresso || ''}
                        </button>
                        ${hasUscita ? `
                            <button id="btnShowUscita" onclick="window.gpsMapModal.switchToPosition('uscita', ${gpsUscita.latitude}, ${gpsUscita.longitude})" 
                                    class="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-700 font-bold py-3 px-4 rounded-lg transition-all flex items-center justify-center gap-2">
                                <span class="w-3 h-3 rounded-full bg-gray-600"></span>
                                🔴 Uscita ${timbratura.ora_uscita || ''}
                            </button>
                        ` : hasOraUscita ? `
                            <button disabled class="flex-1 bg-orange-100 text-orange-700 font-bold py-3 px-4 rounded-lg cursor-not-allowed flex items-center justify-center gap-2 border-2 border-orange-300">
                                <span class="w-3 h-3 rounded-full bg-orange-500"></span>
                                🔴 Uscita ${timbratura.ora_uscita} (GPS non disponibile)
                            </button>
                        ` : `
                            <button disabled class="flex-1 bg-gray-200 text-gray-400 font-bold py-3 px-4 rounded-lg cursor-not-allowed flex items-center justify-center gap-2">
                                <span class="w-3 h-3 rounded-full bg-gray-400"></span>
                                🔴 Uscita (non timbrata)
                            </button>
                        `}
                    </div>
                    
                    <!-- Map Container -->
                    <div id="timbratureMap" class="w-full h-96 bg-gray-100"></div>
                    
                    <!-- Footer Info -->
                    <div id="mapInfo" class="p-4 bg-gray-50 border-t">
                        <div class="space-y-2 text-sm text-gray-700">
                            <div class="flex items-start gap-2">
                                <span class="font-semibold min-w-24">📍 Coordinate:</span>
                                <span id="coordsText">${latIngresso.toFixed(6)}, ${lngIngresso.toFixed(6)}</span>
                            </div>
                            ${indirizzoIngresso ? `
                                <div class="flex items-start gap-2">
                                    <span class="font-semibold min-w-24">📮 Indirizzo:</span>
                                    <span id="addressText">${indirizzoIngresso}</span>
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

        // Store data for switching
        this.currentTimbratura = {
            ingresso: { lat: latIngresso, lng: lngIngresso, address: indirizzoIngresso },
            uscita: hasUscita ? { lat: gpsUscita.latitude, lng: gpsUscita.longitude, address: gpsUscita.indirizzo || null } : null
        };

        // Initialize map with ingresso
        setTimeout(() => this.initMap(latIngresso, lngIngresso), 100);
    }

    /**
     * 🔄 SWITCH TRA INGRESSO E USCITA
     */
    switchToPosition(tipo, lat, lng) {
        // Update buttons
        const btnIngresso = document.getElementById('btnShowIngresso');
        const btnUscita = document.getElementById('btnShowUscita');
        
        if (tipo === 'ingresso') {
            btnIngresso.className = 'flex-1 bg-green-600 hover:bg-green-700 text-white font-bold py-3 px-4 rounded-lg transition-all flex items-center justify-center gap-2 shadow-md';
            if (btnUscita) btnUscita.className = 'flex-1 bg-gray-300 hover:bg-gray-400 text-gray-700 font-bold py-3 px-4 rounded-lg transition-all flex items-center justify-center gap-2';
        } else {
            btnIngresso.className = 'flex-1 bg-gray-300 hover:bg-gray-400 text-gray-700 font-bold py-3 px-4 rounded-lg transition-all flex items-center justify-center gap-2';
            if (btnUscita) btnUscita.className = 'flex-1 bg-red-600 hover:bg-red-700 text-white font-bold py-3 px-4 rounded-lg transition-all flex items-center justify-center gap-2 shadow-md';
        }

        // Update coordinates text
        document.getElementById('coordsText').textContent = `${lat.toFixed(6)}, ${lng.toFixed(6)}`;
        
        // Update address if available
        const addressEl = document.getElementById('addressText');
        if (addressEl && this.currentTimbratura[tipo].address) {
            addressEl.textContent = this.currentTimbratura[tipo].address;
        }

        // Re-center map
        if (this.map) {
            this.map.setView([lat, lng], 16);
            if (this.marker) {
                this.marker.setLatLng([lat, lng]);
            }
        }
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
