class SassaService {
  Future<String> checkStatus(String idNumber) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulated check - real version connects to SASSA API
    if (idNumber.length == 13) {
      return 'Status Checked: Your SRD is currently pending verification. This usually means Home Affairs check is in progress. Try again tomorrow or generate an affidavit.';
    } else {
      return 'Invalid ID length - must be 13 digits';
    }
  }
}
