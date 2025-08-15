import React from 'react';
import ReactDOM from 'react-dom/client';
import App from '../App';
import '../styles/globals.css';

// Initialize theme system and ensure font inheritance
document.documentElement.classList.add('font-sans');

// Check for saved theme preference or default to dark
const savedTheme = localStorage.getItem('theme') as 'light' | 'dark' | null;
const systemTheme = window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
const initialTheme = savedTheme || systemTheme || 'dark';

document.documentElement.classList.add(initialTheme);
document.documentElement.setAttribute('data-theme', initialTheme);

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