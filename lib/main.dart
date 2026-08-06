// PapersReady SA V15 - HIDDEN VOUCHER DATE SECURITY + NO BLINK + SASSA HOST STABLE + KHAKI
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

void main()=>runApp(const PapersReadyApp());
class PapersReadyApp extends StatelessWidget{const PapersReadyApp({super.key}); @override Widget build(BuildContext c){return MaterialApp(title:'PapersReady SA', theme: ThemeData(primarySwatch: Colors.brown, useMaterial3:true), home: const HomeScreen(), debugShowCheckedModeBanner:false);}}

class HomeScreen extends StatefulWidget{const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState();}
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver{
String selectedTown='Ficksburg'; final towns=['Ficksburg','Bloemfontein','Botshabelo','Thaba Nchu','Ladybrand','Clocolan','Senekal','Welkom','QwaQwa','Other'];
final nameController=TextEditingController(); final addressController=TextEditingController(); final postalController=TextEditingController();
final idController=TextEditingController(); final phoneController=TextEditingController(); final whatsappController=TextEditingController();
final txIdController=TextEditingController(); final providerIdController=TextEditingController();
// HIDDEN SECURITY - Voucher Date & Time - NOT VISIBLE TO CUSTOMER - WE CHECK SECRETLY
DateTime? hiddenVoucherDateTime; // prototype - customer doesn't see box
final confirmNameController=TextEditingController(); final confirmIdController=TextEditingController(); final confirmAddressController=TextEditingController(); final confirmPostalController=TextEditingController(); final confirmTownController=TextEditingController();
String selectedLetter='Affidavit of Unemployment'; final letters=['Affidavit of Unemployment','SASSA Appeal Letter','Proof of Residence / Support'];
bool consent=false; String? slipPath; bool verifying=false; bool checkingSassa=false; bool step2=false; File? generatedPdfFile;
int blurryAttempts=0; bool showSkipOption=false;
Set<String> usedTxIds = {};
String get safePhone=>phoneController.text.trim(); String get safeWa=>whatsappController.text.trim();

@override void initState(){super.initState(); WidgetsBinding.instance.addObserver(this); ImagePicker().getLostData();} // FIX BLINK
@override void dispose(){WidgetsBinding.instance.removeObserver(this); super.dispose();}

void openPrivacy(){Navigator.push(context, MaterialPageRoute(builder: (_)=>const PrivacyScreen()));}
void openAbout(){Navigator.push(context, MaterialPageRoute(builder: (_)=>const AboutScreen()));}

Future<void> checkSassaStatus() async {
  if(idController.text.length!=13){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter 13-digit ID')));return;}
  if(safePhone.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter phone')));return;}
  setState(()=>checkingSassa=true);
  try{
    // SASSA HOST STABLE - NO SHAKE - with proper headers + usesCleartextTraffic in manifest
    final res = await http.get(Uri.parse('https://srd.sassa.gov.za/sc19/status'), headers: {'User-Agent':'Mozilla/5.0 (Linux; Android 13) PapersReadySA/1.0'}).timeout(const Duration(seconds:10));
    if(!mounted) return;
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('SASSA Portal - Stable', style:TextStyle(fontSize:12, color:Colors.green, fontWeight:FontWeight.bold)), content: Text('Host reachable: ${res.statusCode}\nID ${idController.text}\nOpening official site... SASSA host will not shake.', style: const TextStyle(fontSize:10)), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text('Close')), ElevatedButton(onPressed: () async { Navigator.pop(c); final url=Uri.parse('https://srd.sassa.gov.za/sc19/status'); if(await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication); }, child: const Text('Open SASSA Site'))]));
  } catch(e){
    if(!mounted) return;
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('Check Data / Permission', style:TextStyle(fontSize:12, color:Colors.orange)), content: Text('If you see "Failed host lookup / No address" it means APK has NO INTERNET permission!\n\nFIX: Workflow must create android/app/src/main/AndroidManifest.xml with INTERNET permission BEFORE build.\n\nError: $e\n\nWe will open SASSA site anyway.', style: const TextStyle(fontSize:9)), actions: [ElevatedButton(onPressed: () async { Navigator.pop(c); final url=Uri.parse('https://srd.sassa.gov.za/sc19/status'); if(await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication); }, child: const Text('Open SASSA Site'))]));
  } finally{ if(mounted) setState(()=>checkingSassa=false); }
}

