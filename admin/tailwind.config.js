/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: '#1B5E20',
        savings: '#2E7D32',
        pending: '#F9A825',
        overdue: '#C62828',
      },
    },
  },
  plugins: [],
}
