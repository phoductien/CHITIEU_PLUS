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
    // SePay gửi các trường: id (mã giao dịch), content (nội dung), amount_in (tiền vào), amount_out (tiền ra)...
    const sepayId = payload.id;
    const content = payload.content || 'Giao dịch ngân hàng';
    const amountIn = parseFloat(payload.amount_in || 0);
    const amountOut = parseFloat(payload.amount_out || 0);
    
    let amount = 0;
    let type = 'expense'; // Mặc định là chi tiêu
    
    if (amountIn > 0) {
      amount = amountIn;
      type = 'income'; // Nếu có tiền vào -> Thu nhập
    } else if (amountOut > 0) {
      amount = amountOut;
      type = 'expense'; // Nếu có tiền ra -> Chi tiêu
    } else {
      // Trường hợp SePay dùng format khác (transfer_amount)
      amount = parseFloat(payload.transfer_amount || 0);
      type = payload.transfer_type === 'in' ? 'income' : 'expense';
    }

    // Nếu số tiền bằng 0 thì bỏ qua không lưu
    if (amount === 0) {
      return res.status(200).json({ success: true, message: 'Giao dịch 0đ, không xử lý' });
    }

    // --- XỬ LÝ THỜI GIAN ---
    let date = new Date();
    if (payload.transaction_date) {
      date = new Date(payload.transaction_date);
    }

    // Tạo ID duy nhất cho giao dịch để tránh lưu trùng lặp nếu SePay gửi lại
    const transactionId = `sepay_${sepayId}`;
    const userPath = isGuest === 'true' ? 'guests' : 'users';

    // --- CHUẨN BỊ DỮ LIỆU ĐỂ LƯU ---
    // Cấu trúc này phải khớp với TransactionModel trong Flutter
    const firestoreData = {
      userId: userId,
      title: content,
      amount: amount,
      category: 'Tự động', // Phân loại mặc định khi nhận từ ngân hàng
      date: admin.firestore.Timestamp.fromDate(date), // Firestore dùng Timestamp
      type: type,
      note: `Đồng bộ tự động từ SePay (${payload.bank_brand_name || 'Ngân hàng'})\nID: ${sepayId}`,
      wallet: 'main',
      isPinned: false,
      aiMetadata: {
        source: 'sepay_webhook',
        bank: payload.bank_brand_name,
        account: payload.account_number
      }
    };

    // --- GHI DỮ LIỆU VÀO FIRESTORE ---
    // Lưu vào collection của người dùng cụ thể
    const transactionDoc = db.collection(userPath).doc(userId).collection('transactions').doc(transactionId);
    await transactionDoc.set(firestoreData);

    // --- GHI DỮ LIỆU VÀO REALTIME DATABASE ---
    // Bước này cực kỳ quan trọng để App nhận được thông báo thay đổi và cập nhật UI ngay lập tức
    const rtdbData = {
      ...firestoreData,
      date: date.toISOString() // RTDB trong App Flutter đang dùng định dạng ISO8601
    };
    await rtdb.ref(`${userPath}/${userId}/transactions/${transactionId}`).set(rtdbData);

    console.log(`Đã xử lý thành công giao dịch ${transactionId} cho người dùng ${userId}`);
    return res.status(200).json({ 
      success: true, 
      transactionId,
      type,
      amount
    });

  } catch (error) {
    console.error('Lỗi xử lý Webhook:', error);
    return res.status(500).json({ error: 'Lỗi máy chủ', details: error.message });
  }
};
