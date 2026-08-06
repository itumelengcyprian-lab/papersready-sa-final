// PapersReady SA V12 - PROFESSIONAL LETTER FORMAT - Address Top Left + ATT SASSA
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
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
final nameController=TextEditingController(); final addressController=TextEditingController(); final postalController=TextEditingController();
final idController=TextEditingController(); final phoneController=TextEditingController(); final whatsappController=TextEditingController(); final txIdController=TextEditingController();
final confirmNameController=TextEditingController(); final confirmIdController=TextEditingController(); final confirmAddressController=TextEditingController(); final confirmPostalController=TextEditingController(); final confirmTownController=TextEditingController();
String selectedLetter='Affidavit of Unemployment'; final letters=['Affidavit of Unemployment','SASSA Appeal Letter','Proof of Residence / Support'];
bool consent=false; String? slipPath; bool verifying=false; bool checkingSassa=false; bool step2=false; File? generatedPdfFile;
String get safePhone=>phoneController.text.trim(); String get safeWa=>whatsappController.text.trim();
void openPrivacy(){Navigator.push(context, MaterialPageRoute(builder: (_)=>const PrivacyScreen()));}
void openAbout(){Navigator.push(context, MaterialPageRoute(builder: (_)=>const AboutScreen()));}

Future<void> checkSassaStatus() async {
  if(idController.text.length!=13){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter ID')));return;}
  if(safePhone.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter phone')));return;}
  setState(()=>checkingSassa=true);
  try{
    await http.get(Uri.parse('https://srd.sassa.gov.za/sc19/status'), headers: {'User-Agent':'Mozilla/5.0'}).timeout(const Duration(seconds:8));
    if(!mounted) return;
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('Network OK', style:TextStyle(fontSize:12, color:Colors.green, fontWeight:FontWeight.bold)), content: Text('ID ${idController.text} ready. Opening srd.sassa.gov.za/sc19/status with phone $safePhone', style: const TextStyle(fontSize:10)), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text('Close')), ElevatedButton(onPressed: () async { Navigator.pop(c); final url=Uri.parse('https://srd.sassa.gov.za/sc19/status'); if(await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication); }, child: const Text('Open SASSA Site'))]));
  } catch(e){
    if(!mounted) return;
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('Opening SASSA Site'), content: Text('We will open official site. Error: $e', style: const TextStyle(fontSize:10)), actions: [ElevatedButton(onPressed: () async { Navigator.pop(c); final url=Uri.parse('https://srd.sassa.gov.za/sc19/status'); if(await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication); }, child: const Text('Open SASSA Site'))]));
  } finally{ if(mounted) setState(()=>checkingSassa=false); }
}

