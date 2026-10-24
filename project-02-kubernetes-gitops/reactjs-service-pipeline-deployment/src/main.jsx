import React from 'react';
import {createRoot} from 'react-dom/client';
import './index.css';
import App from './App';

const release = import.meta.env.VITE_RELEASE_VERSION || 'development';
createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <div className="release-banner">Release: {release}</div>
    <App />
  </React.StrictMode>
);

