// lib/screens/scan_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/classifier.dart';
import '../services/storage_service.dart';
import '../models/app_models.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker   = ImagePicker();
  final _storage  = StorageService();
  bool  _scanning = false;

  Future<void> _scan(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 92);
    if (picked == null || !mounted) return;
    setState(() => _scanning = true);
    try {
      final clf    = DiseaseClassifier();
      final result = await clf.predict(
          File(picked.path), const Uuid().v4());
      await _storage.addToHistory(result);
      if (mounted) {
        setState(() => _scanning = false);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultScreen(result: result)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.diseased));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Scan Leaf')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(children: [

          // Hero scan area
          Container(
            width:   double.infinity,
            height:  260,
            decoration: BoxDecoration(
              gradient:     AppColors.gradientPrimary,
              borderRadius: AppRadius.xxl,
              boxShadow:    AppShadow.green,
            ),
            child: _scanning
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                      const SizedBox(height: 16),
                      const Text('Analyzing leaf...',
                          style: TextStyle(color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('HybridCropNet AI · 99.68% accuracy',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12)),
                    ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2)),
                        child: const Icon(
                            Icons.document_scanner_rounded,
                            size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 18),
                      const Text('Scan a Leaf',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   22,
                            fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Take a clear photo of the leaf',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13)),
                    ]),
          ),
          const SizedBox(height: 28),

          // Buttons
          Row(children: [
            Expanded(child: _ScanButton(
              icon:    Icons.camera_alt_rounded,
              label:   'Camera',
              subtitle:'Take photo now',
              color:   AppColors.primary,
              onTap:   () => _scan(ImageSource.camera),
            )),
            const SizedBox(width: 14),
            Expanded(child: _ScanButton(
              icon:    Icons.photo_library_rounded,
              label:   'Gallery',
              subtitle:'Upload saved photo',
              color:   AppColors.info,
              onTap:   () => _scan(ImageSource.gallery),
            )),
          ]),
          const SizedBox(height: 28),

          // Tips
          Container(
            padding:     const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        AppColors.accentLight,
              borderRadius: AppRadius.lg,
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.tips_and_updates_rounded,
                      color: AppColors.primary, size: 16),
                  SizedBox(width: 6),
                  Text('Tips for best results',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                ]),
                const SizedBox(height: 10),
                ...[
                  '📸 Capture the leaf clearly with good lighting',
                  '🌿 Include the full leaf in the frame',
                  '🔍 Focus on diseased spots or symptoms',
                  '☀️ Avoid shadows or blurry images',
                ].map((tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(tip,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecond)),
                )),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String   label, subtitle;
  final Color    color;
  final VoidCallback onTap;
  const _ScanButton({
    required this.icon, required this.label,
    required this.subtitle, required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.07),
          borderRadius: AppRadius.xl,
          border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 26)),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(
              fontSize: 11, color: AppColors.textHint)),
        ]),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
