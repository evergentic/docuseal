module.exports = {
  future: {
    hoverOnlyWhenSupported: true
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: '#327DC0',
          secondary: '#C2A661',
          accent: '#C2A661',
          neutral: '#0E1013',
          'base-100': '#ffffff',
          'base-200': '#ECEEF1',
          'base-300': '#dfe3e8',
          'base-content': '#0E1013',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
