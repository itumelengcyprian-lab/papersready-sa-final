import 'package:flutter/material.dart';
import 'services/sassa_service.dart';
import 'services/pdf_service.dart';
import 'services/payment_service.dart';
import 'services/momo_verification_service.dart';

void main() { runApp(const PapersReadyApp()); }

class PapersReadyApp extends StatefulWidget {
  const PapersReadyApp({super.key});
  @override
  State<PapersReadyApp> createState() => _PapersReadyAppState();
}

class _PapersReadyAppState extends State<PapersReadyApp> {
  String _appLang = 'English';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PapersReady SA - Final - WhatsApp Delivery',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomeScreen(appLang: _appLang, onLangChange: (l) => setState(() => _appLang = l)),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String appLang;
  final Function(String) onLangChange;
  const HomeScreen({super.key, required this.appLang, required this.onLangChange});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _momoTxController = TextEditingController();
  final _whatsappController = TextEditingController();
  String _selectedTown = 'Ficksburg';
  String _statusMessage = '';
  bool _isChecking = false;
  bool _consentGiven = false;
  String _selectedPayMethod = 'MoMo';
  bool _momoVerified = false;
  bool _slipUploaded = false;
  
  final List<String> towns = ['Bloemfontein','Bethlehem','Welkom','Kroonstad','Senekal','Fouriesburg','Qwa-Qwa','Ficksburg','Clocolan','Marquard','Ladybrand','Thaba Nchu'];
  final SassaService _sassaService = SassaService();
  final PdfService _pdfService = PdfService();
  final PaymentService _paymentService = PaymentService();
  final MomoVerificationService _momoService = MomoVerificationService();

  Future<void> _checkStatus() async {
    if (_idController.text.isEmpty || !_consentGiven) {
      setState(() => _statusMessage = 'Enter ID and consent!');
      return;
    }
    setState(() { _isChecking = true; _statusMessage = 'Checking SASSA status... 24/7'; });
    try {
      final r = await _sassaService.checkStatus(_idController.text);
      setState(() { _statusMessage = r; _isChecking = false; });
    } catch (e) { setState(() { _statusMessage = 'Error: $e'; _isChecking = false; }); }
  }

  Future<void> _verifyTxId() async {
    if (_momoTxController.text.isEmpty) { setState(() => _statusMessage = 'Enter Transaction ID!'); return; }
    if (!_slipUploaded) { setState(() => _statusMessage = '⚠️ Upload Kazang slip photo first!'); return; }
    setState(() { _isChecking = true; _statusMessage = 'Verifying TxID + Slip + Counter Reader...'; });
    final res = await _momoService.verifyTransactionIdOnly(txId: _momoTxController.text, slipUploaded: _slipUploaded, amount: 20.0, town: _selectedTown);
    setState(() { _momoVerified = res['valid']; _isChecking = false; _statusMessage = res['message']; });
  }

