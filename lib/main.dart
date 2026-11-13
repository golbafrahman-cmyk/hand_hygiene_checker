import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const HandHygieneApp());
enum Method { alcohol, soap }
enum Mark { pending, yes, no, unseen }

class Check {
  final String fa, en;
  Mark mark;
  Check(this.fa, this.en, [this.mark = Mark.pending]);
}

class HandHygieneApp extends StatefulWidget {
  const HandHygieneApp({super.key});
  @override
  State<HandHygieneApp> createState() => _HandHygieneAppState();
}

class _HandHygieneAppState extends State<HandHygieneApp> {
  bool en = false, confirmed = false, busy = false;
  Method method = Method.alcohol;
  XFile? video;
  final picker = ImagePicker();
  final name = TextEditingController();
  final personnelCode = TextEditingController();
  final ward = TextEditingController();
  final position = TextEditingController();
  final reviewer = TextEditingController();
  final duration = TextEditingController();
  final notes = TextEditingController();
  final watch = Stopwatch();
  Timer? ticker;
  List<Check> checks = [];
  List<Map<String, dynamic>> records = [];
  String t(String fa, String english) => en ? english : fa;
  int get scored => checks.where((c) => c.mark == Mark.yes || c.mark == Mark.no).length;
  int get passed => checks.where((c) => c.mark == Mark.yes).length;
  int get pending => checks.where((c) => c.mark == Mark.pending).length;
  int? get score => scored == 0 ? null : (100 * passed / scored).round();
  bool get canSave => name.text.trim().isNotEmpty && personnelCode.text.trim().isNotEmpty &&
      reviewer.text.trim().isNotEmpty && duration.text.trim().isNotEmpty && pending == 0;

  @override
  void initState() { super.initState(); loadChecks(); loadRecords(); }
  @override
  void dispose() {
    ticker?.cancel();
    for (final c in [name, personnelCode, ward, position, reviewer, duration, notes]) { c.dispose(); }
    super.dispose();
  }

