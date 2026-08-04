class PaymentService {
  Future<bool> payFixedR20({required String method}) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
