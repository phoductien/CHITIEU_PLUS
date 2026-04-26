const admin = require('firebase-admin');

// --- KHỞI TẠO FIREBASE ADMIN ---
// Sử dụng Service Account để có quyền ghi dữ liệu vào Firestore và Realtime Database
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
const rtdb = admin.database();

module.exports = async (req, res) => {
  // Chỉ chấp nhận các yêu cầu POST từ SePay
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Phương thức không được hỗ trợ' });
  }

  // Lấy các tham số từ URL: /api/sepay-webhook?userId=xxx&key=yyy
  const { userId, key, isGuest } = req.query;

  // --- KIỂM TRA BẢO MẬT ---
  // So sánh mã key trong URL với mã bí mật SEPAY_WEBHOOK_KEY cấu hình trên Vercel
  if (key !== process.env.SEPAY_WEBHOOK_KEY) {
    console.error('Truy cập trái phép, sai mã bảo mật:', key);
    return res.status(401).json({ error: 'Không có quyền truy cập' });
  }

  // Kiểm tra xem có userId (người dùng nào) trong link không
  if (!userId) {
    return res.status(400).json({ error: 'Thiếu ID người dùng (userId)' });
  }

  try {
    const payload = req.body;
    console.log('Đã nhận dữ liệu từ SePay:', JSON.stringify(payload));

    // --- TRÍCH XUẤT DỮ LIỆU TỪ SEPAY ---
    // Hỗ trợ cả snake_case và camelCase từ các phiên bản SePay khác nhau
    const sepayId = payload.id || payload.transaction_id || payload.transactionId;
    const content = payload.content || payload.transaction_content || payload.transactionContent || 'Giao dịch ngân hàng';
    
    // Thử lấy số tiền từ nhiều trường khác nhau (SePay có thể gửi amount_in/out hoặc transferAmount)
    const amountIn = parseFloat(payload.amount_in || payload.amountIn || 0);
    const amountOut = parseFloat(payload.amount_out || payload.amountOut || 0);
    const transferAmount = parseFloat(payload.transfer_amount || payload.transferAmount || payload.amount || 0);
    
    let amount = 0;
    let type = 'expense';
    
    if (amountIn > 0) {
      amount = amountIn;
      type = 'income';
    } else if (amountOut > 0) {
      amount = amountOut;
      type = 'expense';
    } else if (transferAmount > 0) {
      amount = transferAmount;
      // Nếu dùng transfer_amount, cần dựa vào transfer_type hoặc logic tiền vào/ra
      const tType = (payload.transfer_type || payload.transferType || '').toLowerCase();
      type = (tType === 'in' || tType === 'income') ? 'income' : 'expense';
    }

    // Nếu số tiền bằng 0 thì bỏ qua không lưu
    if (amount === 0) {
      return res.status(200).json({ 
        success: true, 
        message: 'Giao dịch 0đ hoặc không xác định được số tiền',
        received_payload: payload // Trả về payload để debug nếu cần
      });
    }

    // --- XỬ LÝ THỜI GIAN ---
    let date = new Date();
    const dateStr = payload.transaction_date || payload.transactionDate || payload.createdAt;
    if (dateStr) {
      date = new Date(dateStr);
    }

    // Tạo ID duy nhất cho giao dịch
    const transactionId = `sepay_${sepayId}`;
    const userPath = isGuest === 'true' ? 'guests' : 'users';

    // --- CHUẨN BỊ DỮ LIỆU ĐỂ LƯU ---
    // Cấu trúc này phải khớp hoàn toàn với TransactionModel trong Flutter
    const firestoreData = {
      userId: userId,
      title: content,
      amount: amount,
      category: 'Ngân hàng',
      date: admin.firestore.Timestamp.fromDate(date),
      type: type,
      note: `Đồng bộ tự động từ SePay (${payload.bank_brand_name || 'Ngân hàng'})\nID: ${sepayId}`,
      wallet: 'main',
      isPinned: false,
      aiMetadata: {
        source: 'sepay_webhook',
        bank_brand_name: payload.bank_brand_name || payload.bankBrandName || 'Ngân hàng',
        account_number: payload.account_number || payload.accountNumber || ''
      }
    };

    // --- GHI DỮ LIỆU VÀO FIRESTORE ---
    const transactionDoc = db.collection(userPath).doc(userId).collection('transactions').doc(transactionId);
    await transactionDoc.set(firestoreData);

    // --- GHI DỮ LIỆU VÀO REALTIME DATABASE ---
    // RTDB cần format date là string để App Flutter parse được
    const rtdbData = {
      ...firestoreData,
      id: transactionId,
      date: date.toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // Ghi vào RTDB để App nhận được thông báo ngay lập tức
    const rtdbPath = `${userPath}/${userId}/transactions/${transactionId}`;
    await rtdb.ref(rtdbPath).set(rtdbData);

    console.log(`Đã ghi vào Firestore và RTDB thành công: ${rtdbPath} (${amount}đ)`);
    return res.status(200).json({ 
      success: true, 
      message: 'Giao dịch đã được ghi nhận',
      transactionId,
      amount,
      path: rtdbPath
    });

  } catch (error) {
    console.error('Lỗi xử lý Webhook:', error);
    return res.status(500).json({ error: 'Lỗi máy chủ', details: error.message });
  }
};
