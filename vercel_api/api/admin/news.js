const admin = require('firebase-admin');

if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)),
      databaseURL: process.env.FIREBASE_DATABASE_URL
    });
  } catch (error) {
    console.error('Lỗi khởi tạo Firebase Admin:', error);
  }
}

const db = admin.firestore();

module.exports = async (req, res) => {
  // CORS setup
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { action } = req.query; // /api/admin/news?action=fetch hoặc action=approve

  try {
    // 1. Kích hoạt logic cào tin tức mới
    if (req.method === 'GET' && action === 'fetch') {
      // Mock logic: Ở đây sẽ gọi script cào dữ liệu thực tế
      // Sau đó lưu vào Firestore (collection 'news')
      
      // Giả lập lưu 1 tin tức mới vào DB
      const newNewsRef = db.collection('news').doc();
      await newNewsRef.set({
        title: 'Thị trường vừa ghi nhận biến động mới',
        source: 'Cào tự động',
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return res.status(200).json({ success: true, message: 'Đã cào dữ liệu tin tức mới thành công!' });
    }

    // 2. Duyệt tin tức
    if (req.method === 'POST' && action === 'approve') {
      const { id } = req.body;
      if (!id) return res.status(400).json({ error: 'Missing news ID' });
      
      // Cập nhật trạng thái tin tức thành 'approved' trên Firestore
      // await db.collection('news').doc(id).update({ status: 'approved' });
      
      return res.status(200).json({ success: true, message: `Đã duyệt tin tức ID: ${id}` });
    }

    return res.status(405).json({ error: 'Method Not Allowed or Invalid Action' });
  } catch (error) {
    console.error('API Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};
