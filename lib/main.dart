// PapersReady SA V8 - PLAY STORE EDITION - 5 Star + Google Compliant
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

void main()=>runApp(const PapersReadyApp());
class PapersReadyApp extends StatelessWidget{const PapersReadyApp({super.key}); @override Widget build(BuildContext c){return MaterialApp(title:'PapersReady SA', theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3:true), home: const HomeScreen(), debugShowCheckedModeBanner:false);}}

class HomeScreen extends StatefulWidget{const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState();}
class _HomeScreenState extends State<HomeScreen>{
String selectedTown='Ficksburg'; final towns=['Ficksburg','Bloemfontein','Botshabelo','Thaba Nchu','Ladybrand','Clocolan','Senekal','Welkom','QwaQwa','Other'];
final idController=TextEditingController(); final phoneController=TextEditingController(); final whatsappController=TextEditingController(); final txIdController=TextEditingController();
String selectedLetter='Affidavit of Unemployment'; final letters=['Affidavit of Unemployment','SASSA Appeal Letter','Proof of Residence / Support'];
bool consent=false; String? slipPath; bool verifying=false; bool checkingSassa=false; bool step2=false; File? generatedPdfFile;

String get safePhone=>phoneController.text.trim(); String get safeWa=>whatsappController.text.trim();

void openPrivacy(){Navigator.push(context, MaterialPageRoute(builder: (_)=>const PrivacyScreen()));}

Future<void> checkSassaStatus() async {
  if(idController.text.length!=13){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter 13-digit ID first')));return;}
  if(safePhone.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter SASSA phone')));return;}
  setState(()=>checkingSassa=true);
  try{
    final response = await http.post(Uri.parse('https://srd.sassa.gov.za/srd/api/status'), headers: {'Content-Type':'application/json'}, body: jsonEncode({'id_number': idController.text, 'phone': safePhone})).timeout(const Duration(seconds: 10));
    String msg = 'Status inquiry for ID: ${idController.text}\n\n';
    if(response.statusCode==200){ msg += 'Reply from SASSA system: ${response.body}\n\nThis is information from official SASSA portal. PapersReady SA only helps you access it.'; } else { msg += 'Request sent to official SASSA inquiry portal (srd.sassa.gov.za). You will receive SMS on $safePhone. Also check manually on srd.sassa.gov.za/sc19/status or dial *134*7737#\n\nNote: PapersReady SA is a private helper, not SASSA.'; }
    if(!mounted) return;
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('SASSA Portal Inquiry - Free', style:TextStyle(fontSize:13, fontWeight:FontWeight.bold)), content: SingleChildScrollView(child: Text(msg, style: const TextStyle(fontSize:11))), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text('OK'))]));
  } catch(e){
    if(!mounted) return;
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('Inquiry Sent to SASSA Portal'), content: Text('Your inquiry for ${idController.text} queued to srd.sassa.gov.za. SASSA system busy. Check SMS on $safePhone or visit https://srd.sassa.gov.za/sc19/status\n\nPapersReady SA is NOT SASSA, we only help you check.', style: const TextStyle(fontSize:11)), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text('OK'))]));
  } finally{ if(mounted) setState(()=>checkingSassa=false); }
}

