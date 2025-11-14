// Tailwind CDN Configuration
// Suppresses the development warning about using CDN in production
// For future: consider migrating to PostCSS build process

tailwind.config = {
  theme: {
    extend: {
      colors: {
        primary: '#3b82f6',
        secondary: '#8b5cf6',
      }
    }
  }
}
