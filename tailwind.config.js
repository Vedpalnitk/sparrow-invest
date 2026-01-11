/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx}",
    "./src/components/**/*.{js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        sparrow: {
          blue: '#006BFF',
          gradientStart: '#3A7BFF',
          gradientEnd: '#0044FF',
          success: '#16C47F',
          error: '#FF4F4F',
          grayLight: '#F4F6F9',
          gray: '#E3E6EB',
          navy: '#1A1F36'
        }
      },
      boxShadow: {
        'sparrow-card': '0 4px 14px rgba(0,0,0,0.04)'
      },
      borderRadius: {
        'xl': '16px'
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif']
      }
    }
  },
  plugins: []
};