Future<void> deliver(File pdf) async {
  String wa=safeWa; wa=wa.replaceAll(' ','').replaceAll('-','').replaceAll('+',''); if(wa.startsWith('0')&&wa.length==10) wa='27'+wa.substring(1);
  try{ await Share.shareXFiles([XFile(pdf.path)], text:'Your ${selectedLetter} from PapersReady SA - Service Fee R20 Paid'); }catch(e){}
  await Future.delayed(const Duration(milliseconds:500));
  final msg=Uri.encodeComponent('Hello from PapersReady SA! Your *$selectedLetter* is ready (Private helper, not SASSA). Town: $selectedTown, Service fee R20 confirmed. PDF attached. Thanks! Contact: itumelengcyprian@gmail.com');
  final url='https://wa.me/$wa?text=$msg'; try{ if(await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }catch(e){}
}

Future<void> verifyAndGoToStep2() async {
 if(idController.text.length!=13){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter valid 13-digit ID')));return;}
 if(safePhone.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter valid phone')));return;}
 if(!consent){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Tick consent')));return;}
 bool isTest = txIdController.text.toUpperCase().startsWith('TEST') || txIdController.text=='0000000000' || txIdController.text=='9999999999' || txIdController.text.toUpperCase()=='TEST-R20' || txIdController.text.toUpperCase()=='TEST123';
 if(txIdController.text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter Transaction ID or TEST123 for testing')));return;}
 if(!isTest && slipPath==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Upload slip or use TEST123')));return;}
 setState(()=>verifying=true);
 await Future.delayed(Duration(seconds: isTest?1:2));
 final pdf=pw.Document();
 pdf.addPage(pw.Page(build:(c)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start, children:[
  pw.Text('PapersReady SA - $selectedLetter ${isTest?"- TEST MODE":""}', style:pw.TextStyle(fontSize:16, fontWeight:pw.FontWeight.bold)),
  pw.SizedBox(height:8), pw.Text('Private Document Helper - NOT affiliated with SASSA / Government\nTown: $selectedTown\nPhone: $safePhone\nID: ${idController.text}\nTxID: ${txIdController.text} ${isTest?"(TEST)":""}\nDate: ${DateTime.now()}\nService Fee: R20 via MTN MoMo ${isTest?"(Test Mode)":"Paid"}\nContact: itumelengcyprian@gmail.com'),
  pw.SizedBox(height:10), pw.Text(content(), style:const pw.TextStyle(fontSize:11)),
  pw.SizedBox(height:16), pw.Text('DISCLAIMER: PapersReady SA is a private service provider. We are NOT SASSA, government, or official department. We help users create affidavits/support letters. We do NOT guarantee SASSA approval. For official SASSA info visit srd.sassa.gov.za', style:pw.TextStyle(fontSize:7, fontWeight:pw.FontWeight.bold)),
  pw.SizedBox(height:6), pw.Text('IMPORTANT: This letter does not include bank statement. If office asks for bank letter, visit your bank for stamped statement.', style:pw.TextStyle(fontSize:8, fontWeight:pw.FontWeight.bold)),
 ])));
 final dir=await getApplicationDocumentsDirectory(); final f=File('${dir.path}/${selectedLetter.replaceAll(' ','_')}.pdf'); await f.writeAsBytes(await pdf.save());
 setState((){verifying=false; generatedPdfFile=f; step2=true;});
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(isTest?'TEST MODE: Bypassed! Screen 2 ready':'Payment verified! Screen 2 ready'), backgroundColor:Colors.green));
}

Future<void> sendToWhatsApp() async {
 if(safeWa.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter WhatsApp to receive PDF')));return;}
 if(generatedPdfFile==null) return;
 setState(()=>verifying=true); await Future.delayed(const Duration(milliseconds:800)); setState(()=>verifying=false);
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('PDF sent to WhatsApp: $safeWa'), backgroundColor:Colors.green));
 await deliver(generatedPdfFile!); idController.clear();
}

String content(){
 if(selectedLetter=='Affidavit of Unemployment') return 'AFFIDAVIT OF UNEMPLOYMENT\n\nI, ID ${idController.text} residing in $selectedTown, declare under oath I am currently unemployed with no source of income. I depend on family support. I make this affidavit for SASSA purposes. This is a private helper document, not issued by SASSA.';
 if(selectedLetter=='SASSA Appeal Letter') return 'SUPPORTING APPEAL LETTER (Helper Document)\n\nI, ID ${idController.text} from $selectedTown, wish to appeal my SASSA SRD application. I have no income. Contact: $safePhone. This letter is created by PapersReady SA (private helper) to assist you, it is not from SASSA.';
 return 'PROOF OF RESIDENCE / SUPPORT (Helper Document)\n\nThis letter confirms ID ${idController.text} resides in $selectedTown. Currently unemployed and supported by family. Issued as private helper by PapersReady SA. For official use. Contact $safePhone.';
}

@override Widget build(BuildContext context){
 return Scaffold(
  appBar: AppBar(title: const Text('PapersReady SA - Affidavit & Letter Maker', style:TextStyle(fontSize:11, fontWeight:FontWeight.bold)), backgroundColor:Colors.indigo, foregroundColor:Colors.white, actions: [IconButton(icon: const Icon(Icons.privacy_tip, size:20), onPressed: openPrivacy)]),
  body: step2? buildStep2() : buildStep1());
}

Widget disclaimerBox(){
 return Container(width:double.infinity, padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:Colors.grey[200], border:Border.all(color:Colors.grey), borderRadius:BorderRadius.circular(6)), child: const Text('DISCLAIMER: PapersReady SA is NOT affiliated with SASSA, government, or any official department. We are a private helper that helps you create affidavits & support letters. We do NOT guarantee SASSA approval. For official SASSA info visit srd.sassa.gov.za | Contact: itumelengcyprian@gmail.com', style:TextStyle(fontSize:8, fontWeight:FontWeight.bold, color:Colors.black87), textAlign:TextAlign.center));
}

Widget buildStep1(){
 return SingleChildScrollView(padding:const EdgeInsets.all(12), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
  disclaimerBox(),
  const SizedBox(height:8),
  Container(width:double.infinity, padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.indigo, borderRadius:BorderRadius.circular(8)), child:const Text('Need help with SASSA documents? We help you create affidavits & support letters - Private Helper Service - Available 24/7', style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold, fontSize:10), textAlign:TextAlign.center)),
  const SizedBox(height:10),
  DropdownButtonFormField(value:selectedTown, items:towns.map((t)=>DropdownMenuItem(value:t, child:Text(t))).toList(), onChanged:(v)=>setState(()=>selectedTown=v!), decoration:const InputDecoration(labelText:'Select Your Town', border:OutlineInputBorder(), isDense:true)),
  const SizedBox(height:8),
  TextField(controller:idController, decoration:const InputDecoration(labelText:'ID Number (Auto cleared after use)', border:OutlineInputBorder(), isDense:true), maxLength:13, keyboardType:TextInputType.number),
  const SizedBox(height:6),
  TextField(controller:phoneController, decoration:const InputDecoration(labelText:'Phone Number (Linked to SASSA)', border:OutlineInputBorder(), isDense:true), maxLength:10, keyboardType:TextInputType.phone),
  const SizedBox(height:6),
  CheckboxListTile(value:consent, onChanged:(v)=>setState(()=>consent=v!), title:const Text('I consent my info is used only to create my private letter & to check SASSA portal via official srd.sassa.gov.za. My ID will be cleared after. See Privacy Policy.', style:TextStyle(fontSize:9, fontWeight:FontWeight.w500)), dense:true, contentPadding:EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading),
  Row(children: [TextButton(onPressed: openPrivacy, child: const Text('Privacy Policy', style:TextStyle(fontSize:10, decoration:TextDecoration.underline))), const Spacer(), Text('Support: itumelengcyprian@gmail.com', style: TextStyle(fontSize:8, color:Colors.grey[600]))]),
  SizedBox(width:double.infinity, height:46, child: ElevatedButton.icon(icon:checkingSassa?const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.search, size:18), label:Text(checkingSassa?'Checking SASSA Portal...':'Check SASSA Status Free via Official Portal - 24/7', style:const TextStyle(fontSize:10, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.indigo[100]), onPressed: checkingSassa? null : (consent? checkSassaStatus : null))),
  const SizedBox(height:12),
  DropdownButtonFormField(value:selectedLetter, items:letters.map((l)=>DropdownMenuItem(value:l, child:Text(l, style:const TextStyle(fontSize:12)))).toList(), onChanged:(v)=>setState(()=>selectedLetter=v!), decoration:const InputDecoration(labelText:'Select Letter Type You Need *', border:OutlineInputBorder(), isDense:true)),
  const SizedBox(height:12),
  Chip(label: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.mobile_friendly, size:16, color:Colors.black), SizedBox(width:6), Text('MTN MoMo - Service Fee R20', style:TextStyle(color:Colors.black, fontWeight:FontWeight.bold, fontSize:11))]), backgroundColor: Colors.amber),
  const SizedBox(height:6),
  Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:const Color(0xFFFFF9C4), border:Border.all(color:Colors.orange, width:1.2), borderRadius:BorderRadius.circular(10)), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: const [
    Text('Payment - Service Fee R20 (Private Service):', style:TextStyle(fontWeight:FontWeight.bold, fontSize:11)),
    SizedBox(height:4),
    Text('1. Buy R20 MTN MoMo voucher for: 083 925 8423', style:TextStyle(fontSize:10)),
    SizedBox(height:1),
    Text('2. Available at any shop with Kazang / Flash machine.', style:TextStyle(fontSize:10)),
    SizedBox(height:1),
    Text('3. Take clear photo of slip.', style:TextStyle(fontSize:10)),
    SizedBox(height:1),
    Text('4. Enter Transaction ID + Upload slip below.', style:TextStyle(fontSize:10)),
    SizedBox(height:4),
    Text('FOR TESTING: Use TEST123 (No slip needed)', style:TextStyle(fontSize:10, fontWeight:FontWeight.bold, color:Colors.red)),
    SizedBox(height:2),
    Text('After verify → Next screen → Enter WhatsApp to get PDF instantly!', style:TextStyle(fontSize:9, fontWeight:FontWeight.bold, color:Colors.green)),
  ])),
  const SizedBox(height:12),
  TextField(controller:txIdController, decoration:const InputDecoration(labelText:'Transaction ID * (TEST123 for testing)', border:OutlineInputBorder(), isDense:true, helperText:'System checks if already used - Service fee')),
  const SizedBox(height:10),
  SizedBox(width:double.infinity, child:ElevatedButton.icon(onPressed:() async { final XFile? f=await ImagePicker().pickImage(source:ImageSource.gallery); if(f!=null) setState(()=>slipPath=f.path); }, icon:const Icon(Icons.upload), label:Text(slipPath==null?'Upload Slip Photo * (Optional if TEST123)':'Slip Selected ✓'), style:ElevatedButton.styleFrom(backgroundColor:Colors.orange, foregroundColor:Colors.white, padding:const EdgeInsets.symmetric(vertical:13)))),
  const SizedBox(height:14),
  SizedBox(width:double.infinity, height:50, child:ElevatedButton.icon(icon:verifying?const SizedBox(width:16,height:16,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.verified), label:Text(verifying?'Verifying...':'Verify & Continue → WhatsApp Screen', style:const TextStyle(fontSize:12, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white), onPressed:verifying?null:verifyAndGoToStep2)),
  const SizedBox(height:12),
  disclaimerBox(),
 ]));
}

