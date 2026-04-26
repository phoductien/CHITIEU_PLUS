export default async function handler(req, res) {
  // 1. Get endpoint and params from query
  const { endpoint, ...otherParams } = req.query;
  const apiToken = process.env.SEPAY_API_TOKEN;

  // 2. Check token
  if (!apiToken) {
    return res.status(500).json({ 
      error: 'SEPAY_API_TOKEN is not configured in Vercel Environment Variables.' 
    });
  }

  // 3. Map allowed endpoints
  const endpointMap = {
    'transactions': 'https://my.sepay.vn/api/transactions/list',
    'bank-accounts': 'https://my.sepay.vn/api/bank-accounts/list',
  };

  let targetUrl = endpointMap[endpoint];

  if (!targetUrl) {
    return res.status(400).json({ error: 'Invalid or missing endpoint parameter.' });
  }

  // 4. Forward query parameters (limit, account_number, etc.)
  const queryString = new URLSearchParams(otherParams).toString();
  if (queryString) {
    targetUrl += `?${queryString}`;
  }

  try {
    // 5. Fetch from SePay with the secret Token
    const response = await fetch(targetUrl, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${apiToken}`,
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    // 6. Return data to Flutter app
    return res.status(response.status).json(data);
  } catch (error) {
    console.error('SePay Proxy Error:', error);
    return res.status(500).json({ error: 'Internal Server Error when contacting SePay.' });
  }
}
