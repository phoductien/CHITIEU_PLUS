import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import { Toaster } from 'react-hot-toast';
import { useAuth } from './context/AuthContext';
import { Login } from './pages/Login';
import { AdminLayout } from './components/AdminLayout';

// Mock Pages (to be implemented)
import { AdminAnalytics } from './pages/AdminAnalytics';
import { AdminUsers } from './pages/AdminUsers';
import { AdminCategories } from './pages/AdminCategories';
import { AdminFeedback } from './pages/AdminFeedback';
import { AdminConfig } from './pages/AdminConfig';
import { AdminNews } from './pages/AdminNews';

const ProtectedRoute = ({ children }) => {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" />;
  return <AdminLayout>{children}</AdminLayout>;
};

const AnimatedRoutes = () => {
  const location = useLocation();
  
  return (
    <AnimatePresence mode="wait">
      <Routes location={location} key={location.pathname}>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<ProtectedRoute><AdminAnalytics /></ProtectedRoute>} />
        <Route path="/users" element={<ProtectedRoute><AdminUsers /></ProtectedRoute>} />
        <Route path="/categories" element={<ProtectedRoute><AdminCategories /></ProtectedRoute>} />
        <Route path="/feedback" element={<ProtectedRoute><AdminFeedback /></ProtectedRoute>} />
        <Route path="/config" element={<ProtectedRoute><AdminConfig /></ProtectedRoute>} />
        <Route path="/news" element={<ProtectedRoute><AdminNews /></ProtectedRoute>} />
      </Routes>
    </AnimatePresence>
  );
};

function App() {
  return (
    <Router>
      <Toaster 
        position="top-right" 
        toastOptions={{
          style: {
            background: '#1a2235',
            color: '#fff',
            border: '1px solid rgba(255, 255, 255, 0.1)',
          }
        }} 
      />
      <AnimatedRoutes />
    </Router>
  );
}

export default App;
