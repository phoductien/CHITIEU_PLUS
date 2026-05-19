import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import axios from 'axios'
import './index.css'
import App from './App.jsx'
import { AuthProvider } from './context/AuthContext'

// Set axios baseURL for production backend hosted on Vercel
axios.defaults.baseURL = import.meta.env.PROD
  ? 'https://chitieu-plus.vercel.app'
  : '';

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <AuthProvider>
      <App />
    </AuthProvider>
  </StrictMode>,
)