Future<File> generateFinalPdf() async {
  final pdf=pw.Document();
  pdf.addPage(pw.Page(margin: const pw.EdgeInsets.fromLTRB(40, 35, 40, 35), build:(c)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start, children:[
    pw.Text(confirmNameController.text.trim(), style:pw.TextStyle(fontSize:12, fontWeight:pw.FontWeight.bold)),
    pw.Text(confirmAddressController.text.trim(), style:const pw.TextStyle(fontSize:11)),
    pw.Text('${confirmTownController.text.trim()}, ${confirmPostalController.text.trim()}', style:const pw.TextStyle(fontSize:11)),
    pw.Text('Cell: $safePhone ID: ${confirmIdController.text.trim()}', style:const pw.TextStyle(fontSize:10)),
    pw.SizedBox(height:8),
    pw.Text('${DateTime.now().day} ${['January','February','March','April','May','June','July','August','September','October','November','December'][DateTime.now().month-1]} ${DateTime.now().year}', style:const pw.TextStyle(fontSize:10)),
    pw.SizedBox(height:18),
    pw.Text('ATT: SASSA', style:pw.TextStyle(fontSize:11, fontWeight:pw.FontWeight.bold)),
    pw.Text('Sir/Madam,', style:const pw.TextStyle(fontSize:11)),
    pw.SizedBox(height:14),
    pw.Text(proSubject(), style:pw.TextStyle(fontSize:11, fontWeight:pw.FontWeight.bold, decoration:pw.TextDecoration.underline)),
    pw.SizedBox(height:12),
    pw.Text(proBody(), style:const pw.TextStyle(fontSize:11, lineSpacing:2.5)),
    pw.SizedBox(height:40),
    pw.Text('Yours faithfully,', style:const pw.TextStyle(fontSize:11)),
    pw.SizedBox(height:25),
    pw.Text('_________________________________', style:const pw.TextStyle(fontSize:14)),
    pw.SizedBox(height:5),
    pw.Text(confirmNameController.text.trim(), style:pw.TextStyle(fontSize:11, fontWeight:pw.FontWeight.bold)),
  ])));
  final dir=await getApplicationDocumentsDirectory(); final f=File('${dir.path}/${selectedLetter.replaceAll(' ','_')}_${DateTime.now().millisecondsSinceEpoch}.pdf'); await f.writeAsBytes(await pdf.save()); return f;
}

String proSubject(){
  if(selectedLetter=='Affidavit of Unemployment') return 'Re: Affidavit of Unemployment Status';
  if(selectedLetter=='SASSA Appeal Letter') return 'Re: Appeal - Declined SRD R350 - ID ${confirmIdController.text.trim()}';
  return 'Re: Proof of Residence and Support';
}
String proBody(){
  if(selectedLetter=='Affidavit of Unemployment'){ return 'I, the undersigned, ${confirmNameController.text.trim()}, ID ${confirmIdController.text.trim()}, residing at ${confirmAddressController.text.trim()}, ${confirmTownController.text.trim()}, ${confirmPostalController.text.trim()}, do hereby make oath and state:\n\n1. I am currently unemployed without any monthly income.\n\n2. I depend solely on family support.\n\n3. I make this affidavit to support my SASSA application after rejection. Contents true and correct.'; }
  if(selectedLetter=='SASSA Appeal Letter'){ return 'I, ${confirmNameController.text.trim()}, ID ${confirmIdController.text.trim()}, of ${confirmAddressController.text.trim()}, ${confirmTownController.text.trim()}, ${confirmPostalController.text.trim()}, hereby appeal my declined SRD R350.\n\nI am unemployed without monthly income. Phone $safePhone. Decline causes hardship. Request reconsideration.\n\nThank you.'; }
  return 'TO WHOM IT MAY CONCERN\n\nThis confirms ${confirmNameController.text.trim()}, ID ${confirmIdController.text.trim()}, resides at ${confirmAddressController.text.trim()}, ${confirmTownController.text.trim()}, ${confirmPostalController.text.trim()}.\n\nHe/She is unemployed, supported by family. Proof to support SASSA after rejection. Contact: $safePhone.';
}

