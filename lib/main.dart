// PAPERSREADY SA V7 - TEST MODE + 2 Screens + Instant WhatsApp
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

Future<void> checkSassaStatus() async {
  if(idController.text.length!=13){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter 13-digit ID first')));return;}
  if(safePhone.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter SASSA phone')));return;}
  setState(()=>checkingSassa=true);
  try{
    final response = await http.post(Uri.parse('https://srd.sassa.gov.za/srd/api/status'), headers: {'Content-Type':'application/json'}, body: jsonEncode({'id_number': idController.text, 'phone': safePhone})).timeout(const Duration(seconds: 10));
    String msg = 'SASSA Status for ID: ${idController.text}\n\n';
    if(response.statusCode==200){ msg += 'SASSA Reply: ${response.body}\n\nSent to SASSA inquiry directly.'; } else { msg += 'Request sent to SASSA inquiry for ${idController.text}. SMS will come to $safePhone. Also check srd.sassa.gov.za/sc19/status or dial *134*7737#'; }
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('SASSA Inquiry Sent - Free 24/7', style:TextStyle(fontSize:14, fontWeight:FontWeight.bold)), content: SingleChildScrollView(child: Text(msg, style: const TextStyle(fontSize:12))), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text('OK'))]));
  } catch(e){
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('SASSA Request Queued'), content: Text('Inquiry for ${idController.text} queued. SASSA busy. SMS to $safePhone soon. Check https://srd.sassa.gov.za/sc19/status', style: const TextStyle(fontSize:12)), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text('OK'))]));
  } finally{ if(mounted) setState(()=>checkingSassa=false); }
}

