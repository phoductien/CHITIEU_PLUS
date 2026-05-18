import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { Shield, Lock, User, AlertCircle, ArrowRight } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { PageTransition } from '../components/PageTransition';

export const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleLogin = (e) => {
    e.preventDefault();
    if (login(username, password)) {
      navigate('/');
    } else {
      setError('Tài khoản hoặc mật khẩu không khớp với cơ sở dữ liệu!');
    }
  };

  return (
    <PageTransition>
      <div className="min-h-screen bg-surface bg-mesh flex items-center justify-center p-4">
        {/* Background Decorative Cosmic Glows */}
        <div className="absolute top-1/4 left-1/4 w-[400px] h-[400px] rounded-full bg-primary/5 blur-[120px] pointer-events-none"></div>
        <div className="absolute bottom-1/4 right-1/4 w-[400px] h-[400px] rounded-full bg-tertiary/5 blur-[120px] pointer-events-none"></div>

        <motion.div 
          className="w-full max-w-[440px] glass-effect nebula-shadow rounded-card p-8 md:p-10 relative overflow-hidden"
          initial={{ opacity: 0, scale: 0.96, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        >
          {/* Subtle light-catching top border glow */}
          <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-tertiary/20 to-transparent"></div>

          {/* Header */}
          <div className="text-center mb-8">
            <motion.div 
              className="w-14 h-14 mx-auto mb-4 rounded-2xl bg-gradient-to-tr from-primary to-primary-container text-surface flex items-center justify-center glow-primary"
              initial={{ rotate: -15, scale: 0.8 }}
              animate={{ rotate: 0, scale: 1 }}
              transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
            >
              <Shield className="w-7 h-7 stroke-[2]" />
            </motion.div>
            <motion.h1
              className="font-display font-bold text-2xl md:text-3xl text-text-main tracking-tight"
              initial={{ opacity: 0, y: 5 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
            >
              Cognitive Portal
            </motion.h1>
            <motion.p
              className="text-xs text-text-dim tracking-widest uppercase mt-1"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
            >
              CHITIEU<span className="text-primary font-bold">PLUS</span> CONTROL CENTER
            </motion.p>
          </div>

          {/* Form */}
          <form onSubmit={handleLogin} className="flex flex-col gap-5">
            <AnimatePresence mode="wait">
              {error && (
                <motion.div 
                  className="bg-error-color/10 border border-error-color/20 text-error-color p-3.5 rounded-xl flex items-center gap-3 text-xs overflow-hidden"
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                >
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span className="font-medium">{error}</span>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Username field - understated box matching spec */}
            <div className="flex flex-col">
              <label className="text-[10px] text-text-dim uppercase tracking-wider font-semibold mb-1 ml-1">Định danh chỉ huy</label>
              <div className="relative flex items-center bg-surface-container-highest rounded-t-xl border-b-2 border-outline-variant/30 focus-within:border-primary transition-all duration-300">
                <User className="absolute left-4 w-4 h-4 text-text-dim" />
                <input 
                  type="text" 
                  placeholder="admin" 
                  value={username} 
                  onChange={(e) => setUsername(e.target.value)}
                  className="w-full bg-transparent border-none outline-none pl-11 pr-4 py-3.5 text-text-main placeholder-text-dim/30 text-sm font-medium"
                  required 
                />
              </div>
            </div>

            {/* Password field */}
            <div className="flex flex-col">
              <label className="text-[10px] text-text-dim uppercase tracking-wider font-semibold mb-1 ml-1">Mã khóa bảo mật</label>
              <div className="relative flex items-center bg-surface-container-highest rounded-t-xl border-b-2 border-outline-variant/30 focus-within:border-primary transition-all duration-300">
                <Lock className="absolute left-4 w-4 h-4 text-text-dim" />
                <input 
                  type="password" 
                  placeholder="••••••••" 
                  value={password} 
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-transparent border-none outline-none pl-11 pr-4 py-3.5 text-text-main placeholder-text-dim/30 text-sm"
                  required 
                />
              </div>
            </div>

            {/* Actions button */}
            <motion.button 
              type="submit" 
              className="mt-4 w-full cursor-pointer py-3.5 px-6 rounded-full bg-gradient-to-r from-primary to-primary-container text-surface font-display font-bold text-sm tracking-wider uppercase flex items-center justify-center gap-2 glow-primary hover:opacity-90 active:scale-[0.99] transition-all"
              whileHover={{ x: 2 }}
            >
              <span>Vào hệ thống</span>
              <ArrowRight className="w-4 h-4" />
            </motion.button>
          </form>

          {/* Footer security badge */}
          <div className="text-center mt-8 pt-6 border-t border-outline-variant/10">
            <p className="text-[10px] text-text-dim uppercase tracking-widest font-semibold flex items-center justify-center gap-1.5">
              <span className="w-1 h-1 rounded-full bg-tertiary"></span>
              SECURE CLIENT SHIELD ACTIVE
            </p>
          </div>
        </motion.div>
      </div>
    </PageTransition>
  );
};