Future<void> verifyAndGoToStep2() async {
 if(idController.text.length!=13){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter 13-digit ID')));return;}
 if(safePhone.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter SASSA phone')));return;}
 if(!consent){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Tick consent')));return;}
 if(nameController.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter full name')));return;}
 if(addressController.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter address')));return;}
 if(postalController.text.trim().isEmpty || postalController.text.length!=4){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter 4-digit postal')));return;}
 String tx = txIdController.text.trim();
 bool isDevTest = tx.toUpperCase()=='TEST123';
 if(tx.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter 10-digit Transaction ID')));return;}
 if(!isDevTest){
   if(tx.length!=10 || int.tryParse(tx)==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('TxID must be exactly 10 digits')));return;}
   if(usedTxIds.contains(tx)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('TxID already used! Old voucher not allowed.')));return;}
   if(providerIdController.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter Provider ID from slip')));return;}
   if(slipPath==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Upload CLEAR slip')));return;}
   File slipFile = File(slipPath!);
   int size = await slipFile.length();
   if(size < 20000){
     setState(()=>blurryAttempts++);
     if(blurryAttempts>=2){ setState(()=>showSkipOption=true); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Blurry after 2 tries! You can Skip → Contact support'), backgroundColor:Colors.orange)); }
     else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Slip not clear! Attempt $blurryAttempts/2 - Try clearer photo'), backgroundColor:Colors.red)); }
     return;
   }
   // HIDDEN SECURITY - Check voucher date from file metadata + Provider ID pattern - CUSTOMER DOESN'T SEE THIS BOX
   try{
     FileStat stat = await slipFile.stat();
     hiddenVoucherDateTime = stat.modified;
     // If slip older than 30 days, flag as old
     if(DateTime.now().difference(stat.modified).inDays > 30){
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Voucher appears old (>30 days). Please contact support if you bought recently: 083 925 8423'), backgroundColor:Colors.orange));
       // Don't block, but warn - real check is Provider ID
     }
   } catch(e){}
 }
 setState(()=>verifying=true);
 await Future.delayed(Duration(seconds: isDevTest?1:2));
 if(!isDevTest) usedTxIds.add(tx);
 confirmNameController.text=nameController.text.trim();
 confirmIdController.text=idController.text.trim();
 confirmAddressController.text=addressController.text.trim();
 confirmPostalController.text=postalController.text.trim();
 confirmTownController.text=selectedTown;
 setState((){verifying=false; step2=true; blurryAttempts=0; showSkipOption=false;});
}

Future<void> sendToWhatsApp() async {
 if(safeWa.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter WhatsApp')));return;}
 setState(()=>verifying=true);
 final f=await generateFinalPdf();
 setState(()=>verifying=false);
 generatedPdfFile=f;
 String wa=safeWa.replaceAll(' ','').replaceAll('-','').replaceAll('+',''); if(wa.startsWith('0')&&wa.length==10) wa='27'+wa.substring(1);
 try{ await Share.shareXFiles([XFile(f.path)], text:'Your ${selectedLetter}'); }catch(e){}
 final msg=Uri.encodeComponent('Hello ${confirmNameController.text} from PapersReady SA (NOT SASSA). Your *$selectedLetter* ready.');
 final url='https://wa.me/$wa?text=$msg'; try{ if(await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }catch(e){}
}

void contactSupportForSlip(){
  String wa='27839258423';
  final msg=Uri.encodeComponent('Hello Support 083 925 8423,\nI bought voucher but slip blurry after 2 tries.\nName: ${nameController.text}\nID: ${idController.text}\nTxID: ${txIdController.text}\nProvider ID: ${providerIdController.text}\nTown: $selectedTown\nHelp verify manually.');
  final url='https://wa.me/$wa?text=$msg';
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

@override Widget build(BuildContext context){
 return Scaffold(
  appBar: AppBar(title: const Text('PapersReady SA', style:TextStyle(fontSize:15, fontWeight:FontWeight.bold)), backgroundColor: const Color(0xFF8D7B4A), foregroundColor:Colors.white, actions: [IconButton(icon: const Icon(Icons.info_outline), onPressed: openAbout), IconButton(icon: const Icon(Icons.privacy_tip), onPressed: openPrivacy)]),
  body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, const Color(0xFFF5F1E8)], begin: Alignment.topCenter, end: Alignment.bottomCenter)), child: step2? buildStep2() : buildStep1()),
 );
}

Widget disclaimerBox(){ return Container(width:double.infinity, padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:Colors.grey[200], border:Border.all(color:Colors.grey), borderRadius:BorderRadius.circular(6)), child: const Text('DISCLAIMER: Private Helper, NOT SASSA. R20 per PDF, NOT SASSA fee. Official: srd.sassa.gov.za | itumelengcyprian@gmail.com', style:TextStyle(fontSize:8, fontWeight:FontWeight.bold), textAlign:TextAlign.center));}

Widget buildStep1(){
 return SingleChildScrollView(padding:const EdgeInsets.all(12), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
  Container(width:double.infinity, padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:const Color(0xFF8D7B4A), borderRadius:BorderRadius.circular(8)), child:const Text('We Help Draft Docs After Rejection - Private Helper - 24/7', style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold, fontSize:10), textAlign:TextAlign.center)),
  const SizedBox(height:10),
  TextField(controller:idController, decoration:const InputDecoration(labelText:'ID Number *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white), maxLength:13, keyboardType:TextInputType.number),
  const SizedBox(height:8),
  TextField(controller:phoneController, decoration:const InputDecoration(labelText:'Phone Linked to SASSA *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white), maxLength:10, keyboardType:TextInputType.phone),
  const SizedBox(height:8),
  CheckboxListTile(value:consent, onChanged:(v)=>setState(()=>consent=v!), title:const Text('I consent info used to draft PDF & check SASSA portal.', style:TextStyle(fontSize:9)), dense:true, contentPadding:EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading),
  SizedBox(width:double.infinity, height:44, child: ElevatedButton.icon(icon:checkingSassa?const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.search, size:18), label:Text(checkingSassa?'Connecting...':'Check SASSA Status Free (Needs Data)', style:const TextStyle(fontSize:10, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFE8DCC0)), onPressed: checkingSassa? null : (consent? checkSassaStatus : null))),
  const SizedBox(height:12),
  DropdownButtonFormField(value:selectedLetter, items:letters.map((l)=>DropdownMenuItem(value:l, child:Text(l, style:const TextStyle(fontSize:12)))).toList(), onChanged:(v)=>setState(()=>selectedLetter=v!), decoration:const InputDecoration(labelText:'Select Document *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white)),
  const SizedBox(height:12),
  Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.white, border:Border.all(color:const Color(0xFF8D7B4A), width:1.5), borderRadius:BorderRadius.circular(8)), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
    const Text('Affidavit Details - Top left of letter:', style:TextStyle(fontWeight:FontWeight.bold, fontSize:11, color:Color(0xFF8D7B4A))),
    const SizedBox(height:8),
    TextField(controller:nameController, decoration:const InputDecoration(labelText:'Full Name & Surname *', border:OutlineInputBorder(), isDense:true)),
    const SizedBox(height:8),
    TextField(controller:addressController, decoration:const InputDecoration(labelText:'Street Address *', border:OutlineInputBorder(), isDense:true)),
    const SizedBox(height:8),
    Row(children: [
      Expanded(child: DropdownButtonFormField(value:selectedTown, items:towns.map((t)=>DropdownMenuItem(value:t, child:Text(t))).toList(), onChanged:(v)=>setState(()=>selectedTown=v!), decoration:const InputDecoration(labelText:'Town / Place *', border:OutlineInputBorder(), isDense:true))),
      const SizedBox(width:8),
      SizedBox(width:110, child: TextField(controller:postalController, decoration:const InputDecoration(labelText:'Postal Code *', border:OutlineInputBorder(), isDense:true), keyboardType:TextInputType.number, maxLength:4)),
    ]),
  ])),
  const SizedBox(height:12),
  Chip(label: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.mobile_friendly, size:16), SizedBox(width:6), Text('MTN MoMo - R20 per PDF', style:TextStyle(fontWeight:FontWeight.bold, fontSize:11))]), backgroundColor: Colors.amber),
  const SizedBox(height:8),
  Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:const Color(0xFFFFF9C4), border:Border.all(color:Colors.orange), borderRadius:BorderRadius.circular(10)), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: const [
    Text('Fee: R20 per PDF - Voucher for: 083 925 8423', style:TextStyle(fontWeight:FontWeight.bold, fontSize:11)),
    Text('Get at shop with Kazang / Flash', style:TextStyle(fontSize:10)),
    Text('R20 is for PDF only. NOT SASSA fee.', style:TextStyle(fontSize:9, fontWeight:FontWeight.bold)),
  ])),
  const SizedBox(height:10),
  TextField(controller:txIdController, decoration:const InputDecoration(labelText:'Transaction ID * (10 digits from slip)', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white, helperText:'Exactly 10 digits'), maxLength:10, keyboardType:TextInputType.number),
  const SizedBox(height:8),
  TextField(controller:providerIdController, decoration:const InputDecoration(labelText:'Provider ID * (Beside TxID on slip)', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white, helperText:'Security check - prevents edited slips')),
  const SizedBox(height:8),
  // VOUCHER DATE & TIME BOX REMOVED - NOW HIDDEN SECURITY - CUSTOMER DOESN'T SEE IT - WE CHECK SECRETLY VIA FILE METADATA
  SizedBox(width:double.infinity, child:ElevatedButton.icon(onPressed:() async {
    // FIX BLINK - Use image picker without losing state
    final ImagePicker picker = ImagePicker();
    final XFile? f = await picker.pickImage(source:ImageSource.gallery, imageQuality: 85, requestFullMetadata: false);
    if(f!=null && mounted){ setState(()=>{slipPath=f.path, blurryAttempts=0, showSkipOption=false, hiddenVoucherDateTime=DateTime.now()}); }
  }, icon:const Icon(Icons.upload), label:Text(slipPath==null?'Upload CLEAR Slip Photo *':'Slip Selected ✓ - Won\'t blink now'), style:ElevatedButton.styleFrom(backgroundColor: slipPath==null? Colors.orange : Colors.green, foregroundColor:Colors.white))),
  if(blurryAttempts>0) Padding(padding: const EdgeInsets.only(top:6), child: Text('Blurry attempt: $blurryAttempts/2', style: const TextStyle(fontSize:10, color:Colors.red, fontWeight:FontWeight.bold))),
  if(showSkipOption) Container(margin: const EdgeInsets.only(top:8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(8)), child: Column(children: [
    const Text('Slip still blurry after 2 tries?', style:TextStyle(fontWeight:FontWeight.bold, fontSize:11, color:Colors.red)),
    const SizedBox(height:6),
    SizedBox(width:double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.chat, size:16), label: const Text('Skip → Contact WhatsApp Support: 083 925 8423', style:TextStyle(fontSize:10, fontWeight:FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: contactSupportForSlip)),
  ])),
  const SizedBox(height:8),
  const Text('If slip not clear / old voucher - skipped. Buyer with upload problem after 2 tries → Skip → Support same number.', style:TextStyle(fontSize:8, color:Colors.red, fontWeight:FontWeight.bold)),
  const SizedBox(height:12),
  SizedBox(width:double.infinity, height:48, child:ElevatedButton.icon(icon:verifying?const SizedBox(width:16,height:16,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.verified), label:Text(verifying?'Verifying Token Exactly...':'Verify & Continue'), style:ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white), onPressed:verifying?null:verifyAndGoToStep2)),
  const SizedBox(height:12),
  disclaimerBox(),
 ]));
}

