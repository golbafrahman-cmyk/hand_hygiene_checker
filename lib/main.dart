import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const HandHygieneApp());

enum HygieneMethod { alcohol, soap }

class HandHygieneApp extends StatefulWidget {
  const HandHygieneApp({super.key});

  @override
  State<HandHygieneApp> createState() => _HandHygieneAppState();
}

class _HandHygieneAppState extends State<HandHygieneApp> {
  bool english = false;
  HygieneMethod method = HygieneMethod.alcohol;
  XFile? video;
  final picker = ImagePicker();

  String tr(String fa, String en) => english ? en : fa;

  Future<void> selectVideo() async {
    final selected = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (selected != null && mounted) setState(() => video = selected);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hand Hygiene AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E8B)),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: Directionality(
        textDirection: english ? TextDirection.ltr : TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(tr('ارزیابی هوشمند بهداشت دست', 'Hand Hygiene Assessment')),
            actions: [
              TextButton(
                onPressed: () => setState(() => english = !english),
                child: Text(english ? 'فارسی' : 'English'),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                const SizedBox(height: 16),
                _methodSelector(),
                const SizedBox(height: 16),
                _videoCard(),
                const SizedBox(height: 16),
                _workflowCard(),
                const SizedBox(height: 16),
                _notice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF087E8B), Color(0xFF145DA0)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.health_and_safety, color: Colors.white, size: 34),
        const SizedBox(height: 12),
        Text(
          tr('سامانه پایش کیفیت بهداشت دست', 'Hand Hygiene Quality Monitor'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          tr('تحلیل ویدئو با هوش مصنوعی و تأیید ارزیاب انسانی',
              'AI-assisted video review with human confirmation'),
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          _tag('Android'),
          _tag('iOS'),
          _tag('FA / EN'),
        ]),
      ],
    ),
  );

  Widget _tag(String text) => Chip(
    label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    backgroundColor: Colors.white24,
    side: BorderSide.none,
    visualDensity: VisualDensity.compact,
  );

  Widget _methodSelector() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('روش بهداشت دست', 'Hand hygiene method'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          RadioListTile<HygieneMethod>(
            contentPadding: EdgeInsets.zero,
            value: HygieneMethod.alcohol,
            groupValue: method,
            onChanged: (v) => setState(() { method = v!; video = null; }),
            title: Text(tr('ضدعفونی با محلول الکلی', 'Alcohol-based hand rub')),
            subtitle: Text(tr('مدت راهنما: ۲۰ تا ۳۰ ثانیه', 'Indicative duration: 20–30 seconds')),
          ),
          RadioListTile<HygieneMethod>(
            contentPadding: EdgeInsets.zero,
            value: HygieneMethod.soap,
            groupValue: method,
            onChanged: (v) => setState(() { method = v!; video = null; }),
            title: Text(tr('شست‌وشو با آب و صابون', 'Handwashing with soap and water')),
            subtitle: Text(tr('مدت راهنما: ۴۰ تا ۶۰ ثانیه', 'Indicative duration: 40–60 seconds')),
          ),
        ],
      ),
    ),
  );

  Widget _videoCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('۱. انتخاب فیلم', '1. Select a video'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(tr('یک فیلم واضح از تمام مراحل انجام بهداشت دست انتخاب کنید.',
              'Choose a clear video showing the complete hand hygiene procedure.')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: selectVideo,
            icon: const Icon(Icons.video_library_outlined),
            label: Text(tr('انتخاب فیلم از گوشی', 'Choose video from device')),
          ),
          if (video != null) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.movie, color: Color(0xFF087E8B)),
              title: Text(video!.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(tr('فیلم انتخاب شده است؛ هنوز تحلیل نشده.',
                  'Video selected; not analyzed yet.')),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => video = null),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _workflowCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('۲. فرایند ارزیابی', '2. Assessment workflow'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _step(Icons.video_settings, tr('کنترل کیفیت ویدئو', 'Video quality check')),
          _step(Icons.auto_awesome, tr('تحلیل حرکات و زمان توسط هوش مصنوعی',
              'AI analysis of hand movements and duration')),
          _step(Icons.fact_check, tr('بازبینی و تأیید ارزیاب انسانی',
              'Human reviewer verification')),
          _step(Icons.assessment, tr('ثبت نمره و گزارش نهایی', 'Final score and report')),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: video == null ? null : () => _showPrototypeMessage(),
            icon: const Icon(Icons.analytics_outlined),
            label: Text(tr('شروع فرایند ارزیابی', 'Start assessment')),
          ),
        ],
      ),
    ),
  );

  Widget _step(IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF087E8B)),
      const SizedBox(width: 10),
      Expanded(child: Text(label)),
    ]),
  );

  Widget _notice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE7C66A)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline, color: Color(0xFF8A6500)),
      const SizedBox(width: 10),
      Expanded(child: Text(tr(
        'نسخه اولیه رابط کاربری است. موتور تحلیل هوش مصنوعی، چک‌لیست اعتبارسنجی‌شده و پنل تأیید ارزیاب در مرحله بعد اضافه می‌شوند. در این نسخه هیچ نمره خودکاری تولید نمی‌شود.',
        'This is an initial UI prototype. The AI analysis engine, validated scoring checklist, and reviewer approval panel will be implemented in the next phase. No automatic score is generated in this version.',
      ))),
    ]),
  );

  void _showPrototypeMessage() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('فیلم دریافت شد', 'Video received')),
        content: Text(tr(
          'فیلم برای طراحی مرحله تحلیل انتخاب شد. در این نسخه تحلیل واقعی هنوز فعال نیست و نباید از آن برای ارزیابی عملکرد کارکنان استفاده شود.',
          'The video is selected for the analysis workflow design. Real AI analysis is not enabled in this prototype and it must not be used to evaluate staff performance.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text(tr('متوجه شدم', 'Understood'))),
        ],
      ),
    );
  }
}