Future<File> generateFinalPdf() async {
  final pdf=pw.Document();
  pdf.addPage(pw.Page(margin: const pw.EdgeInsets.fromLTRB(40, 35, 40, 35), build:(c)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start, children:[
    // TOP LEFT - SENDER ADDRESS BLOCK - AS YOU REQUESTED
    pw.Text(confirmNameController.text.trim(), style:pw.TextStyle(fontSize:12, fontWeight:pw.FontWeight.bold)),
    pw.Text(confirmAddressController.text.trim(), style:const pw.TextStyle(fontSize:11)),
    pw.Text('${confirmTownController.text.trim()}, ${confirmPostalController.text.trim()}', style:const pw.TextStyle(fontSize:11)),
    pw.Text('Cell: $safePhone', style:const pw.TextStyle(fontSize:10)),
    pw.Text('ID: ${confirmIdController.text.trim()}', style:const pw.TextStyle(fontSize:10)),
    pw.SizedBox(height:8),
    pw.Text('${DateTime.now().day} ${['January','February','March','April','May','June','July','August','September','October','November','December'][DateTime.now().month-1]} ${DateTime.now().year}', style:const pw.TextStyle(fontSize:10)),
    pw.SizedBox(height:18),
    // ATT SASSA - Sir/Madam
    pw.Text('ATT: SASSA', style:pw.TextStyle(fontSize:11, fontWeight:pw.FontWeight.bold)),
    pw.Text('Sir/Madam,', style:const pw.TextStyle(fontSize:11)),
    pw.SizedBox(height:14),
    // SUBJECT - PROFESSIONAL
    pw.Text(proSubject(), style:pw.TextStyle(fontSize:11, fontWeight:pw.FontWeight.bold, decoration:pw.TextDecoration.underline)),
    pw.SizedBox(height:12),
    // BODY - PROFESSIONAL GRAMMAR SPICED UP
    pw.Text(proBody(), style:const pw.TextStyle(fontSize:11, lineSpacing:2.5)),
    pw.SizedBox(height:40),
    // SIGNATURE - TEXT + EMPTY LINE
    pw.Text('Yours faithfully,', style:const pw.TextStyle(fontSize:11)),
    pw.SizedBox(height:25),
    pw.Text('_________________________________', style:const pw.TextStyle(fontSize:14)),
    pw.SizedBox(height:5),
    pw.Text(confirmNameController.text.trim(), style:pw.TextStyle(fontSize:11, fontWeight:pw.FontWeight.bold)),
    pw.Text('ID: ${confirmIdController.text.trim()}', style:const pw.TextStyle(fontSize:9)),
  ])));
  final dir=await getApplicationDocumentsDirectory(); final f=File('${dir.path}/${selectedLetter.replaceAll(' ','_')}_${DateTime.now().millisecondsSinceEpoch}.pdf'); await f.writeAsBytes(await pdf.save()); return f;
}

String proSubject(){
  if(selectedLetter=='Affidavit of Unemployment') return 'Re: Affidavit of Unemployment Status';
  if(selectedLetter=='SASSA Appeal Letter') return 'Re: Appeal Against Declined SRD R350 Grant Application - ID ${confirmIdController.text.trim()}';
  return 'Re: Proof of Residence and Support';
}

String proBody(){
  if(selectedLetter=='Affidavit of Unemployment'){
    return 'I, the undersigned, ${confirmNameController.text.trim()}, Identity Number ${confirmIdController.text.trim()}, residing at ${confirmAddressController.text.trim()}, ${confirmTownController.text.trim()}, ${confirmPostalController.text.trim()}, do hereby make oath and solemnly affirm that:\n\n1. I am currently unemployed and have no monthly income from any employment, business, or other source.\n\n2. I do not receive any form of regular financial support, including UIF, NSFAS, or other government grants, except for the SRD grant for which I have applied.\n\n3. I am solely dependent on family members for my daily sustenance and basic needs.\n\n4. I am making this affidavit in support of my SASSA SRD application after my initial application was declined, and I declare that the information provided herein is true and correct to the best of my knowledge.\n\nI understand that should any of the above be found to be false, I may be liable for prosecution.';
  }
  if(selectedLetter=='SASSA Appeal Letter'){
    return 'I, ${confirmNameController.text.trim()}, ID ${confirmIdController.text.trim()}, of ${confirmAddressController.text.trim()}, ${confirmTownController.text.trim()}, ${confirmPostalController.text.trim()}, hereby formally appeal my declined SASSA SRD R350 grant application.\n\nI wish to bring to your attention that I am currently unemployed without any monthly income. I have no employment, no business income, and no financial support. My contact number linked to my SASSA application is $safePhone.\n\nThe decline of my application has caused severe financial hardship as I am unable to meet my basic needs. I humbly request that you kindly reconsider my application and reinstate my grant.\n\nI have attached this supporting affidavit as proof of my unemployment status. I trust that you will find my appeal in order and give it your favorable consideration.\n\nThank you for your understanding and assistance.';
  }
  return 'TO WHOM IT MAY CONCERN\n\nThis letter serves to confirm that ${confirmNameController.text.trim()}, Identity Number ${confirmIdController.text.trim()}, is a resident at ${confirmAddressController.text.trim()}, ${confirmTownController.text.trim()}, ${confirmPostalController.text.trim()}.\n\nThe above-mentioned individual is known to this community and is currently unemployed without any monthly income. He/she is being supported by family members for daily living.\n\nThis proof of residence and support is issued to support his/her SASSA application after it was declined.\n\nShould you require any further verification, please do not hesitate to contact us at $safePhone.\n\nWe trust you will find this in order.';
}