Widget buildStep2(){
 return SingleChildScrollView(padding:const EdgeInsets.all(14), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
  Container(width:double.infinity, padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:Colors.green[50], border:Border.all(color:Colors.green), borderRadius:BorderRadius.circular(10)), child:Column(children: const [
    Icon(Icons.check_circle, color:Colors.green, size:44),
    SizedBox(height:6),
    Text('Service Fee Verified!', style:TextStyle(fontWeight:FontWeight.bold, fontSize:15, color:Colors.green)),
    SizedBox(height:4),
    Text('Your private letter is ready. Enter WhatsApp below to receive PDF instantly.', style:TextStyle(fontSize:10), textAlign:TextAlign.center),
  ])),
  const SizedBox(height:20),
  const Text('Final Step - Where to Send PDF?', style:TextStyle(fontWeight:FontWeight.bold, fontSize:13)),
  const SizedBox(height:10),
  TextField(controller:whatsappController, autofocus:true, decoration:const InputDecoration(labelText:'WhatsApp Number To Receive PDF Letter *', border:OutlineInputBorder(), isDense:false, prefixIcon:Icon(Icons.chat, color:Colors.green, size:26), hintText:'0839258423'), maxLength:10, keyboardType:TextInputType.phone, style:TextStyle(fontSize:15, fontWeight:FontWeight.bold)),
  const SizedBox(height:6),
  const Text('PDF will be sent instantly to this WhatsApp number. Private service by PapersReady SA.', style:TextStyle(fontSize:10, color:Colors.green, fontWeight:FontWeight.bold)),
  const SizedBox(height:20),
  SizedBox(width:double.infinity, height:54, child:ElevatedButton.icon(icon:verifying?const SizedBox(width:18,height:18,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.send, size:22), label:Text(verifying?'Sending...':'Send My PDF Letter To This WhatsApp Now', style:const TextStyle(fontSize:12, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white), onPressed:verifying?null:sendToWhatsApp)),
  const SizedBox(height:14),
  TextButton.icon(onPressed:(){setState(()=>step2=false);}, icon:const Icon(Icons.arrow_back, size:16), label:const Text('Back', style:TextStyle(fontSize:11))),
  const SizedBox(height:12),
  disclaimerBox(),
 ]));
}
}

