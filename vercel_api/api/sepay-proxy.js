let cachedToken = null;
let cachedTokenExpiry = 0;

/**
 * Thực hiện xác thực OAuth 2.0 với SePay Bank Hub bằng grant_type=client_credentials.
 * Token được lưu trữ tạm vào bộ nhớ cache của serverless function để tối ưu hóa hiệu năng.
 */
async function getAccessToken(clientId, clientSecret) {
  // Kiểm tra bộ nhớ đệm (nếu token vẫn hợp lệ)
  if (cachedToken && Date.now() < cachedTokenExpiry) {
    return cachedToken;
  }

  const response = await fetch('https://my.sepay.vn/oauth/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: clientId,
      client_secret: clientSecret,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Lỗi khi xác thực OAuth SePay: ${response.status} ${errText}`);
  }

  const data = await response.json();
  cachedToken = data.access_token;

  // Cache hết hạn sớm hơn 1 phút so với thời hạn gốc của hệ thống (ví dụ: 3600s = 1 giờ)
  const expiresIn = data.expires_in || 3600;
  cachedTokenExpiry = Date.now() + (expiresIn - 60) * 1000;

  return cachedToken;
}

export default async function handler(req, res) {
  // 1. Lấy endpoint và các query params (ví dụ: limit, account_number...)
  const { endpoint, ...otherParams } = req.query;

  // Đọc các biến môi trường từ Cấu hình Vercel Dashboard
  const apiToken = process.env.SEPAY_API_TOKEN;
  const clientId = process.env.SEPAY_CLIENT_ID;
  const clientSecret = process.env.SEPAY_CLIENT_SECRET;

  const isBankHub = clientId && clientSecret;

  // 2. Kiểm tra thông tin cấu hình bảo mật
  if (!apiToken && !isBankHub) {
    return res.status(500).json({ 
      error: 'Chưa cấu hình SEPAY_API_TOKEN hoặc bộ SEPAY_CLIENT_ID/SECRET trong Vercel Environment Variables.' 
    });
  }

  let targetUrl = '';
  let useAuthToken = '';

  if (isBankHub) {
    // --- Chế độ Ngân hàng Doanh nghiệp (Bank Hub) OAuth 2.0 ---
    try {
      useAuthToken = await getAccessToken(clientId, clientSecret);
    } catch (err) {
      console.error('Lỗi xác thực SePay Bank Hub:', err);
      return res.status(500).json({ error: 'Không thể kết nối xác thực với SePay Bank Hub OAuth.' });
    }

    // Map endpoint API v1 của Bank Hub
    const endpointMap = {
      'transactions': 'https://my.sepay.vn/api/v1/transactions',
      'bank-accounts': 'https://my.sepay.vn/api/v1/bank-accounts',
    };
    targetUrl = endpointMap[endpoint];
  } else {
    // --- Chế độ Cá nhân (API v2 mới) - Dùng Token tĩnh ---
    useAuthToken = apiToken;

    const endpointMap = {
      'transactions': 'https://userapi.sepay.vn/v2/transactions',
      'bank-accounts': 'https://userapi.sepay.vn/v2/bank-accounts',
    };
    targetUrl = endpointMap[endpoint];
  }

  if (!targetUrl) {
    return res.status(400).json({ error: 'Thiếu hoặc sai tham số endpoint yêu cầu.' });
  }

  // 3. Ghép nối query string của client
  const queryString = new URLSearchParams(otherParams).toString();
  if (queryString) {
    targetUrl += `?${queryString}`;
  }

  try {
    // 4. Thực hiện truy vấn bảo mật đến SePay API
    const response = await fetch(targetUrl, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${useAuthToken}`,
        'Content-Type': 'application/json',
      },
    });

    // Hỗ trợ xử lý an toàn lỗi dạng HTML / Không phải JSON từ API
    const contentType = response.headers.get('content-type') || '';
    let data;
    if (contentType.includes('application/json')) {
      data = await response.json();
    } else {
      const errText = await response.text();
      console.error('Lỗi SePay API (Không phải JSON):', response.status, errText);
      return res.status(response.status).json({
        error: `SePay API trả về mã lỗi HTTP ${response.status} hoặc nội dung không phải JSON.`,
        details: errText.substring(0, 200)
      });
    }

    // 5. Chuẩn hóa đầu ra (Data Transformation) cho Flutter App tương thích 100%
    // SePay API v2 và Bank Hub API đều trả về cấu trúc: { status: "success", data: [...] }
    // Chuyển về format cũ mà Flutter đang parse sẵn: { status: 200, transactions/bank_accounts: [...] }
    if (data.status === 'success' && Array.isArray(data.data)) {
      const transformed = {
        status: 200,
        error: null,
        messages: []
      };

      if (endpoint === 'transactions') {
        transformed.transactions = data.data;
      } else if (endpoint === 'bank-accounts') {
        // Ánh xạ thêm trường bank_brand_name từ bank_short_name cho tương thích client
        transformed.bank_accounts = data.data.map(acc => ({
          ...acc,
          bank_brand_name: acc.bank_brand_name || acc.bank_short_name || acc.bank_code || 'Ngân hàng'
        }));
      }

      return res.status(200).json(transformed);
    }

    // 6. Trả kết quả nguyên bản
    return res.status(response.status).json(data);
  } catch (error) {
    console.error('Lỗi hệ thống tại SePay Proxy:', error);
    return res.status(500).json({ error: 'Lỗi hệ thống máy chủ nội bộ khi kết nối đến SePay.' });
  }
}