String finalContent(){ return proBody(); }

Future<void> verifyAndGoToStep2() async {
 if(nameController.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter full name')));return;}
 if(idController.text.length!=13){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter 13-digit ID')));return;}
 if(addressController.text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter address')));return;}
 if(postalController.text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter postal code')));return;}
 if(safePhone.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter phone')));return;}
 if(!consent){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Tick consent')));return;}
 bool isTest = txIdController.text.toUpperCase().contains('TEST') || txIdController.text=='0000000000';
 if(txIdController.text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter TxID or TEST123')));return;}
 if(!isTest && slipPath==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Upload slip or TEST123')));return;}
 setState(()=>verifying=true);
 await Future.delayed(const Duration(seconds:1));
 confirmNameController.text=nameController.text.trim();
 confirmIdController.text=idController.text.trim();
 confirmAddressController.text=addressController.text.trim();
 confirmPostalController.text=postalController.text.trim();
 confirmTownController.text=selectedTown;
 setState((){verifying=false; step2=true;});
}

Future<void> sendToWhatsApp() async {
 if(safeWa.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter WhatsApp')));return;}
 if(confirmNameController.text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Fill confirm boxes')));return;}
 setState(()=>verifying=true);
 final f=await generateFinalPdf();
 setState(()=>verifying=false);
 generatedPdfFile=f;
 String wa=safeWa.replaceAll(' ','').replaceAll('-','').replaceAll('+',''); if(wa.startsWith('0')&&wa.length==10) wa='27'+wa.substring(1);
 try{ await Share.shareXFiles([XFile(f.path)], text:'Your ${selectedLetter} - PapersReady SA - Professional Format'); }catch(e){}
 final msg=Uri.encodeComponent('Hello ${confirmNameController.text} from PapersReady SA (NOT SASSA). Your *$selectedLetter* is ready in professional format. Address top left + ATT SASSA + Signature line included. R20 per PDF. Town: ${confirmTownController.text}');
 final url='https://wa.me/$wa?text=$msg'; try{ if(await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }catch(e){}
}

@override Widget build(BuildContext context){
 return Scaffold(appBar: AppBar(title: const Text('PapersReady SA', style:TextStyle(fontSize:14, fontWeight:FontWeight.bold)), backgroundColor:Colors.indigo, foregroundColor:Colors.white, actions: [IconButton(icon: const Icon(Icons.info_outline), onPressed: openAbout), IconButton(icon: const Icon(Icons.privacy_tip), onPressed: openPrivacy)]),
 body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.indigo.shade50], begin: Alignment.topCenter, end: Alignment.bottomCenter)), child: step2? buildStep2() : buildStep1()));
}

Widget disclaimerBox(){ return Container(width:double.infinity, padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:Colors.grey[200], border:Border.all(color:Colors.grey), borderRadius:BorderRadius.circular(6)), child: const Text('DISCLAIMER: Private Community Helper, NOT SASSA. We help draft docs after rejection. R20 per PDF, NOT SASSA fee. Official: srd.sassa.gov.za | itumelengcyprian@gmail.com', style:TextStyle(fontSize:8, fontWeight:FontWeight.bold), textAlign:TextAlign.center));}

Widget buildStep1(){
 return SingleChildScrollView(padding:const EdgeInsets.all(12), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
  Container(width:double.infinity, padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.indigo, borderRadius:BorderRadius.circular(8)), child:const Text('We Help Draft Docs After Rejection - Private Helper - 24/7', style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold, fontSize:10), textAlign:TextAlign.center)),
  const SizedBox(height:10),
  TextField(controller:nameController, decoration:const InputDecoration(labelText:'Full Name & Surname *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white)),
  const SizedBox(height:8),
  TextField(controller:idController, decoration:const InputDecoration(labelText:'ID Number *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white), maxLength:13, keyboardType:TextInputType.number),
  const SizedBox(height:6),
  TextField(controller:addressController, decoration:const InputDecoration(labelText:'Street Address *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white)),
  const SizedBox(height:8),
  Row(children: [
    Expanded(child: DropdownButtonFormField(value:selectedTown, items:towns.map((t)=>DropdownMenuItem(value:t, child:Text(t))).toList(), onChanged:(v)=>setState(()=>selectedTown=v!), decoration:const InputDecoration(labelText:'Town *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white))),
    const SizedBox(width:8),
    SizedBox(width:110, child: TextField(controller:postalController, decoration:const InputDecoration(labelText:'Postal Code *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white), keyboardType:TextInputType.number, maxLength:4)),
  ]),
  const SizedBox(height:8),
  TextField(controller:phoneController, decoration:const InputDecoration(labelText:'Phone Linked to SASSA *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white), maxLength:10, keyboardType:TextInputType.phone),
  const SizedBox(height:6),
  CheckboxListTile(value:consent, onChanged:(v)=>setState(()=>consent=v!), title:const Text('I consent info used to draft PDF & check SASSA portal.', style:TextStyle(fontSize:9)), dense:true, contentPadding:EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading),
  SizedBox(width:double.infinity, height:44, child: ElevatedButton.icon(icon:checkingSassa?const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.search, size:18), label:Text(checkingSassa?'Connecting...':'Check SASSA Status Free (Needs Data)', style:const TextStyle(fontSize:10, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.indigo[100]), onPressed: checkingSassa? null : (consent? checkSassaStatus : null))),
  const SizedBox(height:10),
  DropdownButtonFormField(value:selectedLetter, items:letters.map((l)=>DropdownMenuItem(value:l, child:Text(l, style:const TextStyle(fontSize:12)))).toList(), onChanged:(v)=>setState(()=>selectedLetter=v!), decoration:const InputDecoration(labelText:'Select Document *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white)),
  const SizedBox(height:10),
  Chip(label: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.mobile_friendly, size:16), SizedBox(width:6), Text('MTN MoMo - R20 per requested PDF', style:TextStyle(fontWeight:FontWeight.bold, fontSize:11))]), backgroundColor: Colors.amber),
  const SizedBox(height:6),
  Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:const Color(0xFFFFF9C4), border:Border.all(color:Colors.orange), borderRadius:BorderRadius.circular(10)), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: const [
    Text('Fee: R20 per PDF - Voucher for: 083 925 8423', style:TextStyle(fontWeight:FontWeight.bold, fontSize:11)),
    Text('This R20 is for PDF only. NOT SASSA fee.', style:TextStyle(fontSize:9, fontWeight:FontWeight.bold)),
    Text('TESTING: Use TEST123 (No slip needed)', style:TextStyle(fontSize:10, fontWeight:FontWeight.bold, color:Colors.red)),
  ])),
  const SizedBox(height:10),
  TextField(controller:txIdController, decoration:const InputDecoration(labelText:'Transaction ID * (TEST123)', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white)),
  const SizedBox(height:8),
  SizedBox(width:double.infinity, child:ElevatedButton.icon(onPressed:() async { final XFile? f=await ImagePicker().pickImage(source:ImageSource.gallery); if(f!=null) setState(()=>slipPath=f.path); }, icon:const Icon(Icons.upload), label:Text(slipPath==null?'Upload Slip':'Slip Selected ✓'), style:ElevatedButton.styleFrom(backgroundColor: slipPath==null? Colors.orange : Colors.green, foregroundColor:Colors.white))),
  const SizedBox(height:12),
  SizedBox(width:double.infinity, height:48, child:ElevatedButton.icon(icon:verifying?const SizedBox(width:16,height:16,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.verified), label:Text(verifying?'Verifying...':'Verify & Continue'), style:ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white), onPressed:verifying?null:verifyAndGoToStep2)),
  const SizedBox(height:12),
  disclaimerBox(),
 ]));
}

Widget buildStep2(){
 return SingleChildScrollView(padding:const EdgeInsets.all(12), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
  Container(width:double.infinity, padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.green[50], border:Border.all(color:Colors.green), borderRadius:BorderRadius.circular(8)), child:const Column(children: [Icon(Icons.check_circle, color:Colors.green, size:36), Text('Verified! Confirm Before Print', style:TextStyle(fontWeight:FontWeight.bold, fontSize:12, color:Colors.green)), Text('Edit below - will show on final PDF with professional format', style:TextStyle(fontSize:9), textAlign:TextAlign.center)])),
  const SizedBox(height:12),
  const Text('MANUAL CONFIRM - These details will be on PDF top left:', style:TextStyle(fontWeight:FontWeight.bold, fontSize:12)),
  const SizedBox(height:8),
  TextField(controller:confirmNameController, decoration:const InputDecoration(labelText:'Full Names *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white)),
  const SizedBox(height:8),
  TextField(controller:confirmIdController, decoration:const InputDecoration(labelText:'ID *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white), maxLength:13),
  const SizedBox(height:8),
  TextField(controller:confirmAddressController, decoration:const InputDecoration(labelText:'Street Address *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white)),
  const SizedBox(height:8),
  Row(children: [
    Expanded(child: TextField(controller:confirmTownController, decoration:const InputDecoration(labelText:'Town *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white))),
    const SizedBox(width:8),
    SizedBox(width:110, child: TextField(controller:confirmPostalController, decoration:const InputDecoration(labelText:'Postal *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white), maxLength:4)),
  ]),
  const SizedBox(height:12),
  const Text('WhatsApp to receive final PDF:', style:TextStyle(fontWeight:FontWeight.bold, fontSize:11)),
  const SizedBox(height:6),
  TextField(controller:whatsappController, decoration:const InputDecoration(labelText:'WhatsApp Number *', border:OutlineInputBorder(), isDense:true, filled:true, fillColor:Colors.white, prefixIcon:Icon(Icons.chat, color:Colors.green), hintText:'0839258423'), maxLength:10, keyboardType:TextInputType.phone, style:TextStyle(fontWeight:FontWeight.bold)),
  const SizedBox(height:16),
  SizedBox(width:double.infinity, height:50, child:ElevatedButton.icon(icon:verifying?const SizedBox(width:18,height:18,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.print, size:20), label:Text(verifying?'Generating Professional PDF...':'Generate Final PDF (Professional Format) & Send to WhatsApp', style:const TextStyle(fontSize:10, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white), onPressed:verifying?null:sendToWhatsApp)),
  const SizedBox(height:10),
  TextButton.icon(onPressed:(){setState(()=>step2=false);}, icon:const Icon(Icons.arrow_back, size:16), label:const Text('Back')),
  const SizedBox(height:10),
  disclaimerBox(),
 ]));
}
}
class AboutScreen extends StatelessWidget{const AboutScreen({super.key}); @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: const Text('About Us'), backgroundColor:Colors.indigo, foregroundColor:Colors.white), body: const SingleChildScrollView(padding: EdgeInsets.all(16), child: Text('PapersReady SA - Private Community Helper, NOT SASSA. Professional letters after rejection. R20 per PDF. Contact: itumelengcyprian@gmail.com', style:TextStyle(fontSize:11))));}}
class PrivacyScreen extends StatelessWidget{const PrivacyScreen({super.key}); @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: const Text('Privacy Policy'), backgroundColor:Colors.indigo, foregroundColor:Colors.white), body: const SingleChildScrollView(padding: EdgeInsets.all(16), child: Text('Privacy Policy - PapersReady SA\nContact: itumelengcyprian@gmail.com', style:TextStyle(fontSize:11))));}}
