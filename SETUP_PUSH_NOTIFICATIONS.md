# 🔔 Setup Notifiche Push + PWA

## ✅ Cosa è stato implementato

### Frontend
- **Service Worker v2.0** con cache offline-first, push handlers, background sync
- **notification-service.js** con Supabase Realtime per notifiche automatiche
- **UI Notifiche** nella sezione Profilo con toggle on/off
- **Bottone Test** per provare le notifiche

### Trigger Realtime (automatici)
1. **Nuove lavorazioni assegnate** → Notifica al dipendente
2. **Lavorazioni aggiornate** → Notifica cambio stato
3. **Richieste approvate/rifiutate** → Notifica con emoji
4. **Nuove comunicazioni** → Notifica broadcast/personale
5. **Scadenze imminenti** → Check ogni ora (client-side)

---

## 🛠️ Setup Necessario (IMPORTANTE!)

### Step 1: Eseguire Migration Database

1. Vai su **Supabase Dashboard** > **SQL Editor**
2. Copia il contenuto di `migrations/add-push-notifications.sql`
3. Incolla ed **esegui**

Questo creerà:
- Tabella `push_subscriptions` (subscription tokens)
- Tabella `notification_history` (storico notifiche)
- RLS Policies per sicurezza

### Step 2: Generare VAPID Keys

Le VAPID keys sono necessarie per autenticare le notifiche push.

#### Opzione A: Generare Online
1. Vai su: https://web-push-codelab.glitch.me/
2. Clicca "Generate keys"
3. Copia la **Public Key** (quella che inizia con `B...`)

#### Opzione B: Generare con Node.js
```bash
npx web-push generate-vapid-keys
```

Output:
```
Public Key:
BEl62iUYgUivxIkv69yViEuiBIa-Ib9-SkvMeAtA3LFgDzkrxZJjSgSnfckjBJuBkr3qBroYeXE...

Private Key:
abcd1234... (NON condividere mai!)
```

### Step 3: Aggiornare VAPID Public Key

1. Apri `pannello-utente.html`
2. Cerca la riga (circa linea 3935):
   ```javascript
   const VAPID_PUBLIC_KEY = 'BEl62iUYgUivxIkv69yViEuiBIa-Ib9-SkvMeAtA3LFgDzkrxZJjSgSnfckjBJuBkr3qBroYeXE';
   ```
3. **Sostituisci** con la tua Public Key generata
4. **Salva** e **redeploy**

### Step 4: (Opzionale) Configurare Supabase Edge Function per invio server

Per inviare notifiche dal server (es. da admin panel), serve una Supabase Edge Function.

**Nota:** Per ora le notifiche funzionano tramite Realtime (client-side), quindi questo è opzionale.

<details>
<summary>Espandi per vedere codice Edge Function</summary>

Crea file `supabase/functions/send-push/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const webpush = {
  async sendNotification(subscription, payload, options) {
    // Implementazione Web Push API
    // Richiede libreria web-push per Deno
  }
};

serve(async (req) => {
  const { userId, title, body, data } = await req.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Get user subscriptions
  const { data: subscriptions } = await supabase
    .from('push_subscriptions')
    .select('*')
    .eq('user_id', userId)

  // Send to all devices
  for (const sub of subscriptions) {
    const pushSubscription = {
      endpoint: sub.endpoint,
      keys: {
        p256dh: sub.p256dh,
        auth: sub.auth
      }
    }

    await webpush.sendNotification(
      pushSubscription,
      JSON.stringify({ title, body, data }),
      {
        vapidKeys: {
          publicKey: Deno.env.get('VAPID_PUBLIC_KEY'),
          privateKey: Deno.env.get('VAPID_PRIVATE_KEY')
        }
      }
    )
  }

  return new Response(JSON.stringify({ success: true }))
})
```

Deploy:
```bash
supabase functions deploy send-push
```

</details>

---

## 🧪 Come Testare

### Test 1: Attivazione Notifiche

1. Vai su **Pannello Utente** > **Il Mio Profilo**
2. Trova il pannello **"Notifiche Push"**
3. Attiva il **toggle**
4. Browser chiederà permesso → **Consenti**
5. Verifiche:
   - ✅ Toggle diventa verde
   - ✅ Status mostra "Notifiche attive"
   - ✅ Console browser: "Push notifications initialized successfully"

### Test 2: Notifica di Test

1. Nella sezione Notifiche Push
2. Clicca **"Invia Notifica di Test"**
3. Risultati attesi:
   - **App in foreground**: Toast notification
   - **App in background**: Notifica nativa sistema operativo

### Test 3: Notifica Realtime (Nuova Lavorazione)

Serve 2 browser/dispositivi:

**Browser 1 (Admin):**
1. Vai su **Calendario Admin**
2. Crea nuova lavorazione
3. Assegnala a un dipendente specifico

