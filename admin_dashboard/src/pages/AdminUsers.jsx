import { useState, useEffect } from 'react';
import { 
  Search, UserX, UserCheck, MoreVertical, Mail, 
  Calendar, ShieldAlert, Loader2, X, Phone, 
  User, CreditCard, PieChart, Activity 
} from 'lucide-react';
import { collection, getDocs, doc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { motion, AnimatePresence } from 'framer-motion';
import { PageTransition } from '../components/PageTransition';

const rowVariants = {
  hidden: { opacity: 0, x: -10 },
  show: { opacity: 1, x: 0 },
  exit: { opacity: 0, x: 10 }
};

const modalVariants = {
  hidden: { opacity: 0, scale: 0.95 },
  visible: { opacity: 1, scale: 1 },
  exit: { opacity: 0, scale: 0.95 }
};

export const AdminUsers = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        setLoading(true);
        const usersSnap = await getDocs(collection(db, 'users'));
        const usersData = usersSnap.docs.map(doc => ({ 
          uid: doc.id, 
          ...doc.data(),
          status: doc.data().isLocked ? 'Locked' : 'Active'
        }));

        // Fetch transactions to count usage
        const transSnap = await getDocs(collection(db, 'transactions'));
        const transactions = transSnap.docs.map(d => d.data());

        const usersWithUsage = usersData.map(user => {
           const usage = transactions.filter(t => t.userId === user.uid && t.aiMetadata != null).length;
           return { ...user, requests: usage };
        });

        setUsers(usersWithUsage);
        setLoading(false);
      } catch (error) {
        console.error("Error fetching users:", error);
        setLoading(false);
      }
    };

    fetchUsers();
  }, []);

  const toggleStatus = async (e, uid, currentStatus) => {
    e.stopPropagation();
    try {
      const isLocked = currentStatus === 'Active';
      await updateDoc(doc(db, 'users', uid), { isLocked });
      
      setUsers(users.map(u => 
        u.uid === uid ? { ...u, status: isLocked ? 'Locked' : 'Active' } : u
      ));
      if (selectedUser && selectedUser.uid === uid) {
        setSelectedUser({ ...selectedUser, status: isLocked ? 'Locked' : 'Active' });
      }
    } catch (error) {
      console.error("Error updating user status:", error);
    }
  };

  const filteredUsers = users.filter(u => 
    (u.name || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
    (u.email || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
    (u.phone || '').includes(searchTerm)
  );

  if (loading) {
     return (
       <div className="loading-state">
         <Loader2 className="animate-spin" size={48} color="var(--primary)" />
         <p>Đang tải danh sách người dùng...</p>
       </div>
     );
  }

  return (
    <PageTransition>
      <div className="users-page">
        <div className="page-header">
           <div className="page-title">
              <motion.h1 initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
                Quản lý người dùng
              </motion.h1>
              <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.1 }}>
                Tổng cộng {users.length} tài khoản đang truy cập hệ thống.
              </motion.p>
           </div>
           
           <motion.div 
             className="search-bar glass-card"
             initial={{ opacity: 0, x: 20 }}
             animate={{ opacity: 1, x: 0 }}
           >
              <Search size={18} className="icon" />
              <input 
                 type="text" 
                 placeholder="Tìm theo tên, email hoặc SĐT..." 
                 value={searchTerm}
                 onChange={(e) => setSearchTerm(e.target.value)}
              />
           </motion.div>
        </div>

        <motion.div 
          className="table-container glass-card"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
           <table className="admin-table">
              <thead>
                 <tr>
                    <th>Người dùng</th>
                    <th>Hạng</th>
                    <th>Số dư</th>
                    <th>Trạng thái</th>
                    <th>Hoạt động cuối</th>
                    <th>Thao tác</th>
                 </tr>
              </thead>
              <motion.tbody
                initial="hidden"
                animate="show"
                variants={{ show: { transition: { staggerChildren: 0.05 } } }}
              >
                 <AnimatePresence mode="popLayout">
                   {filteredUsers.map((user) => (
                      <motion.tr 
                        key={user.uid} 
                        layout
                        variants={rowVariants}
                        className={`${user.status === 'Locked' ? 'locked-row' : ''} interactive-row`}
                        onClick={() => setSelectedUser(user)}
                      >
                         <td>
                            <div className="user-cell">
                               <div className="user-avatar">
                                  {user.photoUrl ? <img src={user.photoUrl} alt="" /> : (user.name || 'U').charAt(0)}
                               </div>
                               <div className="user-info">
                                  <span className="name">{user.name || 'Người dùng ẩn'}</span>
                                  <span className="email">{user.email || 'guest@chitieuplus.internal'}</span>
                               </div>
                            </div>
                         </td>
                         <td>
                            <span className={`type-badge ${user.isGuest ? 'guest' : 'registered'}`}>
                               {user.isGuest ? 'GUEST' : 'USER'}
                            </span>
                         </td>
                         <td>
                            <div className="budget-cell">
                               <span className="amount">{(user.totalBudget || 0).toLocaleString()}</span>
                               <span className="currency">{user.currency || 'VND'}</span>
                            </div>
                         </td>
                         <td>
                            <span className={`status-badge ${user.status.toLowerCase()}`}>
                               {user.status === 'Locked' && <ShieldAlert size={12} />}
                               {user.status}
                            </span>
                         </td>
                         <td>
                            <div className="date-cell">
                               <span className="date-text">
                                 {user.lastLogin?.toDate 
                                   ? user.lastLogin.toDate().toLocaleDateString('vi-VN') 
                                   : 'Chưa có dữ liệu'}
                               </span>
                            </div>
                         </td>
                         <td>
                            <div className="actions-cell">
                               {user.status === 'Active' ? (
                                  <button onClick={(e) => toggleStatus(e, user.uid, user.status)} className="action-btn lock" title="Khóa tài khoản">
                                     <UserX size={18} />
                                  </button>
                               ) : (
                                  <button onClick={(e) => toggleStatus(e, user.uid, user.status)} className="action-btn unlock" title="Mở khóa tài khoản">
                                     <UserCheck size={18} />
                                  </button>
                               )}
                            </div>
                         </td>
                      </motion.tr>
                   ))}
                 </AnimatePresence>
              </motion.tbody>
           </table>
        </motion.div>

        <AnimatePresence>
          {selectedUser && (
            <div className="modal-overlay" onClick={() => setSelectedUser(null)}>
              <motion.div 
                className="user-modal glass-card"
                variants={modalVariants}
                initial="hidden"
                animate="visible"
                exit="exit"
                onClick={e => e.stopPropagation()}
              >
                <div className="modal-header">
                  <div className="user-header">
                    <div className="large-avatar">
                      {selectedUser.photoUrl ? <img src={selectedUser.photoUrl} alt="" /> : (selectedUser.name || 'U').charAt(0)}
                    </div>
                    <div className="header-info">
                      <h2>{selectedUser.name || 'Người dùng ẩn'}</h2>
                      <p>{selectedUser.email}</p>
                    </div>
                  </div>
                  <button className="close-btn" onClick={() => setSelectedUser(null)}>
                    <X size={20} />
                  </button>
                </div>

                <div className="modal-content">
                  <div className="info-section">
                    <h3>Thông tin chi tiết</h3>
                    <div className="info-grid">
                      <div className="info-item">
                        <User size={16} />
                        <div className="item-text">
                          <label>Giới tính</label>
                          <span>{selectedUser.gender || 'Chưa cập nhật'}</span>
                        </div>
                      </div>
                      <div className="info-item">
                        <Calendar size={16} />
                        <div className="item-text">
                          <label>Ngày sinh</label>
                          <span>{selectedUser.dob || 'Chưa cập nhật'}</span>
                        </div>
                      </div>
                      <div className="info-item">
                        <Phone size={16} />
                        <div className="item-text">
                          <label>Số điện thoại</label>
                          <span>{selectedUser.phone || 'Chưa cập nhật'}</span>
                        </div>
                      </div>
                      <div className="info-item">
                        <CreditCard size={16} />
                        <div className="item-text">
                          <label>Hạng tài khoản</label>
                          <span>{selectedUser.isGuest ? 'Khách viếng thăm' : 'Thành viên'}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="stats-section">
                    <h3>Thống kê hoạt động</h3>
                    <div className="stats-grid">
                      <div className="stat-box">
                        <Activity size={20} className="icon ai" />
                        <div className="stat-info">
                          <span className="value">{selectedUser.requests}</span>
                          <span className="label">AI Requests</span>
                        </div>
                      </div>
                      <div className="stat-box">
                        <PieChart size={20} className="icon budget" />
                        <div className="stat-info">
                          <span className="value">{selectedUser.totalBudget?.toLocaleString()}</span>
                          <span className="label">Ngân sách (VND)</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="modal-footer">
                  <button 
                    className={`btn-action ${selectedUser.status === 'Active' ? 'lock' : 'unlock'}`}
                    onClick={(e) => toggleStatus(e, selectedUser.uid, selectedUser.status)}
                  >
                    {selectedUser.status === 'Active' ? <UserX size={18} /> : <UserCheck size={18} />}
                    {selectedUser.status === 'Active' ? 'Khóa tài khoản' : 'Mở khóa'}
                  </button>
                  <button className="btn-secondary" onClick={() => setSelectedUser(null)}>Đóng</button>
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>

        <style>{`
          .users-page { display: flex; flex-direction: column; gap: 24px; padding-bottom: 40px; }
          .page-header { display: flex; justify-content: space-between; align-items: flex-start; }
          .page-title h1 { font-size: 28px; margin-bottom: 4px; }
          .page-title p { color: var(--text-dim); font-size: 14px; }

          .search-bar { width: 360px; padding: 0 16px; display: flex; align-items: center; gap: 12px; height: 44px; border-radius: 12px; }
          .search-bar .icon { color: var(--text-dim); }
          .search-bar input { background: transparent; border: none; color: var(--text-main); width: 100%; font-size: 14px; }
          .search-bar input:focus { outline: none; }

          .table-container { overflow-x: auto; padding: 8px; border-radius: 16px; }
          .admin-table { width: 100%; border-collapse: collapse; text-align: left; }
          .admin-table th { 
            padding: 16px 20px; font-size: 11px; text-transform: uppercase; 
            color: var(--text-dim); font-weight: 700; letter-spacing: 1px; 
            border-bottom: 1px solid var(--border); 
          }
          .admin-table td { 
            padding: 14px 20px; border-bottom: 1px solid rgba(48, 54, 61, 0.3); 
            font-size: 13px; transition: var(--transition); 
          }

          .interactive-row { cursor: pointer; }
          .interactive-row:hover td { background: rgba(56, 139, 253, 0.05); }

          .user-cell { display: flex; align-items: center; gap: 12px; }
          .user-avatar { 
            width: 32px; height: 32px; border-radius: 50%; background: var(--bg-accent); 
            display: flex; align-items: center; justify-content: center; 
            border: 1px solid var(--border); font-weight: 700; color: var(--primary);
            overflow: hidden; font-size: 12px;
          }
          .user-avatar img { width: 100%; height: 100%; object-fit: cover; }

          .user-info .name { display: block; font-weight: 600; color: var(--text-main); }
          .user-info .email { display: block; font-size: 11px; color: var(--text-dim); }

          .type-badge { padding: 2px 8px; border-radius: 4px; font-size: 10px; font-weight: 800; border: 1px solid currentColor; }
          .type-badge.guest { color: #8b949e; }
          .type-badge.registered { color: var(--primary); }

          .budget-cell { font-family: 'Space Grotesk', sans-serif; }
          .budget-cell .amount { font-weight: 700; margin-right: 4px; }
          .budget-cell .currency { font-size: 10px; color: var(--text-dim); }

          .status-badge { 
            padding: 4px 10px; border-radius: 20px; font-size: 10px; font-weight: 700; 
            text-transform: uppercase; display: flex; align-items: center; gap: 6px; width: fit-content; 
          }
          .status-badge.active { background: rgba(63, 185, 80, 0.1); color: var(--success); }
          .status-badge.locked { background: rgba(248, 81, 73, 0.1); color: var(--danger); }

          .date-text { color: var(--text-dim); font-size: 12px; }

          .actions-cell { display: flex; gap: 4px; }
          .action-btn { 
            padding: 6px; border-radius: 8px; color: var(--text-dim); transition: var(--transition); 
            border: none; background: transparent; cursor: pointer; 
          }
          .action-btn:hover { background: var(--bg-accent); color: var(--text-main); }

          .modal-overlay {
            position: fixed; top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.8); backdrop-filter: blur(8px);
            display: flex; align-items: center; justify-content: center; z-index: 1000;
          }
          .user-modal {
            width: 500px; padding: 32px; border-radius: 24px; position: relative;
            background: #0d1117; border: 1px solid var(--border);
          }
          .modal-header { display: flex; justify-content: space-between; margin-bottom: 32px; }
          .user-header { display: flex; gap: 20px; align-items: center; }
          .large-avatar {
            width: 64px; height: 64px; border-radius: 20px; background: var(--bg-accent);
            display: flex; align-items: center; justify-content: center;
            font-size: 24px; font-weight: 800; color: var(--primary); border: 1px solid var(--border);
          }
          .large-avatar img { width: 100%; height: 100%; object-fit: cover; border-radius: 18px; }
          .header-info h2 { font-size: 20px; line-height: 1.2; }
          .header-info p { color: var(--text-dim); font-size: 14px; }

          .close-btn { background: transparent; border: none; color: var(--text-dim); cursor: pointer; }

          .modal-content { display: flex; flex-direction: column; gap: 32px; }
          .info-section h3, .stats-section h3 { font-size: 14px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 16px; }
          .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
          .info-item { display: flex; gap: 12px; align-items: center; color: var(--text-dim); }
          .item-text label { display: block; font-size: 11px; color: var(--text-dim); }
          .item-text span { display: block; font-size: 14px; color: var(--text-main); font-weight: 500; }

          .stats-grid { display: flex; gap: 16px; }
          .stat-box {
            flex: 1; padding: 16px; background: rgba(255, 255, 255, 0.03); border: 1px solid var(--border); border-radius: 16px;
            display: flex; gap: 16px; align-items: center;
          }
          .stat-box .icon.ai { color: var(--indigo); }
          .stat-box .icon.budget { color: var(--primary); }
          .stat-info .value { display: block; font-size: 18px; font-weight: 800; font-family: 'Space Grotesk'; }
          .stat-info .label { font-size: 11px; color: var(--text-dim); }

          .modal-footer { display: flex; gap: 12px; margin-top: 40px; }
          .btn-action {
             flex: 1; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; gap: 10px;
             font-weight: 700; border: none; cursor: pointer; transition: var(--transition);
          }
          .btn-action.lock { background: rgba(248, 81, 73, 0.1); color: #f85149; }
          .btn-action.lock:hover { background: #f85149; color: white; }
          .btn-action.unlock { background: rgba(63, 185, 80, 0.1); color: #3fb950; }
          .btn-action.unlock:hover { background: #3fb950; color: white; }
          .btn-secondary { height: 48px; padding: 0 24px; border-radius: 12px; background: var(--bg-accent); border: 1px solid var(--border); color: var(--text-main); font-weight: 600; cursor: pointer; }

          .loading-state { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 16px; min-height: 400px; color: var(--text-dim); }
          .animate-spin { animation: spin 1s linear infinite; }
          @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
        `}</style>
      </div>
    </PageTransition>
  );
};
