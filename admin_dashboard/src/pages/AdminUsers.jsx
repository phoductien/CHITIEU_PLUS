import { useState, useEffect } from 'react';
import { Search, UserX, UserCheck, MoreVertical, Mail, Calendar, ShieldAlert, Loader2 } from 'lucide-react';
import { collection, getDocs, doc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { motion, AnimatePresence } from 'framer-motion';
import { PageTransition } from '../components/PageTransition';

const rowVariants = {
  hidden: { opacity: 0, x: -10 },
  show: { opacity: 1, x: 0 },
  exit: { opacity: 0, x: 10 }
};

export const AdminUsers = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

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

  const toggleStatus = async (uid, currentStatus) => {
    try {
      const isLocked = currentStatus === 'Active';
      await updateDoc(doc(db, 'users', uid), { isLocked });
      
      setUsers(users.map(u => 
        u.uid === uid ? { ...u, status: isLocked ? 'Locked' : 'Active' } : u
      ));
    } catch (error) {
      console.error("Error updating user status:", error);
    }
  };

  const filteredUsers = users.filter(u => 
    (u.name || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
    (u.email || '').toLowerCase().includes(searchTerm.toLowerCase())
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
        <div className="page-title">
           <motion.h1
             initial={{ opacity: 0, y: -10 }}
             animate={{ opacity: 1, y: 0 }}
           >
             Quản lý người dùng
           </motion.h1>
           <motion.p
             initial={{ opacity: 0 }}
             animate={{ opacity: 1 }}
             transition={{ delay: 0.2 }}
           >
             Theo dõi và kiểm soát quyền truy cập của {users.length} người dùng hệ thống.
           </motion.p>
        </div>

        <motion.div 
          className="table-controls"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
        >
           <div className="search-bar glass-card">
              <Search size={18} className="icon" />
              <input 
                 type="text" 
                 placeholder="Tìm kiếm theo tên hoặc email..." 
                 value={searchTerm}
                 onChange={(e) => setSearchTerm(e.target.value)}
              />
           </div>
        </motion.div>

        <motion.div 
          className="table-container glass-card"
          initial={{ opacity: 0, scale: 0.98 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.4 }}
        >
           <table className="admin-table">
              <thead>
                 <tr>
                    <th>Người dùng</th>
                    <th>Trạng thái</th>
                    <th>Ngày hoạt động cuối</th>
                    <th>AI Usage</th>
                    <th>Thao tác</th>
                 </tr>
              </thead>
              <motion.tbody
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
                   {filteredUsers.map((user) => (
                      <motion.tr 
                        key={user.uid} 
                        layout
                        variants={rowVariants}
                        className={user.status === 'Locked' ? 'locked-row' : ''}
                      >
                         <td>
                            <div className="user-cell">
                               <div className="user-avatar">
                                  {user.photoUrl ? <img src={user.photoUrl} alt="" /> : (user.name || 'U').charAt(0)}
                               </div>
                               <div className="user-info">
                                  <span className="name">{user.name || 'N/A'}</span>
                                  <span className="email">{user.email || 'No email'}</span>
                               </div>
                            </div>
                         </td>
                         <td>
                            <span className={`status-badge ${user.status.toLowerCase()}`}>
                               {user.status === 'Locked' ? <ShieldAlert size={14} /> : null}
                               {user.status}
                            </span>
                         </td>
                         <td>
                            <div className="date-cell">
                               <Calendar size={14} />
                               <span>{user.lastLogin?.toDate ? user.lastLogin.toDate().toLocaleDateString('vi-VN') : 'N/A'}</span>
                            </div>
                         </td>
                         <td>
                            <span className="usage-text">{user.requests.toLocaleString()} requests</span>
                         </td>
                         <td>
                            <div className="actions-cell">
                               {user.status === 'Active' ? (
                                  <button onClick={() => toggleStatus(user.uid, user.status)} className="action-btn lock" title="Khóa tài khoản">
                                     <UserX size={18} />
                                  </button>
                               ) : (
                                  <button onClick={() => toggleStatus(user.uid, user.status)} className="action-btn unlock" title="Mở khóa tài khoản">
                                     <UserCheck size={18} />
                                  </button>
                               )}
                               <button className="action-btn more">
                                  <MoreVertical size={18} />
                               </button>
                            </div>
                         </td>
                      </motion.tr>
                   ))}
                 </AnimatePresence>
              </motion.tbody>
           </table>
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

          .users-page { display: flex; flex-direction: column; gap: 32px; }
          .page-title h1 { font-size: 28px; margin-bottom: 8px; }
          .page-title p { color: var(--text-dim); font-size: 14px; }

          .table-controls { display: flex; justify-content: space-between; align-items: center; }
          .search-bar { width: 400px; padding: 0 16px; display: flex; align-items: center; gap: 12px; height: 48px; }
          .search-bar .icon { color: var(--text-dim); }
          .search-bar input { background: transparent; border: none; color: var(--text-main); width: 100%; font-size: 14px; }
          .search-bar input:focus { outline: none; }

          .table-container { overflow: hidden; padding: 8px; }
          .admin-table { width: 100%; border-collapse: collapse; text-align: left; }
          .admin-table th { padding: 16px 20px; font-size: 12px; text-transform: uppercase; color: var(--text-dim); font-weight: 700; letter-spacing: 1px; border-bottom: 1px solid var(--border); }
          .admin-table td { padding: 16px 20px; border-bottom: 1px solid rgba(48, 54, 61, 0.5); font-size: 14px; transition: var(--transition); }

          .user-cell { display: flex; align-items: center; gap: 12px; }
          .user-avatar { 
            width: 36px; height: 36px; border-radius: 50%; background: var(--bg-accent); 
            display: flex; align-items: center; justify-content: center; 
            border: 1px solid var(--border); font-weight: 600; color: var(--primary);
            overflow: hidden;
          }
          .user-avatar img { width: 100%; height: 100%; object-fit: cover; }

          .user-info .name { display: block; font-weight: 600; }
          .user-info .email { display: block; font-size: 12px; color: var(--text-dim); }

          .status-badge { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; text-transform: uppercase; display: flex; align-items: center; gap: 6px; width: fit-content; }
          .status-badge.active { background: rgba(63, 185, 80, 0.1); color: var(--success); }
          .status-badge.locked { background: rgba(248, 81, 73, 0.1); color: var(--danger); }

          .date-cell { display: flex; align-items: center; gap: 8px; color: var(--text-dim); font-size: 13px; }
          .usage-text { font-family: 'Space Grotesk', sans-serif; font-weight: 500; }

          .actions-cell { display: flex; gap: 8px; }
          .action-btn { padding: 8px; border-radius: var(--radius-sm); color: var(--text-dim); transition: var(--transition); border: none; background: transparent; cursor: pointer; }
          .action-btn:hover { background: var(--bg-accent); color: var(--text-main); }
          .action-btn.lock:hover { color: var(--danger); }
          .action-btn.unlock:hover { color: var(--success); }

          .locked-row td { opacity: 0.7; }
          .locked-row .user-avatar { background: rgba(248, 81, 73, 0.05); }
        `}</style>
      </div>
    </PageTransition>
  );
};
