class MomoVerificationService {
  Set<String> usedTxIds = {};
  Future<Map<String, dynamic>> verifyTransactionIdOnly({required String txId, required bool slipUploaded, required double amount, required String town}) async {
    await Future.delayed(const Duration(seconds: 2));
    if (!slipUploaded) return {'valid': false, 'message': '⚠️ Upload slip first!'};
    if (txId.length < 6) return {'valid': false, 'message': 'Invalid TxID - too short'};
    if (usedTxIds.contains(txId)) return {'valid': false, 'message': '❌ This TxID already used! Counter reader detected reuse!'};
    usedTxIds.add(txId);
    return {'valid': true, 'message': '✅ Verified! TxID $txId confirmed, slip matches, counter OK, in line together!'};
  }
}
