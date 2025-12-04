# 🔗 Integrazioni Esterne - AST Panel

Guida completa per configurare le integrazioni esterne (Google Calendar, WhatsApp Business, Email)

## 📋 Indice

1. [Google Calendar Integration](#google-calendar)
2. [WhatsApp Business API](#whatsapp-business)
3. [Email Automation](#email-automation)
4. [Database Setup](#database-setup)
5. [Usage Examples](#usage-examples)

---

## 🗓️ Google Calendar Integration

### Prerequisites
1. Account Google/Gmail
2. Progetto Google Cloud Platform
3. API Calendar abilitata

### Setup Steps

#### 1. Crea Progetto Google Cloud
```
1. Vai su https://console.cloud.google.com
2. Crea nuovo progetto "AST Panel Calendar"
3. Abilita "Google Calendar API"
4. Vai a "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
5. Tipo: "Web application"
6. Authorized JavaScript origins: https://ast-panel.vercel.app
7. Copia CLIENT_ID e API_KEY
```

#### 2. Configurazione Database
```sql
UPDATE integration_settings
SET 
    is_enabled = TRUE,
    settings = jsonb_set(settings, '{client_id}', '"YOUR_CLIENT_ID"'),
    settings = jsonb_set(settings, '{api_key}', '"YOUR_API_KEY"')
WHERE integration_name = 'google_calendar';
```

#### 3. Carica Script nelle Pagine
```html
<script src="/integrations/google-calendar-service.js"></script>
<script src="/integrations/notification-orchestrator.js"></script>
```

#### 4. Utilizzo
```javascript
// Sincronizza task con calendario
await window.NotificationOrchestrator.sendTaskConfirmation(task, client);

// Il sistema crea automaticamente evento Google Calendar
```

---

## 📱 WhatsApp Business API

### Prerequisites
1. Account Facebook Business
2. WhatsApp Business Account
3. Phone Number verificato

### Setup Steps

#### 1. Crea App Facebook
```
1. Vai su https://developers.facebook.com
2. Crea nuova "Business App"
3. Aggiungi prodotto "WhatsApp"
4. Setup numero telefono aziendale
5. Ottieni Phone Number ID e Access Token
```

#### 2. Webhook Setup (Opzionale - per ricevere risposte)
```
Callback URL: https://ast-panel.vercel.app/api/whatsapp-webhook
Verify Token: (genera un token random e salvalo)
Subscribe to: messages
```

#### 3. Configurazione Database
```sql
UPDATE integration_settings
SET 
    is_enabled = TRUE,
    access_token = 'YOUR_WHATSAPP_ACCESS_TOKEN',
    settings = jsonb_set(settings, '{phone_number_id}', '"YOUR_PHONE_NUMBER_ID"')
WHERE integration_name = 'whatsapp_business';
```

#### 4. Aggiungi Numero Cliente
```sql
UPDATE clients
SET 
    whatsapp_number = '+393331234567',
    whatsapp_notifications_enabled = TRUE
WHERE id = 'CLIENT_ID';
```

#### 5. Utilizzo
```javascript
// Invio automatico conferma
await window.WhatsAppService.sendTaskConfirmation(task, client);

// Invio promemoria
await window.WhatsAppService.sendTaskReminder(task, client);
```

---

## 📧 Email Automation

### Option 1: SendGrid (Consigliato)

#### Setup SendGrid
```
1. Crea account su https://sendgrid.com (free tier: 100 email/giorno)
2. Verifica dominio o email sender
3. Crea API Key con permessi "Mail Send"
4. Copia API Key
```

#### Configurazione
```sql
UPDATE integration_settings
SET 
    is_enabled = TRUE,
    api_key = 'YOUR_SENDGRID_API_KEY',
    settings = jsonb_set(settings, '{from_email}', '"noreply@astpanel.com"'),
    settings = jsonb_set(settings, '{from_name}', '"AST Panel"')
WHERE integration_name = 'email_smtp';
```

### Option 2: SMTP Gmail

#### Setup Gmail SMTP
```
1. Abilita "2-Step Verification" su Google Account
2. Genera "App Password": https://myaccount.google.com/apppasswords
3. Usa questa password per SMTP
```

#### Configurazione
```sql
UPDATE integration_settings
SET 
    is_enabled = TRUE,
    settings = '{
        "host": "smtp.gmail.com",
        "port": 587,
        "secure": false,
        "user": "your-email@gmail.com",
        "password": "YOUR_APP_PASSWORD",
        "from_email": "your-email@gmail.com",
        "from_name": "AST Panel"
    }'::jsonb
WHERE integration_name = 'email_smtp';
```

### Supabase Edge Function (per SMTP)

Crea file `supabase/functions/send-email/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { SmtpClient } from "https://deno.land/x/smtp/mod.ts"

serve(async (req) => {
  const { to, subject, html, text, from, fromName } = await req.json()

  const client = new SmtpClient()
  
  await client.connectTLS({
    hostname: "smtp.gmail.com",
    port: 587,
    username: Deno.env.get("SMTP_USER"),
    password: Deno.env.get("SMTP_PASSWORD"),
  })

  await client.send({
    from: `${fromName} <${from}>`,
    to: to,
    subject: subject,
    content: html,
    html: html,
  })

  await client.close()

  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" },
  })
})
```

Deploy:
```bash
supabase functions deploy send-email
supabase secrets set SMTP_USER=your-email@gmail.com
supabase secrets set SMTP_PASSWORD=your-app-password
```

---

## 💾 Database Setup

### 1. Esegui Migration
```sql
-- Esegui in Supabase SQL Editor
\i migrations/add-external-integrations.sql
```

### 2. Verifica Installazione
```sql
-- Controlla tabelle create
SELECT * FROM integration_settings;
SELECT * FROM notification_logs LIMIT 10;
SELECT * FROM notification_stats;
```

---

## 🚀 Usage Examples

### Esempio 1: Conferma Task
```javascript
// Quando crei un nuovo task
async function createTask(taskData) {
    // 1. Salva task nel database
    const { data: task } = await window.dataManager.createTask(taskData);
    
    // 2. Carica dati cliente
    const { data: client } = await window.supabaseClient
        .from('clients')
        .select('*')
        .eq('id', task.cliente_id)
        .single();
    
    // 3. Invia notifiche multi-canale
    await window.NotificationOrchestrator.sendTaskConfirmation(task, client);
    
    // Questo invierà:
    // ✅ Email di conferma
    // ✅ WhatsApp message (se abilitato)
    // ✅ Google Calendar event
}
```

### Esempio 2: Update Status
```javascript
// Quando cambi stato task
async function updateTaskStatus(taskId, newStatus) {
    // 1. Update database
    const { data: task } = await window.supabaseClient
        .from('tasks')
        .update({ stato: newStatus })
        .eq('id', taskId)
        .select('*, clients:cliente_id (*)')
        .single();
    
    // 2. Notifica cliente
    await window.NotificationOrchestrator.sendStatusUpdate(
        task, 
        task.clients, 
        newStatus
    );
    
    // 3. Se completato, invia conferma
    if (newStatus === 'completato') {
        await window.NotificationOrchestrator.sendTaskCompletion(task, task.clients);
    }
}
```

### Esempio 3: Daily Reminders (Cron Job)
```javascript
// Setup cron job per reminder giornalieri
// Esegui ogni giorno alle 18:00

async function dailyReminderJob() {
    const results = await window.NotificationOrchestrator.sendDailyReminders();
    console.log(`✅ Sent ${results.count} reminders`);
}

// Schedule con Vercel Cron (vercel.json)
{
  "crons": [{
    "path": "/api/daily-reminders",
    "schedule": "0 18 * * *"
  }]
}
```

### Esempio 4: Statistiche Notifiche
```javascript
// Visualizza statistiche ultimi 30 giorni
const stats = await window.NotificationOrchestrator.getStatistics(30);

console.table(stats);
// Output:
// type     | channel    | status    | total | sent | delivered | failed
// email    | confirmation| sent     | 45    | 45   | 42        | 3
// whatsapp | reminder   | delivered | 23    | 23   | 23        | 0
```

---

## 📊 Monitoring & Logs

### Visualizza Log Notifiche
```sql
SELECT 
    nl.*,
    t.titolo as task_title,
    c.ragione_sociale as client_name
FROM notification_logs nl
LEFT JOIN tasks t ON nl.task_id = t.id
LEFT JOIN clients c ON nl.client_id = c.id
ORDER BY nl.created_at DESC
LIMIT 50;
```

### Statistiche Performance
```sql
SELECT * FROM notification_stats;
```

---

## ⚙️ Configurazione Avanzata

### Disabilita Integrazioni
```sql
-- Disabilita WhatsApp
UPDATE integration_settings
SET is_enabled = FALSE
WHERE integration_name = 'whatsapp_business';

-- Disabilita notifiche per singolo cliente
UPDATE clients
SET 
    email_notifications_enabled = FALSE,
    whatsapp_notifications_enabled = FALSE
WHERE id = 'CLIENT_ID';
```

### Custom Templates
Modifica i template in `email-service.js` e `whatsapp-service.js`

---

## 🔒 Sicurezza

⚠️ **IMPORTANTE**: Non committare API keys nel codice!

- Salva credenziali SOLO nel database (tabella `integration_settings`)
- Usa Supabase RLS per proteggere accesso
- Cripta token sensibili prima di salvare
- Ruota API keys regolarmente

---

## 📝 Testing

### Test Email
```javascript
await window.EmailService.sendEmail(
    'test@example.com',
    'Test Email',
    '<h1>Test</h1><p>Email di prova</p>'
);
```

### Test WhatsApp
```javascript
await window.WhatsAppService.sendMessage(
    '+393331234567',
    'Test WhatsApp da AST Panel'
);
```

### Test Google Calendar
```javascript
const testTask = {
    id: 'test-id',
    titolo: 'Test Task',
    data_scadenza: new Date().toISOString(),
    cliente_nome: 'Test Client'
};

await window.GoogleCalendarService.createEventFromTask(testTask);
```

---

## 🆘 Troubleshooting

### Email non ricevute
- Controlla spam folder
- Verifica sender email verificata
- Controlla quota SendGrid (max 100/day free)
- Vedi log: `SELECT * FROM notification_logs WHERE type='email' AND status='failed'`

### WhatsApp errori
- Verifica numero in formato internazionale (+39...)
- Controlla Access Token valido
- Phone Number ID corretto
- Numero cliente registrato su WhatsApp

### Google Calendar non sincronizza
- Utente deve autorizzare accesso (popup OAuth)
- Controlla CLIENT_ID e API_KEY corretti
- Verifica dominio autorizzato in Google Console

---

## 📚 Resources

- [Google Calendar API Docs](https://developers.google.com/calendar/api)
- [WhatsApp Business API Docs](https://developers.facebook.com/docs/whatsapp)
- [SendGrid Docs](https://docs.sendgrid.com)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

---

**Supporto**: Per assistenza apri issue su GitHub o contatta il team di sviluppo.
