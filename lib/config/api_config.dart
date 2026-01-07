class ApiConfig {
  static const String baseUrl = "http://10.223.143.201:8000";

  // Parts
  static const String registerPart = "/api/parts/register";
  static const String getParts = "/api/parts";

  // Blockchain
  static const String blockchainRegister = "/api/blockchain/register";
  static const String verifyQr = "/api/blockchain/verify-qr";

  // Transfer
  static const String transferRequest = "/api/transfer/request";
  static const String pendingTransfers = "/api/transfer/pending/";
  static const String approveTransfer = "/api/transfer/approve";
}
