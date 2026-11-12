import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const HandHygieneApp());
enum Method { alcohol, soap }
enum Mark { pending, yes, no, unseen }

class Check {
  final String fa, en;
  Mark mark = Mark.pending;
  Check(this.fa, this.en);
}

class HandHygieneApp extends StatefulWidget {
  const HandHygieneApp({super.key});
  @override
  State<HandHygieneApp> createState() => _HandHygieneAppState();
}

class _HandHygieneAppState extends State<HandHygieneApp> {
  bool en = false, confirmed = false;
  Method method = Method.alcohol;
  XFile? video;
  final picker = ImagePicker();
  final reviewer = TextEditingController();
  final duration = TextEditingController();
  final notes = TextEditingController();
  final watch = Stopwatch();
  Timer? ticker;
  List<Check> checks = [];

  String t(String fa, String english) => en ? english : fa;
  int get scored => checks.where((c) => c.mark == Mark.yes || c.mark == Mark.no).length;
  int get passed => checks.where((c) => c.mark == Mark.yes).length;
  int get pending => checks.where((c) => c.mark == Mark.pending).length;
  int? get score => scored == 0 ? null : (100 * passed / scored).round();
  bool get canConfirm => video != null && reviewer.text.trim().isNotEmpty &&
      duration.text.trim().isNotEmpty && pending == 0;

  @override
  void initState() { super.initState(); loadChecks(); }
  @override
  void dispose() {
    ticker?.cancel(); reviewer.dispose(); duration.dispose(); notes.dispose(); super.dispose();
  }