  Future<void> loadRecords() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('assessment_records_v2');
    if (raw != null) {
      try { records = (jsonDecode(raw) as List).cast<Map<String, dynamic>>(); } catch (_) { records = []; }
      if (mounted) setState(() {});
    }
  }
  Future<void> persistRecords() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('assessment_records_v2', jsonEncode(records));
  }

  void loadChecks() {
    final fa = method == Method.alcohol
      ? ['استفاده از مقدار کافی محلول برای پوشاندن تمام سطوح دست','مالش کف دو دست به یکدیگر','مالش کف دست روی پشت دست مقابل و بالعکس با انگشتان درهم‌رفته','مالش کف دو دست با انگشتان درهم‌رفته','مالش پشت انگشتان به کف دست مقابل','مالش دورانی هر شست','مالش دورانی نوک انگشتان در کف دست مقابل','ادامه مالش تا خشک شدن کامل دست‌ها']
      : ['خیس کردن دست‌ها با آب','استفاده از مقدار کافی صابون','مالش کف دو دست به یکدیگر','مالش کف دست روی پشت دست مقابل و بالعکس با انگشتان درهم‌رفته','مالش کف دو دست با انگشتان درهم‌رفته','مالش پشت انگشتان به کف دست مقابل','مالش دورانی هر شست','مالش دورانی نوک انگشتان در کف دست مقابل','آبکشی کامل دست‌ها','خشک کردن با حوله یکبارمصرف','بستن شیر آب با حوله یکبارمصرف در صورت نیاز'];
    final enList = method == Method.alcohol
      ? ['Uses enough handrub to cover all hand surfaces','Rubs palm to palm','Rub palm over opposite dorsum and vice versa with fingers interlaced','Rubs palm to palm with fingers interlaced','Rubs backs of fingers against opposing palms','Rotational rubbing of each thumb','Rotational rubbing of fingertips in opposite palm','Continues rubbing until hands are completely dry']
      : ['Wets hands with water','Applies enough soap','Rubs palm to palm','Rub palm over opposite dorsum and vice versa with fingers interlaced','Rubs palm to palm with fingers interlaced','Rubs backs of fingers against opposing palms','Rotational rubbing of each thumb','Rotational rubbing of fingertips in opposite palm','Rinses hands thoroughly','Dries hands with a single-use towel','Uses towel to turn off tap when applicable'];
    checks = List.generate(fa.length, (i) => Check(fa[i], enList[i]));
    confirmed = false;
  }

  Future<void> pickVideo() async {
    final f = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
    if (f != null && mounted) setState(() { video = f; confirmed = false; });
  }
  String clock(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  void toggleWatch() {
    setState(() {
      if (watch.isRunning) { watch.stop(); ticker?.cancel(); }
      else { watch.start(); ticker = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); }); }
      duration.text = clock(watch.elapsed);
    });
  }
  void resetWatch() => setState(() { watch.stop(); watch.reset(); ticker?.cancel(); duration.clear(); });

  Map<String, dynamic> recordData() => {
    'id': DateTime.now().microsecondsSinceEpoch.toString(),
    'createdAt': DateTime.now().toIso8601String(),
    'name': name.text.trim(), 'personnelCode': personnelCode.text.trim(),
    'ward': ward.text.trim(), 'position': position.text.trim(),
    'reviewer': reviewer.text.trim(), 'method': method.name,
    'duration': duration.text.trim(), 'score': score,
    'passed': passed, 'scored': scored, 'notes': notes.text.trim(),
    'confirmed': confirmed, 'videoName': video?.name ?? '',
    'items': checks.map((c) => {'fa': c.fa, 'en': c.en, 'mark': c.mark.name}).toList(),
  };

  String reportText(Map<String, dynamic> r) {
    final b = StringBuffer('کارنامه ارزیابی بهداشت دست / HAND HYGIENE REPORT\n');
    b.writeln('نام آزمون‌شونده: ${r['name']}');
    b.writeln('کد پرسنلی: ${r['personnelCode']}');
    b.writeln('بخش: ${r['ward']}');
    b.writeln('سمت: ${r['position']}');
    b.writeln('تاریخ: ${r['createdAt']}');
    b.writeln('روش: ${r['method'] == 'alcohol' ? 'محلول الکلی' : 'آب و صابون'}');
    b.writeln('ارزیاب: ${r['reviewer']}');
    b.writeln('مدت کل اجرای بهداشت دست: ${r['duration']}');
    b.writeln('درصد انطباق موارد قابل مشاهده: ${r['score'] ?? '—'}%');
    b.writeln('موارد انجام‌شده: ${r['passed']} از ${r['scored']}');
    b.writeln('\nجزئیات چک‌لیست:');
    for (final item in (r['items'] as List)) {
      final mark = item['mark'] == 'yes' ? 'انجام شد' : item['mark'] == 'no' ? 'انجام نشد' : item['mark'] == 'unseen' ? 'قابل مشاهده نبود' : 'بررسی نشده';
      b.writeln('- ${item['fa']}: $mark');
    }
    b.writeln('\nنظر ارزیاب: ${r['notes']}');
    b.writeln('تأیید ارزیاب: ${r['confirmed'] == true ? 'بله' : 'خیر'}');
    b.writeln('\nتوجه: این درصد خلاصه چک‌لیست مشاهده انسانی است و نمره رسمی WHO یا نمره اعتبارسنجی‌شده هوش مصنوعی نیست.');
    return b.toString();
  }

  Future<void> saveAssessment() async {
    if (!canSave) return;
    final r = recordData();
    records.insert(0, r);
    await persistRecords();
    if (!mounted) return;
    setState(() {});
    await shareReport(r);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('ارزیابی در سوابق ذخیره شد.','Assessment saved to history.'))));
  }

  Future<void> shareReport(Map<String, dynamic> r) async {
    final dir = await getTemporaryDirectory();
    final safe = (r['personnelCode'] as String).replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/hand_hygiene_report_$safe.txt');
    await file.writeAsString(reportText(r), flush: true);
    await Share.shareXFiles([XFile(file.path)], text: t('کارنامه ارزیابی بهداشت دست','Hand hygiene assessment report'));
  }

  Future<void> exportBackup() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hand_hygiene_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonEncode({'app':'Hand Hygiene AI','version':2,'exportedAt':DateTime.now().toIso8601String(),'records':records}), flush: true);
    await Share.shareXFiles([XFile(file.path)], text: t('نسخه پشتیبان سوابق ارزیابی','Hand hygiene assessment backup'));
  }

  Future<void> importBackup() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
    if (result == null || result.files.single.bytes == null) return;
    try {
      final data = jsonDecode(utf8.decode(result.files.single.bytes!)) as Map<String, dynamic>;
      final incoming = (data['records'] as List).cast<Map<String, dynamic>>();
      final existing = records.map((e) => e['id'].toString()).toSet();
      for (final r in incoming) { if (!existing.contains(r['id'].toString())) records.add(r); }
      records.sort((a,b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      await persistRecords();
      if (mounted) { setState(() {}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('بازیابی نسخه پشتیبان انجام شد.','Backup restored.')))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('فایل پشتیبان معتبر نیست.','Invalid backup file.'))));
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'Hand Hygiene AI',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E8B)), scaffoldBackgroundColor: const Color(0xFFF3F6F9)),
    home: Directionality(textDirection: en ? TextDirection.ltr : TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: Text(t('Hand Hygiene AI | ارزیابی بهداشت دست','Hand Hygiene AI | Review')),
        actions: [TextButton(onPressed: () => setState(() => en = !en), child: Text(en ? 'فارسی' : 'English')),
          PopupMenuButton<String>(onSelected: (v) => v == 'export' ? exportBackup() : v == 'import' ? importBackup() : showHistory(),
            itemBuilder: (_) => [PopupMenuItem(value:'history', child: Text(t('سوابق و کارنامه‌ها','History & reports'))), PopupMenuItem(value:'export', child: Text(t('تهیه نسخه پشتیبان','Export backup'))), PopupMenuItem(value:'import', child: Text(t('بازیابی نسخه پشتیبان','Restore backup')))])]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _hero(), const SizedBox(height: 12), _personCard(), const SizedBox(height: 12), _methodCard(), const SizedBox(height: 12),
        _videoCard(), const SizedBox(height: 12), _durationCard(), const SizedBox(height: 12),
        _reviewerCard(), const SizedBox(height: 12), _checklistCard(), const SizedBox(height: 12),
        _notesCard(), const SizedBox(height: 12), _resultCard(), const SizedBox(height: 12), _warning(), const SizedBox(height: 24),
      ]),
    )),
  );

  Widget _hero() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF087E8B), Color(0xFF145DA0)]), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.health_and_safety, color: Colors.white, size: 34), const SizedBox(height: 10),
      Text(t('سامانه ارزیابی بهداشت دست','Hand Hygiene Review'), style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
      Text(t('ثبت آزمون‌شونده، ارزیابی و صدور کارنامه','Participant registration, assessment and report cards'), style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 8), const Wrap(spacing: 8, children: [Chip(label: Text('Android')), Chip(label: Text('iOS')), Chip(label: Text('FA / EN'))])
    ]));

  Widget _personCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۱. مشخصات فرد آزمون‌شونده','1. Participant details'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    _field(name,t('نام و نام خانوادگی','Full name')), _field(personnelCode,t('کد پرسنلی','Personnel ID')),
    _field(ward,t('بخش محل خدمت','Department / ward')), _field(position,t('سمت شغلی','Job title'))
  ])));

  Widget _field(TextEditingController c, String label) => Padding(padding: const EdgeInsets.only(top:10), child: TextField(controller:c, onChanged: (_) => setState((){}), decoration: InputDecoration(labelText:label, border:const OutlineInputBorder(), isDense:true)));

  Widget _methodCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۲. روش بهداشت دست','2. Hand hygiene method'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    RadioListTile<Method>(contentPadding: EdgeInsets.zero, value: Method.alcohol, groupValue: method, onChanged: (v) => setState(() { method=v!; loadChecks(); }), title: Text(t('محلول الکلی','Alcohol handrub'))),
    RadioListTile<Method>(contentPadding: EdgeInsets.zero, value: Method.soap, groupValue: method, onChanged: (v) => setState(() { method=v!; loadChecks(); }), title: Text(t('آب و صابون','Soap and water')))
  ])));

  Widget _videoCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۳. فیلم اجرای آزمون','3. Procedure video'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    OutlinedButton.icon(onPressed: pickVideo, icon: const Icon(Icons.video_library), label: Text(t('انتخاب فیلم از گوشی','Select video'))),
    if (video != null) ListTile(leading: const Icon(Icons.movie), title: Text(video!.name, maxLines:2, overflow:TextOverflow.ellipsis),
      subtitle: Text(t('فیلم انتخاب شده؛ تحلیل هوشمند هنوز فعال نشده است','Video selected; AI analysis is not implemented yet')))
  ])));

  Widget _durationCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۴. مدت کل اجرای بهداشت دست','4. Total hand hygiene duration'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    Text(t('زمان از شروع اولین حرکت تا پایان آخرین مرحله؛ زمان‌سنج را هم‌زمان با اجرای فرد روشن کنید.','Elapsed time from the first action to the final step; start the stopwatch when the participant begins.')),
    Text('${t('بازه راهنمای مرجع','Reference range')}: ${method == Method.alcohol ? '20–30 s' : '40–60 s'}'),
    Row(children:[Expanded(child:Text(watch.isRunning?clock(watch.elapsed):(duration.text.isEmpty?'00:00':duration.text),style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold))),
      FilledButton.icon(onPressed:toggleWatch,icon:Icon(watch.isRunning?Icons.pause:Icons.play_arrow),label:Text(watch.isRunning?t('توقف','Stop'):t('شروع','Start'))),
      IconButton(onPressed:resetWatch,icon:const Icon(Icons.restart_alt))]),
    TextField(controller:duration,onChanged:(_)=>setState((){}),decoration:InputDecoration(labelText:t('مدت کل (دقیقه:ثانیه)، در صورت ثبت دستی','Total duration (mm:ss), manual entry if needed'),border:const OutlineInputBorder(),isDense:true))
  ])));

  Widget _reviewerCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۵. مشخصات ارزیاب','5. Reviewer details'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), _field(reviewer,t('نام یا کد ارزیاب','Reviewer name or ID'))
  ])));

  Widget _checklistCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۶. چک‌لیست مشاهده انسانی','6. Human observation checklist')),
    Text(t('برای هر مورد وضعیت را انتخاب کنید؛ موارد غیرقابل مشاهده از محاسبه درصد حذف می‌شوند.','Mark each item; not-observable items are excluded from the percentage.')),
    ...List.generate(checks.length,(i){final c=checks[i];return Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('${i+1}. ${en?c.en:c.fa}',style:const TextStyle(fontWeight:FontWeight.w600)),
      Wrap(spacing:4,children:[_mark(i,Mark.yes,t('انجام شد','Done'),Colors.green),_mark(i,Mark.no,t('انجام نشد','Missed'),Colors.red),_mark(i,Mark.unseen,t('قابل مشاهده نیست','Not observable'),Colors.blueGrey),_mark(i,Mark.pending,t('پاک‌کردن','Clear'),Colors.grey)])
    ]));})
  ])));

  Widget _mark(int i,Mark m,String label,Color color)=>ChoiceChip(label:Text(label,style:const TextStyle(fontSize:11)),selected:checks[i].mark==m,onSelected:(_)=>setState(()=>{checks[i].mark=m;confirmed=false;}),selectedColor:color.withOpacity(.18));

  Widget _notesCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Text(t('۷. بازخورد و یادداشت ارزیاب','7. Reviewer feedback')),
    TextField(controller:notes,maxLines:3,onChanged:(_)=>setState(()=>confirmed=false),decoration:InputDecoration(hintText:t('نقاط قوت، موارد نیازمند آموزش و پیشنهاد اصلاحی','Strengths, training needs and recommendations'),border:const OutlineInputBorder()))
  ])));

  Widget _resultCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Text(t('۸. کارنامه و صدور گزارش','8. Report card and report'),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
    Row(children:[Text(score==null?'—':'$score%',style:const TextStyle(fontSize:34,fontWeight:FontWeight.bold,color:Color(0xFF087E8B))),const SizedBox(width:12),Expanded(child:Text(t('درصد انطباق موارد قابل مشاهده؛ نمره رسمی WHO نیست.','Observed-item adherence; not an official WHO score.')))]),
    Text('${t('انجام‌شده','Done')}: $passed | ${t('قابل ارزیابی','Scored')}: $scored | ${t('باقی‌مانده','Pending')}: $pending'),
    const SizedBox(height:10),
    FilledButton.icon(onPressed:canSave?saveAssessment:null,icon:const Icon(Icons.save_alt),label:Text(t('ذخیره ارزیابی و صدور کارنامه','Save assessment & issue report'))),
    OutlinedButton.icon(onPressed:showHistory,icon:const Icon(Icons.history),label:Text(t('مشاهده سوابق و کارنامه‌ها','View history & reports')))
  ])));

  Future<void> showHistory() async {
    await showModalBottomSheet(context:context,isScrollControlled:true,builder:(ctx)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.8,child:Column(children:[
      Padding(padding:const EdgeInsets.all(16),child:Row(children:[Expanded(child:Text(t('سوابق ارزیابی','Assessment history'),style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),IconButton(onPressed:exportBackup,icon:const Icon(Icons.backup)),IconButton(onPressed:importBackup,icon:const Icon(Icons.restore))])),
      Expanded(child:records.isEmpty?Center(child:Text(t('هنوز گزارشی ثبت نشده است.','No reports saved yet.'))):ListView.builder(itemCount:records.length,itemBuilder:(c,i){final r=records[i];return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text('${r['name']} (${r['personnelCode']})'),subtitle:Text('${r['ward']} | ${r['createdAt']} | ${r['score']??'—'}%'),trailing:IconButton(icon:const Icon(Icons.share),onPressed:()=>shareReport(r)));}))
    ])))));
  }

  Widget _warning() => Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFFFF3D6),borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFFE6C56A))),
    child:Text(t('محدودیت مهم: این نسخه هنوز تحلیل خودکار فیلم با هوش مصنوعی ندارد. ارزیابی چک‌لیست توسط ارزیاب انسانی انجام می‌شود. نسخه پشتیبان شامل اطلاعات آزمون‌شونده و نتایج است؛ آن را در محل امن نگهداری کنید.','Important: AI video analysis is not yet available. Checklist scoring is performed by a human reviewer. Backups contain participant details and results; store them securely.'),style:const TextStyle(fontSize:13)));
}
