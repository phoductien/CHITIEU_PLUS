import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { 
  BarChart3, Users, Tags, MessageSquare, LogOut, ShieldCheck,
  ChevronRight, Activity
} from 'lucide-react';
import { motion } from 'framer-motion';

const navItems = [
  { icon: BarChart3, label: 'Thống kê', path: '/' },
  { icon: Users, label: 'Người dùng', path: '/users' },
  { icon: Tags, label: 'Danh mục', path: '/categories' },
  { icon: MessageSquare, label: 'Phản hồi', path: '/feedback' },
];

export const AdminLayout = ({ children }) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="admin-layout">
      <motion.aside 
        initial={{ x: -280 }}
        animate={{ x: 0 }}
        transition={{ type: 'spring', damping: 20, stiffness: 100 }}
        className="admin-sidebar"
      >
        <div className="sidebar-brand">
           <motion.div 
             className="brand-logo"
             whileHover={{ rotate: 180 }}
             transition={{ duration: 0.5 }}
           >
              <ShieldCheck size={24} />
           </motion.div>
           <div className="brand-info">
              <span className="brand-name">ADMIN HQ</span>
              <span className="brand-status">Online • Hệ thống</span>
           </div>
        </div>

        <nav className="sidebar-nav">
          {navItems.map((item, index) => (
            <motion.div
              key={item.path}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 + index * 0.05 }}
            >
              <NavLink 
                to={item.path} 
                className={({ isActive }) => `admin-nav-link ${isActive ? 'active' : ''}`}
              >
                 <item.icon className="nav-icon" size={20} />
                 <span className="nav-label">{item.label}</span>
                 <ChevronRight className="nav-chevron" size={14} />
              </NavLink>
            </motion.div>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="admin-profile">
             <div className="admin-avatar">
                {user?.name?.charAt(0) || 'A'}
             </div>
             <div className="admin-info">
                <span className="name">{user?.name || 'Admin'}</span>
                <span className="role">Tổng quản trị</span>
             </div>
          </div>
          <motion.button 
            onClick={handleLogout} 
            className="logout-btn"
            whileHover={{ backgroundColor: 'var(--danger)', color: 'white' }}
            whileTap={{ scale: 0.95 }}
          >
             <LogOut size={18} />
             <span>Đăng xuất</span>
          </motion.button>
        </div>
      </motion.aside>

      <main className="admin-main">
        <header className="admin-topbar">
           <div className="page-header">
              <Activity size={18} className="indigo-text" />
              <span className="path-text">Hệ thống / Hiện tại</span>
           </div>
           <div className="system-status">
              <div className="status-item">
                 <span className="label">Database:</span>
                 <span className="value success">Sẵn sàng</span>
              </div>
              <div className="status-item">
                 <span className="label">AI API:</span>
                 <span className="value indigo-text">Gemini 3.0+</span>
              </div>
           </div>
        </header>

        <div className="admin-content">
           {children}
        </div>
      </main>

      <style>{`
        .admin-layout {
          display: flex;
          min-height: 100vh;
          background: var(--bg-primary);
        }

        .admin-sidebar {
          width: 280px;
          background: var(--bg-secondary);
          border-right: 1px solid var(--border);
          display: flex;
          flex-direction: column;
          padding: 24px 16px;
          position: fixed;
          height: 100vh;
          z-index: 100;
        }

        .sidebar-brand {
          display: flex;
          align-items: center;
          gap: 12px;
          padding-bottom: 32px;
          margin-bottom: 32px;
          border-bottom: 1px solid var(--border);
        }

        .brand-logo {
          width: 40px;
          height: 40px;
          background: var(--primary);
          color: #161B22;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .brand-info {
          display: flex;
          flex-direction: column;
        }

        .brand-name {
          font-family: 'Space Grotesk', sans-serif;
          font-weight: 700;
          font-size: 18px;
          color: var(--text-main);
          letter-spacing: 0.5px;
        }

        .brand-status {
          font-size: 11px;
          color: var(--success);
          font-weight: 600;
          text-transform: uppercase;
        }

        .sidebar-nav {
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .admin-nav-link {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 12px 16px;
          border-radius: var(--radius-md);
          color: var(--text-dim);
          text-decoration: none;
          transition: var(--transition);
        }

        .admin-nav-link:hover {
          background: var(--bg-accent);
          color: var(--text-main);
        }

        .admin-nav-link.active {
          background: var(--primary-glow);
          color: var(--primary);
        }

        .admin-nav-link.active .nav-icon {
          color: var(--primary);
        }

        .nav-chevron {
          margin-left: auto;
          opacity: 0;
          transform: translateX(-10px);
          transition: var(--transition);
        }

        .admin-nav-link:hover .nav-chevron {
          opacity: 0.5;
          transform: translateX(0);
        }

        .sidebar-footer {
          margin-top: auto;
          padding: 20px 0 0;
          display: flex;
          flex-direction: column;
          gap: 20px;
          border-top: 1px solid var(--border);
        }

        .admin-profile {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 0 8px;
        }

        .admin-avatar {
          width: 36px;
          height: 36px;
          background: var(--indigo);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 700;
          color: white;
        }

        .admin-info .name {
          display: block;
          font-size: 14px;
          font-weight: 600;
        }

        .admin-info .role {
          display: block;
          font-size: 11px;
          color: var(--text-dim);
        }

        .logout-btn {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 10px;
          padding: 12px;
          background: rgba(248, 81, 73, 0.1);
          color: var(--danger);
          border-radius: var(--radius-md);
          font-weight: 600;
          font-size: 14px;
          border: none;
          cursor: pointer;
          transition: var(--transition);
        }

        .admin-main {
          margin-left: 280px;
          flex: 1;
          display: flex;
          flex-direction: column;
        }

        .admin-topbar {
          height: 72px;
          background: var(--bg-primary);
          border-bottom: 1px solid var(--border);
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 40px;
          position: sticky;
          top: 0;
          z-index: 90;
        }

        .page-header {
           display: flex;
           align-items: center;
           gap: 12px;
           font-size: 14px;
           color: var(--text-dim);
        }

        .path-text { color: var(--text-main); font-weight: 500; }
        .indigo-text { color: var(--indigo); }

        .system-status {
           display: flex;
           gap: 24px;
        }

        .status-item {
           display: flex;
           gap: 8px;
           font-size: 12px;
        }

        .status-item .label { color: var(--text-dim); }
        .success { color: var(--success); }

        .admin-content {
          padding: 40px;
          max-width: 1400px;
          margin: 0 auto;
          width: 100%;
        }
      `}</style>
    </div>
  );
};