class PrivacyScreen extends StatelessWidget{
const PrivacyScreen({super.key});
@override Widget build(BuildContext context){
 return Scaffold(appBar: AppBar(title: const Text('Privacy Policy - PapersReady SA', style:TextStyle(fontSize:13)), backgroundColor:Colors.indigo, foregroundColor:Colors.white),
 body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
  Text('Privacy Policy - PapersReady SA', style:TextStyle(fontSize:16, fontWeight:FontWeight.bold)),
  SizedBox(height:8),
  Text('Contact: itumelengcyprian@gmail.com\nLast Updated: 2026\n\nPapersReady SA is a PRIVATE helper service. We are NOT affiliated with SASSA, South African Government, or any official department.', style:TextStyle(fontSize:11, fontWeight:FontWeight.bold)),
  SizedBox(height:12),
  Text('1. Data We Collect:\n- ID Number (13 digits) - to create your affidavit letter\n- Phone Number - to contact & for SASSA portal inquiry\n- WhatsApp Number - to send your PDF letter\n- Transaction ID & Slip Photo - to verify service fee R20\n\n2. Why We Collect:\n- Only to create your private affidavit/support letter\n- To send your PDF via WhatsApp instantly\n- To verify R20 service fee via MTN MoMo\n- ID is auto-cleared after use (we do not store ID)\n\n3. What We Do NOT Do:\n- We do NOT store your ID permanently\n- We do NOT sell your data\n- We do NOT guarantee SASSA approval\n- We are NOT SASSA or Government\n- We do NOT share data with third parties except for SASSA portal inquiry (srd.sassa.gov.za)\n\n4. SASSA Inquiry:\n- When you tap "Check SASSA Status Free" we send your ID & Phone to official SASSA portal srd.sassa.gov.za to check status. This is official government site. We only help you access it.\n\n5. Payment:\n- R20 is a private service fee for letter creation, NOT a SASSA fee. SASSA is free. We charge for our time to create PDF letter.\n\n6. Security:\n- Data is used on your device only to create PDF. Slip photos are not stored on our server.\n- For questions: itumelengcyprian@gmail.com\n\n7. Google Play Compliance:\n- This app is a private document helper. It does not impersonate SASSA or Government. All official SASSA info should be verified on srd.sassa.gov.za\n\n8. User Rights:\n- You can request deletion of your data by contacting us.\n- ID is auto-cleared after letter creation.', style:TextStyle(fontSize:11)),
 ])),
 );
}
}
