/**
 * MOBILE ENHANCEMENTS - AST Panel
 * Funzionalità touch, gestures e ottimizzazioni mobile
 * NON influisce sul desktop
 */

(function() {
    'use strict';
    
    // Detect if mobile
    const isMobile = window.innerWidth <= 768;
    
    if (!isMobile) {
        console.log('Desktop mode - mobile enhancements disabled');
        return; // Exit se non è mobile
    }
    
    console.log('📱 Mobile mode activated');
    
    // ============================================
    // MOBILE HEADER & BOTTOM NAV
    // ============================================
    
    function createMobileUI() {
        // Create mobile header
        const header = document.createElement('div');
        header.className = 'mobile-header';
        header.innerHTML = `
            <button class="mobile-menu-btn" id="mobileMenuBtn">
                <i class="fas fa-bars"></i>
            </button>
            <h1>AST Panel</h1>
            <button class="mobile-menu-btn" style="visibility: hidden;">
                <i class="fas fa-bars"></i>
            </button>
        `;
        document.body.insertBefore(header, document.body.firstChild);
        
        // Bottom navigation REMOVED - using sidebar only
        
        // Mobile menu toggle
        document.getElementById('mobileMenuBtn').addEventListener('click', function() {
            const sidebar = document.getElementById('sidebar');
            sidebar.classList.toggle('mobile-open');
            
            // Use static overlay if exists, otherwise create dynamic one
            let overlay = document.getElementById('sidebar-overlay') || document.getElementById('mobile-overlay');
            
            if (sidebar.classList.contains('mobile-open')) {
                if (overlay && overlay.id === 'sidebar-overlay') {
                    // Static overlay exists, just show it
                    overlay.classList.add('active');
                    overlay.style.display = 'block';
                } else {
                    // Create dynamic overlay
                    overlay = document.createElement('div');
                    overlay.id = 'mobile-overlay';
                    overlay.style.cssText = 'position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 99;';
                    overlay.addEventListener('click', function() {
                        sidebar.classList.remove('mobile-open');
                        this.remove();
                    });
                    document.body.appendChild(overlay);
                }
            } else {
                if (overlay && overlay.id === 'sidebar-overlay') {
                    overlay.classList.remove('active');
                    overlay.style.display = 'none';
                } else if (overlay) {
                    overlay.remove();
                }
            }
        });
        
        // Close sidebar when clicking nav items
        const sidebarLinks = document.querySelectorAll('#sidebar a');
        sidebarLinks.forEach(link => {
            link.addEventListener('click', function() {
                const sidebar = document.getElementById('sidebar');
                sidebar.classList.remove('mobile-open');
                
                // Handle both static and dynamic overlay
                const staticOverlay = document.getElementById('sidebar-overlay');
                const dynamicOverlay = document.getElementById('mobile-overlay');
                
                if (staticOverlay) {
                    staticOverlay.classList.remove('active');
                    staticOverlay.style.display = 'none';
                }
                if (dynamicOverlay) {
                    dynamicOverlay.remove();
                }
            });
        });
    }
    
    // ============================================
    // SWIPE GESTURES
    // ============================================
    
    function initSwipeGestures() {
        let touchStartX = 0;
        let touchEndX = 0;
        let touchStartY = 0;
        let touchEndY = 0;
        
        document.addEventListener('touchstart', function(e) {
            touchStartX = e.changedTouches[0].screenX;
            touchStartY = e.changedTouches[0].screenY;
        }, { passive: true });
        
        document.addEventListener('touchend', function(e) {
            touchEndX = e.changedTouches[0].screenX;
            touchEndY = e.changedTouches[0].screenY;
            handleSwipe(e.target);
        }, { passive: true });
        
        function handleSwipe(target) {
            const deltaX = touchEndX - touchStartX;
            const deltaY = touchEndY - touchStartY;
            
            // Check if horizontal swipe (more horizontal than vertical)
            if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 100) {
                const taskCard = target.closest('.task-card');
                
                if (taskCard) {
                    if (deltaX > 0) {
                        // Swipe right - Complete
                        showSwipeAction(taskCard, 'complete', '✓ Completata');
                    } else {
                        // Swipe left - Archive
                        showSwipeAction(taskCard, 'archive', '📁 Archiviata');
                    }
                }
            }
        }
        
        function showSwipeAction(card, action, text) {
            // Visual feedback
            card.style.transform = action === 'complete' ? 'translateX(20px)' : 'translateX(-20px)';
            card.style.opacity = '0.7';
            
            // Reset after animation
            setTimeout(() => {
                card.style.transform = '';
                card.style.opacity = '';
            }, 300);
            
            // Show toast
            showToast(text, action === 'complete' ? 'success' : 'info');
        }
    }
    
    // ============================================
    // PULL TO REFRESH
    // ============================================
    
    function initPullToRefresh() {
        let touchStartY = 0;
        let isPulling = false;
        
        const pullIndicator = document.createElement('div');
        pullIndicator.className = 'pull-to-refresh';
        pullIndicator.innerHTML = '<i class="fas fa-sync fa-spin"></i> Aggiorna';
        document.body.appendChild(pullIndicator);
        
        document.addEventListener('touchstart', function(e) {
            if (window.scrollY === 0) {
                touchStartY = e.touches[0].clientY;
                isPulling = true;
            }
        }, { passive: true });
        
        document.addEventListener('touchmove', function(e) {
            if (isPulling && window.scrollY === 0) {
                const touchY = e.touches[0].clientY;
                const pullDistance = touchY - touchStartY;
                
                if (pullDistance > 80) {
                    pullIndicator.classList.add('active');
                }
            }
        }, { passive: true });
        
        document.addEventListener('touchend', function() {
            if (isPulling && pullIndicator.classList.contains('active')) {
                // Trigger refresh
                refreshData();
            }
            isPulling = false;
            pullIndicator.classList.remove('active');
        }, { passive: true });
    }
    
    function refreshData() {
        showToast('🔄 Aggiornamento dati...', 'info');
        
        // Reload current section data
        setTimeout(() => {
            if (typeof loadDashboardData === 'function') loadDashboardData();
            if (typeof loadMyTasks === 'function') loadMyTasks();
            if (typeof loadUserCommunications === 'function') loadUserCommunications();
            showToast('✅ Dati aggiornati', 'success');
        }, 500);
    }
    
    // ============================================
    // TOAST NOTIFICATIONS
    // ============================================
    
    function showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `mobile-toast toast-${type}`;
        toast.textContent = message;
        toast.style.cssText = `
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#3b82f6'};
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            z-index: 9999;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
            animation: slideUp 0.3s ease;
        `;
        
        document.body.appendChild(toast);
        
        setTimeout(() => {
            toast.style.animation = 'slideDown 0.3s ease';
            setTimeout(() => toast.remove(), 300);
        }, 2500);
    }
    
    window.showToast = showToast;
    
    // ============================================
    // HAPTIC FEEDBACK (for supported devices)
    // ============================================
    
    function hapticFeedback(type = 'light') {
        if (navigator.vibrate) {
            const patterns = {
                light: [10],
                medium: [20],
                heavy: [30],
                success: [10, 50, 10],
                error: [20, 50, 20, 50, 20]
            };
            navigator.vibrate(patterns[type] || patterns.light);
        }
    }
    
    window.hapticFeedback = hapticFeedback;
    
    // ============================================
    // LONG PRESS DETECTION
    // ============================================
    
    function initLongPress() {
        let pressTimer;
        
        document.addEventListener('touchstart', function(e) {
            const taskCard = e.target.closest('.task-card');
            if (taskCard) {
                pressTimer = setTimeout(() => {
                    hapticFeedback('medium');
                    showTaskContextMenu(taskCard, e);
                }, 500);
            }
        });
        
        document.addEventListener('touchend', function() {
            clearTimeout(pressTimer);
        });
        
        document.addEventListener('touchmove', function() {
            clearTimeout(pressTimer);
        });
    }
    
    function showTaskContextMenu(card, event) {
        const menu = document.createElement('div');
        menu.className = 'mobile-context-menu';
        menu.style.cssText = `
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: white;
            border-radius: 16px 16px 0 0;
            padding: 20px;
            z-index: 9999;
            box-shadow: 0 -4px 20px rgba(0,0,0,0.2);
            animation: slideUpMenu 0.3s ease;
        `;
        
        menu.innerHTML = `
            <div style="text-align: center; margin-bottom: 20px;">
                <div style="width: 40px; height: 4px; background: #d1d5db; border-radius: 2px; margin: 0 auto;"></div>
            </div>
            <div style="display: grid; gap: 12px;">
                <button onclick="this.closest('.mobile-context-menu').remove()" style="padding: 16px; background: #3b82f6; color: white; border: none; border-radius: 8px; font-size: 16px;">
                    <i class="fas fa-eye"></i> Visualizza Dettagli
                </button>
                <button onclick="this.closest('.mobile-context-menu').remove()" style="padding: 16px; background: #10b981; color: white; border: none; border-radius: 8px; font-size: 16px;">
                    <i class="fas fa-check"></i> Segna Completata
                </button>
                <button onclick="this.closest('.mobile-context-menu').remove()" style="padding: 16px; background: #f59e0b; color: white; border: none; border-radius: 8px; font-size: 16px;">
                    <i class="fas fa-edit"></i> Modifica Progresso
                </button>
                <button onclick="this.closest('.mobile-context-menu').remove()" style="padding: 16px; background: #ef4444; color: white; border: none; border-radius: 8px; font-size: 16px;">
                    <i class="fas fa-times"></i> Annulla
                </button>
            </div>
        `;
        
        document.body.appendChild(menu);
        
        // Close on background click
        const overlay = document.createElement('div');
        overlay.style.cssText = 'position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 9998;';
        overlay.addEventListener('click', () => {
            menu.remove();
            overlay.remove();
        });
        document.body.insertBefore(overlay, menu);
    }
    
    // ============================================
    // TEAM MEMBERS TOGGLE
    // ============================================
    
    window.toggleTeamMembers = function(btnElement) {
        const container = btnElement.nextElementSibling;
        const arrow = btnElement.querySelector('.arrow');
        
        if (container.classList.contains('expanded')) {
            container.classList.remove('expanded');
            btnElement.classList.remove('expanded');
        } else {
            container.classList.add('expanded');
            btnElement.classList.add('expanded');
        }
        
        if (typeof hapticFeedback === 'function') {
            hapticFeedback('light');
        }
    };
    
    // ============================================
    // PREVENT ZOOM ON INPUT FOCUS (iOS)
    // ============================================
    
    function preventZoomOnFocus() {
        const inputs = document.querySelectorAll('input, select, textarea');
        inputs.forEach(input => {
            input.addEventListener('focus', function() {
                const viewport = document.querySelector('meta[name=viewport]');
                if (viewport) {
                    viewport.setAttribute('content', 'width=device-width, initial-scale=1, maximum-scale=1');
                }
            });
            
            input.addEventListener('blur', function() {
                const viewport = document.querySelector('meta[name=viewport]');
                if (viewport) {
                    viewport.setAttribute('content', 'width=device-width, initial-scale=1');
                }
            });
        });
    }
    
    // ============================================
    // CUSTOM DATE PICKER FOR REQUEST MODAL (FINAL)
    // ============================================
    
    function initCustomDatePicker() {
        if (!isMobile) return;
        
        // Wait for request modal to exist
        setTimeout(() => {
            const requestModal = document.getElementById('requestModal');
            if (!requestModal) return;
            
            const startDateInput = document.getElementById('requestStartDate');
            const endDateInput = document.getElementById('requestEndDate');
            
            if (!startDateInput || !endDateInput) return;
            
            // Create custom buttons for each date input
            createDatePickerButton(startDateInput, 'Data Inizio');
            createDatePickerButton(endDateInput, 'Data Fine');
        }, 1000);
    }
    
    function createDatePickerButton(input, label) {
        const container = input.parentElement;
        
        // Create button
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'custom-date-picker-btn';
        btn.innerHTML = `
            <span class="icon">📅</span>
            <span class="text">${input.value ? formatDate(input.value) : 'Seleziona data'}</span>
        `;
        
        btn.addEventListener('click', () => {
            openMobileDatePicker(input, label, btn);
        });
        
        container.appendChild(btn);
    }
    
    function openMobileDatePicker(input, title, btn) {
        const popup = document.createElement('div');
        popup.className = 'mobile-calendar-popup';
        
        const today = new Date();
        const currentDate = input.value ? new Date(input.value) : today;
        let selectedDate = input.value ? new Date(input.value) : null;
        
        popup.innerHTML = `
            <div class="mobile-calendar-content">
                <div class="mobile-calendar-header">
                    <div class="mobile-calendar-title">${title}</div>
                    <button class="mobile-calendar-close">✕</button>
                </div>
                <div class="mobile-calendar-month-nav" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                    <button class="mobile-calendar-prev" style="width: 2.5rem; height: 2.5rem; border-radius: 50%; background: #f3f4f6; border: none; font-size: 1.25rem;">‹</button>
                    <div class="mobile-calendar-month-title" style="font-size: 1.1rem; font-weight: 600; color: #374151;"></div>
                    <button class="mobile-calendar-next" style="width: 2.5rem; height: 2.5rem; border-radius: 50%; background: #f3f4f6; border: none; font-size: 1.25rem;">›</button>
                </div>
                <div class="mobile-calendar-grid">
                    <div class="mobile-calendar-day-header">Dom</div>
                    <div class="mobile-calendar-day-header">Lun</div>
                    <div class="mobile-calendar-day-header">Mar</div>
                    <div class="mobile-calendar-day-header">Mer</div>
                    <div class="mobile-calendar-day-header">Gio</div>
                    <div class="mobile-calendar-day-header">Ven</div>
                    <div class="mobile-calendar-day-header">Sab</div>
                </div>
                <div class="mobile-calendar-days"></div>
                <button class="mobile-calendar-confirm">Conferma</button>
            </div>
        `;
        
        document.body.appendChild(popup);
        
        let currentMonth = currentDate.getMonth();
        let currentYear = currentDate.getFullYear();
        
        function renderCalendar() {
            const daysContainer = popup.querySelector('.mobile-calendar-days');
            const monthTitle = popup.querySelector('.mobile-calendar-month-title');
            
            const monthNames = ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
                              'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];
            monthTitle.textContent = `${monthNames[currentMonth]} ${currentYear}`;
            
            const firstDay = new Date(currentYear, currentMonth, 1);
            const lastDay = new Date(currentYear, currentMonth + 1, 0);
            const prevLastDay = new Date(currentYear, currentMonth, 0);
            
            const firstDayIndex = firstDay.getDay();
            const lastDayDate = lastDay.getDate();
            const prevLastDayDate = prevLastDay.getDate();
            
            let days = '';
            
            // Previous month days
            for (let i = firstDayIndex; i > 0; i--) {
                days += `<button class="mobile-calendar-day other-month" data-date="${currentYear}-${currentMonth}-${prevLastDayDate - i + 1}">${prevLastDayDate - i + 1}</button>`;
            }
            
            // Current month days
            for (let i = 1; i <= lastDayDate; i++) {
                const date = new Date(currentYear, currentMonth, i);
                const dateStr = date.toISOString().split('T')[0];
                const isToday = dateStr === today.toISOString().split('T')[0];
                const isSelected = selectedDate && dateStr === selectedDate.toISOString().split('T')[0];
                
                let classes = 'mobile-calendar-day';
                if (isToday) classes += ' today';
                if (isSelected) classes += ' selected';
                
                days += `<button class="${classes}" data-date="${dateStr}">${i}</button>`;
            }
            
            daysContainer.innerHTML = days;
            daysContainer.style.display = 'grid';
            daysContainer.style.gridTemplateColumns = 'repeat(7, 1fr)';
            daysContainer.style.gap = '0.5rem';
            
            // Add click handlers
            daysContainer.querySelectorAll('.mobile-calendar-day:not(.other-month)').forEach(dayBtn => {
                dayBtn.addEventListener('click', () => {
                    selectedDate = new Date(dayBtn.dataset.date);
                    renderCalendar();
                });
            });
        }
        
        renderCalendar();
        
        // Navigation
        popup.querySelector('.mobile-calendar-prev').addEventListener('click', () => {
            currentMonth--;
            if (currentMonth < 0) {
                currentMonth = 11;
                currentYear--;
            }
            renderCalendar();
        });
        
        popup.querySelector('.mobile-calendar-next').addEventListener('click', () => {
            currentMonth++;
            if (currentMonth > 11) {
                currentMonth = 0;
                currentYear++;
            }
            renderCalendar();
        });
        
        // Close
        popup.querySelector('.mobile-calendar-close').addEventListener('click', () => {
            popup.remove();
        });
        
        popup.addEventListener('click', (e) => {
            if (e.target === popup) {
                popup.remove();
            }
        });
        
        // Confirm
        popup.querySelector('.mobile-calendar-confirm').addEventListener('click', () => {
            if (selectedDate) {
                const dateStr = selectedDate.toISOString().split('T')[0];
                input.value = dateStr;
                btn.innerHTML = `
                    <span class="icon">📅</span>
                    <span class="text">${formatDate(dateStr)}</span>
                `;
                btn.classList.add('selected');
            }
            popup.remove();
        });
    }
    
    function formatDate(dateStr) {
        const date = new Date(dateStr);
        const day = date.getDate();
        const month = date.getMonth() + 1;
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    }
    
    // ============================================
    // MOBILE TASK MODAL (CALENDAR PAGE)
    // ============================================
    
    function createMobileTaskModal(taskData) {
        // Remove existing mobile modal if present
        const existing = document.querySelector('.mobile-task-modal');
        if (existing) {
            existing.remove();
        }
        
        const modal = document.createElement('div');
        modal.className = 'mobile-task-modal';
        
        // Add inline styles to ensure visibility
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        `;
        
        const priorityEmoji = {
            'alta': '🔴',
            'media': '🟡',
            'bassa': '🟢',
            'normale': '🔵'
        };
        
        const statusText = {
            'da_fare': 'Da Fare',
            'in_corso': 'In Corso',
            'revisione': 'In Revisione',
            'completato': 'Completato'
        };
        
        const modalContent = document.createElement('div');
        modalContent.style.cssText = `
            background: white;
            border-radius: 16px;
            max-width: 500px;
            width: 100%;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        `;
        
        modalContent.innerHTML = `
            <div class="mobile-task-modal-header" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; color: white; border-radius: 16px 16px 0 0; position: relative;">
                <h2 style="margin: 0; font-size: 20px; font-weight: bold;">${taskData.title}</h2>
                <button class="mobile-task-modal-close" onclick="closeMobileTaskModal()" style="position: absolute; top: 15px; right: 15px; background: rgba(255,255,255,0.2); border: none; color: white; font-size: 24px; width: 35px; height: 35px; border-radius: 50%; cursor: pointer;">✕</button>
            </div>
            
            <div class="mobile-task-modal-content" style="padding: 20px;">
                <!-- Griglia 2 colonne -->
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 12px;">
                    <!-- Cliente -->
                    <div class="mobile-task-info-card client" style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 12px; padding: 12px;">
                        <div style="font-size: 20px; margin-bottom: 8px;">🏢</div>
                        <div class="mobile-task-info-label" style="font-size: 11px; color: #6b7280; margin-bottom: 4px;">Cliente</div>
                        <div class="mobile-task-info-value" style="font-size: 13px; font-weight: 600; color: #111827; line-height: 1.3;">${taskData.client || 'Nessun cliente'}</div>
                    </div>
                    
                    <!-- Scadenza -->
                    <div class="mobile-task-info-card deadline" style="background: #fff7ed; border: 1px solid #fed7aa; border-radius: 12px; padding: 12px;">
                        <div style="font-size: 20px; margin-bottom: 8px;">📅</div>
                        <div class="mobile-task-info-label" style="font-size: 11px; color: #6b7280; margin-bottom: 4px;">Scadenza</div>
                        <div class="mobile-task-info-value" style="font-size: 13px; font-weight: 600; color: #111827;">${taskData.deadline}</div>
                    </div>
                    
                    <!-- Priorità -->
                    <div class="mobile-task-info-card priority" style="background: #fef2f2; border: 1px solid #fecaca; border-radius: 12px; padding: 12px;">
                        <div style="font-size: 20px; margin-bottom: 8px;">⚠️</div>
                        <div class="mobile-task-info-label" style="font-size: 11px; color: #6b7280; margin-bottom: 4px;">Priorità</div>
                        <div class="mobile-task-info-value" style="font-size: 13px; font-weight: 600; color: #111827;">${priorityEmoji[taskData.priority] || '🔵'} ${taskData.priority.charAt(0).toUpperCase() + taskData.priority.slice(1)}</div>
                    </div>
                    
                    <!-- Stato -->
                    <div class="mobile-task-info-card status" style="background: #f5f3ff; border: 1px solid #ddd6fe; border-radius: 12px; padding: 12px;">
                        <div style="font-size: 20px; margin-bottom: 8px;">📊</div>
                        <div class="mobile-task-info-label" style="font-size: 11px; color: #6b7280; margin-bottom: 4px;">Stato</div>
                        <div class="mobile-task-info-value" style="font-size: 13px; font-weight: 600; color: #111827;">${statusText[taskData.status] || 'Da Fare'}</div>
                    </div>
                </div>
                
                ${taskData.progress !== undefined && taskData.progress > 0 ? `
                <!-- Progress -->
                <div class="mobile-task-progress" style="background: #ecfeff; border: 1px solid #a5f3fc; border-radius: 12px; padding: 15px; margin-bottom: 12px;">
                    <div class="mobile-task-progress-header" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                        <div class="mobile-task-progress-label" style="font-size: 12px; color: #6b7280;">
                            <span>📈</span> Progresso
                        </div>
                        <div class="mobile-task-progress-value" style="font-size: 16px; font-weight: bold; color: #0891b2;">${taskData.progress}%</div>
                    </div>
                    <div class="mobile-task-progress-bar-bg" style="background: #e5e7eb; border-radius: 999px; height: 8px; overflow: hidden;">
                        <div class="mobile-task-progress-bar-fill" style="width: ${taskData.progress}%; background: linear-gradient(90deg, #06b6d4 0%, #3b82f6 100%); height: 100%; border-radius: 999px; transition: width 0.3s;"></div>
                    </div>
                </div>
                ` : ''}
                
                <!-- Descrizione -->
                <div class="mobile-task-description" style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 12px; padding: 15px;">
                    <div class="mobile-task-description-header" style="display: flex; align-items: center; gap: 8px; margin-bottom: 10px;">
                        <div class="mobile-task-description-icon" style="font-size: 20px;">📝</div>
                        <div class="mobile-task-description-label" style="font-size: 12px; color: #6b7280; font-weight: 600;">Descrizione</div>
                    </div>
                    <div class="mobile-task-description-text" style="font-size: 14px; color: #374151; line-height: 1.6;">${taskData.description || 'Nessuna descrizione'}</div>
                </div>
            </div>
            
            <div class="mobile-task-modal-footer" style="padding: 15px 20px; border-top: 1px solid #e5e7eb; background: #f9fafb; border-radius: 0 0 16px 16px;">
                <button onclick="closeMobileTaskModal()" style="width: 100%; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 12px; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer;">Chiudi</button>
            </div>
        `;
        
        modal.appendChild(modalContent);
        document.body.appendChild(modal);
        
        // Prevent body scroll
        document.body.style.overflow = 'hidden';
    }
    
    // Make functions global for calendar page
    window.createMobileTaskModal = createMobileTaskModal;
    window.closeMobileTaskModal = function() {
        const modal = document.querySelector('.mobile-task-modal');
        if (modal) {
            modal.remove();
            document.body.style.overflow = '';
        }
    };
    
    // ============================================
    // OPTIMIZE ANIMATIONS FOR MOBILE
    // ============================================
    
    function optimizeAnimations() {
        // Use transform instead of position for better performance
        const style = document.createElement('style');
        style.textContent = `
            @keyframes slideUp {
                from { transform: translate(-50%, 100px); opacity: 0; }
                to { transform: translate(-50%, 0); opacity: 1; }
            }
            @keyframes slideDown {
                from { transform: translate(-50%, 0); opacity: 1; }
                to { transform: translate(-50%, 100px); opacity: 0; }
            }
            @keyframes slideUpMenu {
                from { transform: translateY(100%); }
                to { transform: translateY(0); }
            }
        `;
        document.head.appendChild(style);
    }
    
    // ============================================
    // INITIALIZE ALL MOBILE FEATURES
    // ============================================
    
    function init() {
        console.log('🚀 Initializing mobile enhancements...');
        
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initMobile);
        } else {
            initMobile();
        }
    }
    
    function initMobile() {
        createMobileUI();
        initSwipeGestures();
        initPullToRefresh();
        initLongPress();
        preventZoomOnFocus();
        optimizeAnimations();
        initCustomDatePicker(); // Add custom date picker
        
        console.log('✅ Mobile enhancements loaded');
        
        // Show welcome toast
        setTimeout(() => {
            showToast('👋 Modalità Mobile Attiva', 'info');
        }, 1000);
    }
    
    // Start
    init();
    
    // ============================================
    // SERVICE WORKER FOR OFFLINE SUPPORT
    // ============================================
    
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('/Admin/sw.js')
            .then(() => console.log('✅ Service Worker registered'))
            .catch(err => console.log('❌ SW registration failed:', err));
    }
    
})();