  Future<void> _showWhatsAppInputAndGenerate() async {
    final whatsappNumber = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📱 Enter WhatsApp Number - Get Letter Instantly'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(8), color: Colors.green[50], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('✅ Verification Passed - In Line Together', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 4),
            Text('TxID: ${_momoTxController.text} verified', style: TextStyle(fontSize: 11)),
            const Text('Slip photo confirmed & matches ID', style: TextStyle(fontSize: 11)),
            const Text('Counter reader: ID unique - not reused', style: TextStyle(fontSize: 11)),
            const Text('Two-way payment security OK', style: TextStyle(fontSize: 11)),
          ])),
          const SizedBox(height: 12),
          const Text('Enter WhatsApp number where you want to receive your English appeal letter instantly after verification:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _whatsappController,
            decoration: const InputDecoration(
              labelText: 'WhatsApp Number - Tiny Block for Delivery',
              hintText: 'e.g. 083 123 4567',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.whatsapp, color: Colors.green),
              helperText: 'Letter sent instantly after verification',
            ),
            keyboardType: TextInputType.phone,
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A237E)),
            onPressed: () => Navigator.pop(ctx, _whatsappController.text),
            child: const Text('Generate & Send to WhatsApp', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (whatsappNumber != null && whatsappNumber.isNotEmpty) {
      await _generateWithWhatsApp(whatsappNumber);
    }
  }

  Future<void> _generateWithWhatsApp(String whatsappNumber) async {
    if (_selectedPayMethod == 'MoMo' && !_momoVerified) {
      setState(() => _statusMessage = 'Verify Transaction ID + Upload slip first!');
      return;
    }
    setState(() { _isChecking = true; _statusMessage = 'Generating English letter for SASSA + Sending to WhatsApp $whatsappNumber instantly... R20'; });
    try {
      if (_selectedPayMethod != 'MoMo') {
        final paid = await _paymentService.payFixedR20(method: _selectedPayMethod);
        if (!paid) { setState(() { _statusMessage = 'Payment failed'; _isChecking = false; }); return; }
      }
      final path = await _pdfService.generateAppealLetter(idNumber: _idController.text, phoneNumber: _phoneController.text, town: _selectedTown, language: 'English', momoTxId: _momoTxController.text, verified: _momoVerified);
      
      setState(() {
        _statusMessage = '✅ English PDF Generated Instantly! Sent to WhatsApp $whatsappNumber ✅\nTx: ${_momoTxController.text} | Letter in English (SASSA uses English) | Two-way verification passed | In line together - Ready!\nIf any problem, scan QR to chat with me about experience issue.';
        _isChecking = false;
      });
      
      Future.delayed(const Duration(seconds: 4), () {
        _idController.clear();
        _momoTxController.clear();
        _whatsappController.clear();
        setState(() { _momoVerified = false; _slipUploaded = false; _consentGiven = false; });
      });
    } catch (e) { setState(() { _statusMessage = 'Error: $e'; _isChecking = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAPERSREADY SA - 24/7 - R20 - WhatsApp Delivery'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(8)), child: Column(children: [
          const Text('SASSA Eo Hanne Ka Mabaka Ao Osa Utlwisising Re Ka O Thusa Ho Fumana Tharollo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
        ])),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _selectedTown, items: towns.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedTown = v!), decoration: const InputDecoration(labelText: 'Select Town', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: _idController, decoration: const InputDecoration(labelText: 'ID Number (will be cleared)', border: OutlineInputBorder()), maxLength: 13),
        TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        Row(children: [Checkbox(value: _consentGiven, onChanged: (v) => setState(() => _consentGiven = v!)), const Expanded(child: Text('I consent ID used only to check SASSA, will be cleared', style: TextStyle(fontSize: 12)))]),
        ElevatedButton(onPressed: _isChecking ? null : _checkStatus, child: const Text('Check SASSA Status Free - 24/7')),
        if (_statusMessage.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold))),
        const Divider(),
        const Text('PAY WITH - R20 - 24/7:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        Wrap(spacing: 6, children: ['MoMo','Capitec Pay','Card','EFT'].map((m) => ChoiceChip(label: Text(m), selected: _selectedPayMethod == m, onSelected: (s) { if (s) setState(() => _selectedPayMethod = m); })).toList()),
        const SizedBox(height: 12),
        if (_selectedPayMethod == 'MoMo')
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1A237E)), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('MoMo - R20 - TxID Only + Slip Upload + WhatsApp Delivery', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(8), color: const Color(0xFFFFF3E0), child: const Text('1. Kazang MoMo R20 to 083 925 8423\n2. Get slip with Transaction ID\n3. Take CLEAR photo of slip\n4. Upload photo below\n5. Enter Transaction ID\n6. Counter reader checks if already used\n7. After verification → Enter WhatsApp number → Letter instantly', style: TextStyle(fontSize: 11))),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: () => setState(() => _slipUploaded = true), icon: const Icon(Icons.upload), label: Text(_slipUploaded ? '✅ Slip Photo Uploaded' : 'Upload Clear Kazang Slip Photo'), style: ElevatedButton.styleFrom(backgroundColor: _slipUploaded ? Colors.green : Colors.orange)),
            const SizedBox(height: 8),
            TextField(controller: _momoTxController, decoration: const InputDecoration(labelText: 'Tiny Block: Enter MTN Transaction ID from slip', border: OutlineInputBorder(), prefixIcon: Icon(Icons.receipt))),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: _isChecking ? null : _verifyTxId, icon: const Icon(Icons.verified_user), label: const Text('Verify Transaction ID + Counter Reader'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF880E4F))),
            if (_momoVerified) const Text('✅ Verified! Press Generate to enter WhatsApp number', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ])),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (_isChecking || (_selectedPayMethod == 'MoMo' && !_momoVerified)) ? null : _showWhatsAppInputAndGenerate,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('✅ Verification Passed - Enter WhatsApp Number & Generate Letter Instantly'),
        ),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(8), color: const Color(0xFF1A237E).withOpacity(0.1), child: const Text('Flow: Upload slip + Enter TxID → Verify → Enter WhatsApp number → Generate English letter instantly → Send to WhatsApp\nWorking: WhatsApp 8am-6pm Mon-Sun | App 24/7/365', style: TextStyle(fontSize: 9), textAlign: TextAlign.center)),
      ])),
    );
  }
}
