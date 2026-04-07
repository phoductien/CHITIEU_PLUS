import { useState, useEffect } from 'react';
import { MessageSquare, Star, Send, Trash2, CheckCircle2, AlertTriangle, User, Loader2 } from 'lucide-react';
import { collection, getDocs, doc, updateDoc, deleteDoc, query, orderBy } from 'firebase/firestore';
import { db } from '../firebase';
import { motion, AnimatePresence } from 'framer-motion';
import { PageTransition } from '../components/PageTransition';

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0 },
};

export const AdminFeedback = () => {
  const [feedbacks, setFeedbacks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [replyingTo, setReplyingTo] = useState(null);
  const [replyText, setReplyText] = useState('');

  useEffect(() => {
    const fetchFeedback = async () => {
      try {
        setLoading(true);
        const q = query(collection(db, 'feedback'), orderBy('createdAt', 'desc'));
        const snap = await getDocs(q);
        const data = snap.docs.map(doc => ({
          id: doc.id,
          ...doc.data(),
          date: doc.data().createdAt?.toDate ? doc.data().createdAt.toDate().toLocaleDateString('vi-VN') : 'N/A'
        }));
        setFeedbacks(data);
        setLoading(false);
      } catch (error) {
        console.error("Error fetching feedback:", error);
        setLoading(false);
      }
    };

    fetchFeedback();
  }, []);

  const sendReply = async (id) => {
     try {
       await updateDoc(doc(db, 'feedback', id), {
         status: 'Replied',
         adminReply: replyText,
         repliedAt: new Date()
       });
       
       setFeedbacks(feedbacks.map(f => f.id === id ? { ...f, status: 'Replied' } : f));
       setReplyingTo(null);
       setReplyText('');
       alert('Phản hồi đã được gửi thành công!');
     } catch (error) {
       console.error("Error sending reply:", error);
     }
  };

  const deleteFeedback = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa phản hồi này?')) {
      try {
        await deleteDoc(doc(db, 'feedback', id));
        setFeedbacks(feedbacks.filter(f => f.id !== id));
      } catch (error) {
        console.error("Error deleting feedback:", error);
      }
    }
  };

  if (loading) {
     return (
       <div className="loading-state">
         <Loader2 className="animate-spin" size={48} color="var(--primary)" />
         <p>Đang tải ý kiến người dùng...</p>
       </div>
     );
  }

  return (
    <PageTransition>
      <div className="feedback-page">
        <div className="page-header-row">
           <div className="page-title">
              <motion.h1 initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }}>Góp ý & Phản hồi</motion.h1>
              <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.2 }}>Giải quyết {feedbacks.filter(f => f.status !== 'Replied').length} yêu cầu đang chờ xử lý.</motion.p>
           </div>
        </div>

        <motion.div 
          className="feedback-list"
          initial="hidden"
          animate="show"
          variants={{
            show: {
              transition: {
                staggerChildren: 0.05
              }
            }
          }}
        >
           <AnimatePresence mode="popLayout">
             {feedbacks.map((item) => (
                <motion.div 
                  key={item.id} 
                  layout
                  variants={itemVariants}
                  className="feedback-item glass-card"
                >
                   <div className="feedback-header">
                      <div className="user-info">
                         <div className="avatar-small"><User size={14} /></div>
                         <span className="user-name">{item.userName || item.user || 'Người dùng'}</span>
                         <span className="dot" />
                         <span className="date">{item.date}</span>
                      </div>
                      <div className={`status-tag ${(item.status || 'pending').toLowerCase()}`}>
                         {item.status === 'Replied' ? <CheckCircle2 size={12}/> : (item.status === 'Escalated' ? <AlertTriangle size={12}/> : <MessageSquare size={12}/>)}
                         {item.status || 'Pending'}
                      </div>
                   </div>

                   <div className="rating-row">
                      {[...Array(5)].map((_, i) => (
                         <Star key={i} size={14} className={i < (item.rating || 0) ? 'star filled' : 'star'} />
                      ))}
                   </div>

                   <div className="comment-text">
                      "{item.comment || item.message || 'Không có nội dung'}"
                   </div>

                   <div className="feedback-actions">
                      <AnimatePresence mode="wait">
                        {replyingTo === item.id ? (
                           <motion.div 
                             key="reply-form"
                             className="reply-form"
                             initial={{ opacity: 0, height: 0 }}
                             animate={{ opacity: 1, height: 'auto' }}
                             exit={{ opacity: 0, height: 0 }}
                           >
                              <textarea 
                                 placeholder="Nhập nội dung phản hồi cho người dùng..." 
                                 value={replyText}
                                 onChange={(e) => setReplyText(e.target.value)}
                                 autoFocus
                              />
                              <div className="form-buttons">
                                 <motion.button 
                                   onClick={() => sendReply(item.id)} 
                                   className="send-btn btn-primary"
                                   whileHover={{ scale: 1.02 }}
                                   whileTap={{ scale: 0.98 }}
                                 >
                                    <Send size={16} />
                                    <span>Gửi</span>
                                 </motion.button>
                                 <button onClick={() => setReplyingTo(null)} className="cancel-btn">Hủy</button>
                              </div>
                           </motion.div>
                        ) : (
                           <motion.div 
                             key="action-row"
                             className="action-row"
                             initial={{ opacity: 0 }}
                             animate={{ opacity: 1 }}
                             exit={{ opacity: 0 }}
                           >
                              <button onClick={() => setReplyingTo(item.id)} className="reply-btn">
                                 <MessageSquare size={16} />
                                 <span>Trả lời</span>
                              </button>
                              <button onClick={() => deleteFeedback(item.id)} className="delete-btn action-btn">
                                 <Trash2 size={16} />
                              </button>
                           </motion.div>
                        )}
                      </AnimatePresence>
                   </div>
                </motion.div>
             ))}
           </AnimatePresence>
        </motion.div>

        <style>{`
          .loading-state {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 16px;
            min-height: 400px;
            color: var(--text-dim);
          }

          .animate-spin { animation: spin 1s linear infinite; }
          @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }

          .feedback-page { display: flex; flex-direction: column; gap: 32px; }
          .feedback-list { display: flex; flex-direction: column; gap: 20px; }

          .feedback-item {
            padding: 24px;
            display: flex;
            flex-direction: column;
            gap: 16px;
            transition: var(--transition);
          }

          .feedback-item:hover { border-color: var(--primary); }

          .feedback-header { display: flex; justify-content: space-between; align-items: center; }
          .user-info { display: flex; align-items: center; gap: 10px; }

          .avatar-small {
             width: 24px; height: 24px; border-radius: 50%; background: var(--bg-accent);
             display: flex; align-items: center; justify-content: center; color: var(--text-dim);
          }

          .user-name { font-weight: 600; font-size: 14px; }
          .dot { width: 3px; height: 3px; border-radius: 50%; background: var(--text-dim); opacity: 0.5; }
          .date { font-size: 12px; color: var(--text-dim); }

          .status-tag {
             padding: 4px 10px; border-radius: 4px; font-size: 11px; font-weight: 700;
             display: flex; align-items: center; gap: 6px; text-transform: uppercase;
          }

          .status-tag.pending { background: rgba(212, 175, 55, 0.1); color: var(--primary); }
          .status-tag.replied { background: rgba(63, 185, 80, 0.1); color: var(--success); }
          .status-tag.escalated { background: rgba(248, 81, 73, 0.1); color: var(--danger); }

          .rating-row { display: flex; gap: 4px; }
          .star { color: var(--border); }
          .star.filled { color: var(--primary); fill: var(--primary); }

          .comment-text { font-size: 15px; font-style: italic; color: var(--text-main); padding: 0 4px; }

          .feedback-actions { padding-top: 8px; border-top: 1px solid var(--border); }
          .action-row { display: flex; align-items: center; justify-content: space-between; }
          .reply-btn { 
            display: flex; align-items: center; gap: 10px; color: var(--primary); 
            font-weight: 600; font-size: 13px; border: none; background: transparent; cursor: pointer; 
          }

          .action-btn { border: none; background: transparent; cursor: pointer; color: var(--text-dim); padding: 8px; border-radius: var(--radius-sm); }
          .action-btn:hover { background: var(--bg-accent); color: var(--text-main); }
          .delete-btn:hover { color: var(--danger); }

          .reply-form { display: flex; flex-direction: column; gap: 12px; overflow: hidden; }
          .reply-form textarea {
             background: var(--bg-accent); border: 1px solid var(--border);
             border-radius: var(--radius-md); color: var(--text-main);
             padding: 12px; font-size: 14px; min-height: 80px; resize: vertical;
          }

          .form-buttons { display: flex; gap: 16px; align-items: center; }
          .send-btn { padding: 10px 20px; border: none; cursor: pointer; display: flex; align-items: center; gap: 8px; }
          .cancel-btn { font-size: 13px; color: var(--text-dim); font-weight: 600; border: none; background: transparent; cursor: pointer; }
        `}</style>
      </div>
    </PageTransition>
  );
};
