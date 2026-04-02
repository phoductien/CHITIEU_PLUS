const { GoogleGenerativeAI } = require("@google/generative-ai");

// Mapping of Version + Tier to Model ID (matches Dart implementation)
const modelMap = {
  '2.5': {
    'Nhanh': 'gemini-2.5-flash-lite',
    'Tư duy': 'gemini-2.5-flash',
    'Pro': 'gemini-2.5-pro',
  },
  '3.0': {
    'Nhanh': 'gemini-3.1-flash-lite-preview',
    'Tư duy': 'gemini-3-flash-preview',
    'Pro': 'gemini-3.1-pro-preview',
  }
};

const SYSTEM_INSTRUCTION = `
Bạn là một trợ lý quản lý tài chính thông minh của ứng dụng ChiTieuPlus.

KIẾN THỨC & TƯ DUY:
- Ngoài các logic nghiệp vụ dưới đây, bạn được khuyến khích sử dụng kho kiến thức rộng lớn của mình (World Knowledge) để hỗ trợ người dùng đa dạng các chủ đề.
- Đặc tính phản hồi dựa trên phân tầng model:
    1. Gemini Flash (Nhanh): Tập trung vào tốc độ phản hồi cực nhanh và hiệu suất xử lý khối lượng lớn dữ liệu, trả lời gần như tức thì.
    2. Gemini Thinking (Tư duy): Sử dụng suy luận logic sâu sắc, phân tích vấn đề theo hướng trình bày từng bước (Chain-of-Thought).
    3. Gemini Pro (Nâng cao): Sự cân bằng hoàn hảo giữa sự thông minh vượt trội và tốc độ xử lý nhanh.

LOGIC TÀI CHÍNH QUAN TRỌNG:
- Mọi giao dịch người dùng nhập (ví dụ: "Ăn sáng 20k") đều được coi là Chi tiêu (expense).
- Thu nhập (income) được hiểu là số tiền còn lại trong ví sau khi đã trừ các khoản chi tiêu.
- Nếu số dư trong ví nhỏ hơn 0 (âm), đó là Khoản nợ.
- Nếu số dư chuyển từ trạng thái âm sang dương, phần chênh lệch đó được tính là Thu nhập.

QUY TẮC CỐ ĐỊNH:
1. Luôn phản hồi JSON.
2. Cấu trúc JSON bắt buộc:
{
  "message": "Lời nhắn tự nhiên",
  "transaction": {
    "title": "Tiêu đề",
    "amount": 20000,
    "category": "Ăn uống|Mua sắm|Di chuyển|Nhà cửa|Học phí|Bảo hiểm|Tiền điện|Tiền nước|Tiền Gas|Nạp điện thoại|Giải trí|Lương|Khác",
    "date": "2024-05-13T14:30:00",
    "type": "expense",
    "note": "Ghi chú",
    "wallet": "main"
  }
} (transaction để null nếu chỉ câu hỏi đáp/phân tích. Trong đó date là ngày giờ trên hóa đơn theo chuẩn ISO8601 YYYY-MM-DDTHH:mm:ss, nếu chỉ có ngày thì để YYYY-MM-DD, nếu không thấy để rỗng).
4. Luôn ưu tiên độ chính xác số tiền (k=1000, tr=1tr).
5. Phân loại chuẩn xác: Hãy phân loại theo nhóm category gần nhất, nếu không khớp nhóm nào thì trả về "Khác".
6. Ngôn ngữ: Tiếng Việt.
`;

module.exports = async function (req, res) {
  // Allow explicitly CORS for easy testing
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error("GEMINI_API_KEY is not configured on Vercel");
      return res.status(500).json({ error: 'Server incorrectly configured. Missing API Key.' });
    }

    const ai = new GoogleGenerativeAI(apiKey);
    const body = req.body || {};

    // Feature requested: title, category or chat
    const {
      type = 'chat', // 'chat', 'title', 'category'
      message = '',
      history = [],
      attachments = [],
      contextStrings = [],
      version = '3.0',
      tier = 'Tư duy'
    } = body;

    const modelName = (modelMap[version] && modelMap[version][tier]) ? modelMap[version][tier] : 'gemini-3-flash';

    if (type === 'title') {
      const model = ai.getGenerativeModel({ model: "gemini-3-flash" }); // Utility model
      const prompt = `Tạo tiêu đề ngắn (<4 từ) cho: '${message}'. Chỉ trả về tiêu đề.`;
      const result = await model.generateContent(prompt);
      let text = result.response.text();
      text = text.replace(/"/g, '').trim();
      return res.status(200).json({ result: text });
    }

    if (type === 'category') {
      const model = ai.getGenerativeModel({ model: "gemini-3-flash" }); // Utility model
      const prompt = `Phân loại vào: 'Tài chính', 'Mua sắm', 'Hỏi đáp', 'Phân tích', 'Công việc', 'Giải trí', 'Học tập', 'Khác'. Chỉ trả về 1 tên. Input: '${message}'`;
      const result = await model.generateContent(prompt);
      let text = result.response.text();
      text = text.replace(/"/g, '').trim();
      return res.status(200).json({ result: text });
    }

    // Default chat behavior
    const model = ai.getGenerativeModel({
      model: modelName,
      systemInstruction: SYSTEM_INSTRUCTION,
      generationConfig: {
        temperature: 0.4,
        responseMimeType: 'application/json',
      }
    });

    // Formatting history to Google SDK format if provided
    const chatHistory = history.map(msg => ({
      role: msg.role === 'ai' ? 'model' : 'user', // Vercel SDK requires 'model'/'user' matching
      parts: [{ text: msg.text }]
    }));

    const chat = model.startChat({
      history: chatHistory,
    });

    const parts = [];

    // Add Context Strings
    if (contextStrings && contextStrings.length > 0) {
      const filteredContext = contextStrings.length > 5 ? contextStrings.slice(-5) : contextStrings;
      for (const ctx of filteredContext) {
        parts.push({ text: `--- Ngữ cảnh ---\n${ctx}\n` });
      }
    }

    // Add main message
    parts.push({ text: message });

    // Add attachments
    if (attachments && attachments.length > 0) {
      for (const att of attachments) {
        if (att.base64 && att.mimeType) {
          parts.push({
            inlineData: {
              data: att.base64,
              mimeType: att.mimeType,
            }
          });
        }
      }
    }

    const response = await chat.sendMessage(parts);
    const responseText = response.response.text();

    return res.status(200).json({ response: responseText });

  } catch (error) {
    console.error("Gemini API Error:", error);
    if (error.message && error.message.includes('Quota exceeded')) {
      return res.status(429).json({ error: 'LIMIT_EXCEEDED' });
    }
    return res.status(500).json({ error: error.message || 'Internal Server Error' });
  }
};
