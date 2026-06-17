-- ============================================================
-- Import listino Tecnoalarm / Danea ZG
-- Totale prodotti: 420
-- ============================================================

-- STEP 1: Crea fornitore Tecnoalarm (se non esiste già)
-- Usare gen_random_uuid() direttamente nel CTE

DO $$
DECLARE
    v_fornitore_id UUID;
BEGIN
    -- Inserisci Tecnoalarm solo se non esiste già
    INSERT INTO fornitori (
        ragione_sociale, partita_iva, codice_fiscale,
        email, telefono,
        indirizzo, citta, cap, provincia, nazione,
        codice_fornitore, categoria,
        giorni_consegna, attivo, note
    ) VALUES (
        'TECNOALARM S.r.l.',
        '01792190017',
        '01792190017',
        'info@tecnoalarm.com',
        '+39 011 22 35 410',
        'Via Ciriè, 38',
        'San Mauro Torinese',
        '10099',
        'TO',
        'Italia',
        'TECNOALARM',
        'Antintrusione',
        7,
        true,
        'Produttore italiano sistemi antintrusione, antincendio e videosorveglianza. Sito: www.tecnoalarm.com'
    )
    ON CONFLICT (codice_fornitore) DO NOTHING;

    -- Recupera l''ID (appena inserito o già esistente)
    SELECT id INTO v_fornitore_id FROM fornitori WHERE codice_fornitore = 'TECNOALARM';

    -- STEP 2: Aggiorna le componenti già importate senza fornitore
    UPDATE components
    SET fornitore_id = v_fornitore_id,
        fornitore_preferito_id = v_fornitore_id
    WHERE codice IN (
        '00017',
        '00018',
        '001DFWN2500',
        '001DIR-L',
        '1083/55',
        '1083/94',
        '1183/5',
        '1719/1',
        '1750/2',
        '1760/16U',
        '1760/6',
        '9000/230',
        'ABB B427939',
        'ABB EM 560 8',
        'ABB S529211',
        'ABBONAMENTO',
        'ABBONAMENTO OMAGGIO 12 MESI',
        'ACT-RX2',
        'AJ050TXJ2KG/EU',
        'AJ052TXJ3KG/EU',
        'AR50F12C1AHNEU + AR50F12C1AHXEU',
        'AR50F18C1AHNEU + AR50F18C1AHXEU',
        'AR70F09C1AWNEU',
        'AR70F09C1AWNEU+AR70F09C1AWXEU',
        'AR70F12C1AWNEU',
        'AR70F12C1AWNEU+AR70F12C1AWXEU',
        'AR70F18C1AWNEU',
        'ATTIVAZIONE SIM',
        'AVE 45305',
        'AVE 53T05G',
        'AVE 53T08G',
        'B01332',
        'B10426',
        'BE9176213',
        'BE9230002',
        'BE940902696',
        'BE9534011',
        'BE9591023',
        'BE9764006',
        'BE9863173',
        'BEG 8586L',
        'BEG 8591',
        'BFT 2613388',
        'BH30/840',
        'BMM TP7TG25',
        'BOX-403017-IP65',
        'BOX-403022-IP65',
        'BOXPOLE-4030',
        'BTI 150704',
        'BTI 150713',
        'BTI 336904',
        'BTI 343031',
        'BTI 343051',
        'BTI 344232',
        'BTI 344292',
        'BTI 344652',
        'BTI 344672',
        'BTI 344682',
        'BTI 346020',
        'BTI 346841',
        'BTI 346851',
        'BTI 350010',
        'BTI 350020',
        'BTI 3501/1',
        'BTI 3501/2',
        'BTI 3501/3',
        'BTI 3501/4',
        'BTI 3501/5',
        'BTI 3501/6',
        'BTI 350211',
        'BTI 350221',
        'BTI 350511',
        'BTI 351000',
        'BTI 351021',
        'BTI 351111',
        'BTI 351301',
        'BTI 352000',
        'BTI 352021',
        'BTI 352031',
        'BTI 352041',
        'BTI 352301',
        'BTI 354000',
        'BTI 360002',
        'BTI 360005',
        'BTI 364614',
        'BTI 364622',
        'BTI 89.220',
        'BTI 90.220',
        'BTI F107N36D2',
        'BTI F107N72D',
        'BTI FA82C10',
        'BTI FA82C6',
        'BTI FA84C10',
        'BTI FA84C16',
        'BTI FA84C20',
        'BTI FA84C25',
        'BTI FG881C6',
        'BTI FH84C50',
        'BTI G43AC32',
        'BTI G44AC32',
        'BTI GC8230AC16',
        'BTI GC8813AC16',
        'BTI GN8813AC16',
        'BTI N4002N',
        'BTI N4140/16',
        'BTI N4180',
        'C110C80',
        'C110C90',
        'C110TAMPERTP64M',
        'C110TAPPIWINB',
        'C126BATT2X36SIR',
        'C126BATTCR2',
        'C126BATTRADIO',
        'CB100FS',
        'CB60F',
        'CECOPR00G02500A',
        'CFMOP-20',
        'CLICKER-N',
        'COE 2719W',
        'CPR FG16-2X1,5B',
        'CPR FG16-2X6B',
        'CS4010-8GT-110',
        'CS4220-16GT-190',
        'CSM 6008-20L4',
        'CT375/13R',
        'CUY HR80G3-202740',
        'CUY TRCOB-0811830',
        'DIS 15023200002264',
        'DIS 41482000',
        'DIS 41482300',
        'DUR DU22B2',
        'ECT1250',
        'EOW 15031-IO',
        'EOW 15159',
        'F101EV10504G-IT',
        'F101EV12150-IT',
        'F101EV4244G-IT',
        'F101SPEALM8PLUS',
        'F101SPEED414OC',
        'F101SPEED48P3A',
        'F101SPEED4PLUS',
        'F101SPEED8',
        'F101SPEED8PLUS',
        'F101SPEED8STD',
        'F101SPEEDALM8',
        'F101SPEEDALM8PL',
        'F101T42-IT',
        'F101T88-IT',
        'F102DBS200BIT',
        'F102EVCAMBWL',
        'F102EVCMDBWL',
        'F102EVDREDBWL',
        'F102EVGLOBBWL',
        'F102EVIRBWL/V',
        'F102EVLCDBWL',
        'F102EVMODBWL',
        'F102EVMODPROBWL',
        'F102EVQUADBWL',
        'F102EVREDWABWL',
        'F102EVSAELBWL',
        'F102EVSIRELBWL',
        'F102EVTXBWL',
        'F102EVTXBWLG',
        'F102EVTXBWLM',
        'F102EVTXIBWL',
        'F102EVTXIBWLG',
        'F102EVTXIBWLM',
        'F102EVTXSBWL',
        'F102EVTXSBWLG',
        'F102EVTXSBWLM',
        'F102GLOCALOTTA',
        'F102GLOSPACEBUS',
        'F102SNODOGLOB',
        'F102STAFFAGLOB',
        'F102TRIRED',
        'F102TRIREDBUS',
        'F102TRIREDWL',
        'F102TWIN18/V',
        'F102TWINB18/V',
        'F102WALLBWL',
        'F103EVATPX/KN',
        'F103EVATPX/LINB',
        'F103EVATPX/M',
        'F103EVCMD6BWL',
        'F103EVDIGICARDB',
        'F103EVDIGICARDG',
        'F103EVKEY',
        'F103MYSECURITY',
        'F103PROXKEYHS',
        'F104TECNOCELL4',
        'F105S2010BUSAL',
        'F105S2010PBUSAL',
        'F105SAEL2010LAL',
        'F105SIREL',
        'F105SIRTECBUS',
        'F106415 TF',
        'F106450N',
        'F106462N',
        'F106CINEM5',
        'F106CINSD122',
        'F106CTE 045M',
        'F106CTI 002',
        'F107TAPS-8BUS',
        'F108017 YU',
        'F108021 YU',
        'F108YUASA',
        'F108YUASA 12',
        'F11200000500',
        'F11200000506',
        'F11200000512',
        'F11200000518',
        'F11200000530',
        'F127BIRELEN',
        'F127ESPGSM4G',
        'F127ESPLAN',
        'F127EV430PROX',
        'F127EV50/AV',
        'F127EV700CARDB',
        'F127EV700CARDN',
        'F127EV700PROXB',
        'F127EV700PROXN',
        'F127EVCARD4GB',
        'F127EVESP4IN',
        'F127EVLCD',
        'F127EVOUT5RPBWL',
        'F127EVOUTRPBWL',
        'F127EVTPSKN',
        'F127TECNOVISION',
        'F127UTS43PROX',
        'F130TECNOWIFI',
        'FA7870071',
        'FAN AP3102',
        'FFLXRC2/3FG',
        'FG16-3G1,5M',
        'FG16-3G2,5M',
        'FGCERAPL1202SCH',
        'FGCERAPL802SCH',
        'FGCERAPL952SCH',
        'FIN 104182300000',
        'FIN 140182300000',
        'FIN 181182300000',
        'FIN 270182300000',
        'FLEXIO-SPLIT 1/4',
        'FLEXIO-SPLIT 3/8',
        'FN82C16',
        'FN84C32',
        'FPUWB',
        'FRZ05004GM100',
        'FRZ15003GM100',
        'FRZ25003GM100',
        'GEW GW62227H',
        'GEW GW62426',
        'GEW GWD4227R',
        'GW 27001',
        'GW 66242N',
        'GW 66326N',
        'GW20056',
        'GW20203',
        'GW20246',
        'GW26409',
        'GW26410',
        'GW27002',
        'GW27003',
        'GW27006',
        'GW27615',
        'GW40030',
        'GW50617',
        'GW52073',
        'H93/RX22A/I',
        'HAC-HDW2501TMQ-A-S2',
        'HAC-HFW2501TU-A-S2',
        'HD2TB',
        'HDV-203WD',
        'HDV-403WD',
        'HDV-803WD',
        'IBO B00684',
        'IBO B09505IBO',
        'IN-CONTROL 2DG',
        'INS B10412',
        'INS B10416',
        'INS B10676',
        'IN-SEL-E',
        'IN-SEL-I',
        'INSTALLAZIONE',
        'IPC-HDW3549H-AS-PV-S5',
        'IPC-HDW3849H-AS-PV-S5',
        'IPC-HFW2441S-S',
        'IPC-HFW3449E-S-IL',
        'IPC-HFW3841E-S-S2',
        'IPC-HFW5541T-ASE-S3',
        'KIT SACCHETTO BASE CENTRALE',
        'KM747403',
        'KM749991',
        'L4001N',
        'L4950',
        'LDV DP120018840G3',
        'LDV DP150026840G3',
        'LDV FL6910KLM840BG4',
        'LDV PCA75840S1',
        'LDV PLCMP120033840U',
        'LDV PP1680D940363',
        'LDV PP38120827301',
        'LDV VCA 100840C2',
        'LDV VCA100830C1',
        'LDV VDD268301',
        'LDV VT8EM188401',
        'LDV VT8EM368401',
        'LDV VT8EM588401',
        'LN4703',
        'MANODOPERA',
        'MODULAR 300',
        'MONITOR116',
        'MSZ-AY25VGKP+ MUZ-AY25CG',
        'MSZ-AY35VGKP+MUZ-AY35VG',
        'MSZHR35VF+MUZHR35VF',
        'MSZ-LN25VG2V+MUZ-LN25VG',
        'MSZ-LN35CG2V+MUZ-LN35VG',
        'NICEEPMB',
        'NOB AU4/66',
        'NOB LPX66/4K',
        'NOB LT66/4K',
        'NOB PLDS33',
        'NVR2104HS-P-I2',
        'NVR5208-EI',
        'NVR5216-EI',
        'NVR5216-EI2',
        'P100CARTELALL',
        'PER 1TDTR010/DDV',
        'PFA130-E',
        'PFA134',
        'PFA152-E',
        'PFB204W',
        'PG1M9W01',
        'PIATTAFORMA AEREA',
        'PLSUSPKIT',
        'Plug-in software Zone IP',
        'PMP GUS20G',
        'PT1530SL43',
        'PT1555/05',
        'PT2175/210L',
        'PT2175/210LO1',
        'PT6175R/210S1',
        'PT6775R/210S1',
        'QBX 0502701BLSC0305',
        'QX0502057GRSC0305',
        'R01160000 01',
        'R01650015 01',
        'RV0030610 25',
        'RYT MAGIC-GEL',
        'S105SAEL2010SCL',
        'S110SAEL2010BUN',
        'SC6012',
        'SE180.811',
        'SEM 4301/2',
        'SEM 4553',
        'SEM VRC460N',
        'SHARK 324',
        'SIMGSM',
        'SIMGSM OMAGGIO PER 12 MESI',
        'SNR 10313',
        'SNR A9F89463',
        'SNR MIP10104T',
        'SNR OVA39565',
        'SPB FRZ15002UM100',
        'SYNUS/2',
        'T06200620 01',
        'T06210600 01',
        'TCLNA4803BI',
        'TF1TFA1298-IT',
        'TF1TFA2596-IT',
        'TF1TFA41192-IT',
        'TF1TFSTLX350',
        'TF1TSA1G-IT',
        'TF1TSA1-IT',
        'TF1TSA1PROL50',
        'TF1TSA1R-IT',
        'TF1TSA1Y-IT',
        'TF1TSABILEXT',
        'TF1TSABILLIM',
        'TF1TSSTRACK',
        'TF4TSM1-IT',
        'TO-LED',
        'TO-VEDO',
        'TPC-BF1241-B7F8-DW-S8',
        'URCLWF',
        'URCLWFA',
        'URCLWFM',
        'UTD 1083/55',
        'UTD 1083/80',
        'UTD 1083/94',
        'UTD 1130/11',
        'UTD 1148/11',
        'UTD 1168/130',
        'UTD 1168/131',
        'UTD 1168/14',
        'UTD 1168/140',
        'UTD 1168/141',
        'UTD 1168/142',
        'UTD 1168/24',
        'UTD 1168/311',
        'UTD 1168/313',
        'UTD 1168/4',
        'UTD 1168/401',
        'UTD 1168/61',
        'UTD 1168/62',
        'UTD 1168/63',
        'UTD 1168/64',
        'UTD 1168/8',
        'UTD 1178/312',
        'UTD 1183/5',
        'UTD 1183/622',
        'UTD 1760/16U',
        'UTD 1760/6',
        'UTD 1783/724',
        'UTD 1783/748',
        'UTD 1783/758',
        'VCM 989905001',
        'VI16080',
        'VIW 00230.B',
        'WALKY1024BDKCE'
    )
    AND (fornitore_id IS NULL OR fornitore_id = '00000000-0000-0000-0000-000000000000');

END $$;

-- ============================================================
-- STEP 3: Import dei 420 prodotti
-- (ON CONFLICT DO NOTHING = sicuro da rieseguire)
-- ============================================================

-- Batch 1/5 (100 prodotti)
INSERT INTO components (
  nome, categoria, codice, barcode, descrizione,
  quantita_disponibile, giacenza, giacenza_minima,
  unita_misura, um, prezzo_unitario, prezzo_acquisto,
  fornitore, note, stato,
  fornitore_id, fornitore_preferito_id
)
SELECT
  v.nome, v.categoria, v.codice, v.barcode, v.descrizione,
  0, 0, 0, 'pz', 'pz', v.prezzo, v.prezzo,
  NULL, v.nota, 'attivo',
  f.id, f.id
