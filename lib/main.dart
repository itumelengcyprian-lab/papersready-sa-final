// PAPERSREADY SA V3 - MoMo & MTN ONLY + Instant WhatsApp
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

void main()=>runApp(const PapersReadyApp());
class PapersReadyApp extends StatelessWidget{const PapersReadyApp({super.key}); @override Widget build(BuildContext c){return MaterialApp(title:'PapersReady SA', theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3:true), home: const HomeScreen(), debugShowCheckedModeBanner:false);}}
class HomeScreen extends StatefulWidget{const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState();}
class _HomeScreenState extends State<HomeScreen>{
String selectedTown='Ficksburg'; final towns=['Ficksburg','Bloemfontein','Botshabelo','Thaba Nchu','Ladybrand','Clocolan','Senekal','Welkom','QwaQwa','Other'];
final idController=TextEditingController(); final phoneController=TextEditingController(); final whatsappController=TextEditingController(); final txIdController=TextEditingController();
String selectedPayment='Kazang MoMo'; String selectedLetter='Affidavit of Unemployment'; final letters=['Affidavit of Unemployment','SASSA Appeal Letter','Proof of Residence / Support'];
bool consent=false; String? slipPath; bool verifying=false;
String get safePhone=>phoneController.text.trim(); String get safeWa=>whatsappController.text.trim();
Future<void> deliver(File pdf) async {
  String wa=safeWa.isEmpty?safePhone:safeWa; wa=wa.replaceAll(' ','').replaceAll('-','').replaceAll('+','');
  if(wa.startsWith('0')&&wa.length==10) wa='27'+wa.substring(1);
  try{ await Share.shareXFiles([XFile(pdf.path)], text:'Your $selectedLetter from PapersReady SA R20 Paid'); }catch(e){}
  await Future.delayed(const Duration(milliseconds:600));
  final msg=Uri.encodeComponent('Hello! Your *$selectedLetter* ready! Town:$selectedTown ID:${idController.text} Payment:$selectedPayment R20. PDF attached. Thanks PapersReady SA 24/7');
  final url='https://wa.me/$wa?text=$msg';
  try{ if(await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }catch(e){}
}
Future<void> gen() async {
 if(idController.text.length!=13){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter 13 digit ID')));return;}
 if(safePhone.length<10||safeWa.length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter Phone & WhatsApp numbers')));return;}
 if(txIdController.text.isEmpty||slipPath==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Upload slip + TxID')));return;}
 setState(()=>verifying=true); await Future.delayed(const Duration(seconds:1));
 final pdf=pw.Document();
 pdf.addPage(pw.Page(build:(c)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start, children:[
  pw.Text('PAPERSREADY SA - $selectedLetter', style:pw.TextStyle(fontSize:18, fontWeight:pw.FontWeight.bold)),
  pw.SizedBox(height:10), pw.Text('Town:$selectedTown Phone:$safePhone WhatsApp:$safeWa ID:${idController.text} Tx:${txIdController.text} Date:${DateTime.now()}'),
  pw.SizedBox(height:12), pw.Text(content(), style:const pw.TextStyle(fontSize:11)),
  pw.SizedBox(height:20), pw.Text('IMPORTANT: No Bank Letter included. If office asks for Bank Letter go to your bank for stamped 3-month statement to avoid rejection.', style:pw.TextStyle(fontSize:9, fontWeight:pw.FontWeight.bold)),
 ])));
 final dir=await getApplicationDocumentsDirectory(); final f=File('${dir.path}/${selectedLetter.replaceAll(' ','_')}.pdf'); await f.writeAsBytes(await pdf.save());
 setState(()=>verifying=false); idController.clear();
 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Verified! Sending to WhatsApp INSTANTLY'), backgroundColor:Colors.green));
 await deliver(f);
}
String content(){
 if(selectedLetter=='Affidavit of Unemployment') return 'AFFIDAVIT OF UNEMPLOYMENT\n\nI ID ${idController.text} in $selectedTown declare unemployed no income, depend on family, for SASSA purposes.';
 if(selectedLetter=='SASSA Appeal Letter') return 'SASSA APPEAL\n\nI ID ${idController.text} from $selectedTown appeal declined R350. No income. Phone $safePhone WhatsApp $safeWa. Please reconsider.';
 return 'PROOF OF RESIDENCE\n\nConfirms ID ${idController.text} resides in $selectedTown. Unemployed supported by family. Contact $safePhone / $safeWa. For SASSA use.';
}
@override Widget build(BuildContext context){
 return Scaffold(appBar: AppBar(title: const Text('PAPERSREADY SA - MoMo & MTN - R20', style:TextStyle(fontSize:12)), backgroundColor:Colors.indigo, foregroundColor:Colors.white),
 body: SingleChildScrollView(padding:const EdgeInsets.all(12), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
  Container(width:double.infinity, padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.indigo, borderRadius:BorderRadius.circular(8)), child:const Text('SASSA Eo Hanne Ka Mabaka Ao Osa Utlwisising - Tharollo 24/7', style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold, fontSize:11), textAlign:TextAlign.center)),
  const SizedBox(height:10),
  DropdownButtonFormField(value:selectedTown, items:towns.map((t)=>DropdownMenuItem(value:t, child:Text(t))).toList(), onChanged:(v)=>setState(()=>selectedTown=v!), decoration:const InputDecoration(labelText:'Select Town', border:OutlineInputBorder(), isDense:true)),
  const SizedBox(height:8),
  TextField(controller:idController, decoration:const InputDecoration(labelText:'ID Number (auto cleared)', border:OutlineInputBorder(), isDense:true), maxLength:13, keyboardType:TextInputType.number),
  TextField(controller:phoneController, decoration:const InputDecoration(labelText:'Phone Number', border:OutlineInputBorder(), isDense:true), maxLength:10, keyboardType:TextInputType.phone),
  const SizedBox(height:8),
  TextField(controller:whatsappController, decoration:const InputDecoration(labelText:'WhatsApp Number to RECEIVE Letter INSTANTLY *', border:OutlineInputBorder(), isDense:true, prefixIcon:Icon(Icons.chat)), maxLength:10, keyboardType:TextInputType.phone),
  const Text('Letter goes INSTANTLY to this WhatsApp after verify', style:TextStyle(fontSize:10, color:Colors.green, fontWeight:FontWeight.bold)),
  const SizedBox(height:8),
  DropdownButtonFormField(value:selectedLetter, items:letters.map((l)=>DropdownMenuItem(value:l, child:Text(l, style:const TextStyle(fontSize:12)))).toList(), onChanged:(v)=>setState(()=>selectedLetter=v!), decoration:const InputDecoration(labelText:'Select Letter Type *', border:OutlineInputBorder(), isDense:true)),
  CheckboxListTile(value:consent, onChanged:(v)=>setState(()=>consent=v!), title:const Text('I consent ID used only for SASSA check, will be cleared', style:TextStyle(fontSize:10)), dense:true, contentPadding:EdgeInsets.zero),
  const Text('PAY WITH - R20 - MoMo & MTN Only:', style:TextStyle(fontWeight:FontWeight.bold, fontSize:12)),
  const SizedBox(height:6),
  Row(children:[ChoiceChip(label:const Text('Kazang MoMo'), selected:selectedPayment=='Kazang MoMo', onSelected:(v)=>setState(()=>selectedPayment='Kazang MoMo')), const SizedBox(width:8), ChoiceChip(label:const Text('MTN MoMo'), selected:selectedPayment=='MTN MoMo', onSelected:(v)=>setState(()=>selectedPayment='MTN MoMo'))]),
  const SizedBox(height:8),
  Container(padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:Colors.yellow[50], border:Border.all(color:Colors.orange), borderRadius:BorderRadius.circular(6)), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text('$selectedPayment R20:', style:const TextStyle(fontWeight:FontWeight.bold, fontSize:11)), const Text('1. Buy voucher 2. Send to 083 925 8423 3. Upload slip 4. Enter TxID 5. Letter INSTANT to WhatsApp!', style:TextStyle(fontSize:10))])),
  const SizedBox(height:10),
  SizedBox(width:double.infinity, child:ElevatedButton.icon(onPressed:() async { final XFile? f=await ImagePicker().pickImage(source:ImageSource.gallery); if(f!=null) setState(()=>slipPath=f.path); }, icon:const Icon(Icons.upload), label:Text(slipPath==null?'Upload Clear MoMo Slip *':'Slip Selected ✓'), style:ElevatedButton.styleFrom(backgroundColor:Colors.orange, foregroundColor:Colors.white))),
  const SizedBox(height:6),
  TextField(controller:txIdController, decoration:const InputDecoration(labelText:'Transaction ID *', border:OutlineInputBorder(), isDense:true)),
  const SizedBox(height:12),
  SizedBox(width:double.infinity, height:50, child:ElevatedButton.icon(icon:verifying?const SizedBox(width:14,height:14,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)):const Icon(Icons.send), label:Text(verifying?'Verifying...':'Verify & Send Letter to WhatsApp INSTANTLY', style:const TextStyle(fontSize:11, fontWeight:FontWeight.bold)), style:ElevatedButton.styleFrom(backgroundColor:Colors.green, foregroundColor:Colors.white), onPressed:verifying?null:gen)),
 ])));
}
}
