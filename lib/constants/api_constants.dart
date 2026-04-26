class ApiConstants {
  // SePay API Configuration
  // Use --dart-define-from-file=secrets.json to provide these values
  static const String sepayApiToken = String.fromEnvironment('SEPAY_API_TOKEN');
  static const String sepayBaseUrl = 'https://my.sepay.vn';

  // SePay Webhook Configuration
  static const String sepayWebhookKey = String.fromEnvironment('SEPAY_WEBHOOK_KEY');
  static const String vercelBaseUrl = 'https://chitieu-plus.vercel.app';

  // API Endpoints (Now via Vercel Proxy for security)
  static const String sepayTransactionsUrl = '$vercelBaseUrl/api/sepay-proxy?endpoint=transactions';
  static const String sepayBankAccountsUrl = '$vercelBaseUrl/api/sepay-proxy?endpoint=bank-accounts';
  static const String sepayWebhookUrl = '$vercelBaseUrl/api/sepay-webhook';
}
