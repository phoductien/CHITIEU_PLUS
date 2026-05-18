import { useState } from 'react';
import { motion } from 'framer-motion';
import axios from 'axios';
import toast from 'react-hot-toast';
import { PageTransition } from '../components/PageTransition';
import { 
  RefreshCw, 
  Sparkles, 
  Brain, 
  CheckCircle, 
  Edit, 
  EyeOff, 
  Check, 
  Sliders 
} from 'lucide-react';

const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.1 }
  }
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0 }
};

export const AdminNews = () => {
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleRefreshNews = async () => {
    setIsRefreshing(true);
    const toastId = toast.loading('Đang làm mới dữ liệu...');
    try {
      const res = await axios.get('/api/admin/news?action=fetch');
      toast.success(res.data.message || 'Dữ liệu đã được cập nhật!', { id: toastId });
    } catch (error) {
      toast.error('Có lỗi xảy ra khi làm mới.', { id: toastId });
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleApprove = async (id) => {
    const toastId = toast.loading('Đang duyệt tin...');
    try {
      const res = await axios.post('/api/admin/news?action=approve', { id });
      toast.success(res.data.message || 'Đã duyệt tin thành công!', { id: toastId });
    } catch (error) {
      toast.error('Lỗi duyệt tin.', { id: toastId });
    }
  };

  return (
    <PageTransition>
      <div className="space-y-8">
        {/* Header Section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-8">
          <div>
            <h2 className="text-4xl font-display font-bold text-white tracking-tight leading-none mb-2">Trung tâm Tin tức Tài chính</h2>
            <p className="text-on-surface-variant font-body">Cập nhật và quản lý dòng chảy dữ liệu thị trường theo thời gian thực.</p>
          </div>
          <button 
            onClick={handleRefreshNews}
            disabled={isRefreshing}
            className="group flex items-center gap-2 bg-surface-container-high hover:bg-surface-container-highest text-primary border border-primary/10 px-6 py-3 rounded-xl transition-all duration-300 disabled:opacity-70 disabled:hover:bg-surface-container-high cursor-pointer"
          >
            <RefreshCw className={`w-5 h-5 ${isRefreshing ? 'animate-spin' : 'group-hover:rotate-180 transition-transform duration-500'}`} />
            <span className="font-bold tracking-wide">{isRefreshing ? 'Đang tải...' : 'Làm mới dữ liệu'}</span>
          </button>
        </div>

        {/* Dashboard Stats (Bento Minimal) */}
        <motion.div 
          className="grid grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6"
          variants={containerVariants}
          initial="hidden"
          animate="show"
        >
          <motion.div variants={itemVariants} className="p-6 rounded-2xl bg-surface-container-low border border-outline-variant/15 flex flex-col justify-between h-32">
            <span className="text-xs font-bold uppercase tracking-widest text-slate-500">Tin tức mới cào</span>
            <div className="text-3xl font-display font-bold text-white">128</div>
          </motion.div>
          <motion.div variants={itemVariants} className="p-6 rounded-2xl bg-surface-container-low border border-outline-variant/15 flex flex-col justify-between h-32">
            <span className="text-xs font-bold uppercase tracking-widest text-slate-500">Chờ duyệt</span>
            <div className="text-3xl font-display font-bold text-tertiary">42</div>
          </motion.div>
          <motion.div variants={itemVariants} className="p-6 rounded-2xl bg-surface-container-low border border-outline-variant/15 flex flex-col justify-between h-32">
            <span className="text-xs font-bold uppercase tracking-widest text-slate-500">Nguồn hoạt động</span>
            <div className="text-3xl font-display font-bold text-secondary">08</div>
          </motion.div>
          <motion.div variants={itemVariants} className="p-6 rounded-2xl bg-primary-container/20 border border-primary/20 flex flex-col justify-between h-32">
            <span className="text-xs font-bold uppercase tracking-widest text-primary">Phân tích AI</span>
            <div className="text-3xl font-display font-bold text-primary">98% <span className="text-sm font-normal">Chính xác</span></div>
          </motion.div>
        </motion.div>

        {/* News List Section */}
        <motion.div 
          className="space-y-6"
          variants={containerVariants}
          initial="hidden"
          animate="show"
        >
          {/* News Item 1 */}
          <motion.div variants={itemVariants} className="relative group">
            <div className="absolute -inset-0.5 bg-gradient-to-r from-primary/10 to-tertiary/10 rounded-2xl blur opacity-0 group-hover:opacity-100 transition duration-1000"></div>
            <div className="relative p-6 md:p-8 rounded-2xl bg-surface-container border border-outline-variant/10 flex flex-col lg:flex-row gap-8 items-start">
              {/* Content Side */}
              <div className="flex-1 space-y-4">
                <div className="flex items-center gap-3 text-xs font-medium">
                  <span className="px-2 py-1 rounded bg-surface-container-highest text-secondary border border-secondary/10">VnExpress</span>
                  <span className="text-slate-500">• 15 phút trước</span>
                  <span className="flex items-center gap-1 text-tertiary">
                    <Sparkles className="w-3.5 h-3.5" />
                    AI Hub
                  </span>
                </div>
                <h3 className="text-2xl font-display font-bold text-white leading-snug group-hover:text-primary transition-colors duration-300">
                  Thị trường chứng khoán Việt Nam khởi sắc: VN-Index vượt ngưỡng 1,280 điểm nhờ nhóm cổ phiếu ngân hàng
                </h3>
                {/* AI Summary Module */}
                <div className="bg-surface-container-low/40 backdrop-blur-xl p-5 rounded-xl border-l-4 border-tertiary/50">
                  <div className="flex items-center gap-2 mb-3">
                    <Brain className="w-4 h-4 text-tertiary" />
                    <span className="text-xs font-bold text-tertiary tracking-widest uppercase">Tóm tắt nhanh bởi AI</span>
                  </div>
                  <ul className="space-y-2 text-sm text-on-surface-variant leading-relaxed list-none">
                    <li className="flex gap-2">
                      <span className="text-tertiary font-bold">›</span> 
                      Dòng vốn ngoại quay trở lại mua ròng mạnh mẽ các cổ phiếu trụ cột như VCB, BID, TCB.
                    </li>
                    <li className="flex gap-2">
                      <span className="text-tertiary font-bold">›</span> 
                      Thanh khoản thị trường cải thiện 15% so với phiên giao dịch hôm qua, đạt mức cao nhất trong 2 tuần.
                    </li>
                    <li className="flex gap-2">
                      <span className="text-tertiary font-bold">›</span> 
                      Các chuyên gia dự báo xu hướng tăng trưởng ngắn hạn vẫn được duy trì nhờ chính sách tiền tệ nới lỏng.
                    </li>
                  </ul>
                </div>
              </div>
              {/* Actions Side */}
              <div className="flex lg:flex-col gap-3 w-full lg:w-48 lg:border-l lg:border-outline-variant/10 lg:pl-8">
                <button 
                  onClick={() => handleApprove(1)}
                  className="flex-1 flex items-center justify-center gap-2 bg-primary hover:bg-on-primary-container text-on-primary-fixed font-bold py-3 px-4 rounded-xl transition-all active:scale-95 cursor-pointer"
                >
                  <CheckCircle className="w-5 h-5" />
                  Duyệt đăng
                </button>
                <button className="flex-1 flex items-center justify-center gap-2 bg-surface-container-highest hover:bg-slate-700 text-on-surface font-semibold py-3 px-4 rounded-xl transition-all">
                  <Edit className="w-5 h-5" />
                  Sửa nội dung
                </button>
                <button className="flex items-center justify-center gap-2 text-error border border-error/20 hover:bg-error/10 py-3 px-4 rounded-xl transition-all">
                  <EyeOff className="w-5 h-5" />
                  Ẩn
                </button>
              </div>
            </div>
          </motion.div>

          {/* News Item 2 */}
          <motion.div variants={itemVariants} className="relative group">
            <div className="relative p-6 md:p-8 rounded-2xl bg-surface-container border border-outline-variant/10 flex flex-col lg:flex-row gap-8 items-start">
              {/* Content Side */}
              <div className="flex-1 space-y-4">
                <div className="flex items-center gap-3 text-xs font-medium">
                  <span className="px-2 py-1 rounded bg-surface-container-highest text-secondary border border-secondary/10">CafeF</span>
                  <span className="text-slate-500">• 45 phút trước</span>
                  <span className="flex items-center gap-1 text-tertiary">
                    <Sparkles className="w-3.5 h-3.5" />
                    AI Hub
                  </span>
                </div>
                <h3 className="text-2xl font-display font-bold text-white leading-snug group-hover:text-primary transition-colors duration-300">
                  Lãi suất tiết kiệm đồng loạt giảm tại nhiều ngân hàng lớn: Xu hướng dòng tiền chuyển dịch sang đầu tư?
                </h3>
                {/* AI Summary Module */}
                <div className="bg-surface-container-low/40 backdrop-blur-xl p-5 rounded-xl border-l-4 border-tertiary/50">
                  <div className="flex items-center gap-2 mb-3">
                    <Brain className="w-4 h-4 text-tertiary" />
                    <span className="text-xs font-bold text-tertiary tracking-widest uppercase">Tóm tắt nhanh bởi AI</span>
                  </div>
                  <ul className="space-y-2 text-sm text-on-surface-variant leading-relaxed list-none">
                    <li className="flex gap-2">
                      <span className="text-tertiary font-bold">›</span> 
                      Nhóm Big4 ngân hàng dẫn đầu làn sóng hạ lãi suất huy động kỳ hạn 12 tháng xuống mức thấp kỷ lục.
                    </li>
                    <li className="flex gap-2">
                      <span className="text-tertiary font-bold">›</span> 
                      Dữ liệu cho thấy lượng tiền gửi mới giảm nhẹ, trong khi giao dịch tại các sàn bất động sản tăng 5%.
                    </li>
                  </ul>
                </div>
              </div>
              {/* Actions Side */}
              <div className="flex lg:flex-col gap-3 w-full lg:w-48 lg:border-l lg:border-outline-variant/10 lg:pl-8">
                <button 
                  onClick={() => handleApprove(2)}
                  className="flex-1 flex items-center justify-center gap-2 bg-primary hover:bg-on-primary-container text-on-primary-fixed font-bold py-3 px-4 rounded-xl transition-all active:scale-95 cursor-pointer"
                >
                  <CheckCircle className="w-5 h-5" />
                  Duyệt đăng
                </button>
                <button className="flex-1 flex items-center justify-center gap-2 bg-surface-container-highest hover:bg-slate-700 text-on-surface font-semibold py-3 px-4 rounded-xl transition-all">
                  <Edit className="w-5 h-5" />
                  Sửa nội dung
                </button>
                <button className="flex items-center justify-center gap-2 text-error border border-error/20 hover:bg-error/10 py-3 px-4 rounded-xl transition-all">
                  <EyeOff className="w-5 h-5" />
                  Ẩn
                </button>
              </div>
            </div>
          </motion.div>

          {/* News Item 3 */}
          <motion.div variants={itemVariants} className="relative group">
            <div className="relative p-6 md:p-8 rounded-2xl bg-surface-container border border-outline-variant/10 flex flex-col lg:flex-row gap-8 items-center">
              <div className="w-full lg:w-1/3 h-48 rounded-xl overflow-hidden bg-surface-container-highest">
                <img 
                  alt="Financial chart and technology" 
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" 
                  src="https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&q=80&w=1200"
                />
              </div>
              {/* Content Side */}
              <div className="flex-1 space-y-4">
                <div className="flex items-center gap-3 text-xs font-medium">
                  <span className="px-2 py-1 rounded bg-surface-container-highest text-secondary border border-secondary/10">VnExpress</span>
                  <span className="text-slate-500">• 2 giờ trước</span>
                </div>
                <h3 className="text-2xl font-display font-bold text-white leading-snug group-hover:text-primary transition-colors duration-300">
                  Công nghệ AI đột phá trong việc dự báo rủi ro tín dụng cho doanh nghiệp vừa và nhỏ
                </h3>
                {/* AI Summary Module */}
                <div className="bg-surface-container-low/40 backdrop-blur-xl p-5 rounded-xl border-l-4 border-tertiary/50">
                  <ul className="space-y-2 text-sm text-on-surface-variant leading-relaxed list-none">
                    <li className="flex gap-2">
                      <span className="text-tertiary font-bold">›</span> 
                      Mô hình mới giảm thiểu tỷ lệ nợ xấu lên đến 20% thông qua phân tích dữ liệu hành vi.
                    </li>
                  </ul>
                </div>
              </div>
              {/* Actions Side */}
              <div className="flex lg:flex-col gap-2">
                <button className="p-3 bg-primary hover:bg-on-primary-container text-on-primary-fixed rounded-xl active:scale-95 transition-all group/btn">
                  <Check className="w-5 h-5 group-hover/btn:scale-110 transition-transform" />
                </button>
                <button className="p-3 bg-surface-container-highest hover:bg-slate-700 text-white rounded-xl active:scale-95 transition-all group/btn">
                  <Sliders className="w-5 h-5 group-hover/btn:scale-110 transition-transform" />
                </button>
              </div>
            </div>
          </motion.div>
        </motion.div>

        {/* Footer Pagination */}
        <div className="flex justify-center py-8">
          <button className="text-slate-400 font-bold tracking-widest uppercase text-xs border-b-2 border-transparent hover:border-primary hover:text-white transition-all py-2 cursor-pointer">
            Tải thêm tin tức • Cuộn để xem tiếp
          </button>
        </div>
      </div>
    </PageTransition>
  );
};
