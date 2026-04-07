import { useState, useEffect } from 'react';
import { Utensils, Car, ShoppingBag, Gamepad2, HeartPulse, GraduationCap, Plus, Edit2, Trash2, Save, X, Tag, Loader2 } from 'lucide-react';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../firebase';
import { motion, AnimatePresence } from 'framer-motion';
import { PageTransition } from '../components/PageTransition';

const iconMap = {
  'Ăn uống': Utensils,
  'Di chuyển': Car,
  'Mua sắm': ShoppingBag,
  'Giải trí': Gamepad2,
  'Sức khỏe': HeartPulse,
  'Giáo dục': GraduationCap,
};

const cardVariants = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0 },
};

export const AdminCategories = () => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState(null);
  const [tempName, setTempName] = useState('');

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        setLoading(true);
        const transSnap = await getDocs(collection(db, 'transactions'));
        const transactions = transSnap.docs.map(doc => doc.data());
        
        // Extract unique categories
        const uniqueCats = [...new Set(transactions.map(t => t.category))].filter(Boolean);
        
        const catData = uniqueCats.map((name, index) => ({
           id: index + 1,
           name: name,
           icon: iconMap[name] || Tag,
           color: ['#EC5B13', '#3B82F6', '#F59E0B', '#8B5CF6', '#10B981', '#6366F1'][index % 6],
           type: transactions.find(t => t.category === name)?.type || 'Expense'
        }));

        setCategories(catData);
        setLoading(false);
      } catch (error) {
        console.error("Error fetching categories:", error);
        setLoading(false);
      }
    };

    fetchCategories();
  }, []);

  const startEdit = (cat) => {
    setEditingId(cat.id);
    setTempName(cat.name);
  };

  const saveEdit = (id) => {
    // In a real app, you'd update a 'categories' collection or all transactions with this category
    setCategories(categories.map(c => c.id === id ? { ...c, name: tempName } : c));
    setEditingId(null);
  };

  if (loading) {
     return (
       <div className="loading-state">
         <Loader2 className="animate-spin" size={48} color="var(--primary)" />
         <p>Đang phân tích danh mục từ dữ liệu...</p>
       </div>
     );
  }

  return (
    <PageTransition>
      <div className="categories-page">
        <div className="page-header-row">
           <div className="page-title">
              <motion.h1 initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>Quản lý danh mục</motion.h1>
              <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.2 }}>Phát hiện {categories.length} danh mục đang được sử dụng trong hệ thống.</motion.p>
           </div>
           <motion.button 
             className="add-btn btn-primary"
             whileHover={{ scale: 1.05 }}
             whileTap={{ scale: 0.95 }}
           >
              <Plus size={20} />
              <span>Thêm danh mục</span>
           </motion.button>
        </div>

        <motion.div 
          className="categories-grid"
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
             {categories.map((cat) => (
                <motion.div 
                  key={cat.id} 
                  layout
                  variants={cardVariants}
                  className="category-card glass-card"
                >
                   <div className="cat-icon" style={{ background: `${cat.color}20`, color: cat.color }}>
                      <cat.icon size={28} />
                   </div>
                   
                   <div className="cat-details">
                      {editingId === cat.id ? (
                         <div className="edit-mode">
                            <input 
                               type="text" 
                               value={tempName} 
                               onChange={(e) => setTempName(e.target.value)}
                               autoFocus 
                            />
                            <div className="edit-actions">
                               <button onClick={() => saveEdit(cat.id)} className="save-btn"><Save size={16} /></button>
                               <button onClick={() => setEditingId(null)} className="cancel-btn"><X size={16} /></button>
                            </div>
                         </div>
                      ) : (
                         <div className="view-mode">
                            <span className="cat-name">{cat.name}</span>
                            <span className="cat-type">{cat.type === 'expense' ? 'Chi tiêu' : 'Thu nhập'}</span>
                         </div>
                      )}
                   </div>

                   <div className="card-actions">
                      <button onClick={() => startEdit(cat)} className="cat-action edit"><Edit2 size={16} /></button>
                      <button className="cat-action delete"><Trash2 size={16} /></button>
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

          .categories-page { display: flex; flex-direction: column; gap: 32px; }
          .page-header-row { display: flex; justify-content: space-between; align-items: center; }
          .add-btn { display: flex; align-items: center; gap: 10px; border: none; cursor: pointer; }
          .categories-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }

          .category-card {
             padding: 24px;
             display: flex;
             align-items: center;
             gap: 20px;
             position: relative;
             transition: var(--transition);
          }

          .category-card:hover { border-color: var(--primary); transform: translateY(-2px); }

          .cat-icon {
             width: 56px; height: 56px; border-radius: 14px;
             display: flex; align-items: center; justify-content: center; flex-shrink: 0;
          }

          .cat-details { flex: 1; min-width: 0; }
          .view-mode .cat-name { display: block; font-weight: 700; font-size: 18px; margin-bottom: 2px; }
          .view-mode .cat-type { display: block; font-size: 12px; color: var(--text-dim); text-transform: uppercase; font-weight: 600; }

          .edit-mode { display: flex; flex-direction: column; gap: 8px; }
          .edit-mode input {
             background: var(--bg-accent); border: 1px solid var(--primary);
             border-radius: var(--radius-sm); color: var(--text-main);
             padding: 6px 10px; font-size: 16px; width: 100%;
          }

          .edit-actions { display: flex; gap: 8px; }
          .edit-actions button { padding: 4px; border-radius: 4px; border: none; cursor: pointer; }
          .save-btn { color: var(--success); background: rgba(63, 185, 80, 0.1); }
          .cancel-btn { color: var(--danger); background: rgba(248, 81, 73, 0.1); }

          .card-actions { position: absolute; top: 12px; right: 12px; display: flex; gap: 4px; opacity: 0; transition: var(--transition); }
          .category-card:hover .card-actions { opacity: 1; }

          .cat-action { padding: 6px; border-radius: var(--radius-sm); color: var(--text-dim); border: none; background: transparent; cursor: pointer; }
          .cat-action:hover { background: var(--bg-accent); color: var(--text-main); }
          .cat-action.delete:hover { color: var(--danger); }
        `}</style>
      </div>
    </PageTransition>
  );
};
