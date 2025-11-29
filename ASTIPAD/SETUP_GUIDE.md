# Guida Setup Progetto Xcode - AST Panel iPad

## 📱 Creazione Progetto

### 1. Apri Xcode

1. Apri **Xcode**
2. Seleziona **"Create a new Xcode project"**
3. Scegli **iOS** → **App**
4. Click **Next**

### 2. Configurazione Progetto

Compila i campi come segue:

- **Product Name**: `ASTPanel`
- **Team**: Seleziona il tuo team di sviluppo
- **Organization Identifier**: `com.yourcompany` (o il tuo identificativo)
- **Bundle Identifier**: Verrà generato automaticamente
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: **None**
- **Include Tests**: Deselezionato (opzionale)

Click **Next**

### 3. Salva il Progetto

1. Seleziona la cartella: `/Users/akirayouky/Desktop/AST:ZG/ASTIPAD/`
2. Click **Create**

### 4. Importa i File

Ora hai il progetto Xcode creato. Devi importare i file Swift che ho creato:

#### Metodo 1: Drag & Drop (Consigliato)

1. Nel Finder, apri `/Users/akirayouky/Desktop/AST:ZG/ASTIPAD/ASTPanel/ASTPanel/`
2. Trascina le cartelle nel progetto Xcode:
   - `App/`
   - `Models/`
   - `Services/`
   - `Views/`
   - `Utilities/`
   - `Resources/`

3. Assicurati di selezionare:
   - ✅ **Copy items if needed**
   - ✅ **Create groups**
   - ✅ **Add to targets: ASTPanel**

#### Metodo 2: Add Files

1. Right-click sulla cartella `ASTPanel` nel navigatore
2. Seleziona **Add Files to "ASTPanel"...**
3. Naviga a `/Users/akirayouky/Desktop/AST:ZG/ASTIPAD/ASTPanel/ASTPanel/`
4. Seleziona tutte le cartelle (App, Models, Services, Views, Utilities)
5. Click **Add**

### 5. Configura Target

1. Seleziona il progetto `ASTPanel` nel navigatore
2. Seleziona il target `ASTPanel`
3. Tab **General**:
   - **Deployment Info**:
     - Minimum Deployments: **iPadOS 16.0**
     - Supported Destinations: **iPad**
   - **Supported Interface Orientations**: Tutte selezionate

### 6. Configurazione Build Settings

1. Tab **Build Settings**
2. Cerca "Swift Language Version"
3. Assicurati sia impostato su **Swift 5** o superiore

### 7. Info.plist

Aggiungi le seguenti chiavi se necessario:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>supabase.co</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 8. Build & Run

1. Seleziona un simulatore iPad (es. iPad Pro 12.9")
2. Premi **Cmd + R** oppure click sul pulsante ▶️
3. L'app dovrebbe compilare e avviarsi!

## 🔧 Risoluzione Problemi

### Errori di Compilazione

Se vedi errori del tipo "Cannot find type 'XXX'":

1. Verifica che tutti i file siano stati importati
2. Controlla che i file siano aggiunti al target `ASTPanel`
3. Prova **Clean Build Folder** (Shift + Cmd + K)

### Struttura File Mancante

Se mancano alcuni file, controlla che la struttura sia:

```
ASTPanel/
├── App/
│   ├── ASTPanelApp.swift
│   ├── ContentView.swift
│   └── Config.swift
├── Models/
│   ├── User.swift
│   ├── Task.swift
│   ├── Client.swift
│   ├── Component.swift
│   ├── Team.swift
│   ├── Communication.swift
│   └── Request.swift
├── Services/
│   ├── SupabaseService.swift
│   └── AuthService.swift
├── Views/
│   ├── LoginView.swift
│   ├── AdminDashboardView.swift
│   ├── UserDashboardView.swift
│   └── PlaceholderViews.swift
└── Utilities/
    └── NetworkMonitor.swift
```

## ✅ Prossimi Passi

Dopo aver compilato con successo:

1. ✅ Testare il login con credenziali esistenti
2. 🔄 Implementare le view dettagliate (Tasks, Users, etc.)
3. 🔄 Aggiungere funzionalità CRUD
4. 🔄 Implementare sincronizzazione offline
5. 🔄 Aggiungere notifiche push
6. 🔄 Ottimizzazione UI/UX per iPad

## 📞 Note Importanti

- **Simulatore vs Device**: Testa su simulatore prima, poi su device reale
- **Credenziali**: Le credenziali Supabase sono già configurate in `Config.swift`
- **Network**: L'app richiede connessione internet per funzionare
- **Autenticazione**: Usa le stesse credenziali della webapp

## 🎯 Stato Implementazione

### Completato ✅
- [x] Struttura progetto base
- [x] Modelli dati completi
- [x] Servizio Supabase generico
- [x] Sistema autenticazione
- [x] Login view
- [x] Dashboard layout (Admin & User)
- [x] Network monitoring

### Da Implementare 🔄
- [ ] View dettagliate per ogni sezione
- [ ] CRUD operations
- [ ] Grafici e statistiche
- [ ] Calendario interattivo
- [ ] Gestione componenti lavorazioni
- [ ] Sistema notifiche
- [ ] Caching e offline mode
- [ ] Search e filtri
- [ ] Export PDF
- [ ] Foto profilo upload

---

**Creato il**: 27 Novembre 2025  
**Versione**: 1.0.0 (Base)