FROM (VALUES
  ('HELMAN - 1QB08 Helman - Armadio metallico per videosorveglianza con doppia serratura, 53 x 65 x 20 cm - Colore bianco', 'Videosorveglianza', '00017', '00017', 'HELMAN - 1QB08 Helman - Armadio metallico per videosorveglianza con doppia serratura, 53 x 65 x 20 cm - Colore bianco', 456.0, 'Produttore: HELMAN | Subcategoria: ARMADI METALLICI'),
  ('Dahua - Telecamera TiOC dome IP 8Mp, AI WizSense, fissa 2.8mm, WDR, Starlight, deterrenza attiva, Smart Dual Illuminator, AcuPick', 'Videosorveglianza', '00018', '00018', 'Dahua - Telecamera TiOC dome IP 8Mp, AI WizSense, fissa 2.8mm, WDR, Starlight, deterrenza attiva, Smart Dual Illuminator, AcuPick', 488.0, 'Produttore: DAHUA | Subcategoria: TELECAMERE DOME'),
  ('Profilo di sicurezza in gomma a contatto meccanico', 'Automazione', '001DFWN2500', '001DFWN2500', 'Profilo di sicurezza in gomma a contatto meccanico', 123.7, 'Produttore: CAME | Subcategoria: COSTE DI SICUREZZA'),
  ('Colonnina in alluminio per fotocellula DIR', 'Automazione', '001DIR-L', '001DIR-L', 'Colonnina in alluminio per fotocellula DIR', 28.0, 'Produttore: CAME | Subcategoria: COLONNINE'),
  ('DISTRIBUTORE 4 UTENZE 2VOICE', 'Citofonia', '1083/55', '1083/55', 'DISTRIBUTORE 4 UTENZE 2VOICE', 39.03, 'Produttore: URMET'),
  ('CAVO 2VOICE MATASSA D 100 M', 'Citofonia', '1083/94', '1083/94', 'CAVO 2VOICE MATASSA D 100 M', 167.26, 'Produttore: URMET | Subcategoria: CAVI'),
  ('CITOFONO 2VOICE COMFORT', 'Citofonia', '1183/5', '1183/5', 'CITOFONO 2VOICE COMFORT', 44.86, 'Produttore: URMET | Subcategoria: CITOFONO'),
  ('VDEOCITOFONO 7'''' VMODO PER 2VOICE', 'Citofonia', '1719/1', '1719/1', 'VDEOCITOFONO 7'''' VMODO PER 2VOICE', 219.7, 'Produttore: URMET | Subcategoria: VIDEOCITOFONO'),
  ('VIDEOCITOFONO A COLORI 2VOICE', 'Citofonia', '1750/2', '1750/2', 'VIDEOCITOFONO A COLORI 2VOICE', 196.3, 'Produttore: URMET | Subcategoria: VIDEOCITOFONO'),
  ('VIDEOCITOFONO VOG5W VIVAVOCE 2VOICE BIANCO', 'Citofonia', '1760/16U', '1760/16U', 'VIDEOCITOFONO VOG5W VIVAVOCE 2VOICE BIANCO', 358.11, 'Produttore: URMET | Subcategoria: VIDEOCITOFONO'),
  ('VIDEOCITOFONO VOG5 VIVAVOCE 2VOICE', 'Citofonia', '1760/6', '1760/6', 'VIDEOCITOFONO VOG5 VIVAVOCE 2VOICE', 202.8, 'Produttore: URMET | Subcategoria: VIDEOCITOFONO'),
  ('TRASFORMATORE 12V - 230V/18VA', 'Citofonia', '9000/230', '9000/230', 'TRASFORMATORE 12V - 230V/18VA', 64.31, 'Subcategoria: TRASFORMATORE'),
  ('DDA204 AC 25A 30MA BLOCCO DIFFERENZIALE 4P', 'Elettrico', 'ABB B427939', 'ABB B427939', 'DDA204 AC 25A 30MA BLOCCO DIFFERENZIALE 4P', 194.6, 'Produttore: ABB | Subcategoria: MAGNETOTERMICI'),
  ('Minicontattori tripolari con connessione a vite-5,5 kW (AC-3), bobina in c.a.', 'Elettrico', 'ABB EM 560 8', 'ABB EM 560 8', 'Minicontattori tripolari con connessione a vite-5,5 kW (AC-3), bobina in c.a.', 45.97, 'Produttore: ABB | Subcategoria: ACCESSORI'),
  ('S204 C16 INTERRUTTORE AUTOMATICO 6KA 4P', 'Elettrico', 'ABB S529211', 'ABB S529211', 'S204 C16 INTERRUTTORE AUTOMATICO 6KA 4P', 117.6, 'Produttore: ABB | Subcategoria: MAGNETOTERMICI'),
  ('Abbonamento ai servizi per la manutenzione ordinaria dell''impianto antintrusione. Durata 12 mesi', 'Servizi', 'ABBONAMENTO', 'ABBONAMENTO', 'Abbonamento ai servizi per la manutenzione ordinaria dell''impianto antintrusione. Durata 12 mesi', 120.0, NULL),
  ('Abbonamento ai servizi per la manutenzione ordinaria dell''impianto antintrusione. Durata 12 mesi (OMAGGIO PER I PRIMI 12 MESI DALLA DATA DI ATTIVAZIONE)', 'Servizi', 'ABBONAMENTO OMAGGIO 12 MESI', 'ABBONAMENTO OMAGGIO 12 MESI', 'Abbonamento ai servizi per la manutenzione ordinaria dell''impianto antintrusione. Durata 12 mesi (OMAGGIO PER I PRIMI 12 MESI DALLA DATA DI ATTIVAZIONE)', 120.0, NULL),
  ('Ricevitore bicanale in autoapprendimento', 'Automazione', 'ACT-RX2', 'ACT-RX2', 'Ricevitore bicanale in autoapprendimento', 42.0, 'Produttore: inteGRA | Subcategoria: RICEVENTI'),
  ('Unità esterna dual classe A+++', 'Climatizzazione', 'AJ050TXJ2KG/EU', 'AJ050TXJ2KG/EU', 'Unità esterna dual classe A+++', 1261.0, 'Produttore: SAMSUNG | Subcategoria: UNITA'' ESTERNA'),
  ('Unità esterna AJ052', 'Climatizzazione', 'AJ052TXJ3KG/EU', 'AJ052TXJ3KG/EU', 'Unità esterna AJ052', 1508.0, 'Produttore: SAMSUNG | Subcategoria: UNITA'' ESTERNA'),
  ('Unità interna a parete mono 12 000 btu. Pannello microforato. Modello Cebu. Possibilità di comando da remoto conl''app Smart Things. Wi-Fi. Classe A++', 'Climatizzazione', 'AR50F12C1AHNEU + AR50F12C1AHXEU', 'AR50F12C1AHNEU + AR50F12C1AHXEU', 'Unità interna a parete mono 12 000 btu. Pannello microforato. Modello Cebu. Possibilità di comando da remoto conl''app Smart Things. Wi-Fi. Classe A++', 695.5, 'Produttore: SAMSUNG | Subcategoria: MONO 12000 BTU'),
  ('Unità interna a parete mono 18 000 btu. Pannello microforato. Modello Cebu. Possibilità di comando da remoto conl''app Smart Things. Wi-Fi. Classe A++', 'Climatizzazione', 'AR50F18C1AHNEU + AR50F18C1AHXEU', 'AR50F18C1AHNEU + AR50F18C1AHXEU', 'Unità interna a parete mono 18 000 btu. Pannello microforato. Modello Cebu. Possibilità di comando da remoto conl''app Smart Things. Wi-Fi. Classe A++', 1073.8, 'Produttore: SAMSUNG | Subcategoria: MONO 18000 BTU'),
  ('Unità interna 9000 btu Wind Free Avant Pannello microforato. Raffrescamento dell’ambiente senza getti d’aria diretti.
Possibilità di comando da remoto con l’app Smart Things. Wi-Fi.Classe A++', 'Climatizzazione', 'AR70F09C1AWNEU', 'AR70F09C1AWNEU', 'Unità interna 9000 btu Wind Free Avant Pannello microforato. Raffrescamento dell’ambiente senza getti d’aria diretti.
Possibilità di comando da remoto con l’app Smart Things. Wi-Fi.Classe A++', 468.0, 'Produttore: SAMSUNG | Subcategoria: UNITA'' INTERNA'),
  ('Unità interna a parete ed unità esterna mono 9.000 btu. Pannello microforato. Modello Wind free Avant. Possibilità di comando da remoto con l’app Smart Things.Wi-Fi. Classe A++', 'Climatizzazione', 'AR70F09C1AWNEU+AR70F09C1AWXEU', 'AR70F09C1AWNEU+AR70F09C1AWXEU', 'Unità interna a parete ed unità esterna mono 9.000 btu. Pannello microforato. Modello Wind free Avant. Possibilità di comando da remoto con l’app Smart Things.Wi-Fi. Classe A++', 1066.0, 'Produttore: SAMSUNG | Subcategoria: MONO 9000 BTU'),
  ('Unità interna 12000 btu Wind Free Avant Pannello microforato. Raffrescamento dell’ambiente senza getti d’aria diretti.
Possibilità di comando da remoto con l’app Smart Things.Wi-Fi.Classe A++', 'Climatizzazione', 'AR70F12C1AWNEU', 'AR70F12C1AWNEU', 'Unità interna 12000 btu Wind Free Avant Pannello microforato. Raffrescamento dell’ambiente senza getti d’aria diretti.
Possibilità di comando da remoto con l’app Smart Things.Wi-Fi.Classe A++', 520.0, 'Subcategoria: UNITA'' INTERNA'),
  ('Unità interna a parete mono 12 000 btu. Pannello microforato. Modello WInd Free Avant. Possibilità di comando da remoto conl''app Smart Things. Wi-Fi. Classe A+++', 'Climatizzazione', 'AR70F12C1AWNEU+AR70F12C1AWXEU', 'AR70F12C1AWNEU+AR70F12C1AWXEU', 'Unità interna a parete mono 12 000 btu. Pannello microforato. Modello WInd Free Avant. Possibilità di comando da remoto conl''app Smart Things. Wi-Fi. Classe A+++', 1189.5, 'Produttore: SAMSUNG | Subcategoria: MONO 12000 BTU'),
  ('Unità interna a parete 18.000 btu.
Pannello microforato.Raffrescamento dell’ambiente senza getti d’aria diretti
Possibilità di comando da remoto con l’app Smart Things.Wi-Fi.Classe A++', 'Climatizzazione', 'AR70F18C1AWNEU', 'AR70F18C1AWNEU', 'Unità interna a parete 18.000 btu.
Pannello microforato.Raffrescamento dell’ambiente senza getti d’aria diretti
Possibilità di comando da remoto con l’app Smart Things.Wi-Fi.Classe A++', 832.0, 'Produttore: SAMSUNG'),
  ('Attivazione scheda sim (UNATANTUM)', 'SIM', 'ATTIVAZIONE SIM', 'ATTIVAZIONE SIM', 'Attivazione scheda sim (UNATANTUM)', 19.0, NULL),
  ('Pulsante unipolare nero', 'Elettrico', 'AVE 45305', 'AVE 45305', 'Pulsante unipolare nero', 9.05, 'Produttore: AVE | Subcategoria: ACCESSORI'),
  ('Coperchio grigio metallizzato IP40 5 moduli DIN - Dimensioni (L H P): 153 x 169 x 28 mm', 'Elettrico', 'AVE 53T05G', 'AVE 53T05G', 'Coperchio grigio metallizzato IP40 5 moduli DIN - Dimensioni (L H P): 153 x 169 x 28 mm', 22.95, 'Produttore: AVE | Subcategoria: ACCESSORI'),
  ('Coperchio IP40 colore grigio metallizzato - 8 moduli DIN - per scatole', 'Elettrico', 'AVE 53T08G', 'AVE 53T08G', 'Coperchio IP40 colore grigio metallizzato - 8 moduli DIN - per scatole', 25.41, 'Produttore: AVE | Subcategoria: ACCESSORI'),
  ('Canalina a pavimento 3 scomparti grigio 75x17 CSP-N', 'Elettrico', 'B01332', 'B01332', 'Canalina a pavimento 3 scomparti grigio 75x17 CSP-N', 31.77, 'Produttore: BOCCHIOTTI | Subcategoria: CANALINE'),
  ('Tubo rigido autoestinguente diam 16 PVC', 'Elettrico', 'B10426', 'B10426', 'Tubo rigido autoestinguente diam 16 PVC', 1.16, 'Produttore: INSET | Subcategoria: CANALINE'),
  ('centrale di comando per 1/2 attuatori per cancelli a battente, scorrevoli, operatori idraulici, porte industriali', 'Automazione', 'BE9176213', 'BE9176213', 'centrale di comando per 1/2 attuatori per cancelli a battente, scorrevoli, operatori idraulici, porte industriali', 147.0, 'Produttore: BENINCA | Subcategoria: CENTRALINE'),
  ('Colonnina Singola non premontata H 0,5 M', 'Automazione', 'BE9230002', 'BE9230002', 'Colonnina Singola non premontata H 0,5 M', 81.31, 'Produttore: BENINCA | Subcategoria: FOTOCELLULE'),
  ('Coppia di fotocellule per montaggio esterno su colonnina', 'Automazione', 'BE940902696', 'BE940902696', 'Coppia di fotocellule per montaggio esterno su colonnina', 37.8, 'Produttore: BENINCA | Subcategoria: FOTOCELLULE'),
  ('Lampeggiante bianco full range, 20÷255 Vac/dc con antenna integrata', 'Automazione', 'BE9534011', 'BE9534011', 'Lampeggiante bianco full range, 20÷255 Vac/dc con antenna integrata', 68.38, 'Produttore: BENINCA | Subcategoria: LAMPEGGIATORE'),
  ('Motoriduttore elettromeccanico irreversibile 230 V Encoder fino a 5 m', 'Automazione', 'BE9591023', 'BE9591023', 'Motoriduttore elettromeccanico irreversibile 230 V Encoder fino a 5 m', 315.0, 'Produttore: BENINCA'),
  ('Selettore a chiave da esterno', 'Automazione', 'BE9764006', 'BE9764006', 'Selettore a chiave da esterno', 23.8, 'Subcategoria: SELETTORI A CHIAVE'),
  ('BENINCA Trasmettitore 2 canali con codifica Advanced Rolling Code e Rolling Code.', 'Automazione', 'BE9863173', 'BE9863173', 'BENINCA Trasmettitore 2 canali con codifica Advanced Rolling Code e Rolling Code.', 16.66, 'Produttore: BENINCA | Subcategoria: RADIOCOMANDI'),
  ('Lampada di emergenza con elevato flusso luminoso IP65 LED 18W SE', 'Elettrico', 'BEG 8586L', 'BEG 8586L', 'Lampada di emergenza con elevato flusso luminoso IP65 LED 18W SE', 53.33, 'Produttore: BEGHELLI | Subcategoria: LAMPADE DI EMERGENZA'),
  ('Lampada di emergenza SA. Autonomia 2h. 4K', 'Elettrico', 'BEG 8591', 'BEG 8591', 'Lampada di emergenza SA. Autonomia 2h. 4K', 108.0, 'Produttore: BEGHELLI | Subcategoria: LAMPADE DI EMERGENZA'),
  ('MURA A30 - Coppia di fotocellule - P111812', 'Automazione', 'BFT 2613388', 'BFT 2613388', 'MURA A30 - Coppia di fotocellule - P111812', 39.0, 'Produttore: BFT | Subcategoria: FOTOCELLULE'),
  ('Motoriduttore Brushless irreversibile ad uso super intensivo 1000 kg completo di controller digitale finecorsa magnetico', 'Automazione', 'BH30/840', 'BH30/840', 'Motoriduttore Brushless irreversibile ad uso super intensivo 1000 kg completo di controller digitale finecorsa magnetico', 466.7, 'Produttore: ROGER | Subcategoria: CENTRALINE'),
  ('TUBO GUAINA IP67 D 25', 'Elettrico', 'BMM TP7TG25', 'BMM TP7TG25', 'TUBO GUAINA IP67 D 25', 0.94, 'Subcategoria: Tubo - Guaina'),
  ('Box in poliestere
Dimensioni esterne 40x30x17 cm
Grado di protezione IP65
Filtro di ventilazione
Guida Din regolabile
Colore grigio', 'Videosorveglianza', 'BOX-403017-IP65', 'BOX-403017-IP65', 'Box in poliestere
Dimensioni esterne 40x30x17 cm
Grado di protezione IP65
Filtro di ventilazione
Guida Din regolabile
Colore grigio', 70.0, NULL),
  ('Box in poliestere
Dimensioni esterne 40x30x22 cm
Grado di protezione IP65
Filtro di ventilazione
Guida Din regolabile
Colore grigio', 'Videosorveglianza', 'BOX-403022-IP65', 'BOX-403022-IP65', 'Box in poliestere
Dimensioni esterne 40x30x22 cm
Grado di protezione IP65
Filtro di ventilazione
Guida Din regolabile
Colore grigio', 84.0, NULL),
  ('Montaggio su palo e parete
Diametro 90-100 Ø
2 pezzi
Compatibile con BOX-403017-IP65 e BOX-403022-IP65', 'Videosorveglianza', 'BOXPOLE-4030', 'BOXPOLE-4030', 'Montaggio su palo e parete
Diametro 90-100 Ø
2 pezzi
Compatibile con BOX-403017-IP65 e BOX-403022-IP65', 34.0, NULL),
  ('Torretta a scomparsa 16/20 moduli
torretta a scomparsa 16/20 moduli - coperchio con finitura inox antiscivolo e maniglia ergonomica', 'Elettrico', 'BTI 150704', 'BTI 150704', 'Torretta a scomparsa 16/20 moduli
torretta a scomparsa 16/20 moduli - coperchio con finitura inox antiscivolo e maniglia ergonomica', 197.4, 'Produttore: BTICINO | Subcategoria: ACCESSORI'),
  ('Supporto per 4 moduli Matix per torrette a scomparsa', 'Elettrico', 'BTI 150713', 'BTI 150713', 'Supporto per 4 moduli Matix per torrette a scomparsa', 10.65, 'Produttore: BTICINO | Subcategoria: ACCESSORI'),
  ('Cavo bus citofonico', 'Citofonia', 'BTI 336904', 'BTI 336904', 'Cavo bus citofonico', 1.34, 'Produttore: BTICINO | Subcategoria: CAVI'),
  ('Pulsantiera Linea 2000. Tecnologia 2 fili, installazione da parete con frontale in alluminio, telecamera a colori ed illuminazione a LED bianchi per le riprese notturne.', 'Citofonia', 'BTI 343031', 'BTI 343031', 'Pulsantiera Linea 2000. Tecnologia 2 fili, installazione da parete con frontale in alluminio, telecamera a colori ed illuminazione a LED bianchi per le riprese notturne.', 287.0, 'Produttore: BTICINO'),
  ('Tetto antipioggia per pulsantiera Linea 3000 - finitura grigio.', 'Citofonia', 'BTI 343051', 'BTI 343051', 'Tetto antipioggia per pulsantiera Linea 3000 - finitura grigio.', 72.8, 'Produttore: BTICINO | Subcategoria: TETTI ANTIPIOGGIA'),
  ('Citofono Sprint L2 con cornetta', 'Citofonia', 'BTI 344232', 'BTI 344232', 'Citofono Sprint L2 con cornetta', 49.95, 'Produttore: BTICINO | Subcategoria: CORNETTE'),
  ('Citofono 2 fili con cornetta', 'Citofonia', 'BTI 344292', 'BTI 344292', 'Citofono 2 fili con cornetta', 69.11, 'Produttore: BTICINO'),
  ('Videocitofono 2 fili vivavoce con display a colori LCD da 5''''', 'Citofonia', 'BTI 344652', 'BTI 344652', 'Videocitofono 2 fili vivavoce con display a colori LCD da 5''''', 197.42, 'Produttore: BTICINO'),
  ('Videocitofono 2 fili vivavoce Classe 100. Tecnologia 2 fili vivavoce, con teleloop e display LCD a colori da 5”', 'Citofonia', 'BTI 344672', 'BTI 344672', 'Videocitofono 2 fili vivavoce Classe 100. Tecnologia 2 fili vivavoce, con teleloop e display LCD a colori da 5”', 385.0, 'Produttore: BTICINO'),
  ('Videocitofono connesso 2 fili Wifi vivavoce con display a colori LCD da 5''''', 'Citofonia', 'BTI 344682', 'BTI 344682', 'Videocitofono connesso 2 fili Wifi vivavoce con display a colori LCD da 5''''', 390.15, 'Produttore: BTICINO'),
  ('Alimentatore supplementare per BUS-SCS 2 moduli DIN. 27 Vdc 600 mA', 'Citofonia', 'BTI 346020', 'BTI 346020', 'Alimentatore supplementare per BUS-SCS 2 moduli DIN. 27 Vdc 600 mA', 119.45, 'Produttore: BTICINO'),
  ('Deviatore di piano 2 fili', 'Citofonia', 'BTI 346841', 'BTI 346841', 'Deviatore di piano 2 fili', 54.31, 'Produttore: BTICINO'),
  ('Interfaccia espansione impianto 2 fili. Consente di raddoppiare la lunghezza della tratta posto esterno - posto interno, di creare montanti a fonica indipendente e di espandere le prestazioni dell''impianto di appartamento.', 'Citofonia', 'BTI 346851', 'BTI 346851', 'Interfaccia espansione impianto 2 fili. Consente di raddoppiare la lunghezza della tratta posto esterno - posto interno, di creare montanti a fonica indipendente e di espandere le prestazioni dell''impianto di appartamento.', 490.0, 'Produttore: BTICINO'),
  ('Scatola da incasso 1 modulo', 'Citofonia', 'BTI 350010', 'BTI 350010', 'Scatola da incasso 1 modulo', 28.71, 'Produttore: BTICINO'),
  ('Scatola da incasso 2 moduli per linea SFERA e linea 3000', 'Citofonia', 'BTI 350020', 'BTI 350020', 'Scatola da incasso 2 moduli per linea SFERA e linea 3000', 29.28, 'Produttore: BTICINO'),
  ('Configuratore per sistemi 2 fili', 'Citofonia', 'BTI 3501/1', 'BTI 3501/1', 'Configuratore per sistemi 2 fili', 9.54, 'Produttore: BTICINO'),
  ('Configuratore per sistemi 2 fili', 'Citofonia', 'BTI 3501/2', 'BTI 3501/2', 'Configuratore per sistemi 2 fili', 9.54, 'Produttore: BTICINO'),
  ('Configuratore per sistemi 2 fili', 'Citofonia', 'BTI 3501/3', 'BTI 3501/3', 'Configuratore per sistemi 2 fili', 9.54, 'Produttore: BTICINO'),
  ('Configuratore per sistemi 2 fili', 'Citofonia', 'BTI 3501/4', 'BTI 3501/4', 'Configuratore per sistemi 2 fili', 9.54, 'Produttore: BTICINO'),
  ('Configuratore per sistemi 2 fili', 'Citofonia', 'BTI 3501/5', 'BTI 3501/5', 'Configuratore per sistemi 2 fili', 9.54, 'Produttore: BTICINO'),
  ('Configuratore per sistemi 2 fili', 'Citofonia', 'BTI 3501/6', 'BTI 3501/6', 'Configuratore per sistemi 2 fili', 9.54, 'Produttore: BTICINO'),
  ('Telaio supporto con cornice 1 modulo - SFERA', 'Citofonia', 'BTI 350211', 'BTI 350211', 'Telaio supporto con cornice 1 modulo - SFERA', 107.14, 'Produttore: BTICINO'),
  ('Telaio supporto con cornice 2 moduli. Linea SFERA', 'Citofonia', 'BTI 350221', 'BTI 350221', 'Telaio supporto con cornice 2 moduli. Linea SFERA', 96.55, 'Produttore: BTICINO'),
  ('Tetto antipioggia 1 modulo SFERA finitura Allmetal', 'Citofonia', 'BTI 350511', 'BTI 350511', 'Tetto antipioggia 1 modulo SFERA finitura Allmetal', 73.17, 'Produttore: BTICINO | Subcategoria: TETTI ANTIPIOGGIA'),
  ('Modulo fonico base SFERA per la realizzazione di impianti citofonici 2 fili', 'Citofonia', 'BTI 351000', 'BTI 351000', 'Modulo fonico base SFERA per la realizzazione di impianti citofonici 2 fili', 155.56, 'Produttore: BTICINO'),
  ('Frontale fonico base con 2 pulsanti di chiamata - linea SFERA', 'Citofonia', 'BTI 351021', 'BTI 351021', 'Frontale fonico base con 2 pulsanti di chiamata - linea SFERA', 46.2, 'Produttore: BTICINO'),
  ('Frontale modulo fonico evoluto 1 Pulsante', 'Citofonia', 'BTI 351111', 'BTI 351111', 'Frontale modulo fonico evoluto 1 Pulsante', 44.78, 'Produttore: BTICINO'),
  ('Frontale A/V grandangolare finitura Allmetal', 'Citofonia', 'BTI 351301', 'BTI 351301', 'Frontale A/V grandangolare finitura Allmetal', 44.7, 'Produttore: BTICINO'),
  ('Modulo SFERA con 4 pulsanti aggiuntivi disposti su colonna singola', 'Citofonia', 'BTI 352000', 'BTI 352000', 'Modulo SFERA con 4 pulsanti aggiuntivi disposti su colonna singola', 78.1, 'Produttore: BTICINO'),
  ('Frontale 2 pulsanti linea SFERA', 'Citofonia', 'BTI 352021', 'BTI 352021', 'Frontale 2 pulsanti linea SFERA', 22.8, 'Produttore: BTICINO'),
  ('Frontale 3 pulsanti su colonna singola finitura Allmetal', 'Citofonia', 'BTI 352031', 'BTI 352031', 'Frontale 3 pulsanti su colonna singola finitura Allmetal', 38.92, 'Produttore: BTICINO'),
  ('Frontale 4 pulsanti su colonna singola finitura Allmetal', 'Citofonia', 'BTI 352041', 'BTI 352041', 'Frontale 4 pulsanti su colonna singola finitura Allmetal', 30.38, 'Produttore: BTICINO'),
  ('Frontale copriforo finitura Allmetal', 'Citofonia', 'BTI 352301', 'BTI 352301', 'Frontale copriforo finitura Allmetal', 16.69, 'Produttore: BTICINO'),
  ('Cavo per il collegamento di più moduli pulsanti linea SFERA - lunghezza 620 mm', 'Citofonia', 'BTI 354000', 'BTI 354000', 'Cavo per il collegamento di più moduli pulsanti linea SFERA - lunghezza 620 mm', 27.88, 'Produttore: BTICINO'),
  ('Kit base d''impianto audio', 'Citofonia', 'BTI 360002', 'BTI 360002', 'Kit base d''impianto audio', 212.63, 'Produttore: BTICINO'),
  ('Kit impianto con modulo audio video e alimentatore - linea SFERA', 'Citofonia', 'BTI 360005', 'BTI 360005', 'Kit impianto con modulo audio video e alimentatore - linea SFERA', 430.65, 'Produttore: BTICINO'),
  ('Kit vivavoce monofamiliare con: videocitofono connesso CLASSE 100X16E Wi-Fi, vivavoce, teleloop, display LCD da 5”; pulsantiera LINEA 3000 con frontale in zama, telecamera a colori grandangolare e lettore di prossimità e con un kit di badge colorati e due', 'Citofonia', 'BTI 364614', 'BTI 364614', 'Kit vivavoce monofamiliare con: videocitofono connesso CLASSE 100X16E Wi-Fi, vivavoce, teleloop, display LCD da 5”; pulsantiera LINEA 3000 con frontale in zama, telecamera a colori grandangolare e lettore di prossimità e con un kit di badge colorati e due clear disc per attivazione elettroserratura.', 826.0, 'Produttore: BTICINO'),
  ('Kit video vivavoce bifamiliare composto da due videocitofoni Classe 100V16B e pulsantiera Linea 2000 con telecamera a colori e 2 pulsanti di chiamata. I videocitofoni dispongono di display LCD a colori da 5” e di 2 tasti fisici per il comando delle princi', 'Citofonia', 'BTI 364622', 'BTI 364622', 'Kit video vivavoce bifamiliare composto da due videocitofoni Classe 100V16B e pulsantiera Linea 2000 con telecamera a colori e 2 pulsanti di chiamata. I videocitofoni dispongono di display LCD a colori da 5” e di 2 tasti fisici per il comando delle principali funzioni videocitofoniche.', 679.0, 'Produttore: BTICINO'),
  ('Campana in bronzo dia 80 mm 230 Vac', 'Citofonia', 'BTI 89.220', 'BTI 89.220', 'Campana in bronzo dia 80 mm 230 Vac', 136.78, 'Produttore: BTICINO | Subcategoria: CAMPANE'),
  ('Campana in bronzo dia 120 mm_230 Vac', 'Citofonia', 'BTI 90.220', 'BTI 90.220', 'Campana in bronzo dia 120 mm_230 Vac', 178.74, 'Produttore: BTICINO | Subcategoria: CAMPANE'),
  ('Centralino da parete in polistirene antiurto rinforzato IP65 IDROBOARD 36 moduli DIN', 'Elettrico', 'BTI F107N36D2', 'BTI F107N36D2', 'Centralino da parete in polistirene antiurto rinforzato IP65 IDROBOARD 36 moduli DIN', 150.23, 'Produttore: BTICINO | Subcategoria: CENTRALINI'),
  ('Centralino da parete in polistirene antiurto rinforzato IP65 IDROBOARD 72 moduli DIN (4x18), classe di isolamento II, temperatura d’impiego: -20÷70°C', 'Elettrico', 'BTI F107N72D', 'BTI F107N72D', 'Centralino da parete in polistirene antiurto rinforzato IP65 IDROBOARD 72 moduli DIN (4x18), classe di isolamento II, temperatura d’impiego: -20÷70°C', 222.64, 'Produttore: BTICINO | Subcategoria: CENTRALINI'),
  ('Interruttore magnetotermico 2P curva C - In= 10A - Icn= 4,5kA - Vn= 400 Vac - 2 moduli', 'Elettrico', 'BTI FA82C10', 'BTI FA82C10', 'Interruttore magnetotermico 2P curva C - In= 10A - Icn= 4,5kA - Vn= 400 Vac - 2 moduli', 27.8, 'Produttore: TECNOALARM | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore magnetotermico 2P curva C - In= 6A - Icn= 4,5kA - Vn= 400 Vac - 2 moduli', 'Elettrico', 'BTI FA82C6', 'BTI FA82C6', 'Interruttore magnetotermico 2P curva C - In= 6A - Icn= 4,5kA - Vn= 400 Vac - 2 moduli', 29.51, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore magnetotermico 4P curva C - In= 10A - Icn= 4,5kA - Vn= 400 Vac - 4 moduli', 'Elettrico', 'BTI FA84C10', 'BTI FA84C10', 'Interruttore magnetotermico 4P curva C - In= 10A - Icn= 4,5kA - Vn= 400 Vac - 4 moduli', 79.29, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Iinterruttore magnetotermico 4P curva C - In= 16A - Icn= 4,5kA - Vn= 400 Vac - 4 moduli', 'Elettrico', 'BTI FA84C16', 'BTI FA84C16', 'Iinterruttore magnetotermico 4P curva C - In= 16A - Icn= 4,5kA - Vn= 400 Vac - 4 moduli', 78.12, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore magnetotermico 4P curva C - In= 20A - Icn= 4,5kA - Vn= 400 Vac - 4 moduli', 'Elettrico', 'BTI FA84C20', 'BTI FA84C20', 'Interruttore magnetotermico 4P curva C - In= 20A - Icn= 4,5kA - Vn= 400 Vac - 4 moduli', 78.37, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore magnetotermico 4P curva C - In= 25A - Icn= 4,5kA - Vn= 400 Vac - 4 moduli', 'Elettrico', 'BTI FA84C25', 'BTI FA84C25', 'Interruttore magnetotermico 4P curva C - In= 25A - Icn= 4,5kA - Vn= 400 Vac - 4 moduli', 78.37, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore magnetotermico modulare BTDIN-RS 1P+N curva C - In= 6A', 'Elettrico', 'BTI FG881C6', 'BTI FG881C6', 'Interruttore magnetotermico modulare BTDIN-RS 1P+N curva C - In= 6A', 11.04, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore magnetotermico 4P curva C - In= 50A - Icn= 10kA - Vn= 400 Vac - 4 moduli', 'Elettrico', 'BTI FH84C50', 'BTI FH84C50', 'Interruttore magnetotermico 4P curva C - In= 50A - Icn= 10kA - Vn= 400 Vac - 4 moduli', 190.67, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Modulo differenziale salvavita 4P - tipo AC - In= 32A - Idn= 30mA', 'Elettrico', 'BTI G43AC32', 'BTI G43AC32', 'Modulo differenziale salvavita 4P - tipo AC - In= 32A - Idn= 30mA', 173.35, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Modulo differenziale SALVAVITA 4P - tipo AC - In= 32A - Idn= 300mA - Vn= 400 Vac', 'Elettrico', 'BTI G44AC32', 'BTI G44AC32', 'Modulo differenziale SALVAVITA 4P - tipo AC - In= 32A - Idn= 300mA - Vn= 400 Vac', 128.39, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI')
) AS v(nome, categoria, codice, barcode, descrizione, prezzo, nota)
CROSS JOIN (SELECT id FROM fornitori WHERE codice_fornitore = 'TECNOALARM') AS f
ON CONFLICT (codice) DO NOTHING;

-- Batch 2/5 (100 prodotti)
INSERT INTO components (
  nome, categoria, codice, barcode, descrizione,
  quantita_disponibile, giacenza, giacenza_minima,
  unita_misura, um, prezzo_unitario, prezzo_acquisto,
  fornitore, note, stato,
  fornitore_id, fornitore_preferito_id
)
SELECT
  v.nome, v.categoria, v.codice, v.barcode, v.descrizione,
  0, 0, 0, 'pz', 'pz', v.prezzo, v.prezzo,
  NULL, v.nota, 'attivo',
  f.id, f.id
FROM (VALUES
  ('BTDIN-RS - interruttore magnetotermico differenziale 2P - 4,5kA - Idn=0,03A tipo AC - 4 moduli DIN - 230V - In=16A', 'Elettrico', 'BTI GC8230AC16', 'BTI GC8230AC16', 'BTDIN-RS - interruttore magnetotermico differenziale 2P - 4,5kA - Idn=0,03A tipo AC - 4 moduli DIN - 230V - In=16A', 51.8, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore magnetotermico differenziale AC1P+N 30MA', 'Elettrico', 'BTI GC8813AC16', 'BTI GC8813AC16', 'Interruttore magnetotermico differenziale AC1P+N 30MA', 35.1, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore magnetotermico differenziale BTDIN60 1P+N tipo AC - In= 16A - Idn= 0.03A', 'Elettrico', 'BTI GN8813AC16', 'BTI GN8813AC16', 'Interruttore magnetotermico differenziale BTDIN60 1P+N tipo AC - In= 16A - Idn= 0.03A', 168.13, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore bipolare 01 Living Light - Colore bianco', 'Elettrico', 'BTI N4002N', 'BTI N4002N', 'Interruttore bipolare 01 Living Light - Colore bianco', 16.9, 'Produttore: BTICINO | Subcategoria: ACCESSORI'),
  ('Presa schuko Living Light - Colore bianco', 'Elettrico', 'BTI N4140/16', 'BTI N4140/16', 'Presa schuko Living Light - Colore bianco', 21.41, 'Produttore: BTICINO | Subcategoria: ACCESSORI'),
  ('Presa bipasso Living Light - Colore bianco', 'Elettrico', 'BTI N4180', 'BTI N4180', 'Presa bipasso Living Light - Colore bianco', 10.54, 'Produttore: BTICINO | Subcategoria: ACCESSORI'),
  ('C 80 - Contenitore in ABS
Dimensioni (L x A x P): 140 x 92 x 38mm', 'Antintrusione', 'C110C80', 'C110C80', 'C 80 - Contenitore in ABS
Dimensioni (L x A x P): 140 x 92 x 38mm', 22.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('C90 - Contenitore in ABS 
Dimensioni (L x A x P): 165 x 110 x 41mm', 'Antintrusione', 'C110C90', 'C110C90', 'C90 - Contenitore in ABS 
Dimensioni (L x A x P): 165 x 110 x 41mm', 22.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('KIT TAMPER - Micro autoprotezione', 'Antintrusione', 'C110TAMPERTP64M', 'C110TAMPERTP64M', 'KIT TAMPER - Micro autoprotezione', 20.0, 'Produttore: TECNOALARM | Subcategoria: TAMPER'),
  ('Tappo terminale per barriere doorbeam/windbeam', 'Antintrusione', 'C110TAPPIWINB', 'C110TAPPIWINB', 'Tappo terminale per barriere doorbeam/windbeam', 3.8, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('Pack di 2 batterie AA 3,6V/2,6Ah per
ev sirel', 'Antintrusione', 'C126BATT2X36SIR', 'C126BATT2X36SIR', 'Pack di 2 batterie AA 3,6V/2,6Ah per
ev sirel', 22.0, 'Produttore: TECNOALARM | Subcategoria: BATTERIE'),
  ('BATTCR2 - Batteria 3V 0,85Ah per EV TX/TXS/TXI/IRS', 'Antintrusione', 'C126BATTCR2', 'C126BATTCR2', 'BATTCR2 - Batteria 3V 0,85Ah per EV TX/TXS/TXI/IRS', 6.0, 'Produttore: TECNOALARM | Subcategoria: BATTERIE'),
  ('Batteria AA 3,6V/2,6Ah per EV IR/EV DRED/REDWAVE/SMK/ TX310', 'Antintrusione', 'C126BATTRADIO', 'C126BATTRADIO', 'Batteria AA 3,6V/2,6Ah per EV IR/EV DRED/REDWAVE/SMK/ TX310', 12.0, 'Produttore: TECNOALARM | Subcategoria: BATTERIE'),
  ('Colonnina per fotocellula selettore H 1000 - 2 fori con base saldata', 'Automazione', 'CB100FS', 'CB100FS', 'Colonnina per fotocellula selettore H 1000 - 2 fori con base saldata', 44.2, 'Produttore: ROGER | Subcategoria: ACCESSORI'),
  ('Colonnina per fotocellula selettore H600 - 1 foro con base saldata', 'Automazione', 'CB60F', 'CB60F', 'Colonnina per fotocellula selettore H600 - 1 foro con base saldata', 28.6, 'Produttore: ROGER | Subcategoria: ACCESSORI'),
  ('Dispositivo di protezione con tecnologia a microinterruttori', 'Automazione', 'CECOPR00G02500A', 'CECOPR00G02500A', 'Dispositivo di protezione con tecnologia a microinterruttori', 65.38, 'Produttore: INTEGRA | Subcategoria: COSTE DI SICUREZZA'),
  ('Nologo - Costa di sicurezza con banda sensibile meccanica da 2,0 metri 8k2 certificata UNI EN 12978', 'Automazione', 'CFMOP-20', 'CFMOP-20', 'Nologo - Costa di sicurezza con banda sensibile meccanica da 2,0 metri 8k2 certificata UNI EN 12978', 79.65, 'Subcategoria: COSTE DI SICUREZZA'),
  ('Radiocomando 4 canali - 433 - colore nero', 'Automazione', 'CLICKER-N', 'CLICKER-N', 'Radiocomando 4 canali - 433 - colore nero', 13.49, 'Produttore: INTEGRA | Subcategoria: RADIOCOMANDI'),
  ('Citofono con cornetta serie MINI con chiamata elettronica, regolazione volume di chiamata. Dotato di serie di pulsanti apriporta e di altri 4 pulsanti predisposti per funzione intercomunicante o usi vari.', 'Citofonia', 'COE 2719W', 'COE 2719W', 'Citofono con cornetta serie MINI con chiamata elettronica, regolazione volume di chiamata. Dotato di serie di pulsanti apriporta e di altri 4 pulsanti predisposti per funzione intercomunicante o usi vari.', 96.6, 'Produttore: TECNOALARM | Subcategoria: CORNETTE'),
  ('Cavo FG 2X1,5 mmq', 'Elettrico', 'CPR FG16-2X1,5B', 'CPR FG16-2X1,5B', 'Cavo FG 2X1,5 mmq', 1.05, 'Subcategoria: CAVI'),
  ('Cavo FG16OR16 2X6mmq', 'Elettrico', 'CPR FG16-2X6B', 'CPR FG16-2X6B', 'Cavo FG16OR16 2X6mmq', 2.57, 'Subcategoria: CAVI'),
  ('Dahua - Switch Gigabit PoE Cloud Managed da 10 porte con: 8 porte RJ45 Gigabit PoE 10/100/1000Mbps e 2 porte Uplink 10/100/1000Mbps', 'Videosorveglianza', 'CS4010-8GT-110', 'CS4010-8GT-110', 'Dahua - Switch Gigabit PoE Cloud Managed da 10 porte con: 8 porte RJ45 Gigabit PoE 10/100/1000Mbps e 2 porte Uplink 10/100/1000Mbps', 306.0, 'Produttore: DAHUA | Subcategoria: SWITCH'),
  ('Dahua - Switch Gigabit Poe Cloud Managed da 20 porte con 16 porte RJ45 Gigabit PoE 10/100/1000 Mbps, 2 porte Uplink 10/100Mbps e 2 porte', 'Videosorveglianza', 'CS4220-16GT-190', 'CS4220-16GT-190', 'Dahua - Switch Gigabit Poe Cloud Managed da 20 porte con 16 porte RJ45 Gigabit PoE 10/100/1000 Mbps, 2 porte Uplink 10/100Mbps e 2 porte', 371.0, 'Produttore: dahuA'),
  ('Tubo rigido acciaio zincato diam. 20', 'Videosorveglianza', 'CSM 6008-20L4', 'CSM 6008-20L4', 'Tubo rigido acciaio zincato diam. 20', 2.17, 'Subcategoria: ACCESSORI'),
  ('Alpha Elettronica - Ricevitore per extender HDMI CT375/13-180p-KVM-Over IP', 'Videosorveglianza', 'CT375/13R', 'CT375/13R', 'Alpha Elettronica - Ricevitore per extender HDMI CT375/13-180p-KVM-Over IP', 201.6, NULL),
  ('Lampadina attacco E27 - 20W - 2450 lm', 'Elettrico', 'CUY HR80G3-202740', 'CUY HR80G3-202740', 'Lampadina attacco E27 - 20W - 2450 lm', 6.3, 'Produttore: CENTURY | Subcategoria: LAMPADINE'),
  ('Lampadina RS7 - 3K - 8W', 'Elettrico', 'CUY TRCOB-0811830', 'CUY TRCOB-0811830', 'Lampadina RS7 - 3K - 8W', 11.34, 'Produttore: CENTURY | Subcategoria: LAMPADINE'),
  ('Led panel 60x60 IP65', 'Elettrico', 'DIS 15023200002264', 'DIS 15023200002264', 'Led panel 60x60 IP65', 42.53, 'Produttore: DISANO | Subcategoria: LAMPADE'),
  ('Faro Rodio 1897 led 79W. Colore grafite', 'Elettrico', 'DIS 41482000', 'DIS 41482000', 'Faro Rodio 1897 led 79W. Colore grafite', 122.85, 'Produttore: DISANO | Subcategoria: FARI'),
  ('Faro Rodio 1897 led 196W,
Colore Grafite', 'Elettrico', 'DIS 41482300', 'DIS 41482300', 'Faro Rodio 1897 led 196W,
Colore Grafite', 179.55, 'Produttore: DISANO | Subcategoria: FARI'),
  ('Batterie CR2032 3V', 'Elettrico', 'DUR DU22B2', 'DUR DU22B2', 'Batterie CR2032 3V', 2.24, 'Produttore: DURACELL | Subcategoria: BATTERIE'),
  ('DELL ECT1250 Codice: D06H2 P/N: D06H2
 
Livello Capacità AI:Non-AI PC
Tipo di prodotto: PC Tecnologia del processore: Intel Core i7
Dimensione Dischi:1024 GBRAM:16 GB
Versione S.O.:Professional
Modello del processore:i7-14700Tipo Supporto 1:SSDModello sch', 'Generale', 'ECT1250', 'ECT1250', 'DELL ECT1250 Codice: D06H2 P/N: D06H2
 
Livello Capacità AI:Non-AI PC
Tipo di prodotto: PC Tecnologia del processore: Intel Core i7
Dimensione Dischi:1024 GBRAM:16 GB
Versione S.O.:Professional
Modello del processore:i7-14700Tipo Supporto 1:SSDModello scheda grafica: UHD Graphics 770S.o.: Windows 11
Form Factor:Tower', 900.0, 'Produttore: DELL'),
  ('Led panel EDGE LIGHT 1195X295X9,5MM 40K 40W+ALI', 'Elettrico', 'EOW 15031-IO', 'EOW 15031-IO', 'Led panel EDGE LIGHT 1195X295X9,5MM 40K 40W+ALI', 73.04, 'Produttore: ELCOM | Subcategoria: LAMPADE'),
  ('Kit di sospensione led panel', 'Elettrico', 'EOW 15159', 'EOW 15159', 'Kit di sospensione led panel', 5.18, 'Produttore: ELCOM | Subcategoria: ACCESSORI'),
  ('EV 10-50 - Sistema di allarme espandibile da 10 fino a 50 zone filari/wireless/virtuali - Vettori telefonici integrati IP e 4G LTE, Contenitore in metallo dimensioni (L x A x P): 398 x 309 x 108mm', 'Antintrusione', 'F101EV10504G-IT', 'F101EV10504G-IT', 'EV 10-50 - Sistema di allarme espandibile da 10 fino a 50 zone filari/wireless/virtuali - Vettori telefonici integrati IP e 4G LTE, Contenitore in metallo dimensioni (L x A x P): 398 x 309 x 108mm', 860.0, 'Produttore: TECNOALARM | Subcategoria: CENTRALI'),
  ('EV 12-150 - Sistema di allarme espandibile da 12 fino a 150 zone filari/wireless/virtuali - Vettori telefonici integrati IP e 4G LTE, tecnologia RDV®
e RSC®, sintesi vocale TTS, integrazioni wireless, video, home e automation, 1 Serial Bus, 1 Siren Bus, 1', 'Antintrusione', 'F101EV12150-IT', 'F101EV12150-IT', 'EV 12-150 - Sistema di allarme espandibile da 12 fino a 150 zone filari/wireless/virtuali - Vettori telefonici integrati IP e 4G LTE, tecnologia RDV®
e RSC®, sintesi vocale TTS, integrazioni wireless, video, home e automation, 1 Serial Bus, 1 Siren Bus, 1 Sensor Bus - Contenitore
in metallo dimensioni (L x A x P): 380 x 450 x 118mm, alloggiamento 2 batterie 12V/17Ah (non incluse), alimentatore switching 6A
@ 14,4V DC', 1100.0, 'Produttore: TECNOALARM | Subcategoria: CENTRALI'),
  ('EV 4-24 - Sistema di allarme espandibile da 4 fino a 24 zone, fino a 12 zone filari e 24 wireless - Vettori telefonici integrati IP e 4G LTE - Contenitore in ABS dimensioni (L x A x P): 350 x 285 x 93mm', 'Antintrusione', 'F101EV4244G-IT', 'F101EV4244G-IT', 'EV 4-24 - Sistema di allarme espandibile da 4 fino a 24 zone, fino a 12 zone filari e 24 wireless - Vettori telefonici integrati IP e 4G LTE - Contenitore in ABS dimensioni (L x A x P): 350 x 285 x 93mm', 504.0, 'Produttore: TECNOALARM | Subcategoria: CENTRALI'),
  ('SPEED SPEALM8PLUS - Modulo di espansione con 8 ingressi + 4 uscite
Alimentatore switching 1,8A - Contenitore in ABS
Dimensioni (L x A x P): 350 x 285 x 93mm', 'Antintrusione', 'F101SPEALM8PLUS', 'F101SPEALM8PLUS', 'SPEED SPEALM8PLUS - Modulo di espansione con 8 ingressi + 4 uscite
Alimentatore switching 1,8A - Contenitore in ABS
Dimensioni (L x A x P): 350 x 285 x 93mm', 260.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('SPEED 4-14 OC - Modulo di espansione con 4 ingressi + 14 uscite', 'Antintrusione', 'F101SPEED414OC', 'F101SPEED414OC', 'SPEED 4-14 OC - Modulo di espansione con 4 ingressi + 14 uscite', 82.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('SPEED 4-8 P3A - Modulo di espansione con 8 ingressi + 4 uscite
Alimentatore switching 3A - Contenitore in metallo
Dimensioni (L x A x P): 315 x 260 x 108mm', 'Antintrusione', 'F101SPEED48P3A', 'F101SPEED48P3A', 'SPEED 4-8 P3A - Modulo di espansione con 8 ingressi + 4 uscite
Alimentatore switching 3A - Contenitore in metallo
Dimensioni (L x A x P): 315 x 260 x 108mm', 340.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('SPEED 4 PLUS - Modulo di espansione con 4 ingressi + 1 uscita', 'Antintrusione', 'F101SPEED4PLUS', 'F101SPEED4PLUS', 'SPEED 4 PLUS - Modulo di espansione con 4 ingressi + 1 uscita', 120.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('SPEED 8 - Modulo di espansione con 8 ingressi + 2 uscite', 'Antintrusione', 'F101SPEED8', 'F101SPEED8', 'SPEED 8 - Modulo di espansione con 8 ingressi + 2 uscite', 108.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('SPEED 8 PLUS - Modulo di espansione con 8 ingressi + 2 uscite', 'Antintrusione', 'F101SPEED8PLUS', 'F101SPEED8PLUS', 'SPEED 8 PLUS - Modulo di espansione con 8 ingressi + 2 uscite', 130.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('SPEED 8 STD - Modulo di espansione con 8 ingressi convenzionali', 'Antintrusione', 'F101SPEED8STD', 'F101SPEED8STD', 'SPEED 8 STD - Modulo di espansione con 8 ingressi convenzionali', 86.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('SPEED ALM8 - Modulo di espansione con 8 ingressi + 4 uscite -
Alimentatore switching 1,8A - Contenitore in metallo
Dimensioni (L x A x P): 310 x 255 x 75mm', 'Antintrusione', 'F101SPEEDALM8', 'F101SPEEDALM8', 'SPEED ALM8 - Modulo di espansione con 8 ingressi + 4 uscite -
Alimentatore switching 1,8A - Contenitore in metallo
Dimensioni (L x A x P): 310 x 255 x 75mm', 270.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('SPEED ALM8PL - Modulo espansione dotato di 8 ingressi zona. Alimentatore switching 1,8A. Alloggiamento batteria 12V/7Ah. Collegamento bus RS485. Contenitore ABS.', 'Antintrusione', 'F101SPEEDALM8PL', 'F101SPEEDALM8PL', 'SPEED ALM8PL - Modulo espansione dotato di 8 ingressi zona. Alimentatore switching 1,8A. Alloggiamento batteria 12V/7Ah. Collegamento bus RS485. Contenitore ABS.', 236.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('TP 10-42 - Sistema di allarme espandibile da 10 fino a 24 zone filari/wireless - Vettori telefonici PSTN integrato, IP e 4G LTE opzionali,
tecnologia RDV® e RSC®, sintesi vocale, 1 Serial Bus, 1 Siren Bus, 1 Sensor Bus - Contenitore in metallo dimensioni ', 'Antintrusione', 'F101T42-IT', 'F101T42-IT', 'TP 10-42 - Sistema di allarme espandibile da 10 fino a 24 zone filari/wireless - Vettori telefonici PSTN integrato, IP e 4G LTE opzionali,
tecnologia RDV® e RSC®, sintesi vocale, 1 Serial Bus, 1 Siren Bus, 1 Sensor Bus - Contenitore in metallo dimensioni (L x A x P): 398 x 309 x 108mm, alimentatore switching 3A @ 14,4V DC.', 430.0, 'Produttore: TECNOALARM | Subcategoria: CENTRALI'),
  ('TP 8-88 - Sistema di allarme espandibile da 8 fino a 88 zone filari/wireless - Vettori telefonici PSTN integrato, IP e 4G LTE opzionali,
tecnologia RDV® e RSC®, sintesi vocale, 1 Serial Bus, 1 Siren Bus, 1 Sensor Bus - Contenitore in metallo dimensioni (L', 'Antintrusione', 'F101T88-IT', 'F101T88-IT', 'TP 8-88 - Sistema di allarme espandibile da 8 fino a 88 zone filari/wireless - Vettori telefonici PSTN integrato, IP e 4G LTE opzionali,
tecnologia RDV® e RSC®, sintesi vocale, 1 Serial Bus, 1 Siren Bus, 1 Sensor Bus - Contenitore in metallo dimensioni (L x A x P): 455 x 445 x 115mm', 560.0, 'Produttore: TECNOALARM | Subcategoria: CENTRALI'),
  ('DOORBEAM - Barriera a infrarossi attivi per la protezione di porte e finestre - 8 fasci - Colore bianco
Altezza su misura (da 2060 a 3000mm)', 'Antintrusione', 'F102DBS200BIT', 'F102DBS200BIT', 'DOORBEAM - Barriera a infrarossi attivi per la protezione di porte e finestre - 8 fasci - Colore bianco
Altezza su misura (da 2060 a 3000mm)', 365.0, 'Produttore: TECNOALARM | Subcategoria: BARRIERE INFRAROSSI'),
  ('EV CAM BWL - Rivelatore a infrarossi passivi wireless con fotocamera.
Banda di frequenza 868MHz', 'Antintrusione', 'F102EVCAMBWL', 'F102EVCAMBWL', 'EV CAM BWL - Rivelatore a infrarossi passivi wireless con fotocamera.
Banda di frequenza 868MHz', 231.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI'),
  ('EV CMD BWL - Radiocomando con 3 pulsanti di attuazione, 1 pulsante di
interrogazione. Banda di frequenza 868MHz', 'Antintrusione', 'F102EVCMDBWL', 'F102EVCMDBWL', 'EV CMD BWL - Radiocomando con 3 pulsanti di attuazione, 1 pulsante di
interrogazione. Banda di frequenza 868MHz', 74.0, 'Produttore: TECNOALARM | Subcategoria: RADIOCOMANDI'),
  ('EV DRED BWL - Rivelatore a infrarossi passivi wireless con contatto reed interno e ingresso per dispositivo esterno - Banda di frequenza 868MHz - Colore bianco', 'Antintrusione', 'F102EVDREDBWL', 'F102EVDREDBWL', 'EV DRED BWL - Rivelatore a infrarossi passivi wireless con contatto reed interno e ingresso per dispositivo esterno - Banda di frequenza 868MHz - Colore bianco', 100.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI ESTERNI'),
  ('EV GLOB BWL - Rivelatore a infrarossi passivi wireless. Protezione volumetrica multipoint alta densità. Portata 15m - IP44-IK04
Banda di frequenza 868MHz', 'Antintrusione', 'F102EVGLOBBWL', 'F102EVGLOBBWL', 'EV GLOB BWL - Rivelatore a infrarossi passivi wireless. Protezione volumetrica multipoint alta densità. Portata 15m - IP44-IK04
Banda di frequenza 868MHz', 252.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI ESTERNI'),
  ('EV IR BWL - Rivelatore a infrarossi passivi wireless. Banda di frequenza 868MHz. Lente volumetrica, portata 14m', 'Antintrusione', 'F102EVIRBWL/V', 'F102EVIRBWL/V', 'EV IR BWL - Rivelatore a infrarossi passivi wireless. Banda di frequenza 868MHz. Lente volumetrica, portata 14m', 97.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI'),
  ('EV LCD BWL - Console LCD wireless con lettore RFID integrato.
Banda di frequenza 868MHz', 'Antintrusione', 'F102EVLCDBWL', 'F102EVLCDBWL', 'EV LCD BWL - Console LCD wireless con lettore RFID integrato.
Banda di frequenza 868MHz', 190.0, 'Produttore: TECNOALARM | Subcategoria: TASTIERE'),
  ('EV MOD BWL - Modulo di integrazione wireless. Collegamento via bus seriale dedicato WL Bus', 'Antintrusione', 'F102EVMODBWL', 'F102EVMODBWL', 'EV MOD BWL - Modulo di integrazione wireless. Collegamento via bus seriale dedicato WL Bus', 126.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('EV MOD PRO - Modulo di integrazione wireless. Collegamento via bus seriale dedicato WL Bus', 'Antintrusione', 'F102EVMODPROBWL', 'F102EVMODPROBWL', 'EV MOD PRO - Modulo di integrazione wireless. Collegamento via bus seriale dedicato WL Bus', 240.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('EV QUADWING BWL - Rivelatore a infrarossi passivi wireless
2 fasci - Portata 12m - IP55
Banda di frequenza 868MHz
N.B. Pack di batterie (C126BATT2X36SIR) da ordinare
separatamente', 'Antintrusione', 'F102EVQUADBWL', 'F102EVQUADBWL', 'EV QUADWING BWL - Rivelatore a infrarossi passivi wireless
2 fasci - Portata 12m - IP55
Banda di frequenza 868MHz
N.B. Pack di batterie (C126BATT2X36SIR) da ordinare
separatamente', 288.0, 'Produttore: TECNOALARM'),
  ('EV REDWAVE BWL - Rivelatore doppia tecnologia wireless con contatto reed interno e ingresso per dispositivo esterno
Portata 3m - IP4x-IK04
Banda di frequenza 868MHz- Colore bianco', 'Antintrusione', 'F102EVREDWABWL', 'F102EVREDWABWL', 'EV REDWAVE BWL - Rivelatore doppia tecnologia wireless con contatto reed interno e ingresso per dispositivo esterno
Portata 3m - IP4x-IK04
Banda di frequenza 868MHz- Colore bianco', 120.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI ESTERNI'),
  ('EV SAEL BWL - Sirena piezoelettrica wireless con lampeggiante a LED.
Contenitore in ABS/ASA - IP43-IK07
Banda di frequenza 868MHz', 'Antintrusione', 'F102EVSAELBWL', 'F102EVSAELBWL', 'EV SAEL BWL - Sirena piezoelettrica wireless con lampeggiante a LED.
Contenitore in ABS/ASA - IP43-IK07
Banda di frequenza 868MHz', 242.0, 'Produttore: TECNOALARM | Subcategoria: SIRENE'),
  ('EV SIREL BWL - Sirena piezoelettrica wireless. Banda di frequenza 868MHz', 'Antintrusione', 'F102EVSIRELBWL', 'F102EVSIRELBWL', 'EV SIREL BWL - Sirena piezoelettrica wireless. Banda di frequenza 868MHz', 105.0, 'Produttore: TECNOALARM | Subcategoria: SIRENE'),
  ('EV TX BWL - Contatto magnetico wireless con due ingressi per dispositivi esterni - Banda di frequenza 868MHz - Colore Marrone', 'Antintrusione', 'F102EVTXBWL', 'F102EVTXBWL', 'EV TX BWL - Contatto magnetico wireless con due ingressi per dispositivi esterni - Banda di frequenza 868MHz - Colore Marrone', 74.0, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('EV TX BWLG - Contatto magnetico wireless con due ingressi per dispositivi esterni - Banda di frequenza 868MHz - Colore Grigio', 'Antintrusione', 'F102EVTXBWLG', 'F102EVTXBWLG', 'EV TX BWLG - Contatto magnetico wireless con due ingressi per dispositivi esterni - Banda di frequenza 868MHz - Colore Grigio', 74.0, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('EV TX BWLM - Contatto magnetico wireless con due ingressi per dispositivi esterni - Banda di frequenza 868MHz - Colore Marrone', 'Antintrusione', 'F102EVTXBWLM', 'F102EVTXBWLM', 'EV TX BWLM - Contatto magnetico wireless con due ingressi per dispositivi esterni - Banda di frequenza 868MHz - Colore Marrone', 74.0, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('EV TXI BWL - Contatto magnetico wireless con rilevatore di eventi fisici - IP3x-IK04 - Banda di frequenza 868MHz - Colore bianco', 'Antintrusione', 'F102EVTXIBWL', 'F102EVTXIBWL', 'EV TXI BWL - Contatto magnetico wireless con rilevatore di eventi fisici - IP3x-IK04 - Banda di frequenza 868MHz - Colore bianco', 80.0, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('EV TXI BWLG - Contatto magnetico wireless con rilevatore di eventi fisici - IP3x-IK04 - Banda di frequenza 868MHz - Colore grigio', 'Antintrusione', 'F102EVTXIBWLG', 'F102EVTXIBWLG', 'EV TXI BWLG - Contatto magnetico wireless con rilevatore di eventi fisici - IP3x-IK04 - Banda di frequenza 868MHz - Colore grigio', 80.0, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('EV TXI BWLM - Contatto magnetico wireless con rilevatore di eventi fisici - IP3x-IK04 - Banda di frequenza 868MHz - Colore marrone', 'Antintrusione', 'F102EVTXIBWLM', 'F102EVTXIBWLM', 'EV TXI BWLM - Contatto magnetico wireless con rilevatore di eventi fisici - IP3x-IK04 - Banda di frequenza 868MHz - Colore marrone', 80.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI ESTERNI'),
  ('EV TXS BWL - Contatto magnetico wireless. Banda di frequenza 868MHz', 'Antintrusione', 'F102EVTXSBWL', 'F102EVTXSBWL', 'EV TXS BWL - Contatto magnetico wireless. Banda di frequenza 868MHz', 66.0, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('EV TXS BWLG - Contatto magnetico wireless - IP3x-IK04
Banda di frequenza 868MHz
Colore grigio', 'Antintrusione', 'F102EVTXSBWLG', 'F102EVTXSBWLG', 'EV TXS BWLG - Contatto magnetico wireless - IP3x-IK04
Banda di frequenza 868MHz
Colore grigio', 66.0, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('EV TXS BWLM - Contatto wireless per porte/finestre - Colore marrone', 'Antintrusione', 'F102EVTXSBWLM', 'F102EVTXSBWLM', 'EV TXS BWLM - Contatto wireless per porte/finestre - Colore marrone', 66.0, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('CALOTTA GLOBAL SPACE - Calotta di protezione superiore, ampia superficie di copertura, protegge il rilevatore da eventi atmosferici e luce solare. Dimensioni (L x A x P): 136 x 58 x 162mm.', 'Antintrusione', 'F102GLOCALOTTA', 'F102GLOCALOTTA', 'CALOTTA GLOBAL SPACE - Calotta di protezione superiore, ampia superficie di copertura, protegge il rilevatore da eventi atmosferici e luce solare. Dimensioni (L x A x P): 136 x 58 x 162mm.', 13.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('GLOBAL SPACE BUS - Rivelatore doppia tecnologia per esterni', 'Antintrusione', 'F102GLOSPACEBUS', 'F102GLOSPACEBUS', 'GLOBAL SPACE BUS - Rivelatore doppia tecnologia per esterni', 216.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI ESTERNI'),
  ('SNODO GLOBAL SPACE - Snodo che consente un orientamento di H ± 90°, V ± 10°. Montaggio su superficie. Autoprotezioni: rimozione.', 'Antintrusione', 'F102SNODOGLOB', 'F102SNODOGLOB', 'SNODO GLOBAL SPACE - Snodo che consente un orientamento di H ± 90°, V ± 10°. Montaggio su superficie. Autoprotezioni: rimozione.', 22.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('STAFFA ANGOLARE GLOBAL SPACE - Staffa angolare reversibile che consente di montare il rilevatore a parete con un orientamento angolare di 22,5° o di 45°.', 'Antintrusione', 'F102STAFFAGLOB', 'F102STAFFAGLOB', 'STAFFA ANGOLARE GLOBAL SPACE - Staffa angolare reversibile che consente di montare il rilevatore a parete con un orientamento angolare di 22,5° o di 45°.', 6.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('TRIRED - Rivelatore a infrarossi passivi con modalità di rilevamento
programmabile, antimascheramento, compensazione temperatura e self test - Portata 30m - IP55', 'Antintrusione', 'F102TRIRED', 'F102TRIRED', 'TRIRED - Rivelatore a infrarossi passivi con modalità di rilevamento
programmabile, antimascheramento, compensazione temperatura e self test - Portata 30m - IP55', 322.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI ESTERNI'),
  ('TRIRED BUS - Rivelatore a infrarossi passivi con modalità di rilevamento
programmabile, antimascheramento, compensazione temperatura e self test - Portata 30m - IP55', 'Antintrusione', 'F102TRIREDBUS', 'F102TRIREDBUS', 'TRIRED BUS - Rivelatore a infrarossi passivi con modalità di rilevamento
programmabile, antimascheramento, compensazione temperatura e self test - Portata 30m - IP55', 344.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI ESTERNI'),
  ('TRIRED WL - Rivelatore a infrarossi passivi con modalità di rilevamento
programmabile, antimascheramento, compensazione temperatura e self test - Portata 15/30m - IP55', 'Antintrusione', 'F102TRIREDWL', 'F102TRIREDWL', 'TRIRED WL - Rivelatore a infrarossi passivi con modalità di rilevamento
programmabile, antimascheramento, compensazione temperatura e self test - Portata 15/30m - IP55', 430.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI ESTERNI'),
  ('TWINTEC - Rivelatore doppia tecnologia infrosso passivo + microonda con modalità di rilevamento programmabile (AND/WALK), funzione
RDV®, compensazione temperatura
Lente volumetrica - Portata 18m - IP4x-IK04', 'Antintrusione', 'F102TWIN18/V', 'F102TWIN18/V', 'TWINTEC - Rivelatore doppia tecnologia infrosso passivo + microonda con modalità di rilevamento programmabile (AND/WALK), funzione
RDV®, compensazione temperatura
Lente volumetrica - Portata 18m - IP4x-IK04', 82.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI'),
  ('TWINTEC BUS - Rivelatore doppia tecnologia con modalità di rilevamento programmabile, lente volumetrica - Portata 18m - IP4x-IK04', 'Antintrusione', 'F102TWINB18/V', 'F102TWINB18/V', 'TWINTEC BUS - Rivelatore doppia tecnologia con modalità di rilevamento programmabile, lente volumetrica - Portata 18m - IP4x-IK04', 108.0, 'Produttore: TECNOALARM | Subcategoria: VOLUMETRICI'),
  ('EV WALLGUARD BWL - Rivelatore a infrarossi passivi wireless
2 fasci - Portata 12m - IP55
Banda di frequenza 868MHz
N.B. Pack di batterie (C126BATT2X36SIR) da ordinare
separatamente', 'Antintrusione', 'F102WALLBWL', 'F102WALLBWL', 'EV WALLGUARD BWL - Rivelatore a infrarossi passivi wireless
2 fasci - Portata 12m - IP55
Banda di frequenza 868MHz
N.B. Pack di batterie (C126BATT2X36SIR) da ordinare
separatamente', 300.0, 'Produttore: TECNOALARM'),
  ('KEYSTONE - Moduli lettore chiavi RFID da incasso compatibile con adattatore Keystone - Colore nero', 'Antintrusione', 'F103EVATPX/KN', 'F103EVATPX/KN', 'KEYSTONE - Moduli lettore chiavi RFID da incasso compatibile con adattatore Keystone - Colore nero', 54.0, 'Produttore: TECNOALARM | Subcategoria: LETTORI CHIAVI RFID'),
  ('EV ATPROX/LINB - Moduli lettore chiavi RFID da incasso per serie BTicino Living International® - Colore bianco.', 'Antintrusione', 'F103EVATPX/LINB', 'F103EVATPX/LINB', 'EV ATPROX/LINB - Moduli lettore chiavi RFID da incasso per serie BTicino Living International® - Colore bianco.', 54.0, 'Produttore: TECNOALARM | Subcategoria: LETTORI CHIAVI RFID'),
  ('EV ATPROX/M - Moduli lettore chiavi RFID da incasso per serie BTicino Magic® - Colore bianco', 'Antintrusione', 'F103EVATPX/M', 'F103EVATPX/M', 'EV ATPROX/M - Moduli lettore chiavi RFID da incasso per serie BTicino Magic® - Colore bianco', 54.0, 'Produttore: TECNOALARM | Subcategoria: LETTORI CHIAVI RFID'),
  ('EV CMD6 BWL - Radiocomando con 5 pulsanti di attuazione, 1 pulsante di
interrogazione
Banda di frequenza 868MHz', 'Antintrusione', 'F103EVCMD6BWL', 'F103EVCMD6BWL', 'EV CMD6 BWL - Radiocomando con 5 pulsanti di attuazione, 1 pulsante di
interrogazione
Banda di frequenza 868MHz', 85.0, 'Produttore: TECNOALARM | Subcategoria: RADIOCOMANDI'),
  ('EV DIGITEX CARD - Tastiera con membrana tattile ad effetto capacitivo e lettore carte RFID MIFARE® DESFire® integrato - IP65 - Colore bianco', 'Antintrusione', 'F103EVDIGICARDB', 'F103EVDIGICARDB', 'EV DIGITEX CARD - Tastiera con membrana tattile ad effetto capacitivo e lettore carte RFID MIFARE® DESFire® integrato - IP65 - Colore bianco', 250.0, 'Produttore: TECNOALARM | Subcategoria: TASTIERE'),
  ('EV DIGITEX CARD - Tastiera con membrana tattile ad effetto capacitivo e lettore carte RFID MIFARE® DESFire® integrato - IP65 - Colore grigio', 'Antintrusione', 'F103EVDIGICARDG', 'F103EVDIGICARDG', 'EV DIGITEX CARD - Tastiera con membrana tattile ad effetto capacitivo e lettore carte RFID MIFARE® DESFire® integrato - IP65 - Colore grigio', 250.0, 'Produttore: TECNOALARM | Subcategoria: TASTIERE'),
  ('EV KEY - Chiave RFID', 'Antintrusione', 'F103EVKEY', 'F103EVKEY', 'EV KEY - Chiave RFID', 11.0, 'Produttore: TECNOALARM | Subcategoria: CHIAVI'),
  ('MYSECURITY CARD - Carta RFID MIFARE® DESFire® con codice univoco pre-programmato e non modificabile. La chiave non è duplicabile', 'Antintrusione', 'F103MYSECURITY', 'F103MYSECURITY', 'MYSECURITY CARD - Carta RFID MIFARE® DESFire® con codice univoco pre-programmato e non modificabile. La chiave non è duplicabile', 7.0, 'Produttore: TECNOALARM | Subcategoria: CHIAVI'),
  ('PROX KEY HS - Chiave Transponder non duplicabile - Colore blu', 'Antintrusione', 'F103PROXKEYHS', 'F103PROXKEYHS', 'PROX KEY HS - Chiave Transponder non duplicabile - Colore blu', 22.0, 'Produttore: TECNOALARM | Subcategoria: CHIAVI'),
  ('Comunicatore GSM 4G', 'Antintrusione', 'F104TECNOCELL4', 'F104TECNOCELL4', 'Comunicatore GSM 4G', 344.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI INTEGRAZIONE E INTERFACCE'),
  ('SAEL 2010 BUS AL - Sirena bus magneto dinamica con lampeggiante a LED. Cover in alluminio', 'Antintrusione', 'F105S2010BUSAL', 'F105S2010BUSAL', 'SAEL 2010 BUS AL - Sirena bus magneto dinamica con lampeggiante a LED. Cover in alluminio', 150.0, 'Produttore: TECNOALARM | Subcategoria: SIRENE'),
  ('SAEL 2010 PRO BUS - Sirena bus magneto dinamica con lampeggiante a LED, protezione antiperforazione - Cover in alluminio verniciato', 'Antintrusione', 'F105S2010PBUSAL', 'F105S2010PBUSAL', 'SAEL 2010 PRO BUS - Sirena bus magneto dinamica con lampeggiante a LED, protezione antiperforazione - Cover in alluminio verniciato', 172.0, 'Produttore: TECNOALARM | Subcategoria: SIRENE'),
  ('SAEL 2010 LED - Sirena magneto dinamica con lampeggiante a LED - cover in alluminio verniciato', 'Antintrusione', 'F105SAEL2010LAL', 'F105SAEL2010LAL', 'SAEL 2010 LED - Sirena magneto dinamica con lampeggiante a LED - cover in alluminio verniciato', 150.0, 'Produttore: TECNOALARM | Subcategoria: SIRENE'),
  ('SIREL - Sirena piezoelettrica.
Contenitore in ASA - IP3x-IK0', 'Antintrusione', 'F105SIREL', 'F105SIREL', 'SIREL - Sirena piezoelettrica.
Contenitore in ASA - IP3x-IK0', 35.0, 'Produttore: TECNOALARM | Subcategoria: SIRENE'),
  ('Sirena bus magneto dinamica autoalimentata. Molteplici opzioni di programmazione per caratterizzare la modalità di segnalazione in funzione dell’evento. Funzione di test alimentazione, batteria e altoparlante. SIRTEC BUS - Completa gestione RSC®. Ambito i', 'Antintrusione', 'F105SIRTECBUS', 'F105SIRTECBUS', 'Sirena bus magneto dinamica autoalimentata. Molteplici opzioni di programmazione per caratterizzare la modalità di segnalazione in funzione dell’evento. Funzione di test alimentazione, batteria e altoparlante. SIRTEC BUS - Completa gestione RSC®. Ambito installazione: interni. Autoprotezioni: apertura e rimozione. Alloggiamento batteria da 12V/2Ah. Certificazione EN 50131 grado di sicurezza 3.', 92.0, 'Produttore: TECNOALARM | Subcategoria: SIRENE'),
  ('415 TF - Contatti magnetici in ABS - Montaggio a incasso - Colore bianco', 'Antintrusione', 'F106415 TF', 'F106415 TF', '415 TF - Contatti magnetici in ABS - Montaggio a incasso - Colore bianco', 5.8, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('450 N - Contatto magnetico in alluminio per porte a battente - Montaggio a pavimento', 'Antintrusione', 'F106450N', 'F106450N', '450 N - Contatto magnetico in alluminio per porte a battente - Montaggio a pavimento', 27.8, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('462 N - Contatto magnetico in alluminio, montaggio a vista', 'Antintrusione', 'F106462N', 'F106462N', '462 N - Contatto magnetico in alluminio, montaggio a vista', 26.8, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('CINEM5 - Contatto inerziale in plastica - Montaggio a vista - Colore bianco', 'Antintrusione', 'F106CINEM5', 'F106CINEM5', 'CINEM5 - Contatto inerziale in plastica - Montaggio a vista - Colore bianco', 57.0, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('CINS D122 - Sensore inerziale e di vibrazione - Montaggio a incasso - Colore bianco', 'Antintrusione', 'F106CINSD122', 'F106CINSD122', 'CINS D122 - Sensore inerziale e di vibrazione - Montaggio a incasso - Colore bianco', 18.5, 'Produttore: TECNOALARM | Subcategoria: CONTATTI')
) AS v(nome, categoria, codice, barcode, descrizione, prezzo, nota)
CROSS JOIN (SELECT id FROM fornitori WHERE codice_fornitore = 'TECNOALARM') AS f
ON CONFLICT (codice) DO NOTHING;

-- Batch 3/5 (100 prodotti)
INSERT INTO components (
  nome, categoria, codice, barcode, descrizione,
  quantita_disponibile, giacenza, giacenza_minima,
  unita_misura, um, prezzo_unitario, prezzo_acquisto,
  fornitore, note, stato,
  fornitore_id, fornitore_preferito_id
)
SELECT
  v.nome, v.categoria, v.codice, v.barcode, v.descrizione,
  0, 0, 0, 'pz', 'pz', v.prezzo, v.prezzo,
  NULL, v.nota, 'attivo',
  f.id, f.id
FROM (VALUES
  ('CTE 045 - Contatto magnetico in ABS - Colore marrone', 'Antintrusione', 'F106CTE 045M', 'F106CTE 045M', 'CTE 045 - Contatto magnetico in ABS - Colore marrone', 7.1, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('CTI 002 - Contatto magnetico in ottone - Grado 2 - Montaggio ad incasso', 'Antintrusione', 'F106CTI 002', 'F106CTI 002', 'CTI 002 - Contatto magnetico in ottone - Grado 2 - Montaggio ad incasso', 5.3, 'Produttore: TECNOALARM | Subcategoria: CONTATTI'),
  ('TAPS-8 BUS - Gruppo di alimentazione switching 8A @ 14,4V DC - Contenitore in metallo - Dimensioni (L x A x P): 320 x 365 x 170mm', 'Antintrusione', 'F107TAPS-8BUS', 'F107TAPS-8BUS', 'TAPS-8 BUS - Gruppo di alimentazione switching 8A @ 14,4V DC - Contenitore in metallo - Dimensioni (L x A x P): 320 x 365 x 170mm', 465.0, 'Produttore: TECNOALARM'),
  ('Batteria YUASA® 12V/17Ah', 'Antintrusione', 'F108017 YU', 'F108017 YU', 'Batteria YUASA® 12V/17Ah', 114.0, 'Produttore: YUASA | Subcategoria: BATTERIE'),
  ('Batteria YUASA® 12V/2.3Ah', 'Antintrusione', 'F108021 YU', 'F108021 YU', 'Batteria YUASA® 12V/2.3Ah', 31.0, 'Produttore: TECNOALARM | Subcategoria: BATTERIE'),
  ('Batteria YUASA® 12V/7Ah', 'Antintrusione', 'F108YUASA', 'F108YUASA', 'Batteria YUASA® 12V/7Ah', 41.0, 'Produttore: YUASA | Subcategoria: BATTERIE'),
  ('Batteria YUASA® 12V/12Ah', 'Antintrusione', 'F108YUASA 12', 'F108YUASA 12', 'Batteria YUASA® 12V/12Ah', 82.5, 'Produttore: TECNOALARM | Subcategoria: BATTERIE'),
  ('4X022 - Cavo schermato', 'Antintrusione', 'F11200000500', 'F11200000500', '4X022 - Cavo schermato', 0.63, 'Produttore: TECNOALARM | Subcategoria: CAVI'),
  ('Cavo 2x034+2x022+1x022', 'Antintrusione', 'F11200000506', 'F11200000506', 'Cavo 2x034+2x022+1x022', 0.94, 'Produttore: TECNOALARM | Subcategoria: CAVI'),
  ('Cavo 2X0,50+2X0,22', 'Antintrusione', 'F11200000512', 'F11200000512', 'Cavo 2X0,50+2X0,22', 0.92, 'Produttore: TECNOALARM | Subcategoria: CAVI'),
  ('Cavo 2x1+2x050', 'Antintrusione', 'F11200000518', 'F11200000518', 'Cavo 2x1+2x050', 1.75, 'Produttore: TECNOALARM | Subcategoria: CAVI'),
  ('Cavo 2x050+4x022', 'Antintrusione', 'F11200000530', 'F11200000530', 'Cavo 2x050+4x022', 1.24, 'Produttore: TECNOALARM | Subcategoria: CAVI'),
  ('BIRELÈ - Scheda 2 relè 12V indipendenti con bobina di comando libera
da potenziale - Uscite contatti relè in scambio libero', 'Antintrusione', 'F127BIRELEN', 'F127BIRELEN', 'BIRELÈ - Scheda 2 relè 12V indipendenti con bobina di comando libera
da potenziale - Uscite contatti relè in scambio libero', 16.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI INTEGRAZIONE E INTERFACCE'),
  ('ESP GSM 4G - Interfaccia GSM 4G', 'Antintrusione', 'F127ESPGSM4G', 'F127ESPGSM4G', 'ESP GSM 4G - Interfaccia GSM 4G', 344.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('ESP LAN - Interfaccia Ethernet', 'Antintrusione', 'F127ESPLAN', 'F127ESPLAN', 'ESP LAN - Interfaccia Ethernet', 130.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('EV 430 PROX - Console touch screen con lettore RFID integrato
Collegamento via linea seriale RS485', 'Antintrusione', 'F127EV430PROX', 'F127EV430PROX', 'EV 430 PROX - Console touch screen con lettore RFID integrato
Collegamento via linea seriale RS485', 220.0, 'Produttore: TECNOALARM | Subcategoria: CENTRALI'),
  ('PROGRAMMAZIONE AVANZATA - Plug-in software programmazione avanzata', 'Antintrusione', 'F127EV50/AV', 'F127EV50/AV', 'PROGRAMMAZIONE AVANZATA - Plug-in software programmazione avanzata', 60.0, 'Produttore: TECNOALARM | Subcategoria: SOFTWARE'),
  ('EV 700 CARDB - Console touch screen con lettore carte RFID MIFARE® DESFire® integrato
Collegamento via linea seriale RS485 - Colore bianco', 'Antintrusione', 'F127EV700CARDB', 'F127EV700CARDB', 'EV 700 CARDB - Console touch screen con lettore carte RFID MIFARE® DESFire® integrato
Collegamento via linea seriale RS485 - Colore bianco', 450.0, 'Produttore: TECNOALARM | Subcategoria: TASTIERE'),
  ('EV 700 CARDB - Console touch screen con lettore carte RFID MIFARE® DESFire® integrato
Collegamento via linea seriale RS485 - Colore nero', 'Antintrusione', 'F127EV700CARDN', 'F127EV700CARDN', 'EV 700 CARDB - Console touch screen con lettore carte RFID MIFARE® DESFire® integrato
Collegamento via linea seriale RS485 - Colore nero', 450.0, 'Produttore: TECNOALARM | Subcategoria: TASTIERE'),
  ('EV 700 PROX - Console touch screen con lettore carte RFID integrato
Collegamento via linea seriale RS485 - Colore bianco', 'Antintrusione', 'F127EV700PROXB', 'F127EV700PROXB', 'EV 700 PROX - Console touch screen con lettore carte RFID integrato
Collegamento via linea seriale RS485 - Colore bianco', 450.0, 'Produttore: TECNOALARM | Subcategoria: TASTIERE'),
  ('EV 700 PROX - Console touch screen con lettore carte RFID integrato
Collegamento via linea seriale RS485 - Colore nero', 'Antintrusione', 'F127EV700PROXN', 'F127EV700PROXN', 'EV 700 PROX - Console touch screen con lettore carte RFID integrato
Collegamento via linea seriale RS485 - Colore nero', 450.0, 'Produttore: TECNOALARM | Subcategoria: TASTIERE'),
  ('EV CARD - Scheda micro SD 4 GB per registro foto scattate dai rivelatori
EV CAM BWL', 'Antintrusione', 'F127EVCARD4GB', 'F127EVCARD4GB', 'EV CARD - Scheda micro SD 4 GB per registro foto scattate dai rivelatori
EV CAM BWL', 28.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('ESP 4IN - Modulo di espansione interno con 4 ingressi zona', 'Antintrusione', 'F127EVESP4IN', 'F127EVESP4IN', 'ESP 4IN - Modulo di espansione interno con 4 ingressi zona', 32.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI INTEGRAZIONE E INTERFACCE'),
  ('EV LCD - Console LCD con lettore RFID integrato', 'Antintrusione', 'F127EVLCD', 'F127EVLCD', 'EV LCD - Console LCD con lettore RFID integrato', 147.0, 'Produttore: TECNOALARM | Subcategoria: TASTIERE'),
  ('EV OUT5RP BWL - Modulo di espansione uscite wireless con
3 relè 0,3A 24V DC, 2 relè 16A 250V AC
Alimentazione 12V DC
Banda di frequenza 868MHz', 'Antintrusione', 'F127EVOUT5RPBWL', 'F127EVOUT5RPBWL', 'EV OUT5RP BWL - Modulo di espansione uscite wireless con
3 relè 0,3A 24V DC, 2 relè 16A 250V AC
Alimentazione 12V DC
Banda di frequenza 868MHz', 114.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI INTEGRAZIONE E INTERFACCE'),
  ('EV OUTRP BWL - Modulo di espansione uscite wireless con
1 relè 16A 250V AC - Alimentazione 230V AC
Banda di frequenza 868MHz', 'Antintrusione', 'F127EVOUTRPBWL', 'F127EVOUTRPBWL', 'EV OUTRP BWL - Modulo di espansione uscite wireless con
1 relè 16A 250V AC - Alimentazione 230V AC
Banda di frequenza 868MHz', 84.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI INTEGRAZIONE E INTERFACCE'),
  ('EV TP SKN - Interfaccia per chiavi RFID', 'Antintrusione', 'F127EVTPSKN', 'F127EVTPSKN', 'EV TP SKN - Interfaccia per chiavi RFID', 60.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI INTEGRAZIONE E INTERFACCE'),
  ('TECNOVISION - Modulo di integrazione video per la gestione di un totale di 12 telecamere IP', 'Antintrusione', 'F127TECNOVISION', 'F127TECNOVISION', 'TECNOVISION - Modulo di integrazione video per la gestione di un totale di 12 telecamere IP', 600.0, 'Produttore: TECNOALARM | Subcategoria: MODULI DI ESPANSIONE ED INTERFACCE INTERNE'),
  ('UTS 4.3 PROX - Console touch screen con lettore chiavi RFID - TFT 4,3" - Colore bianco', 'Antintrusione', 'F127UTS43PROX', 'F127UTS43PROX', 'UTS 4.3 PROX - Console touch screen con lettore chiavi RFID - TFT 4,3" - Colore bianco', 215.0, 'Produttore: TECNOALARM | Subcategoria: TASTIERE'),
  ('TECNO WIFI - Modulo di interfaccia Ethernet-WIFI', 'Antintrusione', 'F130TECNOWIFI', 'F130TECNOWIFI', 'TECNO WIFI - Modulo di interfaccia Ethernet-WIFI', 74.0, 'Produttore: TECNOALARM | Subcategoria: INTERFACCE ETHERNET WIFI'),
  ('Radiocomando XT2 433 SLH LR nera', 'Automazione', 'FA7870071', 'FA7870071', 'Radiocomando XT2 433 SLH LR nera', 17.54, 'Produttore: FAAC | Subcategoria: RADIOCOMANDI'),
  ('Ventola aspirante', 'Elettrico', 'FAN AP3102', 'FAN AP3102', 'Ventola aspirante', 63.0, 'Produttore: FANTINI COSMI'),
  ('Sacca fluido 500 ml', 'Nebbiogeno', 'FFLXRC2/3FG', 'FFLXRC2/3FG', 'Sacca fluido 500 ml', 44.85, 'Produttore: UR FOG'),
  ('Cavo 3x1,5 mmq', 'Elettrico', 'FG16-3G1,5M', 'FG16-3G1,5M', 'Cavo 3x1,5 mmq', 1.16, 'Subcategoria: CAVI'),
  ('Cavo 3x2,5', 'Elettrico', 'FG16-3G2,5M', 'FG16-3G2,5M', 'Cavo 3x2,5', 1.69, 'Subcategoria: CAVI'),
  ('Tecnoware - Gruppo di continuità UPS offline da 1200VA', 'UPS', 'FGCERAPL1202SCH', 'FGCERAPL1202SCH', 'Tecnoware - Gruppo di continuità UPS offline da 1200VA', 240.0, 'Produttore: TECOWARE'),
  ('Tecnoware - Gruppo di continuità UPS offline da 800VA', 'UPS', 'FGCERAPL802SCH', 'FGCERAPL802SCH', 'Tecnoware - Gruppo di continuità UPS offline da 800VA', 150.0, 'Produttore: TECOWARE'),
  ('Tecnoware - Gruppo di continuità UPS offline da 950VA', 'UPS', 'FGCERAPL952SCH', 'FGCERAPL952SCH', 'Tecnoware - Gruppo di continuità UPS offline da 950VA', 202.0, 'Produttore: TECOWARE'),
  ('Crepuscolare da parete o palo 10.41', 'Elettrico', 'FIN 104182300000', 'FIN 104182300000', 'Crepuscolare da parete o palo 10.41', 48.6, 'Produttore: FINDER | Subcategoria: TEMPORIZZATORI'),
  ('Temporizzatore modulare luce scale 16 A', 'Elettrico', 'FIN 140182300000', 'FIN 140182300000', 'Temporizzatore modulare luce scale 16 A', 45.98, 'Produttore: FINDER | Subcategoria: TEMPORIZZATORI'),
  ('Rilevatore di movimento', 'Elettrico', 'FIN 181182300000', 'FIN 181182300000', 'Rilevatore di movimento', 37.87, 'Produttore: FINDER | Subcategoria: TEMPORIZZATORI'),
  ('Relè ad impulsi 10A', 'Elettrico', 'FIN 270182300000', 'FIN 270182300000', 'Relè ad impulsi 10A', 13.16, 'Produttore: FINDER | Subcategoria: RELÈ'),
  ('Tubo rame preisolato 1/4 mm 6,35', 'Climatizzazione', 'FLEXIO-SPLIT 1/4', 'FLEXIO-SPLIT 1/4', 'Tubo rame preisolato 1/4 mm 6,35', 2.5, 'Subcategoria: TUBI'),
  ('Tubo rame preisolato 3/8 mm 9,52', 'Climatizzazione', 'FLEXIO-SPLIT 3/8', 'FLEXIO-SPLIT 3/8', 'Tubo rame preisolato 3/8 mm 9,52', 3.67, 'Subcategoria: TUBI'),
  ('Interruttore magnetotermico 2Pcurva C 16A', 'Elettrico', 'FN82C16', 'FN82C16', 'Interruttore magnetotermico 2Pcurva C 16A', 74.07, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Interruttore magnetotermico modulare BTDIN60 4P curva C - In= 32A', 'Elettrico', 'FN84C32', 'FN84C32', 'Interruttore magnetotermico modulare BTDIN60 4P curva C - In= 32A', 120.06, 'Produttore: BTICINO | Subcategoria: MAGNETOTERMICI'),
  ('Staffa orientabile per montaggio
a parete nebbiogeno', 'Nebbiogeno', 'FPUWB', 'FPUWB', 'Staffa orientabile per montaggio
a parete nebbiogeno', 35.75, NULL),
  ('Cavo fror 4x0,50', 'Elettrico', 'FRZ05004GM100', 'FRZ05004GM100', 'Cavo fror 4x0,50', 0.59, 'Subcategoria: CAVI'),
  ('Cordina giallo verde 3GX1,5 mmq', 'Elettrico', 'FRZ15003GM100', 'FRZ15003GM100', 'Cordina giallo verde 3GX1,5 mmq', 1.03, 'Subcategoria: CAVI'),
  ('Cordina giallo verde 3GX2,5 mmq', 'Elettrico', 'FRZ25003GM100', 'FRZ25003GM100', 'Cordina giallo verde 3GX2,5 mmq', 1.66, 'Subcategoria: CAVI'),
  ('Presa fissa da incasso a 10° - IP66/IP67 - 2P+T 16A 200', 'Elettrico', 'GEW GW62227H', 'GEW GW62227H', 'Presa fissa da incasso a 10° - IP66/IP67 - 2P+T 16A 200', 9.98, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Presa fissa 2P+T 220V', 'Elettrico', 'GEW GW62426', 'GEW GW62426', 'Presa fissa 2P+T 220V', 21.0, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Interruttore magnetotermico a riarmo automatico - 16A - 4500A -  curva C
- 3 moduli', 'Elettrico', 'GEW GWD4227R', 'GEW GWD4227R', 'Interruttore magnetotermico a riarmo automatico - 16A - 4500A -  curva C
- 3 moduli', 225.05, 'Produttore: GEWISS | Subcategoria: MAGNETOTERMICI'),
  ('Scatola da esterno 1 posto', 'Elettrico', 'GW 27001', 'GW 27001', 'Scatola da esterno 1 posto', 2.59, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Presa fissa interbloccata verticale con fondo e base portafusibili -  3P+N+T 32A 346-415V - 50/60HZ 6H - IP67', 'Elettrico', 'GW 66242N', 'GW 66242N', 'Presa fissa interbloccata verticale con fondo e base portafusibili -  3P+N+T 32A 346-415V - 50/60HZ 6H - IP67', 149.4, 'Produttore: GEWISS | Subcategoria: PRESE INTERBLOCCATE'),
  ('Presa fissa interbloccata verticale senza fondo con base portafusibili  2P+T 16A 200-250V - 50/60HZ 6H - IP67', 'Elettrico', 'GW 66326N', 'GW 66326N', 'Presa fissa interbloccata verticale senza fondo con base portafusibili  2P+T 16A 200-250V - 50/60HZ 6H - IP67', 79.11, 'Produttore: GEWISS | Subcategoria: PRESE INTERBLOCCATE'),
  ('Copriforo bianco. Gewiss System', 'Elettrico', 'GW20056', 'GW20056', 'Copriforo bianco. Gewiss System', 1.31, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Presa bipasso - Gewiss System bianca', 'Elettrico', 'GW20203', 'GW20203', 'Presa bipasso - Gewiss System bianca', 5.56, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Presa schuko Gewiss System. Colore bianco', 'Elettrico', 'GW20246', 'GW20246', 'Presa schuko Gewiss System. Colore bianco', 10.18, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Guida din - Supporto per montaggio componenti serie Gewiss System', 'Elettrico', 'GW26409', 'GW26409', 'Guida din - Supporto per montaggio componenti serie Gewiss System', 1.81, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Supporto per montaggio componenti serie Gewiss System', 'Elettrico', 'GW26410', 'GW26410', 'Supporto per montaggio componenti serie Gewiss System', 2.3, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Scatola da esterno 2 posti Gewiss System', 'Elettrico', 'GW27002', 'GW27002', 'Scatola da esterno 2 posti Gewiss System', 2.08, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Scatola da esterno 3 posti. Gewiss System', 'Elettrico', 'GW27003', 'GW27003', 'Scatola da esterno 3 posti. Gewiss System', 4.0, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Scatola da esterno 8 posti Gewiss System - colore bianco', 'Elettrico', 'GW27006', 'GW27006', 'Scatola da esterno 8 posti Gewiss System - colore bianco', 10.08, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Scatola da esterno 3 posti - Gewiss System', 'Elettrico', 'GW27615', 'GW27615', 'Scatola da esterno 3 posti - Gewiss System', 6.3, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Centralino protetto senza porta 24 moduli', 'Elettrico', 'GW40030', 'GW40030', 'Centralino protetto senza porta 24 moduli', 39.31, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Graffetta in polimero antiurto con chiodo in acciaio. Diam 20', 'Elettrico', 'GW50617', 'GW50617', 'Graffetta in polimero antiurto con chiodo in acciaio. Diam 20', 0.2, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Pressacavo in nylon diam. 20', 'Elettrico', 'GW52073', 'GW52073', 'Pressacavo in nylon diam. 20', 0.88, 'Produttore: GEWISS | Subcategoria: ACCESSORI'),
  ('Radio ricevente a 2 canali ad innesto 433 92 MHz per centrali Roger', 'Automazione', 'H93/RX22A/I', 'H93/RX22A/I', 'Radio ricevente a 2 canali ad innesto 433 92 MHz per centrali Roger', 92.3, 'Produttore: ROGER | Subcategoria: RICEVENTI'),
  ('Dahua - Telecamera dome HDCVI 5Mp, fissa 2.8mm, IR 60m, WDR, Starlight', 'Videosorveglianza', 'HAC-HDW2501TMQ-A-S2', 'HAC-HDW2501TMQ-A-S2', 'Dahua - Telecamera dome HDCVI 5Mp, fissa 2.8mm, IR 60m, WDR, Starlight', 164.0, 'Produttore: DAHUA | Subcategoria: TELECAMERE DOME'),
  ('Dahua - Telecamera bullet HDCVI 5Mp, fissa 3.6mm, IR 80m, WDR, Starlight', 'Videosorveglianza', 'HAC-HFW2501TU-A-S2', 'HAC-HFW2501TU-A-S2', 'Dahua - Telecamera bullet HDCVI 5Mp, fissa 3.6mm, IR 80m, WDR, Starlight', 101.61, 'Produttore: DAHUA | Subcategoria: TELECAMERE BULLET'),
  ('Western Digital Purple - Hard Disk SATA 3.5'''' per TVCC da 2TB', 'Videosorveglianza', 'HD2TB', 'HD2TB', 'Western Digital Purple - Hard Disk SATA 3.5'''' per TVCC da 2TB', 198.0, 'Produttore: WESTERN DIGITAL | Subcategoria: HARD DISK'),
  ('Hard Disk SATA 3.5" da 2 TB specifico per TVCC', 'Videosorveglianza', 'HDV-203WD', 'HDV-203WD', 'Hard Disk SATA 3.5" da 2 TB specifico per TVCC', 231.0, 'Produttore: WESTERN DIGITAL | Subcategoria: HARD DISK'),
  ('Western Digital Purple - Hard Disk SATA 3.5" da 4 TB specifico per TVCC', 'Videosorveglianza', 'HDV-403WD', 'HDV-403WD', 'Western Digital Purple - Hard Disk SATA 3.5" da 4 TB specifico per TVCC', 413.0, 'Produttore: WESTERN DIGITAL | Subcategoria: HARD DISK'),
  ('Western Digital Purple - Hard Disk SATA 3.5" da 8 TB specifico per TVCC', 'Videosorveglianza', 'HDV-803WD', 'HDV-803WD', 'Western Digital Purple - Hard Disk SATA 3.5" da 8 TB specifico per TVCC', 717.0, 'Produttore: WESTERN DIGITAL | Subcategoria: HARD DISK'),
  ('Canalina 22x10', 'Elettrico', 'IBO B00684', 'IBO B00684', 'Canalina 22x10', 3.63, 'Produttore: BOCCHIOTTI | Subcategoria: CANALINE'),
  ('Canalina 40x17 monoscomparto con coperchio standard BIANCO', 'Elettrico', 'IBO B09505IBO', 'IBO B09505IBO', 'Canalina 40x17 monoscomparto con coperchio standard BIANCO', 4.81, 'Produttore: BOCCHIOTTI | Subcategoria: CANALINE'),
  ('Centrale elettronica di comando 2 motori 230V - 1 Ricevente-1 - completa di box', 'Automazione', 'IN-CONTROL 2DG', 'IN-CONTROL 2DG', 'Centrale elettronica di comando 2 motori 230V - 1 Ricevente-1 - completa di box', 140.0, 'Produttore: INTEGRA | Subcategoria: CENTRALINE'),
  ('Tubo rigido PVC diametro 20', 'Elettrico', 'INS B10412', 'INS B10412', 'Tubo rigido PVC diametro 20', 1.08, 'Produttore: INSET | Subcategoria: ACCESSORI'),
  ('Tubo rigido pvc - diametro 25', 'Elettrico', 'INS B10416', 'INS B10416', 'Tubo rigido pvc - diametro 25', 1.54, 'Produttore: INSET | Subcategoria: ACCESSORI'),
  ('Raccordo tubo-tubo diam. 20', 'Elettrico', 'INS B10676', 'INS B10676', 'Raccordo tubo-tubo diam. 20', 0.32, 'Produttore: INSET | Subcategoria: ACCESSORI'),
  ('Selettore a chiave da esterno in alluminio', 'Automazione', 'IN-SEL-E', 'IN-SEL-E', 'Selettore a chiave da esterno in alluminio', 28.6, 'Produttore: INTEGRA | Subcategoria: SELETTORI A CHIAVE'),
  ('Selettore a chiave da incasso in alluminio', 'Automazione', 'IN-SEL-I', 'IN-SEL-I', 'Selettore a chiave da incasso in alluminio', 28.6, 'Produttore: INTEGRA | Subcategoria: SELETTORI A CHIAVE'),
  ('Installazione', 'Servizi', 'INSTALLAZIONE', 'INSTALLAZIONE', 'Installazione', 400.0, NULL),
  ('Dahua - Telecamera TiOC dome IP 5Mp, AI WizSense, fissa 2.8mm, WDR, Starlight, deterrenza attiva, Smart Dual Illuminator, AcuPick', 'Videosorveglianza', 'IPC-HDW3549H-AS-PV-S5', 'IPC-HDW3549H-AS-PV-S5', 'Dahua - Telecamera TiOC dome IP 5Mp, AI WizSense, fissa 2.8mm, WDR, Starlight, deterrenza attiva, Smart Dual Illuminator, AcuPick', 446.0, 'Produttore: DAHUA | Subcategoria: TELECAMERE DOME'),
  ('Dahua - Telecamera TiOC dome IP 8Mp, AI WizSense, fissa 2.8mm, WDR, Starlight, deterrenza attiva, Smart Dual Illuminator, AcuPick', 'Videosorveglianza', 'IPC-HDW3849H-AS-PV-S5', 'IPC-HDW3849H-AS-PV-S5', 'Dahua - Telecamera TiOC dome IP 8Mp, AI WizSense, fissa 2.8mm, WDR, Starlight, deterrenza attiva, Smart Dual Illuminator, AcuPick', 488.0, 'Produttore: DAHUA | Subcategoria: TELECAMERE DOME'),
  ('Dahua - Telecamera bullet IP 4Mp, AI, fissa 3.6mm, IR 30m, WDR, Starlight', 'Videosorveglianza', 'IPC-HFW2441S-S', 'IPC-HFW2441S-S', 'Dahua - Telecamera bullet IP 4Mp, AI, fissa 3.6mm, IR 30m, WDR, Starlight', 237.54, 'Produttore: DAHUA | Subcategoria: TELECAMERE BULLET'),
  ('Dahua - Telecamera bullet IP 4Mp, AI WizSense, fissa 3.6 mm, IR 50m, Smart Dual Light', 'Videosorveglianza', 'IPC-HFW3449E-S-IL', 'IPC-HFW3449E-S-IL', 'Dahua - Telecamera bullet IP 4Mp, AI WizSense, fissa 3.6 mm, IR 50m, Smart Dual Light', 283.0, 'Produttore: DAHUA | Subcategoria: TELECAMERE BULLET'),
  ('Dahua - Telecamera bullet IP 8Mp, AI WizSense, fissa M12 3.6mm, IR 30m, WDR, Starlight', 'Videosorveglianza', 'IPC-HFW3841E-S-S2', 'IPC-HFW3841E-S-S2', 'Dahua - Telecamera bullet IP 8Mp, AI WizSense, fissa M12 3.6mm, IR 30m, WDR, Starlight', 438.0, 'Produttore: DAHUA | Subcategoria: TELECAMERE BULLET'),
  ('Dahua - Telecamera bullet IP 5Mp, AI WizMind, fissa 3.6mm, IR 80m, WDR, Starlight, I/O audio, I/O allarme', 'Videosorveglianza', 'IPC-HFW5541T-ASE-S3', 'IPC-HFW5541T-ASE-S3', 'Dahua - Telecamera bullet IP 5Mp, AI WizMind, fissa 3.6mm, IR 80m, WDR, Starlight, I/O audio, I/O allarme', 541.42, 'Produttore: DAHUA | Subcategoria: TELECAMERE BULLET'),
  ('Kit sacchetto base centrale per centrali TP ed EV.', 'Antintrusione', 'KIT SACCHETTO BASE CENTRALE', 'KIT SACCHETTO BASE CENTRALE', 'Kit sacchetto base centrale per centrali TP ed EV.', 20.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('DUAL 9+9 AY CON U.E. DA 5.3KW MXZ-2F53VF5-E1 MULTISPLIT 2 ATT.
R32', 'Climatizzazione', 'KM747403', 'KM747403', 'DUAL 9+9 AY CON U.E. DA 5.3KW MXZ-2F53VF5-E1 MULTISPLIT 2 ATT.
R32', 1442.5, 'Produttore: MITSUBISHI | Subcategoria: UNITA'' ESTERNA'),
  ('MSZ-AY25VGKP2-E1 U.INT 2,5KW WIFI', 'Climatizzazione', 'KM749991', 'KM749991', 'MSZ-AY25VGKP2-E1 U.INT 2,5KW WIFI', 518.75, 'Produttore: MITSUBISHI | Subcategoria: UNITA'' INTERNA'),
  ('Interruttore Bticino Living Light - Colore Antracite', 'Elettrico', 'L4001N', 'L4001N', 'Interruttore Bticino Living Light - Colore Antracite', 13.87, 'Produttore: BTICINO | Subcategoria: ACCESSORI'),
  ('Falso polo Bticino Living Light - colore antracite', 'Elettrico', 'L4950', 'L4950', 'Falso polo Bticino Living Light - colore antracite', 2.52, 'Produttore: BTICINO | Subcategoria: ACCESSORI'),
  ('Plafoniera dp 1200 18W 840 IP65 GY', 'Elettrico', 'LDV DP120018840G3', 'LDV DP120018840G3', 'Plafoniera dp 1200 18W 840 IP65 GY', 39.83, 'Produttore: LEDVANCE | Subcategoria: LAMPADE'),
  ('Plafoniera 26W - 3500 lm -  IP65 - 4000 K', 'Elettrico', 'LDV DP150026840G3', 'LDV DP150026840G3', 'Plafoniera 26W - 3500 lm -  IP65 - 4000 K', 43.2, 'Produttore: LEDVANCE | Subcategoria: LAMPADE'),
  ('Faretto LEDV, 100W, 10KLM, 840 PS, Nero', 'Elettrico', 'LDV FL6910KLM840BG4', 'LDV FL6910KLM840BG4', 'Faretto LEDV, 100W, 10KLM, 840 PS, Nero', 133.0, 'Produttore: LEDVANCE | Subcategoria: FARI'),
  ('Lampadina attacco E27 - 7,5W - 4K - classic', 'Elettrico', 'LDV PCA75840S1', 'LDV PCA75840S1', 'Lampadina attacco E27 - 7,5W - 4K - classic', 9.8, 'Produttore: LEDVANCE | Subcategoria: LAMPADINE'),
  ('Pannello rettangolare a ridotto abbagliamento, per sistemi a soffitto da 1200 x 300 mmPL COMP 1200 V 33W 840 U19', 'Elettrico', 'LDV PLCMP120033840U', 'LDV PLCMP120033840U', 'Pannello rettangolare a ridotto abbagliamento, per sistemi a soffitto da 1200 x 300 mmPL COMP 1200 V 33W 840 U19', 70.51, 'Produttore: LEDVANCE | Subcategoria: LAMPADE')
) AS v(nome, categoria, codice, barcode, descrizione, prezzo, nota)
CROSS JOIN (SELECT id FROM fornitori WHERE codice_fornitore = 'TECNOALARM') AS f
ON CONFLICT (codice) DO NOTHING;

-- Batch 4/5 (100 prodotti)
INSERT INTO components (
  nome, categoria, codice, barcode, descrizione,
  quantita_disponibile, giacenza, giacenza_minima,
  unita_misura, um, prezzo_unitario, prezzo_acquisto,
  fornitore, note, stato,
  fornitore_id, fornitore_preferito_id
)
SELECT
  v.nome, v.categoria, v.codice, v.barcode, v.descrizione,
  0, 0, 0, 'pz', 'pz', v.prezzo, v.prezzo,
  NULL, v.nota, 'attivo',
  f.id, f.id
FROM (VALUES
  ('Lampadina LED attacco GU10 - 6W - 575 lm - 4K', 'Elettrico', 'LDV PP1680D940363', 'LDV PP1680D940363', 'Lampadina LED attacco GU10 - 6W - 575 lm - 4K', 9.64, 'Produttore: LEDVANCE | Subcategoria: LAMPADINE'),
  ('Lampada LED PAR3812030 12W attacco E27', 'Elettrico', 'LDV PP38120827301', 'LDV PP38120827301', 'Lampada LED PAR3812030 12W attacco E27', 24.81, 'Produttore: LEDVANCE | Subcategoria: LAMPADE'),
  ('Lampada LED GOCCIA a Filamento E27 11W 4000K', 'Elettrico', 'LDV VCA 100840C2', 'LDV VCA 100840C2', 'Lampada LED GOCCIA a Filamento E27 11W 4000K', 5.04, 'Produttore: ledVANCE | Subcategoria: LAMPADINE'),
  ('Lampada LED GOCCIA a Filamento E27 11W 3000K', 'Elettrico', 'LDV VCA100830C1', 'LDV VCA100830C1', 'Lampada LED GOCCIA a Filamento E27 11W 3000K', 5.04, 'Produttore: ledVANCE | Subcategoria: LAMPADINE'),
  ('DULUX LED D26 EM V 9W 830 G24D-3 LEDV', 'Elettrico', 'LDV VDD268301', 'LDV VDD268301', 'DULUX LED D26 EM V 9W 830 G24D-3 LEDV', 18.63, 'Produttore: LEDVANCE | Subcategoria: LAMPADE'),
  ('Led neon 18W', 'Elettrico', 'LDV VT8EM188401', 'LDV VT8EM188401', 'Led neon 18W', 5.39, 'Produttore: LEDVANCE | Subcategoria: TUBI LED'),
  ('Led neon 36W', 'Elettrico', 'LDV VT8EM368401', 'LDV VT8EM368401', 'Led neon 36W', 9.45, 'Produttore: LEDVANCE | Subcategoria: LAMPADE'),
  ('Led neon 58W', 'Elettrico', 'LDV VT8EM588401', 'LDV VT8EM588401', 'Led neon 58W', 10.8, 'Produttore: LEDVANCE | Subcategoria: LAMPADE'),
  ('Supporto Living Light', 'Elettrico', 'LN4703', 'LN4703', 'Supporto Living Light', 3.5, 'Produttore: BTICINO | Subcategoria: ACCESSORI'),
  ('Manodopera', 'Servizi', 'MANODOPERA', 'MANODOPERA', 'Manodopera', 40.0, NULL),
  ('Sistema nebbiogeno con erogazione e saturazione della nebbia
fino a 900 m³ in 40 secondi
(300 m³ visibilità inferiore a 1 m)', 'Nebbiogeno', 'MODULAR 300', 'MODULAR 300', 'Sistema nebbiogeno con erogazione e saturazione della nebbia
fino a 900 m³ in 40 secondi
(300 m³ visibilità inferiore a 1 m)', 878.15, 'Produttore: UR FOG'),
  ('Monitor LCD HD 11,6 pollici - HDMI/VGA/BNC/AV/Altoparlante integrato/VESA, 12-24V', 'Videosorveglianza', 'MONITOR116', 'MONITOR116', 'Monitor LCD HD 11,6 pollici - HDMI/VGA/BNC/AV/Altoparlante integrato/VESA, 12-24V', 121.5, 'Subcategoria: MONITOR'),
  ('Climatizzatore a parete. Timer settimanale. Controllo Wi-Fi MELCloud integrato. Classe A+++
Mono 9000 btu
Colore bianco.', 'Climatizzazione', 'MSZ-AY25VGKP+ MUZ-AY25CG', 'MSZ-AY25VGKP+ MUZ-AY25CG', 'Climatizzatore a parete. Timer settimanale. Controllo Wi-Fi MELCloud integrato. Classe A+++
Mono 9000 btu
Colore bianco.', 1386.0, 'Produttore: MITSUBISHI | Subcategoria: MONO 9000 BTU'),
  ('Climatizzatore a parete. Timer settimanale. Controllo Wi-Fi MELCloud integrato. Classe A+++
Mono 12000 btu
Colore bianco.', 'Climatizzazione', 'MSZ-AY35VGKP+MUZ-AY35VG', 'MSZ-AY35VGKP+MUZ-AY35VG', 'Climatizzatore a parete. Timer settimanale. Controllo Wi-Fi MELCloud integrato. Classe A+++
Mono 12000 btu
Colore bianco.', 1582.0, 'Produttore: MITSUBISHI | Subcategoria: MONO 12000 BTU'),
  ('MITSUBISHI - Climatizzatore a parete linea Smart - Mono 1200 BTU - Classe A+', 'Climatizzazione', 'MSZHR35VF+MUZHR35VF', 'MSZHR35VF+MUZHR35VF', 'MITSUBISHI - Climatizzatore a parete linea Smart - Mono 1200 BTU - Classe A+', 783.0, 'Produttore: MITSUBISHI | Subcategoria: MONO 12000 BTU'),
  ('Climatizzatore a parete. Timer settimanale. Controllo Wi-Fi MELCloud integrato. Sistema 3D I-see-Sensor per comfort e risparmio energetico. Classe A+++
Mono 9000 btu
Colore bianco.', 'Climatizzazione', 'MSZ-LN25VG2V+MUZ-LN25VG', 'MSZ-LN25VG2V+MUZ-LN25VG', 'Climatizzatore a parete. Timer settimanale. Controllo Wi-Fi MELCloud integrato. Sistema 3D I-see-Sensor per comfort e risparmio energetico. Classe A+++
Mono 9000 btu
Colore bianco.', 1848.0, 'Produttore: MITSUBISHI | Subcategoria: MONO 9000 BTU'),
  ('Climatizzatore a parete. Timer settimanale. Controllo Wi-Fi MELCloud integrato. Sistema 3D I-see-Sensor per comfort e risparmio energetico. Classe A+++
Mono 12000 btu
Colore bianco.', 'Climatizzazione', 'MSZ-LN35CG2V+MUZ-LN35VG', 'MSZ-LN35CG2V+MUZ-LN35VG', 'Climatizzatore a parete. Timer settimanale. Controllo Wi-Fi MELCloud integrato. Sistema 3D I-see-Sensor per comfort e risparmio energetico. Classe A+++
Mono 12000 btu
Colore bianco.', 2163.0, 'Produttore: MITSUBISHI | Subcategoria: MONO 12000 BTU'),
  ('Coppia di fotocellule da esterno per collegamento via BUS- modello EPMB', 'Automazione', 'NICEEPMB', 'NICEEPMB', 'Coppia di fotocellule da esterno per collegamento via BUS- modello EPMB', 81.8, 'Produttore: NICE | Subcategoria: FOTOCELLULE'),
  ('Carter per led panel 60X60', 'Elettrico', 'NOB AU4/66', 'NOB AU4/66', 'Carter per led panel 60X60', 28.35, 'Produttore: LEDVANCE | Subcategoria: ACCESSORI'),
  ('Led panel 60X60 36W 4K 110 IP20', 'Elettrico', 'NOB LPX66/4K', 'NOB LPX66/4K', 'Led panel 60X60 36W 4K 110 IP20', 46.55, 'Produttore: NOBILE | Subcategoria: LAMPADE'),
  ('Led panel 60X60 36W 4K CRI80', 'Elettrico', 'NOB LT66/4K', 'NOB LT66/4K', 'Led panel 60X60 36W 4K CRI80', 29.7, 'Produttore: LEDVANCE | Subcategoria: LAMPADE'),
  ('Plafoniera 24W - temperatura colore da 3000 a 5000 - 240V - IP20', 'Elettrico', 'NOB PLDS33', 'NOB PLDS33', 'Plafoniera 24W - temperatura colore da 3000 a 5000 - 240V - IP20', 61.6, 'Produttore: NOBILE | Subcategoria: LAMPADE'),
  ('NVR 4 canali, 4K, AI WizSense, 1HDD, I/O audio, 4 porte PoE, fornito con SSD interno da 960GB', 'Videosorveglianza', 'NVR2104HS-P-I2', 'NVR2104HS-P-I2', 'NVR 4 canali, 4K, AI WizSense, 1HDD, I/O audio, 4 porte PoE, fornito con SSD interno da 960GB', 655.91, 'Produttore: DAHUA | Subcategoria: NVR'),
  ('Dahua - NVR 8 canali, AI WizSense, 4K, 2HDD, I/O audio, I/O allarme', 'Videosorveglianza', 'NVR5208-EI', 'NVR5208-EI', 'Dahua - NVR 8 canali, AI WizSense, 4K, 2HDD, I/O audio, I/O allarme', 676.0, 'Produttore: DAHUA | Subcategoria: NVR'),
  ('NVR 16 canali, AI WizSense, 4K, 2HDD, I/O audio, I/O allarme', 'Videosorveglianza', 'NVR5216-EI', 'NVR5216-EI', 'NVR 16 canali, AI WizSense, 4K, 2HDD, I/O audio, I/O allarme', 751.0, 'Produttore: DAHUA | Subcategoria: NVR'),
  ('Dahua - NVR 16 canali, AI WizSense, 4K, 2HDD, I/O audio, I/O allarme', 'Videosorveglianza', 'NVR5216-EI2', 'NVR5216-EI2', 'Dahua - NVR 16 canali, AI WizSense, 4K, 2HDD, I/O audio, I/O allarme', 928.76, 'Produttore: DAHUA | Subcategoria: NVR'),
  ('Cartello dissuasore - Alluminio
Dimensioni (Ø x P): 300 x 1,5mm', 'Antintrusione', 'P100CARTELALL', 'P100CARTELALL', 'Cartello dissuasore - Alluminio
Dimensioni (Ø x P): 300 x 1,5mm', 20.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('Trasformatore 15VA per servizio intermittente uscite 12-12-24V 2 DIN, montaggio a retroquadro IP40', 'Elettrico', 'PER 1TDTR010/DDV', 'PER 1TDTR010/DDV', 'Trasformatore 15VA per servizio intermittente uscite 12-12-24V 2 DIN, montaggio a retroquadro IP40', 29.4, 'Produttore: ELECTRIC | Subcategoria: TRASFORMATORI'),
  ('Dahua - Box di giunzione stagno in alluminio per telecamere bullet e dome', 'Videosorveglianza', 'PFA130-E', 'PFA130-E', 'Dahua - Box di giunzione stagno in alluminio per telecamere bullet e dome', 31.0, 'Produttore: DAHUA | Subcategoria: ACCESSORI'),
  ('Dahua - Box di giunzione stagno in alluminio per telecamere bullet con base rotonda', 'Videosorveglianza', 'PFA134', 'PFA134', 'Dahua - Box di giunzione stagno in alluminio per telecamere bullet con base rotonda', 19.26, 'Produttore: DAHUA | Subcategoria: ACCESSORI'),
  ('Dahua - Adattatore da palo in alluminio e SUS304 per staffe della serie PFA', 'Videosorveglianza', 'PFA152-E', 'PFA152-E', 'Dahua - Adattatore da palo in alluminio e SUS304 per staffe della serie PFA', 25.0, 'Produttore: DAHUA | Subcategoria: ACCESSORI'),
  ('Staffa di fissaggio a muro in alluminio e SECC per telecamere dome', 'Videosorveglianza', 'PFB204W', 'PFB204W', 'Staffa di fissaggio a muro in alluminio e SECC per telecamere dome', 25.68, 'Produttore: DAHUA | Subcategoria: ACCESSORI'),
  ('Pulsante, IP66, 1Ö1S, NC e NO, rosso, giallo, nero', 'Elettrico', 'PG1M9W01', 'PG1M9W01', 'Pulsante, IP66, 1Ö1S, NC e NO, rosso, giallo, nero', 49.0, NULL),
  ('Piattaforma aerea autocarrata fino a 20MT', 'Servizi', 'PIATTAFORMA AEREA', 'PIATTAFORMA AEREA', 'Piattaforma aerea autocarrata fino a 20MT', 15.0, NULL),
  ('Kit di sospensione per led panel', 'Elettrico', 'PLSUSPKIT', 'PLSUSPKIT', 'Kit di sospensione per led panel', 16.81, 'Produttore: LEDVANCE | Subcategoria: ACCESSORI'),
  ('ZONE IP - Plug-in software Zone IP', 'Antintrusione', 'Plug-in software Zone IP', 'Plug-in software Zone IP', 'ZONE IP - Plug-in software Zone IP', 300.0, 'Produttore: TECNOALARM | Subcategoria: SOFTWARE'),
  ('Tubo spiralato guaina diam. 20', 'Elettrico', 'PMP GUS20G', 'PMP GUS20G', 'Tubo spiralato guaina diam. 20', 1.4, 'Produttore: PM FLEX | Subcategoria: ACCESSORI'),
  ('INCISIONE CARATT.SL43 SU 1
RIGA SU PULS.IN OTTONE', 'Citofonia', 'PT1530SL43', 'PT1530SL43', 'INCISIONE CARATT.SL43 SU 1
RIGA SU PULS.IN OTTONE', 72.5, 'Produttore: URMET | Subcategoria: FRONTALINO'),
  ('CIRC.SPEC.ILLUM.LED COL.BIANCO DA 5 UNITA', 'Citofonia', 'PT1555/05', 'PT1555/05', 'CIRC.SPEC.ILLUM.LED COL.BIANCO DA 5 UNITA', 50.19, 'Produttore: URMET | Subcategoria: ILLUMINAZIONE'),
  ('FRONT.CITO.SAG.C/LED.S/SCAT.
725/925 C/KIT 2VOICE AUDIO
COMPLETO INCLUSO.10 TX.2F.IN
OTT.LU', 'Citofonia', 'PT2175/210L', 'PT2175/210L', 'FRONT.CITO.SAG.C/LED.S/SCAT.
725/925 C/KIT 2VOICE AUDIO
COMPLETO INCLUSO.10 TX.2F.IN
OTT.LU', 1151.76, 'Produttore: URMET | Subcategoria: FRONTALINO'),
  ('PT2175/210LO1  FRONT.CITO.SAG.C/LED.S/SCAT.725/925 C/KIT ottone', 'Citofonia', 'PT2175/210LO1', 'PT2175/210LO1', 'PT2175/210LO1  FRONT.CITO.SAG.C/LED.S/SCAT.725/925 C/KIT ottone', 1151.76, 'Produttore: URMET | Subcategoria: FRONTALINO'),
  ('FRONT.CITO.RET.S/LED.S/SCAT.725/925 C/KIT -dim.front. 205x280 - dim.scat.incasso 194x249x43 - 10 pulsanti', 'Citofonia', 'PT6175R/210S1', 'PT6175R/210S1', 'FRONT.CITO.RET.S/LED.S/SCAT.725/925 C/KIT -dim.front. 205x280 - dim.scat.incasso 194x249x43 - 10 pulsanti', 646.65, 'Produttore: URMET | Subcategoria: FRONTALINO'),
  ('FRONT.VIDEO.RET.S/LED.S/SCAT.725/925 C/KIT - dim.front. 205x280 - dim.scat.incasso 194x249x43 - 10 pulsanti', 'Citofonia', 'PT6775R/210S1', 'PT6775R/210S1', 'FRONT.VIDEO.RET.S/LED.S/SCAT.725/925 C/KIT - dim.front. 205x280 - dim.scat.incasso 194x249x43 - 10 pulsanti', 940.8, 'Produttore: URMET | Subcategoria: FRONTALINO'),
  ('QUBIX CAVO R6UT4H24 C6 U/UTP AWG24 LSZH E', 'Videosorveglianza', 'QBX 0502701BLSC0305', 'QBX 0502701BLSC0305', 'QUBIX CAVO R6UT4H24 C6 U/UTP AWG24 LSZH E', 0.96, 'Produttore: QUBIX | Subcategoria: CAVI'),
  ('QUBIX CAVO CAT 5E U/UTP AWG24 PVC ECA', 'Videosorveglianza', 'QX0502057GRSC0305', 'QX0502057GRSC0305', 'QUBIX CAVO CAT 5E U/UTP AWG24 PVC ECA', 0.72, 'Produttore: QUBIX | Subcategoria: CAVI'),
  ('Contro piastrina di unione', 'Elettrico', 'R01160000 01', 'R01160000 01', 'Contro piastrina di unione', 0.58, 'Produttore: ZAMET | Subcategoria: ACCESSORI'),
  ('Staffa a "C" per passerella', 'Elettrico', 'R01650015 01', 'R01650015 01', 'Staffa a "C" per passerella', 12.23, 'Produttore: ZAMET | Subcategoria: ACCESSORI'),
  ('Passerella rete incastro 3 MT 60X100', 'Elettrico', 'RV0030610 25', 'RV0030610 25', 'Passerella rete incastro 3 MT 60X100', 9.56, 'Produttore: ZAMET | Subcategoria: ACCESSORI'),
  ('Magic Gel 1000', 'Elettrico', 'RYT MAGIC-GEL', 'RYT MAGIC-GEL', 'Magic Gel 1000', 1.08, 'Produttore: RAY TECH | Subcategoria: ACCESSORI'),
  ('Scheda LED', 'Antintrusione', 'S105SAEL2010SCL', 'S105SAEL2010SCL', 'Scheda LED', 12.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('Scheda elettronica per SAEL 2010 BUS', 'Antintrusione', 'S110SAEL2010BUN', 'S110SAEL2010BUN', 'Scheda elettronica per SAEL 2010 BUS', 54.0, 'Produttore: TECNOALARM | Subcategoria: ACCESSORI'),
  ('Alimentatore switching CE RoHS UPS 60w 12v 5a con UPS/funzione di carica ac 110/220v a dc 12v Caricabatteria 13,8V (SC-60-12)', 'Videosorveglianza', 'SC6012', 'SC6012', 'Alimentatore switching CE RoHS UPS 60w 12v 5a con UPS/funzione di carica ac 110/220v a dc 12v Caricabatteria 13,8V (SC-60-12)', 60.0, NULL),
  ('Plug categoria 5E', 'Videosorveglianza', 'SE180.811', 'SE180.811', 'Plug categoria 5E', 0.51, 'Produttore: SCAME | Subcategoria: ACCESSORI'),
  ('PORTELLA PER PALO DM 127-168MM', 'Elettrico', 'SEM 4301/2', 'SEM 4301/2', 'PORTELLA PER PALO DM 127-168MM', 10.7, 'Subcategoria: ACCESSORI'),
  ('PALO RASTREMATO H.TOT. 550 CM.', 'Videosorveglianza', 'SEM 4553', 'SEM 4553', 'PALO RASTREMATO H.TOT. 550 CM.', 127.0, NULL),
  ('Palo conico vetroresina 460 cm vero', 'Videosorveglianza', 'SEM VRC460N', 'SEM VRC460N', 'Palo conico vetroresina 460 cm vero', 189.0, NULL),
  ('Giunti ad isolamento in gel per connessione in linea', 'Elettrico', 'SHARK 324', 'SHARK 324', 'Giunti ad isolamento in gel per connessione in linea', 32.54, 'Produttore: ETELEC | Subcategoria: ACCESSORI'),
  ('Abbonamento sim gsm per la connessione dati della centrale antintrusione. Durata 12 mesi', 'SIM', 'SIMGSM', 'SIMGSM', 'Abbonamento sim gsm per la connessione dati della centrale antintrusione. Durata 12 mesi', 34.43, 'Produttore: KPN | Subcategoria: ABBONAMENTO SIM'),
  ('Abbonamento sim gsm per la connessione dati della centrale antintrusione. Durata 12 mesi (OMAGGIO PER I PRIMI 12 MESI DALLA DATA DI ATTIVAZIONE)', 'SIM', 'SIMGSM OMAGGIO PER 12 MESI', 'SIMGSM OMAGGIO PER 12 MESI', 'Abbonamento sim gsm per la connessione dati della centrale antintrusione. Durata 12 mesi (OMAGGIO PER I PRIMI 12 MESI DALLA DATA DI ATTIVAZIONE)', 34.43, 'Produttore: KPN | Subcategoria: ABBONAMENTO SIM'),
  ('Centralino parete Mureva Enclosures IP65 1 fila 6 moduli', 'Elettrico', 'SNR 10313', 'SNR 10313', 'Centralino parete Mureva Enclosures IP65 1 fila 6 moduli', 28.0, 'Produttore: SCHNEIDER ELETRIC'),
  ('Interruttore magnetotermico IC60H 4P C 63A 10000A', 'Elettrico', 'SNR A9F89463', 'SNR A9F89463', 'Interruttore magnetotermico IC60H 4P C 63A 10000A', 173.04, 'Produttore: SCHNEIDER ELETRIC | Subcategoria: MAGNETOTERMICI'),
  ('Centralino da parete 4 moduli con portella traslucida.', 'Elettrico', 'SNR MIP10104T', 'SNR MIP10104T', 'Centralino da parete 4 moduli con portella traslucida.', 13.3, 'Produttore: SCHNEIDER ELETRIC | Subcategoria: CENTRALINI'),
  ('Lampada di emergenza SE - 300lm - Autonomia 3h', 'Elettrico', 'SNR OVA39565', 'SNR OVA39565', 'Lampada di emergenza SE - 300lm - Autonomia 3h', 51.8, 'Produttore: SCHNEIDER ELETRIC | Subcategoria: LAMPADE DI EMERGENZA'),
  ('Cavo FROR16 OR 2X1,5 mmq', 'Elettrico', 'SPB FRZ15002UM100', 'SPB FRZ15002UM100', 'Cavo FROR16 OR 2X1,5 mmq', 0.81, 'Produttore: SPECIALCAVI | Subcategoria: CAVI'),
  ('Trasmettitore bicanale doppia frequenza fisso e rollng code', 'Automazione', 'SYNUS/2', 'SYNUS/2', 'Trasmettitore bicanale doppia frequenza fisso e rollng code', 15.99, 'Produttore: ROGER | Subcategoria: RADIOCOMANDI'),
  ('Bullone + quadro sottotesta 6x20', 'Elettrico', 'T06200620 01', 'T06200620 01', 'Bullone + quadro sottotesta 6x20', 0.16, 'Produttore: ZAMET | Subcategoria: ACCESSORI'),
  ('Dado flangiato zigrinato', 'Elettrico', 'T06210600 01', 'T06210600 01', 'Dado flangiato zigrinato', 0.05, 'Produttore: ZAMET | Subcategoria: ACCESSORI'),
  ('Placca Living light Bianca', 'Elettrico', 'TCLNA4803BI', 'TCLNA4803BI', 'Placca Living light Bianca', 8.4, 'Produttore: BTICINO | Subcategoria: ACCESSORI'),
  ('TFA1-298 - Centrale di rilevazione incendio indirizzata a 1 loop con capacità fino a 298 indirizzi. Protocollo Fire-Speed, display
grafico TFT true color 482X272 pixel, speaker di diffusione notifiche acustiche. Gestione fino a 5 ripetitori remoti lcd,
1 ', 'Antincendio', 'TF1TFA1298-IT', 'TF1TFA1298-IT', 'TFA1-298 - Centrale di rilevazione incendio indirizzata a 1 loop con capacità fino a 298 indirizzi. Protocollo Fire-Speed, display
grafico TFT true color 482X272 pixel, speaker di diffusione notifiche acustiche. Gestione fino a 5 ripetitori remoti lcd,
1 bus seriale RS485, 5 uscite di segnalazione programmabili, 150 zone specializzabili incendio o tecnologico. Porta
seriale per collegamento stampante, porta USB per collegamento pc per programmazione. Batterie 2X12V 7Ah
escluse.
Certificata EN 54.2-4', 1740.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI'),
  ('TFA2-596 - Centrale di rilevazione incendio indirizzata a 2 loop con capacità fino a 596 indirizzi. Protocollo Fire-Speed, display
grafico TFT true color 482X272 pixel, speaker di diffusione notifiche acustiche. Configurabile locale, Master/Slave,
gestion', 'Antincendio', 'TF1TFA2596-IT', 'TF1TFA2596-IT', 'TFA2-596 - Centrale di rilevazione incendio indirizzata a 2 loop con capacità fino a 596 indirizzi. Protocollo Fire-Speed, display
grafico TFT true color 482X272 pixel, speaker di diffusione notifiche acustiche. Configurabile locale, Master/Slave,
gestione fino a 16 ripetitori remoti lcd, 2 bus seriali RS485, 10 uscite di segnalazione programmabili, 300 zone
specializzabili incendio o tecnologico. Porta seriale per collegamento stampante, porta USB per collegamento pc
per programmazione, nodo Ethernet con vettore IP protocollo Contact-id, Sia, Tecnoalarm. Gestione locale, remota
della programmazione, telegestione con collegamento telematico LAN/WAN. Batterie 2X12V 12Ah escluse.
Certificata EN 54.2-4.', 3470.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI'),
  ('TFA4-1192 - Centrale di rilevazione incendio indirizzata a 4 loop con capacità fino a 1192 indirizzi. Protocollo Fire-Speed, display
grafico TFT true color 482X272 pixel, speaker di diffusione notifiche acustiche. Configurabile locale, Master/Slave,
gesti', 'Antincendio', 'TF1TFA41192-IT', 'TF1TFA41192-IT', 'TFA4-1192 - Centrale di rilevazione incendio indirizzata a 4 loop con capacità fino a 1192 indirizzi. Protocollo Fire-Speed, display
grafico TFT true color 482X272 pixel, speaker di diffusione notifiche acustiche. Configurabile locale, Master/Slave,
gestione fino a 16 ripetitori remoti lcd, 2 bus seriali RS485, 10 uscite di segnalazione programmabili, 300 zone
specializzabili incendio o tecnologico. Porta seriale per collegamento stampante, porta USB per collegamento pc
per programmazione, nodo Ethernet con vettore IP protocollo Contact-id, Sia, Tecnoalarm. Gestione locale, remota
della programmazione, telegestione con collegamento telematico LAN/WAN. Batterie 2X12V 12Ah escluse.
Certificata EN 54.2-4.', 4850.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI'),
  ('TFST-LX350 - Stampante seriale da tavolo 80 colonne a 9 aghi per carta a modulo continuo. Alimentazione 230Vac.', 'Antincendio', 'TF1TFSTLX350', 'TF1TFSTLX350', 'TFST-LX350 - Stampante seriale da tavolo 80 colonne a 9 aghi per carta a modulo continuo. Alimentazione 230Vac.', 1000.0, 'Produttore: TECNOFIRE | Subcategoria: ACCESSORI CENTRALI'),
  ('TSA1G - Centrale di rivelazione incendio come TSA1 con pannello frontale di colore grigio.', 'Antincendio', 'TF1TSA1G-IT', 'TF1TSA1G-IT', 'TSA1G - Centrale di rivelazione incendio come TSA1 con pannello frontale di colore grigio.', 1900.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI DI SPEGNIMENTO'),
  ('TSA1 - Centrale di rivelazione incendio ed estinzione ad 1 linea Loop analogica fino a 199 rivelatori, 99 moduli e 10 EDU
inclusa licenza BASIC fino a 32 rivelatori, 16 moduli, 1 EDU, 5 zone. L’unità di estinzione EDU integrata è dotata di:
3 ingressi zon', 'Antincendio', 'TF1TSA1-IT', 'TF1TSA1-IT', 'TSA1 - Centrale di rivelazione incendio ed estinzione ad 1 linea Loop analogica fino a 199 rivelatori, 99 moduli e 10 EDU
inclusa licenza BASIC fino a 32 rivelatori, 16 moduli, 1 EDU, 5 zone. L’unità di estinzione EDU integrata è dotata di:
3 ingressi zona di rivelazione convenzionale, 7 ingressi controllati per la gestione degli organi di attuazione e
controllo, 2 uscite controllate per la gestione delle valvole di estinzione, 2 uscite controllate per la gestione dei
dispositivi di segnalazione ottico acustici, 5 uscite di segnalazione specializzate. Interfaccia utente: display a colori
4.3”, tastiera soft touch di programmazione e gestione, 33 Led di segnalazione. Alimentatore switching 27Vcc 2,7A.
2 batterie 12V 7A/h. Cassa in metallo, pannello frontale plastico, Bianco. Certificata secondo EN54-2:
1997+A1:2006 - EN54-4: 1997+A2:2006 - EN 12094-1: 2004.', 1900.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI DI SPEGNIMENTO'),
  ('TSA1PROL50 - Coppia di prolunghe cavo Flat per TSA1 da 50 cm, completa di connettori (maschio e femmina)', 'Antintrusione', 'TF1TSA1PROL50', 'TF1TSA1PROL50', 'TSA1PROL50 - Coppia di prolunghe cavo Flat per TSA1 da 50 cm, completa di connettori (maschio e femmina)', 50.0, 'Produttore: TECNOFIRE'),
  ('TSA1R - Centrale di rivelazione incendio come TSA1 con pannello frontale di colore rosso.', 'Antincendio', 'TF1TSA1R-IT', 'TF1TSA1R-IT', 'TSA1R - Centrale di rivelazione incendio come TSA1 con pannello frontale di colore rosso.', 1900.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI DI SPEGNIMENTO'),
  ('TSA1Y - Centrale di rivelazione incendio come TSA1 con pannello frontale di colore giallo.', 'Antincendio', 'TF1TSA1Y-IT', 'TF1TSA1Y-IT', 'TSA1Y - Centrale di rivelazione incendio come TSA1 con pannello frontale di colore giallo.', 1900.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI DI SPEGNIMENTO'),
  ('TSA1ABIL-EXT - Licenza per l''estensione della centrale TSA1 da 6 a 10 EDU su moduli TSM1, 199 rivelatori, 99 moduli e 150 zone
incendio.', 'Antincendio', 'TF1TSABILEXT', 'TF1TSABILEXT', 'TSA1ABIL-EXT - Licenza per l''estensione della centrale TSA1 da 6 a 10 EDU su moduli TSM1, 199 rivelatori, 99 moduli e 150 zone
incendio.', 600.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI DI SPEGNIMENTO'),
  ('TSA1ABIL-LIM - Licenza per l''estensione della centrale TSA1 da 2 a 5 EDU su moduli TSM1, 64 rivelatori, 32 moduli e 50 zone
incendio.', 'Antincendio', 'TF1TSABILLIM', 'TF1TSABILLIM', 'TSA1ABIL-LIM - Licenza per l''estensione della centrale TSA1 da 2 a 5 EDU su moduli TSM1, 64 rivelatori, 32 moduli e 50 zone
incendio.', 600.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI DI SPEGNIMENTO'),
  ('TS-ST RACK - Coppia di staffe per il montaggio su rack 19U per centrale TSA1', 'Antincendio', 'TF1TSSTRACK', 'TF1TSSTRACK', 'TS-ST RACK - Coppia di staffe per il montaggio su rack 19U per centrale TSA1', 115.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI DI SPEGNIMENTO'),
  ('TSM1 - Modulo indirizzato di rivelazione ed estinzione incendio. Gestione completa di un canale di estinzione
decentralizzato. L’unità di estinzione EDU integrata è dotata di: 3 ingressi zona di rivelazione convenzionale, 7
ingressi controllati per la ges', 'Antincendio', 'TF4TSM1-IT', 'TF4TSM1-IT', 'TSM1 - Modulo indirizzato di rivelazione ed estinzione incendio. Gestione completa di un canale di estinzione
decentralizzato. L’unità di estinzione EDU integrata è dotata di: 3 ingressi zona di rivelazione convenzionale, 7
ingressi controllati per la gestione degli organi di attuazione e controllo, 2 uscite controllate per la gestione delle
valvole di estinzione, 2 uscite controllate per la gestione dei dispositivi di segnalazione ottico acustici, 5 uscite di
segnalazione specializzate, 2 uscite di segnalazione liberamente programmabili. Separatore di linea con doppio
isolatore. Interfaccia utente: display a colori touch screen capacitivo da 2.4”, 18 Led di segnalazione. Buzzer di
segnalazione acustica multifunzionale. Completa gestione RSC® del dispositivo: programmazione, telegestione e
controllo di tutti i parametri di funzionamento.
Modulo conforme EN 54-17: 2005 - EN 12094-1: 2004.', 850.0, 'Produttore: TECNOFIRE | Subcategoria: CENTRALI DI SPEGNIMENTO'),
  ('Lampeggiatore a led con antenna integrata 24-230V completo di supporto', 'Automazione', 'TO-LED', 'TO-LED', 'Lampeggiatore a led con antenna integrata 24-230V completo di supporto', 24.7, 'Produttore: TO-VEDO | Subcategoria: LAMPEGGIATORE'),
  ('Fotocellule da esterno infrarossi orientabili 25 mt antiurto', 'Automazione', 'TO-VEDO', 'TO-VEDO', 'Fotocellule da esterno infrarossi orientabili 25 mt antiurto', 25.35, 'Produttore: TO-VEDO | Subcategoria: FOTOCELLULE'),
  ('Dahua - Telecamera termica ibrida bullet IP 4Mp, AI, ottica termica 7mm, ottica standard 8mm - Serie Eureka', 'Videosorveglianza', 'TPC-BF1241-B7F8-DW-S8', 'TPC-BF1241-B7F8-DW-S8', 'Dahua - Telecamera termica ibrida bullet IP 4Mp, AI, ottica termica 7mm, ottica standard 8mm - Serie Eureka', 1235.85, 'Produttore: DAHUA | Subcategoria: TELECAMERE BULLET'),
  ('Scheda LAN/WiFi Active Cloud', 'Nebbiogeno', 'URCLWF', 'URCLWF', 'Scheda LAN/WiFi Active Cloud', 182.0, 'Produttore: UR FOG'),
  ('Antenna WiFi', 'Nebbiogeno', 'URCLWFA', 'URCLWFA', 'Antenna WiFi', 12.35, 'Produttore: UR FOG'),
  ('Kit di montaggio scheda Active Cloud/
Active Server: cavo 12 V e cavo piatto', 'Nebbiogeno', 'URCLWFM', 'URCLWFM', 'Kit di montaggio scheda Active Cloud/
Active Server: cavo 12 V e cavo piatto', 9.75, 'Produttore: UR FOG'),
  ('Distributore 4 utenze', 'Citofonia', 'UTD 1083/55', 'UTD 1083/55', 'Distributore 4 utenze', 36.94, 'Produttore: URMET'),
  ('Decodifica speciale 2 voice', 'Citofonia', 'UTD 1083/80', 'UTD 1083/80', 'Decodifica speciale 2 voice', 79.65, 'Produttore: URMET'),
  ('Cavo per sistema 2Voice - 2 x 0,5 mm2', 'Citofonia', 'UTD 1083/94', 'UTD 1083/94', 'Cavo per sistema 2Voice - 2 x 0,5 mm2', 1.63, 'Produttore: URMET | Subcategoria: CAVI'),
  ('Citofono tradizionale 1130, sistema 4+n', 'Citofonia', 'UTD 1130/11', 'UTD 1130/11', 'Citofono tradizionale 1130, sistema 4+n', 64.4, 'Produttore: URMET | Subcategoria: CORNETTE'),
  ('Sinthesi 1 pulsante - Misure: L 90 mm, H 90 mm', 'Citofonia', 'UTD 1148/11', 'UTD 1148/11', 'Sinthesi 1 pulsante - Misure: L 90 mm, H 90 mm', 53.2, 'Produttore: URMET'),
  ('Frontalino Alpha per posto esterno senza pulsanti', 'Citofonia', 'UTD 1168/130', 'UTD 1168/130', 'Frontalino Alpha per posto esterno senza pulsanti', 51.14, 'Produttore: URMET'),
  ('Frontale per posto esterno audio, 1 pulsante, Alpha, nero', 'Citofonia', 'UTD 1168/131', 'UTD 1168/131', 'Frontale per posto esterno audio, 1 pulsante, Alpha, nero', 54.95, 'Produttore: URMET'),
  ('Frontale 4 pulsanti - modello ALPHA, nero', 'Citofonia', 'UTD 1168/14', 'UTD 1168/14', 'Frontale 4 pulsanti - modello ALPHA, nero', 41.39, 'Produttore: URMET'),
  ('Frontale senza pulsanti per posto esterno video, serie URMET ALPHA - Colore nero', 'Citofonia', 'UTD 1168/140', 'UTD 1168/140', 'Frontale senza pulsanti per posto esterno video, serie URMET ALPHA - Colore nero', 59.2, 'Produttore: URMET'),
  ('Frontale per posto esterno video, 1 pulsante - serie ALPHA, nero', 'Citofonia', 'UTD 1168/141', 'UTD 1168/141', 'Frontale per posto esterno video, 1 pulsante - serie ALPHA, nero', 60.75, 'Produttore: URMET'),
  ('Frontale per posto esterno video, 2 pulsanti - modello ALPHA colore nero', 'Citofonia', 'UTD 1168/142', 'UTD 1168/142', 'Frontale per posto esterno video, 2 pulsanti - modello ALPHA colore nero', 63.33, 'Produttore: URMET'),
  ('Frontale 4 pulsanti - modello ALPHA', 'Citofonia', 'UTD 1168/24', 'UTD 1168/24', 'Frontale 4 pulsanti - modello ALPHA', 49.38, 'Produttore: URMET'),
  ('Custodia con telaio, 1 modulo, Alpha, appoggio muro', 'Citofonia', 'UTD 1168/311', 'UTD 1168/311', 'Custodia con telaio, 1 modulo, Alpha, appoggio muro', 119.0, 'Produttore: URMET')
) AS v(nome, categoria, codice, barcode, descrizione, prezzo, nota)
CROSS JOIN (SELECT id FROM fornitori WHERE codice_fornitore = 'TECNOALARM') AS f
ON CONFLICT (codice) DO NOTHING;

-- Batch 5/5 (20 prodotti)
INSERT INTO components (
  nome, categoria, codice, barcode, descrizione,
  quantita_disponibile, giacenza, giacenza_minima,
  unita_misura, um, prezzo_unitario, prezzo_acquisto,
  fornitore, note, stato,
  fornitore_id, fornitore_preferito_id
)
SELECT
  v.nome, v.categoria, v.codice, v.barcode, v.descrizione,
  0, 0, 0, 'pz', 'pz', v.prezzo, v.prezzo,
  NULL, v.nota, 'attivo',
  f.id, f.id
FROM (VALUES
  ('Custodia con telaio 1F 3 moduli appoggio muro - modello Alpha', 'Citofonia', 'UTD 1168/313', 'UTD 1168/313', 'Custodia con telaio 1F 3 moduli appoggio muro - modello Alpha', 240.3, NULL),
  ('Modulo 4 pulsanti - modello ALPHA', 'Citofonia', 'UTD 1168/4', 'UTD 1168/4', 'Modulo 4 pulsanti - modello ALPHA', 74.78, 'Produttore: URMET'),
  ('Visiera antipioggia Urmet Alpha per 1 fila', 'Citofonia', 'UTD 1168/401', 'UTD 1168/401', 'Visiera antipioggia Urmet Alpha per 1 fila', 28.0, 'Produttore: URMET'),
  ('Telaio 1 modulo', 'Citofonia', 'UTD 1168/61', 'UTD 1168/61', 'Telaio 1 modulo', 60.14, 'Produttore: URMET'),
  ('Telaio 2 moduli', 'Citofonia', 'UTD 1168/62', 'UTD 1168/62', 'Telaio 2 moduli', 69.94, 'Produttore: URMET'),
  ('Telaio 3 moduli - modello ALPHA', 'Citofonia', 'UTD 1168/63', 'UTD 1168/63', 'Telaio 3 moduli - modello ALPHA', 74.39, 'Produttore: URMET'),
  ('Telaio 4 moduli', 'Citofonia', 'UTD 1168/64', 'UTD 1168/64', 'Telaio 4 moduli', 71.97, 'Produttore: URMET'),
  ('Modulo 8 pulsanti - modulo ALPHA', 'Citofonia', 'UTD 1168/8', 'UTD 1168/8', 'Modulo 8 pulsanti - modulo ALPHA', 94.92, 'Produttore: URMET'),
  ('Custodia con telaio 1F 2 moduli appoggio muro - modello Alpha', 'Citofonia', 'UTD 1178/312', 'UTD 1178/312', 'Custodia con telaio 1F 2 moduli appoggio muro - modello Alpha', 186.3, NULL),
  ('Cornetta - Dimensione (L x A x P): 90 x 220x 50 mm', 'Citofonia', 'UTD 1183/5', 'UTD 1183/5', 'Cornetta - Dimensione (L x A x P): 90 x 220x 50 mm', 39.83, 'Produttore: URMET | Subcategoria: CORNETTE'),
  ('Kit base impianto audio, Alpha, 2 citofoni Mìro cornetta, sistema 2Voice', 'Citofonia', 'UTD 1183/622', 'UTD 1183/622', 'Kit base impianto audio, Alpha, 2 citofoni Mìro cornetta, sistema 2Voice', 374.9, 'Produttore: URMET'),
  ('Videocitofono vivavoce con Wi-Fi - display 5" - colore bianco - Dimensioni: 160 x 130 x 26 mm', 'Citofonia', 'UTD 1760/16U', 'UTD 1760/16U', 'Videocitofono vivavoce con Wi-Fi - display 5" - colore bianco - Dimensioni: 160 x 130 x 26 mm', 353.3, 'Produttore: URMET'),
  ('Videocitofono vivavoce, display 5" - colore bianco - Dimensioni: 160 x 130 x 26 mm', 'Citofonia', 'UTD 1760/6', 'UTD 1760/6', 'Videocitofono vivavoce, display 5" - colore bianco - Dimensioni: 160 x 130 x 26 mm', 202.37, 'Produttore: URMET'),
  ('Kit base impianto video - modello ALPHA', 'Citofonia', 'UTD 1783/724', 'UTD 1783/724', 'Kit base impianto video - modello ALPHA', 371.09, 'Produttore: URMET'),
  ('Kit colonna secondaria audio, Alpha, sistema 2Voice, con distributore 4DIN', 'Citofonia', 'UTD 1783/748', 'UTD 1783/748', 'Kit colonna secondaria audio, Alpha, sistema 2Voice, con distributore 4DIN', 388.68, 'Produttore: URMET'),
  ('Kit colonna secondaria video sistema, con distributore 4DIN -  modello ALPHA', 'Citofonia', 'UTD 1783/758', 'UTD 1783/758', 'Kit colonna secondaria video sistema, con distributore 4DIN -  modello ALPHA', 435.93, 'Produttore: URMET'),
  ('Tubo scarico condensa 18-20', 'Climatizzazione', 'VCM 989905001', 'VCM 989905001', 'Tubo scarico condensa 18-20', 0.81, 'Produttore: VECAMCO | Subcategoria: TUBI'),
  ('Pulsante 1P NO 10A generico grigio 16080 - VIMAR', 'Elettrico', 'VI16080', 'VI16080', 'Pulsante 1P NO 10A generico grigio 16080 - VIMAR', 11.52, 'Produttore: VIMAR | Subcategoria: ACCESSORI'),
  ('Spina schuko volante', 'Elettrico', 'VIW 00230.B', 'VIW 00230.B', 'Spina schuko volante', 1.96, 'Produttore: VIMAR | Subcategoria: ACCESSORI'),
  ('Nice - Walky 1024 - Kit per cancelli a battente con anta fino a 1,8 metri, 24Vdc, bidirezionale', 'Automazione', 'WALKY1024BDKCE', 'WALKY1024BDKCE', 'Nice - Walky 1024 - Kit per cancelli a battente con anta fino a 1,8 metri, 24Vdc, bidirezionale', 877.0, NULL)
) AS v(nome, categoria, codice, barcode, descrizione, prezzo, nota)
CROSS JOIN (SELECT id FROM fornitori WHERE codice_fornitore = 'TECNOALARM') AS f
ON CONFLICT (codice) DO NOTHING;

-- ✅ Verifica finale:
SELECT categoria, COUNT(*) AS totale FROM components GROUP BY categoria ORDER BY totale DESC;
SELECT ragione_sociale, email, telefono, citta FROM fornitori WHERE codice_fornitore = 'TECNOALARM';