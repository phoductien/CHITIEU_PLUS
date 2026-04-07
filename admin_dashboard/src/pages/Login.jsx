import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { Shield, Lock, User, AlertCircle } from 'lucide-react';
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
      setError('Tài khoản hoặc mật khẩu không đúng!');
    }
  };

  return (
    <PageTransition className="login-wrapper">
      <motion.div 
        className="login-card glass-card"
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.5, ease: "easeOut" }}
      >
        <div className="login-header">
           <motion.div 
             className="logo-badge"
             initial={{ rotate: -10, opacity: 0 }}
             animate={{ rotate: 0, opacity: 1 }}
             transition={{ delay: 0.2, duration: 0.5 }}
           >
              <Shield size={32} />
           </motion.div>
           <motion.h1
             initial={{ opacity: 0, x: -10 }}
             animate={{ opacity: 1, x: 0 }}
             transition={{ delay: 0.3 }}
           >
             Administrator
           </motion.h1>
           <motion.p
             initial={{ opacity: 0, x: 10 }}
             animate={{ opacity: 1, x: 0 }}
             transition={{ delay: 0.4 }}
           >
             ChiTieu<span>Plus</span> Control Panel
           </motion.p>
        </div>

        <form onSubmit={handleLogin} className="login-form">
          <AnimatePresence mode="wait">
            {error && (
              <motion.div 
                className="error-message"
                initial={{ opacity: 0, height: 0, y: -10 }}
                animate={{ opacity: 1, height: 'auto', y: 0 }}
                exit={{ opacity: 0, height: 0, y: -10 }}
              >
                <AlertCircle size={18} />
                <span>{error}</span>
              </motion.div>
            )}
          </AnimatePresence>

          <div className="input-field">
            <User className="icon" size={20} />
            <input 
              type="text" 
              placeholder="Username" 
              value={username} 
              onChange={(e) => setUsername(e.target.value)}
              required 
            />
          </div>

          <div className="input-field">
            <Lock className="icon" size={20} />
            <input 
              type="password" 
              placeholder="Password" 
              value={password} 
              onChange={(e) => setPassword(e.target.value)}
              required 
            />
          </div>

          <motion.button 
            type="submit" 
            className="login-btn"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
             <span>ĐĂNG NHẬP</span>
          </motion.button>
        </form>

        <div className="login-footer">
           <p>© 2026 ChiTieuPlus HQ. Bảo mật tuyệt đối.</p>
        </div>
      </motion.div>

      <style>{`
        .login-wrapper {
          width: 100vw;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          background: radial-gradient(circle at center, #1C2128 0%, #0A0C10 100%);
        }

        .login-card {
          width: 400px;
          padding: 48px;
          display: flex;
          flex-direction: column;
          gap: 32px;
        }

        .login-header {
          text-align: center;
        }

        .logo-badge {
          width: 64px;
          height: 64px;
          margin: 0 auto 20px;
          background: var(--primary);
          color: #161B22;
          border-radius: 16px;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 8px 32px var(--primary-glow);
        }

        .login-header h1 {
          font-size: 28px;
          margin-bottom: 4px;
        }

        .login-header p {
          font-size: 14px;
          color: var(--text-dim);
          text-transform: uppercase;
          letter-spacing: 1px;
        }

        .login-header span {
          color: var(--primary);
        }

        .login-form {
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .error-message {
          background: rgba(248, 81, 73, 0.1);
          border: 1px solid var(--danger);
          padding: 12px;
          border-radius: var(--radius-md);
          display: flex;
          align-items: center;
          gap: 10px;
          color: var(--danger);
          font-size: 14px;
          overflow: hidden;
        }

        .input-field {
          position: relative;
          display: flex;
          align-items: center;
        }

        .input-field .icon {
          position: absolute;
          left: 14px;
          color: var(--text-dim);
          pointer-events: none;
        }

        .input-field input {
          width: 100%;
          padding: 14px 14px 14px 44px;
          background: var(--bg-accent);
          border: 1px solid var(--border);
          border-radius: var(--radius-md);
          color: var(--text-main);
          font-size: 15px;
          transition: var(--transition);
        }

        .input-field input:focus {
          border-color: var(--primary);
          outline: none;
          box-shadow: 0 0 0 4px var(--primary-glow);
        }

        .login-btn {
          margin-top: 8px;
          background: var(--primary);
          color: #161B22;
          padding: 16px;
          border-radius: var(--radius-md);
          font-weight: 800;
          letter-spacing: 2px;
          border: none;
          cursor: pointer;
        }

        .login-footer {
          text-align: center;
        }

        .login-footer p {
          font-size: 12px;
          color: var(--text-dim);
        }
      `}</style>
    </PageTransition>
  );
};
