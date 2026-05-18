import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import axios from 'axios';
import toast from 'react-hot-toast';
import { PageTransition } from '../components/PageTransition';
import { 
  Sparkles, 
  EyeOff, 
  Zap, 
  FileText, 
  Wrench, 
  Megaphone, 
  Info, 
  Save,
  RefreshCw
} from 'lucide-react';

const itemVariants = {
  hidden: { opacity: 0, y: 15 },
  show: { opacity: 1, y: 0 }
};

const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.1 }
  }
};

export const AdminConfig = () => {
  const [apiKey, setApiKey] = useState('****************************************');
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [ocrSensitivity, setOcrSensitivity] = useState(85);
  const [notification, setNotification] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    const fetchConfig = async () => {
      try {
        const res = await axios.get('/api/admin/config');
        if (res.data) {
          setApiKey(res.data.apiKey || '');
          setMaintenanceMode(res.data.maintenanceMode || false);
          setOcrSensitivity(res.data.ocrSensitivity || 85);
          setNotification(res.data.notification || '');
        }
      } catch (error) {
        console.error('Error fetching config', error);
      }
    };
    fetchConfig();
  }, []);

  const handleSaveConfig = async () => {
    setIsSaving(true);
    const toastId = toast.loading('Đang lưu cấu hình...');
    try {
      await axios.post('/api/admin/config', {
        apiKey,
        maintenanceMode,
        ocrSensitivity,
        notification
      });
      toast.success('Đã lưu cấu hình thành công!', { id: toastId });
    } catch (error) {
      toast.error('Lỗi khi lưu cấu hình. Vui lòng thử lại.', { id: toastId });
      console.error(error);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <PageTransition>
      <div className="mb-12">
        <h2 className="text-4xl font-bold font-display text-on-surface mb-2">Cấu hình Hệ thống</h2>
        <p className="text-on-surface-variant text-sm max-w-xl">
          Quản lý các tham số vận hành cốt lõi, tích hợp trí tuệ nhân tạo và trạng thái hệ thống thời gian thực.
        </p>
      </div>

      <motion.div 
        className="grid grid-cols-12 gap-6"
        variants={containerVariants}
        initial="hidden"
        animate="show"
      >
        {/* Gemini API Section */}
        <motion.div variants={itemVariants} className="col-span-12 md:col-span-8 bg-surface-container-low rounded-[1.5rem] p-8 border border-transparent hover:border-outline-variant/15 transition-all">
          <div className="flex items-center gap-4 mb-8">
            <div className="w-12 h-12 rounded-xl bg-tertiary/10 flex items-center justify-center text-tertiary">
              <Sparkles className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-xl font-bold font-display text-white">Cấu hình API Gemini</h3>
              <p className="text-xs text-on-surface-variant">Thiết lập kết nối với mô hình ngôn ngữ lớn từ Google</p>
            </div>
          </div>
          <div className="space-y-6">
            <div className="group">
              <label className="block text-xs font-semibold text-on-surface-variant mb-2 uppercase tracking-widest">Khóa Bí Mật (API Key)</label>
              <div className="relative">
                <input 
                  className="w-full bg-surface-container-highest border-none rounded-xl py-3 px-4 text-on-surface focus:ring-2 focus:ring-primary transition-all font-mono outline-none" 
                  placeholder="Nhập API Key của bạn..." 
                  type="password" 
                  value={apiKey}
                  onChange={(e) => setApiKey(e.target.value)}
                />
                <button className="absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary transition-colors">
                  <EyeOff className="w-5 h-5" />
                </button>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-2 uppercase tracking-widest">Phiên Bản Model</label>
                <select className="w-full bg-surface-container-highest border-none rounded-xl py-3 px-4 text-on-surface focus:ring-2 focus:ring-primary outline-none appearance-none cursor-pointer">
                  <option>Gemini 1.5 Pro</option>
                  <option>Gemini 1.5 Flash</option>
                  <option>Gemini 1.0 Ultra</option>
                </select>
              </div>
              <div className="flex items-end">
                <div className="bg-surface-container-highest/40 backdrop-blur-xl p-4 rounded-xl flex items-center gap-3 w-full border border-outline-variant/10">
                  <Zap className="w-5 h-5 text-tertiary fill-tertiary" />
                  <span className="text-xs text-on-tertiary-container font-medium">Trạng thái: Đã kết nối</span>
                </div>
              </div>
            </div>
          </div>
        </motion.div>

        {/* OCR Sensitivity */}
        <motion.div variants={itemVariants} className="col-span-12 md:col-span-4 bg-surface-container-low rounded-[1.5rem] p-8 flex flex-col justify-between border border-transparent hover:border-outline-variant/15 transition-all">
          <div>
            <div className="w-12 h-12 rounded-xl bg-secondary/10 flex items-center justify-center text-secondary mb-6">
              <FileText className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold font-display text-white mb-2">Độ nhạy OCR</h3>
            <p className="text-xs text-on-surface-variant mb-8">Điều chỉnh ngưỡng nhận diện văn bản từ hình ảnh hóa đơn.</p>
          </div>
          <div className="space-y-4">
            <div className="flex justify-between items-end">
              <span className="text-3xl font-bold font-display text-primary">{ocrSensitivity}%</span>
              <span className="text-xs font-bold text-on-surface-variant">TỐI ƯU</span>
            </div>
            <input 
              className="w-full h-1.5 bg-surface-container-highest rounded-full appearance-none cursor-pointer accent-primary" 
              max="100" 
              min="0" 
              type="range" 
              value={ocrSensitivity}
              onChange={(e) => setOcrSensitivity(e.target.value)}
            />
          </div>
        </motion.div>

        {/* Maintenance Mode */}
        <motion.div variants={itemVariants} className="col-span-12 md:col-span-4 bg-surface-container-low rounded-[1.5rem] p-8 border border-transparent hover:border-outline-variant/15 transition-all">
          <div className="flex items-start justify-between mb-6">
            <div className="w-12 h-12 rounded-xl bg-error/10 flex items-center justify-center text-error">
              <Wrench className="w-6 h-6" />
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input 
                type="checkbox" 
                className="sr-only peer" 
                checked={maintenanceMode}
                onChange={() => setMaintenanceMode(!maintenanceMode)}
              />
              <div className="w-14 h-7 bg-surface-container-highest peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:start-[4px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-error"></div>
            </label>
          </div>
          <h3 className="text-xl font-bold font-display text-white mb-2">Chế độ bảo trì</h3>
          <p className="text-xs text-on-surface-variant">Tạm ngưng mọi giao diện người dùng để thực hiện cập nhật cơ sở dữ liệu.</p>
        </motion.div>

        {/* System Notification */}
        <motion.div variants={itemVariants} className="col-span-12 md:col-span-8 bg-surface-container-low rounded-[1.5rem] p-8 border border-transparent hover:border-outline-variant/15 transition-all">
          <div className="flex items-center gap-4 mb-6">
            <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
              <Megaphone className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-xl font-bold font-display text-white">Thông báo hệ thống</h3>
              <p className="text-xs text-on-surface-variant">Gửi thông điệp toàn cục tới bảng điều khiển của người dùng</p>
            </div>
          </div>
          <textarea 
            className="w-full bg-surface-container-highest border-none outline-none rounded-xl p-4 text-on-surface focus:ring-2 focus:ring-primary transition-all h-24 resize-none" 
            placeholder="Nhập nội dung thông báo tại đây..."
            value={notification}
            onChange={(e) => setNotification(e.target.value)}
          ></textarea>
          <div className="mt-4 flex items-center gap-2 text-[10px] font-bold text-on-surface-variant/50 uppercase tracking-widest">
            <Info className="w-4 h-4" />
            Sẽ xuất hiện dưới dạng biểu ngữ (banner) nổi bật.
          </div>
        </motion.div>
      </motion.div>

      {/* Floating Footer Action */}
      <motion.div 
        initial={{ opacity: 0, y: 50 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="fixed bottom-0 left-0 md:left-72 right-0 p-8 flex justify-center pointer-events-none z-40"
      >
        <button 
          onClick={handleSaveConfig}
          disabled={isSaving}
          className="pointer-events-auto bg-gradient-to-r from-primary to-on-primary-container text-on-primary-fixed px-12 py-4 rounded-full font-bold font-display shadow-[0px_24px_48px_rgba(0,0,0,0.4)] flex items-center gap-3 hover:scale-105 active:scale-95 transition-all disabled:opacity-70 disabled:hover:scale-100"
        >
          {isSaving ? <RefreshCw className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5 fill-current" />}
          {isSaving ? 'Đang lưu...' : 'Lưu cấu hình'}
        </button>
      </motion.div>
    </PageTransition>
  );
};