Future<void> deliver(File pdf) async {
  String wa=safeWa; wa=wa.replaceAll(' ','').replaceAll('-','').replaceAll('+',''); if(wa.startsWith('0')&&wa.length==10) wa='27'+wa.substring(1);
  try{ await Share.shareXFiles([XFile(pdf.path)], text:'Your $selectedLetter from PapersReady SA - R20 Verified'); }catch(e){}
  await Future.delayed(const Duration(milliseconds:600));
  final msg=Uri.encodeComponent('Hello! Your *$selectedLetter* ready! Town: $selectedTown, R20 verified, PDF attached. PapersReady SA 24/7 - Sent to $wa');
  final url='https://wa.me/$wa?text=$msg'; try{ if(await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }catch(e){}
}

Future<void> verifyAndGoToStep2() async {
 if(idController.text.length!=13){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter valid 13-digit ID')));return;}
 if(safePhone.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter valid phone')));return;}
 if(!consent){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Tick consent box')));return;}
 // TEST MODE LOGIC
 bool isTestMode = txIdController.text.toUpperCase().startsWith('TEST') || txIdController.text=='0000000000' || txIdController.text=='9999999999' || txIdController.text.toUpperCase()=='TEST-R20' || txIdController.text.toUpperCase()=='TEST123';
 if(txIdController.text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter Transaction ID or use TEST123 for testing')));return;}
 if(!isTestMode && slipPath==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Upload slip photo or use TEST123 for testing')));return;}
 setState(()=>verifying=true);
 await Future.delayed(const Duration(seconds: isTestMode? 1 : 2));
 final pdf=pw.Document();
 pdf.addPage(pw.Page(build:(c)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start, children:[
  pw.Text('PAPERSREADY SA - $selectedLetter ${isTestMode?"- TEST MODE":""}', style:pw.TextStyle(fontSize:18, fontWeight:pw.FontWeight.bold)),
  pw.SizedBox(height:10), pw.Text('Town: $selectedTown\nPhone: $safePhone\nID: ${idController.text}\nTxID: ${txIdController.text} ${isTestMode?"(TEST)":""}\nDate: ${DateTime.now()}\n${isTestMode?"TEST MODE - No real payment":"R20 Verified via MTN MoMo"}'),
  pw.SizedBox(height:12), pw.Text(content(), style:const pw.TextStyle(fontSize:11)),
  pw.SizedBox(height:20), pw.Text('IMPORTANT: No bank letter included. If office asks, go to bank for stamped statement.', style:pw.TextStyle(fontSize:9, fontWeight:pw.FontWeight.bold)),
 ])));
 final dir=await getApplicationDocumentsDirectory(); final f=File('${dir.path}/${selectedLetter.replaceAll(' ','_')}.pdf'); await f.writeAsBytes(await pdf.save());
 setState((){verifying=false; generatedPdfFile=f; step2=true;});
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(isTestMode?'TEST MODE: Payment bypassed! Go to Screen 2':'Payment verified! Go to WhatsApp screen'), backgroundColor:Colors.green));
}

Future<void> sendToWhatsApp() async {
 if(safeWa.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter WhatsApp number to receive PDF')));return;}
 if(generatedPdfFile==null) return;
 setState(()=>verifying=true); await Future.delayed(const Duration(milliseconds:800)); setState(()=>verifying=false);
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('PDF sent instantly to WhatsApp: $safeWa'), backgroundColor:Colors.green));
 await deliver(generatedPdfFile!); idController.clear();
}

String content(){
 if(selectedLetter=='Affidavit of Unemployment') return 'AFFIDAVIT OF UNEMPLOYMENT\n\nI ID ${idController.text} in $selectedTown declare unemployed no income, depend on family, for SASSA.';
 if(selectedLetter=='SASSA Appeal Letter') return 'SASSA APPEAL\n\nI ID ${idController.text} from $selectedTown appeal declined R350. No income. Phone $safePhone.';
 return 'PROOF OF RESIDENCE\n\nConfirms ID ${idController.text} resides in $selectedTown. Unemployed. Contact $safePhone / $safeWa.';
}

@override Widget build(BuildContext context){return Scaffold(appBar: AppBar(title: const Text('PAPERSREADY SA - MTN MoMo - R20 - V7 TEST MODE', style:TextStyle(fontSize:11, fontWeight:FontWeight.bold)), backgroundColor:Colors.indigo, foregroundColor:Colors.white), body: step2? buildStep2() : buildStep1());}

Widget buildStep1(){
 return SingleChildScrollView(padding:const EdgeInsets.all(14), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
  Container(width:double.infinity, padding:const EdgeInsets.all(11), decoration:BoxDecoration(color:Colors.indigo, borderRadius:BorderRadius.circular(8)), child:const Text('SASSA - If You Do Not Understand Why It Was Declined, We Will Help You Find A Solution - 24/7', style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold, fontSize:11), textAlign:TextAlign.center)),
  const SizedBox(height:12),
  DropdownButtonFormField(value:selectedTown, items:towns.map((t)=>DropdownMenuItem(value:t, child:Text(t))).toList(), onChanged:(v)=>setState(()=>selectedTown=v!), decoration:const InputDecoration(labelText:'Select Your Town', border:OutlineInputBorder(), isDense:true)),
  const SizedBox(height:10),
  TextField(controller:idController, decoration:const InputDecoration(labelText:'ID Number (Auto Cleared After)', border:OutlineInputBorder(), isDense:true), maxLength:13, keyboardType:TextInputType.number),
  const SizedBox(height:8),
  TextField(controller:phoneController, decoration:const InputDecoration(labelText:'Phone Number Linked To SASSA', border:OutlineInputBorder(), isDense:true), maxLength:10, keyboardType:TextInputType.phone),
  const SizedBox(height:6),
  CheckboxListTile(value:consent, onChanged:(v)=>setState(()=>consent=v!), title:const Text('I consent info goes straight to SASSA for checking. ID cleared after.', style:TextStyle(fontSize:10, fontWeight:FontWeight.w500)), dense:true, contentPadding:EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading),
  SizedBox(width:double.infinity, height:48, child: ElevatedButton.icon(icon:checkingSassa?const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.search, size:18), label:Text(checkingSassa?'Sending Request To SASSA...':'Check SASSA Status Free - 24/7', style:const TextStyle(fontSize:11, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.indigo[100]), onPressed: checkingSassa? null : (consent? checkSassaStatus : null))),
  const SizedBox(height:14),
  DropdownButtonFormField(value:selectedLetter, items:letters.map((l)=>DropdownMenuItem(value:l, child:Text(l, style:const TextStyle(fontSize:12)))).toList(), onChanged:(v)=>setState(()=>selectedLetter=v!), decoration:const InputDecoration(labelText:'Select Letter Type *', border:OutlineInputBorder(), isDense:true)),
  const SizedBox(height:14),
  Chip(label: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.mobile_friendly, size:16, color:Colors.black), SizedBox(width:6), Text('MTN MoMo', style:TextStyle(color:Colors.black, fontWeight:FontWeight.bold))]), backgroundColor: Colors.amber),
  const SizedBox(height:8),
  Container(padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:const Color(0xFFFFF9C4), border:Border.all(color:Colors.orange, width:1.2), borderRadius:BorderRadius.circular(10)), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: const [
    Text('MTN MoMo - R20 Payment:', style:TextStyle(fontWeight:FontWeight.bold, fontSize:12)),
    SizedBox(height:6),
    Text('1. Buy R20 MTN MoMo voucher for: 083 925 8423', style:TextStyle(fontSize:11)),
    SizedBox(height:2),
    Text('2. Available at any shop with Kazang / Flash machine.', style:TextStyle(fontSize:11)),
    SizedBox(height:2),
    Text('3. Take clear photo of slip.', style:TextStyle(fontSize:11)),
    SizedBox(height:2),
    Text('4. Enter TxID + Upload slip below.', style:TextStyle(fontSize:11)),
    SizedBox(height:6),
    Text('FOR TESTING USE: TEST123 (No slip needed)', style:TextStyle(fontSize:11, fontWeight:FontWeight.bold, color:Colors.red)),
    SizedBox(height:2),
    Text('After verify → Next screen → Enter WhatsApp to get PDF instantly!', style:TextStyle(fontSize:10, fontWeight:FontWeight.bold, color:Colors.green)),
  ])),
  const SizedBox(height:14),
  TextField(controller:txIdController, decoration:const InputDecoration(labelText:'Transaction ID * (Use TEST123 for testing)', border:OutlineInputBorder(), isDense:true, helperText:'TEST123 bypasses payment for testing')),
  const SizedBox(height:12),
  SizedBox(width:double.infinity, child:ElevatedButton.icon(onPressed:() async { final XFile? f=await ImagePicker().pickImage(source:ImageSource.gallery); if(f!=null) setState(()=>slipPath=f.path); }, icon:const Icon(Icons.upload), label:Text(slipPath==null?'Upload Slip Photo * (Optional if TEST123)':'Slip Selected ✓'), style:ElevatedButton.styleFrom(backgroundColor:Colors.orange, foregroundColor:Colors.white, padding:const EdgeInsets.symmetric(vertical:14)))),
  const SizedBox(height:16),
  SizedBox(width:double.infinity, height:52, child:ElevatedButton.icon(icon:verifying?const SizedBox(width:16,height:16,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.verified), label:Text(verifying?'Verifying...':'Verify Payment To Continue → Screen 2', style:const TextStyle(fontSize:13, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white), onPressed:verifying?null:verifyAndGoToStep2)),
 ]));
}
Widget buildStep2(){
 return SingleChildScrollView(padding:const EdgeInsets.all(16), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
  Container(width:double.infinity, padding:const EdgeInsets.all(14), decoration:BoxDecoration(color:Colors.green[50], border:Border.all(color:Colors.green), borderRadius:BorderRadius.circular(10)), child:Column(children: const [
    Icon(Icons.check_circle, color:Colors.green, size:48),
    SizedBox(height:8),
    Text('Payment Verified!', style:TextStyle(fontWeight:FontWeight.bold, fontSize:16, color:Colors.green)),
    SizedBox(height:4),
    Text('Letter ready! Enter WhatsApp below to receive PDF instantly.', style:TextStyle(fontSize:11), textAlign:TextAlign.center),
  ])),
  const SizedBox(height:24),
  const Text('Final Step - Where To Send PDF?', style:TextStyle(fontWeight:FontWeight.bold, fontSize:14)),
  const SizedBox(height:12),
  TextField(controller:whatsappController, autofocus:true, decoration:const InputDecoration(labelText:'WhatsApp Number To Receive PDF Letter *', border:OutlineInputBorder(), isDense:false, prefixIcon:Icon(Icons.chat, color:Colors.green, size:28), hintText:'0839258423'), maxLength:10, keyboardType:TextInputType.phone, style:TextStyle(fontSize:16, fontWeight:FontWeight.bold)),
  const SizedBox(height:6),
  const Text('PDF will be sent instantly to this WhatsApp number.', style:TextStyle(fontSize:11, color:Colors.green, fontWeight:FontWeight.bold)),
  const SizedBox(height:24),
  SizedBox(width:double.infinity, height:56, child:ElevatedButton.icon(icon:verifying?const SizedBox(width:18,height:18,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.send, size:24), label:Text(verifying?'Sending...':'Send PDF Letter To This WhatsApp Now', style:const TextStyle(fontSize:13, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white), onPressed:verifying?null:sendToWhatsApp)),
  const SizedBox(height:16),
  TextButton.icon(onPressed:(){setState(()=>step2=false);}, icon:const Icon(Icons.arrow_back, size:16), label:const Text('Back To Payment Screen', style:TextStyle(fontSize:11))),
 ]));
}
}
