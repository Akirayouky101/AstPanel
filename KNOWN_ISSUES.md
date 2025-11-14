# Known Issues and Solutions

## CSS/JS CDN Warnings

### FullCalendar CSS MIME Type Error
**Status**: ✅ RISOLTO
- **Problema**: Il CSS di FullCalendar da jsDelivr viene servito con MIME type errato
- **Soluzione Implementata**: Rimosso il link CSS esterno, aggiunti stili inline essenziali
- **File modificato**: `admin-functional.html`

### Tailwind CDN Production Warning
**Status**: ⚠️ FUNZIONA MA CON WARNING
- **Warning**: "cdn.tailwindcss.com should not be used in production"
- **Stato Attuale**: Funzionale per sviluppo e prototipazione
- **Soluzione Futura**: Migrare a build process con PostCSS

#### Come migrare a Tailwind CSS in produzione:

1. **Installare Tailwind via npm**:
```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init
```

2. **Configurare `tailwind.config.js`**:
```javascript
module.exports = {
  content: ["./**.html"],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

3. **Creare `src/input.css`**:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

4. **Build CSS**:
```bash
npx tailwindcss -i ./src/input.css -o ./assets/css/tailwind.css --watch
```

5. **Sostituire nei file HTML**:
```html
<!-- Rimuovi -->
<script src="https://cdn.tailwindcss.com"></script>

<!-- Aggiungi -->
<link href="/assets/css/tailwind.css" rel="stylesheet">
```

## Performance Recommendations

### Priorità Bassa (funziona bene così)
- Il CDN di Tailwind è veloce e cacheable
- Perfetto per applicazioni interne
- Non critico per deployment attuale su Vercel

### Priorità Alta (se l'app cresce)
- Riduce dimensione bundle (~800KB → ~10KB)
- Migliora performance di caricamento
- Elimina JavaScript runtime di Tailwind

## Monitoring
- ✅ Tutti gli endpoint Supabase funzionanti
- ✅ Autenticazione stabile
- ✅ Lucide icons caricati correttamente
- ✅ FullCalendar JS funzionante
