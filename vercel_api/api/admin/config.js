const admin = require('firebase-admin');

// Initialize Firebase Admin
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
    // Lấy cấu hình hệ thống hiện tại
    if (req.method === 'GET') {
      const doc = await db.collection('admin').doc('config').get();
      if (!doc.exists) {
        return res.status(200).json({ 
          apiKey: '', 
          maintenanceMode: false, 
          ocrSensitivity: 85, 
          notification: '' 
        });
      }
      return res.status(200).json(doc.data());
    } 
    
    // Cập nhật cấu hình
    if (req.method === 'POST') {
      const { apiKey, maintenanceMode, ocrSensitivity, notification } = req.body;
      await db.collection('admin').doc('config').set({
        apiKey: apiKey || '',
        maintenanceMode: Boolean(maintenanceMode),
        ocrSensitivity: Number(ocrSensitivity) || 85,
        notification: notification || '',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      
      return res.status(200).json({ success: true, message: 'Cấu hình đã được lưu' });
    }

    return res.status(405).json({ error: 'Method Not Allowed' });
  } catch (error) {
    console.error('API Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};
