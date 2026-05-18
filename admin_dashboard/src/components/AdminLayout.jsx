import { NavLink, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { 
  BarChart3, Users, Tags, MessageSquare, LogOut, ShieldCheck,
  ChevronRight, Activity, Cpu, Database, Menu, X, Bell, Settings, Newspaper
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useState } from 'react';

const navItems = [
  { icon: BarChart3, label: 'Thống kê AI', path: '/' },
  { icon: Users, label: 'Người dùng & Logs', path: '/users' },
  { icon: Tags, label: 'Danh mục & Keywords', path: '/categories' },
  { icon: Newspaper, label: 'Quản lý tin tức', path: '/news' },
  { icon: MessageSquare, label: 'Phản hồi người dùng', path: '/feedback' },
  { icon: Settings, label: 'Cấu hình hệ thống', path: '/config' },
];

export const AdminLayout = ({ children }) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const getPageTitle = () => {
    switch (location.pathname) {
      case '/': return 'Trung tâm Phân tích AI & Tài chính';
      case '/users': return 'Quản lý Người dùng & Nhật ký Hệ thống';
      case '/categories': return 'Từ điển Danh mục & AI Keywords';
      case '/news': return 'Trung tâm Tin tức Tài chính';
      case '/feedback': return 'Hộp thư Góp ý & Ý kiến Trực tuyến';
      case '/config': return 'Cấu hình Hệ thống & API';
      default: return 'Bảng điều khiển';
    }
  };

  return (
    <div className="min-h-screen bg-surface bg-mesh text-text-main font-sans flex flex-col md:flex-row relative">
      {/* Sidebar for Desktop */}
      <aside className="hidden md:flex w-72 bg-surface-container-low flex-col p-6 fixed h-screen z-40 transition-all duration-300">
        {/* Brand */}
        <div className="flex items-center gap-3 pb-8 mb-8 border-b border-outline-variant/10">
          <motion.div 
            className="w-10 h-10 rounded-xl bg-gradient-to-tr from-primary to-primary-container text-surface flex items-center justify-center glow-primary"
            whileHover={{ rotate: 180, scale: 1.05 }}
            transition={{ duration: 0.5 }}
          >
            <ShieldCheck className="w-5 h-5 stroke-[2]" />
          </motion.div>
          <div className="flex flex-col">
            <span className="font-display font-bold text-lg tracking-wider text-text-main">CHITIEU+</span>
            <span className="text-[10px] text-tertiary font-semibold tracking-widest uppercase flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-tertiary animate-pulse"></span>
              AETHER COBALT
            </span>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 flex flex-col gap-1.5">
          {navItems.map((item, index) => (
            <motion.div
              key={item.path}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
            >
              <NavLink 
                to={item.path} 
                className={({ isActive }) => `
                  group flex items-center gap-3.5 px-4 py-3 rounded-xl transition-all duration-300 text-sm font-medium
                  ${isActive 
                    ? 'bg-surface-container-high text-primary glow-primary font-semibold' 
                    : 'text-text-dim hover:bg-surface-container/50 hover:text-text-main'
                  }
                `}
              >
                <item.icon className={`w-5 h-5 transition-transform duration-300 group-hover:scale-110`} />
                <span className="flex-1">{item.label}</span>
                <ChevronRight className="w-4 h-4 opacity-0 -translate-x-2 transition-all duration-300 group-hover:opacity-100 group-hover:translate-x-0" />
              </NavLink>
            </motion.div>
          ))}
        </nav>

        {/* Profile / Footer */}
        <div className="mt-auto pt-6 border-t border-outline-variant/10 flex flex-col gap-4">
          <div className="flex items-center gap-3 px-2">
            <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-secondary to-tertiary text-surface font-bold flex items-center justify-center text-sm shadow-md">
              {user?.name?.charAt(0) || 'A'}
            </div>
            <div className="flex flex-col overflow-hidden">
              <span className="text-sm font-semibold text-text-main truncate">{user?.name || 'Super Admin'}</span>
              <span className="text-[11px] text-text-dim uppercase tracking-wider font-medium truncate">{user?.role || 'Tổng quản trị'}</span>
            </div>
          </div>

          <motion.button 
            onClick={handleLogout} 
            className="flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-error-color/10 hover:bg-error-color/20 text-error-color font-semibold text-sm transition-all duration-300 cursor-pointer"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <LogOut className="w-4 h-4" />
            <span>Đăng xuất</span>
          </motion.button>
        </div>
      </aside>

      {/* Mobile Header & Drawer Nav */}
      <header className="md:hidden flex items-center justify-between p-4 bg-surface-container-low border-b border-outline-variant/10 z-50 sticky top-0 w-full">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-primary to-primary-container text-surface flex items-center justify-center">
            <ShieldCheck className="w-4 h-4" />
          </div>
          <span className="font-display font-bold text-md tracking-wider">CHITIEU+</span>
        </div>
        <button 
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="w-10 h-10 flex items-center justify-center rounded-xl bg-surface-container-high hover:bg-surface-container-highest transition-colors cursor-pointer"
        >
          {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </header>

      {/* Mobile Drawer */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div 
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="md:hidden fixed top-[73px] left-0 right-0 bg-surface-container-low border-b border-outline-variant/10 p-6 z-40 flex flex-col gap-6 shadow-2xl"
          >
            <nav className="flex flex-col gap-2">
              {navItems.map((item) => (
                <NavLink 
                  key={item.path}
                  to={item.path} 
                  onClick={() => setMobileMenuOpen(false)}
                  className={({ isActive }) => `
                    flex items-center gap-3.5 px-4 py-3 rounded-xl transition-all duration-300 text-sm font-medium
                    ${isActive 
                      ? 'bg-surface-container-high text-primary font-semibold shadow-inner' 
                      : 'text-text-dim hover:bg-surface-container/50 hover:text-text-main'
                    }
                  `}
                >
                  <item.icon className="w-5 h-5" />
                  <span>{item.label}</span>
                </NavLink>
              ))}
            </nav>
            <div className="pt-4 border-t border-outline-variant/10 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-full bg-secondary text-surface font-bold flex items-center justify-center text-sm">
                  {user?.name?.charAt(0) || 'A'}
                </div>
                <div className="flex flex-col">
                  <span className="text-sm font-semibold">{user?.name || 'Super Admin'}</span>
                  <span className="text-[10px] text-text-dim uppercase tracking-wider">{user?.role || 'Hệ thống'}</span>
                </div>
              </div>
              <button 
                onClick={handleLogout} 
                className="flex items-center justify-center gap-2 py-2 px-4 rounded-xl bg-error-color/10 text-error-color font-semibold text-xs transition-colors cursor-pointer"
              >
                <LogOut className="w-3.5 h-3.5" />
                <span>Đăng xuất</span>
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Content Area */}
      <main className="flex-1 md:ml-72 flex flex-col min-h-screen overflow-x-hidden">
        {/* Topbar sticky header */}
        <header className="hidden md:flex h-[76px] bg-surface/50 backdrop-blur-xl border-b border-outline-variant/10 px-8 items-center justify-between sticky top-0 z-30">
          <div className="flex items-center gap-2 text-text-dim text-sm">
            <Activity className="w-4 h-4 text-tertiary" />
            <span className="font-semibold text-text-main tracking-wide uppercase text-xs">{getPageTitle()}</span>
          </div>
          
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-4 text-xs font-medium">
              <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-surface-container-low border border-outline-variant/10">
                <Database className="w-3.5 h-3.5 text-tertiary" />
                <span className="text-text-dim">DB:</span>
                <span className="text-tertiary font-semibold">Active & Live</span>
              </div>
              <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-surface-container-low border border-outline-variant/10">
                <Cpu className="w-3.5 h-3.5 text-primary" />
                <span className="text-text-dim">AI engine:</span>
                <span className="text-primary font-semibold">Gemini 3.5 Pro</span>
              </div>
            </div>
            
            {/* Notification Glow Bell */}
            <div className="relative cursor-pointer w-9 h-9 rounded-lg bg-surface-container-low flex items-center justify-center hover:bg-surface-container hover:text-primary transition-colors">
              <Bell className="w-4 h-4" />
              <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-primary animate-ping"></span>
              <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-primary"></span>
            </div>
          </div>
        </header>

        {/* Content Body */}
        <div className="flex-1 p-4 md:p-8 max-w-[1600px] w-full mx-auto">
          {children}
        </div>
      </main>
    </div>
  );
};
