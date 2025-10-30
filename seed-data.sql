-- =====================================================
-- AST PANEL - Dati Iniziali per Testing
-- =====================================================

-- =====================================================
-- USERS (Admin + Dipendenti)
-- =====================================================
INSERT INTO users (email, nome, cognome, ruolo, telefono, avatar, reparto, data_assunzione, stato)
VALUES 
    -- Admin
    ('admin@astpanel.com', 'Admin', 'Sistema', 'admin', '+39 123 456 7890', 'https://i.pravatar.cc/150?img=1', 'Amministrazione', '2024-01-01', 'attivo'),
    
    -- Dipendenti/Tecnici
    ('mario.rossi@astpanel.com', 'Mario', 'Rossi', 'tecnico', '+39 111 222 333', 'https://i.pravatar.cc/150?img=12', 'Installazioni', '2024-01-15', 'attivo'),
    ('anna.verdi@astpanel.com', 'Anna', 'Verdi', 'tecnico', '+39 222 333 444', 'https://i.pravatar.cc/150?img=5', 'Manutenzione', '2024-02-20', 'attivo'),
    ('giuseppe.neri@astpanel.com', 'Giuseppe', 'Neri', 'tecnico', '+39 333 444 555', 'https://i.pravatar.cc/150?img=8', 'Installazioni', '2024-03-10', 'attivo'),
    ('laura.blu@astpanel.com', 'Laura', 'Blu', 'tecnico', '+39 444 555 666', 'https://i.pravatar.cc/150?img=9', 'Assistenza', '2024-04-05', 'attivo');

-- =====================================================
-- CLIENTS (Clienti di esempio)
-- =====================================================
INSERT INTO clients (ragione_sociale, nome, cognome, tipo_cliente, indirizzo, citta, provincia, cap, latitudine, longitudine, telefono, email, pec, partita_iva, settore, note, data_inizio_rapporto, stato)
VALUES 
    ('TechCorp SRL', 'Marco', 'Bianchi', 'azienda', 'Via Roma 123', 'Milano', 'MI', '20100', 45.4642, 9.1900, '+39 02 1234567', 'info@techcorp.it', 'techcorp@pec.it', 'IT12345678901', 'Tecnologia', 'Cliente premium - Alta priorità', '2023-01-15', 'attivo'),
    
    ('DataCorp LTD', 'Laura', 'Verdi', 'azienda', 'Corso Italia 45', 'Roma', 'RM', '00100', 41.9028, 12.4964, '+39 06 9876543', 'contatti@datacorp.com', 'datacorp@pec.com', 'IT98765432109', 'Big Data', 'Richiede reportistica mensile', '2023-05-20', 'attivo'),
    
    ('SecureCorp SPA', 'Giovanni', 'Russo', 'azienda', 'Via Torino 89', 'Torino', 'TO', '10100', 45.0703, 7.6869, '+39 011 5555555', 'security@securecorp.it', 'securecorp@pec.it', 'IT11223344556', 'Sicurezza', 'Contratto annuale manutenzione', '2023-08-10', 'attivo'),
    
    ('Rossi Mario', 'Mario', 'Rossi', 'privato', 'Via Verdi 12', 'Bologna', 'BO', '40100', 44.4949, 11.3426, '+39 333 1234567', 'mario.rossi@email.com', NULL, NULL, 'Residenziale', 'Impianto antifurto abitazione', '2024-02-15', 'attivo'),
    
    ('Bianchi Anna', 'Anna', 'Bianchi', 'privato', 'Piazza Garibaldi 5', 'Firenze', 'FI', '50100', 43.7696, 11.2558, '+39 333 9876543', 'anna.bianchi@email.com', NULL, NULL, 'Residenziale', 'Videosorveglianza villa', '2024-03-20', 'potenziale');

-- =====================================================
-- COMPONENTS (Inventario componenti)
-- =====================================================
INSERT INTO components (nome, codice, categoria, descrizione, quantita_disponibile, unita_misura, prezzo_unitario, fornitore, note)
VALUES 
    -- Antifurto
    ('Centrale Antifurto Paradox SP4000', 'AF-PAR-SP4000', 'Antifurto', 'Centrale antifurto 4 zone espandibile', 15, 'pz', 180.00, 'Paradox Security', 'Consigliato per abitazioni medie'),
    ('Sensore PIR Dual Tech', 'AF-PIR-DT01', 'Antifurto', 'Sensore volumetrico doppia tecnologia', 35, 'pz', 45.00, 'DSC', 'Riduzione falsi allarmi'),
    ('Sirena Esterna Autoalimentata', 'AF-SIR-AUT', 'Antifurto', 'Sirena da esterno con batteria tampone', 20, 'pz', 85.00, 'INIM', 'Lampeggiante LED integrato'),
    
    -- Videosorveglianza
    ('Telecamera IP 4MP Dome', 'VS-IP-4MP-D', 'Videosorveglianza', 'Telecamera dome IP 4 Megapixel', 25, 'pz', 120.00, 'Hikvision', 'Visione notturna 30m'),
    ('NVR 16 Canali 4K', 'VS-NVR-16CH', 'Videosorveglianza', 'Videoregistratore di rete 16 canali', 8, 'pz', 450.00, 'Dahua', 'Supporta fino a 8MP'),
    ('HDD Videosorveglianza 4TB', 'VS-HDD-4TB', 'Videosorveglianza', 'Hard Disk Purple per videosorveglianza', 12, 'pz', 110.00, 'Western Digital', 'Ottimizzato per scrittura continua'),
    
    -- Rete
    ('Switch PoE 8 Porte', 'NET-SW-POE8', 'Rete', 'Switch PoE+ 8 porte Gigabit', 10, 'pz', 95.00, 'TP-Link', 'Budget PoE 120W'),
    ('Access Point WiFi 6', 'NET-AP-WIFI6', 'Rete', 'Access Point WiFi 6 dual band', 18, 'pz', 135.00, 'Ubiquiti', 'Gestione cloud inclusa'),
    
    -- Accessori
    ('Cavo UTP Cat6 305m', 'ACC-CAT6-305', 'Accessori', 'Matassa cavo UTP Cat6 schermato', 8, 'mt', 0.45, 'Nexans', 'Per esterni'),
    ('Alimentatore 12V 5A', 'ACC-PSU-12V5A', 'Accessori', 'Alimentatore switching 12V 5A', 30, 'pz', 18.00, 'Mean Well', 'Protezione sovraccarico');

-- =====================================================
-- Conferma
-- =====================================================
DO $$ 
DECLARE
    user_count INTEGER;
    client_count INTEGER;
    component_count INTEGER;
BEGIN 
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO client_count FROM clients;
    SELECT COUNT(*) INTO component_count FROM components;
    
    RAISE NOTICE '✅ Dati iniziali inseriti con successo!';
    RAISE NOTICE '👥 Users creati: %', user_count;
    RAISE NOTICE '🏢 Clients creati: %', client_count;
    RAISE NOTICE '📦 Components creati: %', component_count;
    RAISE NOTICE '';
    RAISE NOTICE '🔑 Credenziali Admin:';
    RAISE NOTICE '   Email: admin@astpanel.com';
    RAISE NOTICE '   (Password da configurare in Supabase Auth)';
END $$;
