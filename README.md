# AST Panel - Gestionale Aziendale

Sistema di gestione completo con integrazione Supabase.

## 🚀 Deploy su Vercel

Questo progetto è configurato per il deploy automatico su Vercel.

### Prerequisiti

- Account Vercel (gratuito)
- Account Supabase (già configurato)
- Repository GitHub

### Variabili d'Ambiente

Il progetto utilizza le seguenti credenziali Supabase (già integrate nel codice):

- **Supabase URL**: `https://hrqhckksrunniqnzqogk.supabase.co`
- **Supabase Anon Key**: Già configurata in `supabase-client.js`

### Deploy Steps

1. **Push su GitHub**:
   ```bash
   git add .
   git commit -m "Ready for production deploy"
   git push origin main
   ```

2. **Importa su Vercel**:
   - Vai su [vercel.com](https://vercel.com)
   - Click "New Project"
   - Importa il repository GitHub
   - Vercel rileverà automaticamente la configurazione da `vercel.json`
   - Click "Deploy"

3. **Configurazione Post-Deploy**:
   - RLS: Disabilitato per development (vedi `disable-rls.sql`)
   - Per production: riabilitare RLS e configurare policy

## 📁 Struttura Progetto

```
/Admin          - Pagine amministrazione
  index.html    - Login page
  admin-functional.html - Dashboard admin
  
/               - Pagine gestione (root)
  gestione-clienti.html
  gestione-squadre.html
  gestione-lavorazioni.html
  gestione-utenti.html
  calendario-admin.html
  calendario-dipendente.html
  pannello-utente.html

/Api            - API utilities
/Utenti         - User assets

File chiave:
  supabase-client.js    - Client Supabase
  data-migration.js     - Layer migrazione dati
  auth-helper.js        - Autenticazione
  modal-system.js       - Sistema modale
```

## 🔧 Funzionalità

- ✅ Gestione Clienti (CRUD completo)
- ✅ Gestione Squadre con membri
- ✅ Gestione Lavorazioni con Kanban drag&drop
- ✅ Gestione Utenti e ruoli
- ✅ Calendario Admin e Dipendente
- ✅ Dashboard con statistiche real-time
- ✅ Autenticazione basata su sessione
- ✅ Export CSV
- ✅ Modal personalizzate

## 🗄️ Database

Backend: **Supabase PostgreSQL**

### Tabelle:
- `users` - Utenti del sistema
- `clients` - Clienti
- `teams` - Squadre di lavoro
- `team_members` - Membri squadre
- `tasks` - Lavorazioni
- `components` - Componenti lavorazioni
- `task_components` - Relazione task-componenti
- `requests` - Richieste
- `communications` - Comunicazioni

## 🛠️ Sviluppo Locale

```bash
# Avvia server
python3 -m http.server 3005

# Apri browser
open http://localhost:3005/Admin/index.html
```

## 📝 Note di Sicurezza

⚠️ **IMPORTANTE per Production**:

1. Riabilitare RLS in Supabase
2. Configurare policy di sicurezza appropriate
3. Implementare JWT authentication
4. Validazione server-side
5. Rate limiting
6. HTTPS obbligatorio

## 📄 Licenza

Proprietario - AST Panel © 2025