**Browser 2 (Dipendente):**
1. Login come dipendente assegnato
2. **Se app in background**: Riceverai notifica nativa
3. **Se app aperta**: Riceverai toast notification
4. Contenuto: "🆕 Nuova Lavorazione Assegnata - Cliente: [nome]"

### Test 4: Richiesta Approvata

**Browser 1 (Dipendente):**
1. Crea richiesta permesso

**Browser 2 (Admin):**
1. Approva/rifiuta richiesta

**Browser 1 (Dipendente):**
1. Riceverà notifica: "✅ Richiesta APPROVATA 🎉"

---

## 📱 Test Mobile (PWA)

### iOS (Safari)
1. Apri **Pannello Utente** in Safari
2. Tocca **Share** > **Add to Home Screen**
3. App si installa come PWA
4. Apri app dalla home
5. Attiva notifiche nel profilo
6. **Nota**: Safari iOS ha limitazioni su push notifications (funziona solo con app aperta)

### Android (Chrome/Edge)
1. Apri **Pannello Utente** in Chrome
2. Banner "Installa app" apparirà
3. Clicca **Installa**
4. App si installa come PWA
5. Attiva notifiche nel profilo
6. ✅ Push notifications funzionano anche con app chiusa!

---

## 🔧 Troubleshooting

### "Push notifications not supported"
- Browser non supporta Push API
- Prova Chrome/Edge/Firefox (non Safari desktop)

### "Notification permission denied"
- Utente ha bloccato notifiche
- Soluzione: Impostazioni browser > Site Settings > Notifications > Consenti

### "Service Worker registration failed"
- Verifica che `/Admin/sw.js` sia accessibile
- Console deve mostrare: "Service Worker registered"

### Notifiche non arrivano
1. Verifica permesso: `Notification.permission` → deve essere "granted"
2. Check console per errori
3. Verifica subscription salvata in DB:
   ```sql
   SELECT * FROM push_subscriptions WHERE user_id = 'xxx';
   ```
4. Test con "Invia Notifica di Test"

### Realtime non funziona
1. Verifica Supabase Realtime abilitato nel progetto
2. Check console: "Realtime listeners setup complete"
3. Verifica channel subscriptions:
   ```javascript
   console.log(window.notificationService.channels);
   ```

---

## 📊 Monitoring

### Vedere subscriptions attive
```sql
SELECT 
  u.nome,
  u.cognome,
  ps.endpoint,
  ps.created_at,
  ps.last_used_at
FROM push_subscriptions ps
JOIN utenti u ON ps.user_id = u.id
ORDER BY ps.created_at DESC;
```

### Storico notifiche
```sql
SELECT 
  u.nome,
  u.cognome,
  nh.title,
  nh.body,
  nh.type,
  nh.sent_at,
  nh.read_at
FROM notification_history nh
JOIN utenti u ON nh.user_id = u.id
ORDER BY nh.sent_at DESC
LIMIT 50;
```

### Cancellare vecchie subscriptions (cleanup)
```sql
DELETE FROM push_subscriptions 
WHERE updated_at < NOW() - INTERVAL '30 days';
```

---

## ✅ Checklist Setup Completo

- [ ] Migration SQL eseguita
- [ ] Tabelle `push_subscriptions` e `notification_history` create
- [ ] VAPID keys generate
- [ ] VAPID Public Key aggiornata in `pannello-utente.html`
- [ ] Redeploy produzione
- [ ] Test attivazione notifiche OK
- [ ] Test notifica di test OK
- [ ] Test notifica realtime (nuova lavorazione) OK
- [ ] Test su mobile (PWA installata) OK

---

## 🎯 Features Implementate

### Notifiche Automatiche
- ✅ Nuove lavorazioni assegnate
- ✅ Cambio stato lavorazioni
- ✅ Richieste approvate/rifiutate
- ✅ Nuove comunicazioni
- ✅ Scadenze imminenti (check ogni ora)

### PWA Features
- ✅ Installabile (manifest.json)
- ✅ Offline cache (Service Worker v2.0)
- ✅ Background sync
- ✅ Push notifications
- ✅ App-like experience

### UI
- ✅ Toggle notifiche in Profilo
- ✅ Status indicator
- ✅ Bottone test
- ✅ Lista tipi notifiche

---

## 🚀 Link Produzione

**Deploy attuale:** https://ast-panel-i5eocg12a-akirayoukys-projects.vercel.app

**Note:**
- Service Worker path: `/Admin/sw.js`
- Scope: `/` (tutta l'app)
- VAPID key: Aggiornare prima dell'uso!

---

## 📚 Risorse

- Web Push API: https://developer.mozilla.org/en-US/docs/Web/API/Push_API
- Service Worker: https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API
- Notifications API: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API
- VAPID Keys: https://web-push-codelab.glitch.me/
- Supabase Realtime: https://supabase.com/docs/guides/realtime
