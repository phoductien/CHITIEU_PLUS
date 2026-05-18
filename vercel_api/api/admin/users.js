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

  try {
    // Lấy danh sách users
    if (req.method === 'GET') {
      const usersSnap = await db.collection('users').get();
      const usersData = [];
      usersSnap.forEach(doc => {
        const data = doc.data();
        usersData.push({
          uid: doc.id,
          ...data,
          status: data.isLocked ? 'Locked' : 'Active',
          lastLogin: data.lastLogin ? data.lastLogin.toDate().toISOString() : null
        });
      });

      // Đếm số lượng request AI từ bảng transactions
      const transSnap = await db.collection('transactions').get();
      const transactions = [];
      transSnap.forEach(doc => transactions.push(doc.data()));

      const usersWithUsage = usersData.map(user => {
        const usage = transactions.filter(t => t.userId === user.uid && t.aiMetadata != null).length;
        return { ...user, requests: usage };
      });

      return res.status(200).json({ success: true, users: usersWithUsage });
    }

    // Cập nhật trạng thái user (khóa/mở khóa)
    if (req.method === 'PUT') {
      const { uid, isLocked } = req.body;
      if (!uid) return res.status(400).json({ error: 'Missing user ID' });

      await db.collection('users').doc(uid).update({ isLocked });

      return res.status(200).json({ success: true, message: `Updated user ${uid}` });
    }

    return res.status(405).json({ error: 'Method Not Allowed' });
  } catch (error) {
    console.error('API Error:', error);
    return res.status(500).json({ error: 'Internal Server Error', details: error.message });
  }
};