  void loadChecks() {
    final fa = method == Method.alcohol
      ? ['استفاده از مقدار کافی محلول برای پوشاندن تمام سطوح دست','مالش کف دو دست به یکدیگر','مالش کف دست روی پشت دست مقابل و بالعکس با انگشتان درهم‌رفته','مالش کف دو دست با انگشتان درهم‌رفته','مالش پشت انگشتان به کف دست مقابل','مالش دورانی هر شست','مالش دورانی نوک انگشتان در کف دست مقابل','ادامه مالش تا خشک شدن کامل دست‌ها']
      : ['خیس کردن دست‌ها با آب','استفاده از مقدار کافی صابون','مالش کف دو دست به یکدیگر','مالش کف دست روی پشت دست مقابل و بالعکس با انگشتان درهم‌رفته','مالش کف دو دست با انگشتان درهم‌رفته','مالش پشت انگشتان به کف دست مقابل','مالش دورانی هر شست','مالش دورانی نوک انگشتان در کف دست مقابل','آبکشی کامل دست‌ها','خشک کردن با حوله یکبارمصرف','بستن شیر آب با حوله یکبارمصرف در صورت نیاز'];
    final english = method == Method.alcohol
      ? ['Uses enough handrub to cover all hand surfaces','Rubs palm to palm','Rub palm over opposite dorsum and vice versa with fingers interlaced','Rubs palm to palm with fingers interlaced','Rubs backs of fingers against opposing palms','Rotational rubbing of each thumb','Rotational rubbing of fingertips in opposite palm','Continues rubbing until hands are completely dry']
      : ['Wets hands with water','Applies enough soap','Rubs palm to palm','Rub palm over opposite dorsum and vice versa with fingers interlaced','Rubs palm to palm with fingers interlaced','Rubs backs of fingers against opposing palms','Rotational rubbing of each thumb','Rotational rubbing of fingertips in opposite palm','Rinses hands thoroughly','Dries hands with a single-use towel','Uses towel to turn off tap when applicable'];
    checks = List.generate(fa.length, (i) => Check(fa[i], english[i]));
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

  String makeReport() {
    final b = StringBuffer('HAND HYGIENE REVIEW / گزارش ارزیابی بهداشت دست\n');
    b.writeln('${t('روش','Method')}: ${method == Method.alcohol ? t('محلول الکلی','Alcohol handrub') : t('آب و صابون','Soap and water')}');
    b.writeln('${t('ارزیاب','Reviewer')}: ${reviewer.text}');
    b.writeln('${t('مدت','Duration')}: ${duration.text}');
    b.writeln('${t('درصد انطباق موارد قابل مشاهده','Observed-item adherence')}: ${score == null ? 'N/A' : '$score%'}');
    b.writeln('${t('موارد انجام‌شده','Passed')}: $passed / $scored');
    for (var i = 0; i < checks.length; i++) {
      final c = checks[i];
      final m = c.mark == Mark.yes ? 'YES' : c.mark == Mark.no ? 'NO' : c.mark == Mark.unseen ? 'NOT OBSERVABLE' : 'NOT REVIEWED';
      b.writeln('${i + 1}. ${en ? c.en : c.fa}: $m');
    }
    if (notes.text.trim().isNotEmpty) b.writeln('${t('یادداشت','Notes')}: ${notes.text}');
    b.writeln('Human review: ${confirmed ? 'CONFIRMED' : 'DRAFT'}');
    b.writeln('Prototype checklist summary only; not a validated WHO score. AI video analysis is not enabled.');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Hand Hygiene AI',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E8B)), scaffoldBackgroundColor: const Color(0xFFF3F6F9)),
    home: Directionality(textDirection: en ? TextDirection.ltr : TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: Text(t('Hand Hygiene AI | ارزیابی بهداشت دست','Hand Hygiene AI | Review')),
        actions: [TextButton(onPressed: () => setState(() => en = !en), child: Text(en ? 'فارسی' : 'English'))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _hero(), const SizedBox(height: 12), _methodCard(), const SizedBox(height: 12),
        _videoCard(), const SizedBox(height: 12), _durationCard(), const SizedBox(height: 12),
        _reviewerCard(), const SizedBox(height: 12), _checklistCard(), const SizedBox(height: 12),
        _notesCard(), const SizedBox(height: 12), _resultCard(), const SizedBox(height: 12),
        _warning(), const SizedBox(height: 24),
      ]),
    )),
  );

  Widget _hero() => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF087E8B), Color(0xFF145DA0)]), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.health_and_safety, color: Colors.white, size: 34), const SizedBox(height: 10),
      Text(t('سامانه ارزیابی بهداشت دست','Hand Hygiene Review'), style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
      Text(t('ثبت فیلم و ارزیابی با چک‌لیست انسانی','Video intake and human checklist assessment'), style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 8), const Wrap(spacing: 8, children: [Chip(label: Text('Android')), Chip(label: Text('iOS')), Chip(label: Text('FA / EN'))])
    ]));

  Widget _methodCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۱. روش بهداشت دست','1. Hand hygiene method'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    RadioListTile<Method>(contentPadding: EdgeInsets.zero, value: Method.alcohol, groupValue: method,
      onChanged: (v) => setState(() { method = v!; loadChecks(); }),
      title: Text(t('محلول الکلی (۲۰ تا ۳۰ ثانیه)','Alcohol handrub (20–30 seconds)'))),
    RadioListTile<Method>(contentPadding: EdgeInsets.zero, value: Method.soap, groupValue: method,
      onChanged: (v) => setState(() { method = v!; loadChecks(); }),
      title: Text(t('آب و صابون (۴۰ تا ۶۰ ثانیه)','Soap and water (40–60 seconds)')))
  ])));

  Widget _videoCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۲. فیلم اجرا','2. Procedure video'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    OutlinedButton.icon(onPressed: pickVideo, icon: const Icon(Icons.video_library), label: Text(t('انتخاب فیلم از گوشی','Select video from device'))),
    if (video != null) ListTile(leading: const Icon(Icons.movie, color: Color(0xFF087E8B)),
      title: Text(video!.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(t('انتخاب شده؛ تحلیل خودکار انجام نشده است','Selected; no automatic analysis performed')),
      trailing: IconButton(onPressed: () => setState(() { video = null; confirmed = false; }), icon: const Icon(Icons.close)))
  ])));

  Widget _durationCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۳. مدت اجرا','3. Procedure duration'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    Text('${t('بازه راهنمای مرجع','Reference duration')}: ${method == Method.alcohol ? '20–30 s' : '40–60 s'}'),
    Row(children: [Expanded(child: Text(watch.isRunning ? clock(watch.elapsed) : (duration.text.isEmpty ? '00:00' : duration.text),
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
      FilledButton.icon(onPressed: toggleWatch, icon: Icon(watch.isRunning ? Icons.pause : Icons.play_arrow),
        label: Text(watch.isRunning ? t('توقف','Stop') : t('شروع','Start'))),
      IconButton(onPressed: resetWatch, icon: const Icon(Icons.restart_alt))]),
    TextField(controller: duration, decoration: InputDecoration(labelText: t('یا مدت را دستی وارد کنید (مثلاً 00:25)','Or enter duration manually (e.g. 00:25)'), border: const OutlineInputBorder()),
      onChanged: (_) => setState(() {}))
  ])));

  Widget _reviewerCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۴. مشخصات ارزیاب','4. Reviewer details'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    TextField(controller: reviewer, decoration: InputDecoration(labelText: t('نام یا کد ارزیاب','Reviewer name or ID'), border: const OutlineInputBorder()),
      onChanged: (_) => setState(() => confirmed = false))
  ])));

  Widget _checklistCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۵. چک‌لیست مشاهده','5. Observation checklist'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    Text(t('برای هر مورد وضعیت را انتخاب کنید. موارد غیرقابل مشاهده از درصد حذف می‌شوند.','Choose a status for each item. Not-observable items are excluded from the percentage.')),
    ...List.generate(checks.length, (i) {
      final c = checks[i];
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${i + 1}. ${en ? c.en : c.fa}', style: const TextStyle(fontWeight: FontWeight.w600)),
        Wrap(spacing: 4, children: [
          _mark(i, Mark.yes, t('انجام شد','Done'), Colors.green),
          _mark(i, Mark.no, t('انجام نشد','Missed'), Colors.red),
          _mark(i, Mark.unseen, t('قابل مشاهده نیست','Not observable'), Colors.blueGrey),
          _mark(i, Mark.pending, t('پاک‌کردن','Clear'), Colors.grey),
        ])
      ]));
    })
  ])));

  Widget _mark(int i, Mark m, String label, Color color) => ChoiceChip(
    label: Text(label, style: const TextStyle(fontSize: 11)), selected: checks[i].mark == m,
    onSelected: (_) => setState(() { checks[i].mark = m; confirmed = false; }),
    selectedColor: color.withOpacity(.18));

  Widget _notesCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۶. یادداشت ارزیاب','6. Reviewer notes'), style: const TextStyle(fontWeight: FontWeight.bold)),
    TextField(controller: notes, maxLines: 3, decoration: InputDecoration(hintText: t('توضیحات تکمیلی (اختیاری)','Additional comments (optional)'), border: const OutlineInputBorder()),
      onChanged: (_) => setState(() => confirmed = false))
  ])));

  Widget _resultCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t('۷. نتیجه ارزیابی','7. Assessment result'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    Row(children: [Text(score == null ? '—' : '$score%', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF087E8B))),
      const SizedBox(width: 12), Expanded(child: Text(t('درصد انطباق موارد قابل مشاهده؛ نمره رسمی WHO نیست.','Adherence among observable items; not an official WHO score.')))]),
    Text('${t('انجام‌شده','Done')}: $passed  |  ${t('قابل ارزیابی','Scored')}: $scored  |  ${t('باقی‌مانده','Pending')}: $pending'),
    const SizedBox(height: 10),
    FilledButton.icon(onPressed: canConfirm ? () => setState(() => confirmed = true) : null,
      icon: const Icon(Icons.verified), label: Text(t('تأیید نهایی ارزیاب','Confirm human review'))),
    if (confirmed) const ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Human review confirmed')),
    OutlinedButton.icon(onPressed: () async {
      await Clipboard.setData(ClipboardData(text: makeReport()));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('گزارش کپی شد.','Report copied.'))));
    }, icon: const Icon(Icons.copy), label: Text(t('کپی گزارش','Copy report')))
  ])));

  Widget _warning() => Container(padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFFFF3D6), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE6C56A))),
    child: Text(t('محدودیت مهم: این نسخه ابزار ارزیابی انسانی است. تحلیل خودکار ویدئو، تشخیص میکروبی پاکیزگی و نمره‌دهی اعتبارسنجی‌شده فعال نیست. درصد نمایش‌داده‌شده فقط خلاصه چک‌لیست است و برای رتبه‌بندی یا تنبیه کارکنان استفاده نشود. فیلم‌ها به سرور ارسال نمی‌شوند و فایل اصلی در گوشی باقی می‌ماند.',
      'Important: This version supports human review only. Automated video analysis, microbiological verification, and validated scoring are not enabled. The percentage is only a checklist summary and must not be used to rank or penalize staff. Videos are not uploaded; the original file remains on the device.'), style: const TextStyle(fontSize: 13)));
}

// CI fix: analyze application source independently from generated template tests.
