/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./**/*.html",
    "./**/*.js",
    "!./**/node_modules/**",
    "!./.vercel/**",
    "!./test-deploy/**"
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