// RESULT SCREEN
// ══════════════════════════════════════════════════════════════
class ResultScreen extends StatelessWidget {
  final PredictionResult result;
  const ResultScreen({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analysis Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(children: [

          // Image
          ClipRRect(
            borderRadius: AppRadius.xl,
            child: result.imagePath != null
                ? Image.file(File(result.imagePath!),
                    height: 220, width: double.infinity,
                    fit: BoxFit.cover)
                : Container(
                    height: 220, color: AppColors.surfaceAlt,
                    child: const Icon(Icons.image_outlined,
                        size: 60, color: AppColors.textHint)),
          ),
          const SizedBox(height: 16),

          // Main result card
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: result.isHealthy
                  ? AppColors.healthy.withOpacity(0.06)
                  : AppColors.diseased.withOpacity(0.06),
              borderRadius: AppRadius.xl,
              border: Border.all(
                color: result.isHealthy
                    ? AppColors.healthy.withOpacity(0.3)
                    : AppColors.diseased.withOpacity(0.3)),
            ),
            child: Column(children: [
              Icon(
                result.isHealthy
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                size:  52,
                color: result.isHealthy
                    ? AppColors.healthy
                    : AppColors.diseased),
              const SizedBox(height: 12),
              Text(
                result.isHealthy
                    ? '✅ Healthy Plant'
                    : '⚠️ Disease Detected',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: result.isHealthy
                      ? AppColors.healthy : AppColors.diseased)),
              const SizedBox(height: 6),
              Text(result.cleanName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Row(children: [
                Text('Confidence',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecond)),
                const Spacer(),
                Text('${result.confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: result.isHealthy
                          ? AppColors.healthy : AppColors.diseased)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value:           result.confidence / 100,
                  minHeight:       10,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(
                      result.isHealthy
                          ? AppColors.healthy : AppColors.diseased),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Treatment
          if (!result.isHealthy) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        const Color(0xFFFFF8E1),
                borderRadius: AppRadius.lg,
                border: Border.all(
                    color: const Color(0xFFFFB300).withOpacity(0.4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.healing_rounded,
                        color: Color(0xFFFF8F00), size: 18),
                    SizedBox(width: 8),
                    Text('Treatment Suggestion',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100))),
                  ]),
                  const SizedBox(height: 10),
                  Text(result.treatmentSuggestion,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary,
                          height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Top 5
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        AppColors.surface,
              borderRadius: AppRadius.xl,
              border: Border.all(color: AppColors.border),
              boxShadow:    AppShadow.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top 5 Predictions',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
                const SizedBox(height: 14),
                ...result.top5.asMap().entries.map((e) {
                  final rank = e.key;
                  final pred = e.value;
                  final top  = rank == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: top
                                  ? AppColors.primary
                                  : AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6)),
                            child: Center(child: Text('${rank+1}',
                                style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: top
                                      ? Colors.white
                                      : AppColors.textHint)))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(pred.cleanName,
                              style: TextStyle(
                                fontSize:   13,
                                fontWeight: top ? FontWeight.w600 : FontWeight.w400,
                                color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis)),
                          Text('${pred.probability.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: top ? AppColors.primary : AppColors.textHint)),
                        ]),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:           pred.probability / 100,
                            minHeight:       6,
                            backgroundColor: AppColors.surfaceAlt,
                            valueColor: AlwaysStoppedAnimation(
                              top ? AppColors.primary : AppColors.border),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scan again
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon:  const Icon(Icons.document_scanner_rounded),
              label: const Text('Scan Another Leaf'),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
// ANALYTICS SCREEN
// ══════════════════════════════════════════════════════════════
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _storage = StorageService();
  List<PredictionResult> _history = [];
  List<Plant>            _plants  = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final h = await _storage.getHistory();
    final p = await _storage.getPlants();
    if (mounted) setState(() { _history=h; _plants=p; });
  }

  @override
  Widget build(BuildContext context) {
    final diseased = _history.where((h)=>!h.isHealthy).length;
    final healthy  = _history.where((h)=> h.isHealthy).length;
    final total    = _history.length;

    // Disease frequency map
    final freq = <String,int>{};
    for (final r in _history.where((h)=>!h.isHealthy)) {
      freq[r.cleanName] = (freq[r.cleanName] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a,b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(children: [

            // Overview cards
            Row(children: [
              Expanded(child: _AnalyticCard(
                label: 'Total Scans', value: '$total',
                icon:  Icons.document_scanner_rounded,
                color: AppColors.info)),
              const SizedBox(width: 12),
              Expanded(child: _AnalyticCard(
                label: 'Diseased', value: '$diseased',
                icon:  Icons.warning_amber_rounded,
                color: AppColors.diseased)),
              const SizedBox(width: 12),
              Expanded(child: _AnalyticCard(
                label: 'Healthy', value: '$healthy',
                icon:  Icons.check_circle_outline_rounded,
                color: AppColors.healthy)),
            ]),
            const SizedBox(height: 20),

            // Health rate card
            if (total > 0) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: AppRadius.xl,
                  border: Border.all(color: AppColors.border),
                  boxShadow:    AppShadow.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall Farm Health Rate',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${(healthy/total*100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w800,
                                color: AppColors.healthy)),
                          const Text('plants healthy',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecond)),
                        ],
                      )),
                      SizedBox(width: 80, height: 80,
                        child: Stack(alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value:           healthy/total,
                              strokeWidth:     7,
                              backgroundColor: AppColors.diseased.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.healthy)),
                            Text('${(healthy/total*100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          ]),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Most common diseases
            if (sorted.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: AppRadius.xl,
                  border: Border.all(color: AppColors.border),
                  boxShadow:    AppShadow.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Most Common Diseases',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    ...sorted.take(5).map((e) {
                      final pct = e.value / diseased;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(e.key,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis)),
                              Text('${e.value}x',
                                  style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.diseased)),
                            ]),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value:           pct,
                                minHeight:       8,
                                backgroundColor: AppColors.surfaceAlt,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.diseased)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Column(children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 60, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No data yet',
                      style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecond,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Scan some leaves to see analytics',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHint)),
                ]),
              ),
            const SizedBox(height: 80),
          ]),
        ),
      ),
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;
  const _AnalyticCard({
    required this.label, required this.value,
    required this.icon,  required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border),
        boxShadow:    AppShadow.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: color)),
          Text(label, style: const TextStyle(
              fontSize: 11, color: AppColors.textSecond)),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ══════════════════════════════════════════════════════════════
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(children: [
          // Profile card
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient:     AppColors.gradientPrimary,
              borderRadius: AppRadius.xxl),
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded,
                    size: 44, color: Colors.white)),
              const SizedBox(height: 12),
              const Text('Farmer Profile',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   18,
                    fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('HybridCropNet v1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 20),

          // Model info
          _ProfileSection('AI Model', [
            _ProfileTile('Architecture',
                'EfficientNetV2-S + ViT-S/16 + CBAM',
                Icons.memory_rounded),
            _ProfileTile('Test Accuracy', '99.68%',
                Icons.verified_rounded),
            _ProfileTile('Disease Classes', '15 categories',
                Icons.bug_report_outlined),
            _ProfileTile('Model Size', '172.9 MB (ONNX)',
                Icons.storage_rounded),
          ]),
          const SizedBox(height: 16),

          // App settings
          _ProfileSection('Settings', [
            _ProfileTile('Language', 'English',
                Icons.language_rounded),
            _ProfileTile('Notifications', 'Enabled',
                Icons.notifications_outlined),
            _ProfileTile('Scan Reminder', 'Every 7 days',
                Icons.alarm_rounded),
          ]),
          const SizedBox(height: 16),

          // About
          _ProfileSection('About', [
            _ProfileTile('Research',
                'IEEE Conference Paper · 2025',
                Icons.article_outlined),
            _ProfileTile('Dataset',
                'PlantVillage · 20,638 images',
                Icons.dataset_outlined),
            _ProfileTile('Version', '1.0.0',
                Icons.info_outline_rounded),
          ]),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String       title;
  final List<Widget> tiles;
  const _ProfileSection(this.title, this.tiles);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textHint, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: AppRadius.xl,
            border: Border.all(color: AppColors.border),
            boxShadow:    AppShadow.sm),
          child: Column(children: tiles.asMap().entries.map((e) {
            final isLast = e.key == tiles.length - 1;
            return Column(children: [
              e.value,
              if (!isLast)
                const Divider(height: 1,
                    indent: 52, color: AppColors.border),
            ]);
          }).toList()),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String   title, subtitle;
  final IconData icon;
  const _ProfileTile(this.title, this.subtitle, this.icon);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
            Text(subtitle, style: const TextStyle(
                fontSize: 11, color: AppColors.textSecond)),
          ],
        )),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.textHint, size: 18),
      ]),
    );
  }
}