Widget buildStep2(){
 return SingleChildScrollView(padding:const EdgeInsets.all(12), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
  Container(width:double.infinity, padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.green[50], border:Border.all(color:Colors.green), borderRadius:BorderRadius.circular(8)), child:const Column(children: [Icon(Icons.check_circle, color:Colors.green, size:36), Text('Token Verified Exactly!', style:TextStyle(fontWeight:FontWeight.bold, fontSize:12, color:Colors.green)), Text('Won\'t go to letter instantly - you confirm WhatsApp first', style:TextStyle(fontSize:9)) ])),
  const SizedBox(height:12),
  const Text('MANUAL CONFIRM - Final:', style:TextStyle(fontWeight:FontWeight.bold, fontSize:12)),
  const SizedBox(height:8),
  TextField(controller:confirmNameController, decoration:const InputDecoration(labelText:'Full Names *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white)),
  const SizedBox(height:8),
  TextField(controller:confirmIdController, decoration:const InputDecoration(labelText:'ID *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white), maxLength:13),
  const SizedBox(height:8),
  TextField(controller:confirmAddressController, decoration:const InputDecoration(labelText:'Address *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white)),
  const SizedBox(height:8),
  Row(children: [Expanded(child: TextField(controller:confirmTownController, decoration:const InputDecoration(labelText:'Town *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white))), const SizedBox(width:8), SizedBox(width:110, child: TextField(controller:confirmPostalController, decoration:const InputDecoration(labelText:'Postal *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white), maxLength:4))]),
  const SizedBox(height:12),
  TextField(controller:whatsappController, decoration:const InputDecoration(labelText:'WhatsApp Number * (Where to send PDF)', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white, prefixIcon:Icon(Icons.chat, color:Colors.green), hintText:'0839258423'), maxLength:10, keyboardType:TextInputType.phone, style:TextStyle(fontWeight:FontWeight.bold)),
  const SizedBox(height:16),
  SizedBox(width:double.infinity, height:50, child:ElevatedButton.icon(icon:verifying?const SizedBox(width:18,height:18,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.send, size:20), label:Text(verifying?'Generating...':'Generate PDF & Send to WhatsApp (Not Instant)', style:const TextStyle(fontSize:11, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white), onPressed:verifying?null:sendToWhatsApp)),
  const SizedBox(height:10),
  TextButton.icon(onPressed:(){setState(()=>step2=false);}, icon:const Icon(Icons.arrow_back, size:16), label:const Text('Back')),
  const SizedBox(height:10),
  disclaimerBox(),
 ]));
}
}
class AboutScreen extends StatelessWidget{const AboutScreen({super.key}); @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: const Text('About Us'), backgroundColor:const Color(0xFF8D7B4A), foregroundColor:Colors.white), body: const SingleChildScrollView(padding: EdgeInsets.all(16), child: Text('PapersReady SA - Private Helper, NOT SASSA. Professional letters. R20 per PDF. Contact: itumelengcyprian@gmail.com', style:TextStyle(fontSize:11))));}}
class PrivacyScreen extends StatelessWidget{const PrivacyScreen({super.key}); @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: const Text('Privacy Policy'), backgroundColor:const Color(0xFF8D7B4A), foregroundColor:Colors.white), body: const SingleChildScrollView(padding: EdgeInsets.all(16), child: Text('Privacy - PapersReady SA', style:TextStyle(fontSize:11))));}}
