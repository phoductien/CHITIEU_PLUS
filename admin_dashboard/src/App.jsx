import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import { useAuth } from './context/AuthContext';
import { Login } from './pages/Login';
import { AdminLayout } from './components/AdminLayout';

// Mock Pages (to be implemented)
import { AdminAnalytics } from './pages/AdminAnalytics';
import { AdminUsers } from './pages/AdminUsers';
import { AdminCategories } from './pages/AdminCategories';
import { AdminFeedback } from './pages/AdminFeedback';

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
      </Routes>
    </AnimatePresence>
  );
};

function App() {
  return (
    <Router>
      <AnimatedRoutes />
    </Router>
  );
}

export default App;
