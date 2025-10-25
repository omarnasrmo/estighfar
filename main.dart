import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

void main() {
  runApp(EstighfarApp());
}

class EstighfarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كم فاتك من الاستغفار',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        brightness: Brightness.light,
        fontFamily: 'Arial',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState(){
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
    });
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Center(child: Text('استغفار', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
          ),
          SizedBox(height: 18),
          Text('كم فاتك من الاستغفار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
        ]),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? birthDate;
  int totalRequired = 0;
  int remaining = 0;
  bool loaded = false;

  static const String prefBirth = 'birthDate';
  static const String prefRemaining = 'remaining';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final birthMillis = sp.getInt(prefBirth);
    final rem = sp.getInt(prefRemaining);

    setState(() {
      if (birthMillis != null) birthDate = DateTime.fromMillisecondsSinceEpoch(birthMillis);
      if (rem != null) remaining = rem;
      loaded = true;
    });

    _recalculate();
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    if (birthDate != null) {
      await sp.setInt(prefBirth, birthDate!.millisecondsSinceEpoch);
    }
    await sp.setInt(prefRemaining, remaining);
  }

  void _recalculate() {
    if (birthDate == null) {
      setState(() {
        totalRequired = 0;
        if (remaining == 0) remaining = 0;
      });
      return;
    }

    final pubertyDate = DateTime(birthDate!.year + 15, birthDate!.month, birthDate!.day);
    final today = DateTime.now();
    final daysSincePuberty = today.isBefore(pubertyDate) ? 0 : today.difference(pubertyDate).inDays;
    final total = daysSincePuberty * 70;

    setState(() {
      totalRequired = total;
      if (remaining == 0 || remaining > total) remaining = total;
    });

    _savePrefs();
  }

  Future<void> _pickBirthDate() async {
    final initial = birthDate ?? DateTime.now().subtract(Duration(days: 365 * 20));
    final newDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (newDate != null) {
      setState(() {
        birthDate = newDate;
      });
      _recalculate();
    }
  }

  void _changeRemaining(int delta) {
    setState(() {
      remaining = (remaining - delta).clamp(0, totalRequired);
    });
    _savePrefs();
  }

  void _addToRemaining(int delta) {
    setState(() {
      remaining = (remaining + delta).clamp(0, totalRequired);
    });
    _savePrefs();
  }

  void _resetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تأكيد إعادة الضبط'),
        content: Text('هل تريد إعادة ضبط تاريخ الميلاد وعداد الاستغفار؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('نعم')),
        ],
      ),
    );
    if (confirm == true) {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(prefBirth);
      await sp.remove(prefRemaining);
      setState(() {
        birthDate = null;
        totalRequired = 0;
        remaining = 0;
      });
    }
  }

  String _formatDate(DateTime d) {
    return DateFormat.yMMMMd('ar').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final pubertyDateStr = birthDate == null ? '-' : _formatDate(DateTime(birthDate!.year + 15, birthDate!.month, birthDate!.day));
    final birthStr = birthDate == null ? 'لم يتم التحديد' : _formatDate(birthDate!);
    final percent = totalRequired == 0 ? 0.0 : (1 - (remaining / totalRequired)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('كم فاتك من الاستغفار'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'إعادة ضبط',
            onPressed: _resetAll,
          )
        ],
      ),
      body: loaded ? SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 6),
            Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [
                  Text('المجموع المطلوب من الاستغفار منذ البلوغ', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressWidget(
                        percent: percent,
                        total: totalRequired,
                        remaining: remaining,
                        onTapMinus: () => _changeRemaining(1),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('استغفر الله وأصلح ما بينك وبين ربك 💚', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ]),
              ),
            ),

            SizedBox(height: 18),
            Text('تفاصيل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('تاريخ الميلاد: $birthStr'),
            SizedBox(height: 6),
            Text('تاريخ بداية سن البلوغ: $pubertyDateStr'),
            SizedBox(height: 12),
            Text('المجموع الكلي المطلوب: $totalRequired'),
            SizedBox(height: 12),
            Text('المتبقي الآن: $remaining', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),

            SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(onPressed: remaining > 0 ? () => _changeRemaining(1) : null, icon: Icon(Icons.remove), label: Text('استغفرت -1')),
              ElevatedButton.icon(onPressed: remaining > 4 ? () => _changeRemaining(5) : null, icon: Icon(Icons.remove_circle), label: Text('استغفرت -5')),
              ElevatedButton.icon(onPressed: () async {
                final n = await _showNumberInput(context, 'اخصم (عدد)', 1);
                if (n != null && n>0) _changeRemaining(n);
              }, icon: Icon(Icons.exposure_minus_1), label: Text('خصم مخصص')),
              ElevatedButton.icon(onPressed: () async {
                final n = await _showNumberInput(context, 'أضف (عدد)', 1);
                if (n != null && n>0) _addToRemaining(n);
              }, icon: Icon(Icons.add), label: Text('إضافة/تعويض')),
              OutlinedButton.icon(onPressed: _pickBirthDate, icon: Icon(Icons.calendar_today), label: Text('تغيير تاريخ الميلاد')),
            ]),

            SizedBox(height: 18),
            Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• الحساب يفترض 70 استغفار/يوم لكل أيام ما بعد سن 15.\n• يمكنك تغيير تاريخ الميلاد في أي وقت وسيتم إعادة حساب المجموع.\n• التطبيق يخزن المتبقي محليًا على جهازك فقط.'),

            SizedBox(height: 30),
          ],
        ),
      ) : Center(child: CircularProgressIndicator()),
    );
  }

  Future<int?> _showNumberInput(BuildContext context, String title, int initial) async {
    final controller = TextEditingController(text: initial.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'أدخل رقماً صحيحاً'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: Text('إلغاء')),
          TextButton(onPressed: () {
            final v = int.tryParse(controller.text);
            Navigator.pop(context, v);
          }, child: Text('موافق')),
        ],
      ),
    );
    return result;
  }
}

class CircularProgressWidget extends StatelessWidget {
  final double percent;
  final int total;
  final int remaining;
  final VoidCallback onTapMinus;

  const CircularProgressWidget({required this.percent, required this.total, required this.remaining, required this.onTapMinus});

  @override
  Widget build(BuildContext context) {
    final displayRemaining = remaining;
    final displayTotal = total;
    return GestureDetector(
      onTap: onTapMinus,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160, height: 160,
            child: CustomPaint(
              painter: _RingPainter(progress: percent),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$displayRemaining', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
            SizedBox(height: 6),
            Text('من $displayTotal', style: TextStyle(fontSize: 12, color: Colors.black54)),
            SizedBox(height: 8),
            ElevatedButton(onPressed: onTapMinus, child: Text('استغفرت')),
          ]),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 14.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - stroke/2;
    final bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2*math.pi*progress,
        colors: [Colors.green, Colors.green.shade700],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    final start = -math.pi/2;
    final sweep = 2*math.pi*progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
