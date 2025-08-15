import React from 'react';
import ReactDOM from 'react-dom/client';
import App from '../App';
import '../styles/globals.css';

// Enable dark mode by default and ensure font inheritance
document.documentElement.classList.add('dark', 'font-sans');

// Disable browser scroll restoration and snap to top on page load
if ('scrollRestoration' in history) {
  history.scrollRestoration = 'manual';
}

// Scroll to top immediately on page load (no animation)
window.scrollTo(0, 0);

// Also scroll to top when the page becomes visible (for browser back/forward)
document.addEventListener('visibilitychange', () => {
  if (!document.hidden) {
    window.scrollTo(0, 0);
  }
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);