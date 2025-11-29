# AST Panel - iPad App (Swift/SwiftUI)

## 📱 Progetto iOS/iPadOS

Versione nativa per iPad dell'applicazione AST Panel, sviluppata in Swift con SwiftUI.

## 🎯 Obiettivi

Trasformare la PWA esistente in un'app nativa per iPad con:
- Tutte le funzionalità del pannello web
- Interfaccia ottimizzata per iPad
- Supporto offline
- Notifiche push native
- Integrazione completa con Supabase

## 📂 Struttura Progetto

```
ASTIPAD/
├── ASTPanel.xcodeproj          # Progetto Xcode
├── ASTPanel/
│   ├── App/                    # Entry point e configurazione
│   ├── Models/                 # Modelli dati
│   ├── Views/                  # Viste SwiftUI
│   ├── ViewModels/             # Business logic
│   ├── Services/               # API e networking
│   ├── Utilities/              # Helper e utilities
│   └── Resources/              # Asset, fonts, etc.
└── README.md
```

## 🚀 Funzionalità da Implementare

### Core
- [x] Struttura progetto base
- [ ] Configurazione Supabase
- [ ] Sistema di autenticazione
- [ ] Modelli dati completi

### Dashboard
- [ ] Dashboard Admin
- [ ] Dashboard Utente
- [ ] Statistiche in tempo reale
- [ ] Widget personalizzati

### Gestione
- [ ] Gestione Lavorazioni
- [ ] Gestione Utenti
- [ ] Gestione Clienti
- [ ] Gestione Squadre
- [ ] Gestione Componenti/Magazzino

### Features
- [ ] Calendario lavorazioni
- [ ] Sistema comunicazioni
- [ ] Richieste utenti
- [ ] Notifiche push
- [ ] Sincronizzazione offline
- [ ] Export PDF/Excel

## 🛠 Tecnologie

- **Linguaggio**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage
- **Networking**: URLSession + Async/Await
- **Minimum iOS**: iPadOS 16.0+

## 📦 Dipendenze

- Supabase Swift SDK
- Charts (SwiftUI)
- MapKit
- UserNotifications

## 🔧 Setup

1. Apri `ASTPanel.xcodeproj` con Xcode
2. Configura le credenziali Supabase in `Config.swift`
3. Build and Run

## 🎨 Design

L'app segue il design system della versione web con:
- Gradient blu-viola per Admin
- Gradient cyan-blu per User
- Design responsive per diverse dimensioni iPad
- Support Dark Mode

## 📝 Note

- Questo progetto è una versione nativa dell'app web esistente
- Il database Supabase è condiviso tra web e mobile
- La struttura è organizzata per supportare future espansioni iPhone

---

**Backup Web App**: Tag `backup-before-ios-migration` (27 Nov 2025)
