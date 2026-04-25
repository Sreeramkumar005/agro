// lib/screens/plant_detail_screen.dart
// Premium plant profile — like a patient chart in a health app

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  const PlantDetailScreen({required this.plant, super.key});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Plant         _plant;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _tabs  = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _reload() async {
    final plants = await _storage.getPlants();
    final found  = plants.firstWhere(
        (p) => p.id == _plant.id, orElse: () => _plant);
    if (mounted) setState(() => _plant = found);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(),
        ],
        body: Column(children: [
          // Tab bar
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller:        _tabs,
              labelColor:        AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor:    AppColors.primary,
              indicatorWeight:   2.5,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Health Log'),
                Tab(text: 'Nutrients'),
                Tab(text: 'Treatment'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _HealthLogTab(plant: _plant, onRefresh: _reload),
                _NutrientTab(plant: _plant, onRefresh: _reload),
                _TreatmentTab(plant: _plant, onRefresh: _reload),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned:         true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
              gradient: AppColors.gradientPrimary),
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:  MainAxisAlignment.end,
            children: [
              Row(children: [
                Text(_plant.cropEmoji,
                    style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_plant.name,
                        style: const TextStyle(
                          fontSize:   22,
                          fontWeight: FontWeight.w700,
                          color:      Colors.white)),
                    Text('${_plant.cropType} · '
                        '${_plant.daysOld} days old',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75))),
                  ],
                )),
                // Health score ring
                _HealthRing(score: _plant.healthScore),
              ]),
              const SizedBox(height: 14),
              // Mini stats
              Row(children: [
                _MiniStat('${_plant.healthLogs.length}',
                    'Scans', Icons.document_scanner_rounded),
                const SizedBox(width: 16),
                _MiniStat('${_plant.nutrientLogs.length}',
                    'Nutrient logs', Icons.science_outlined),
                const SizedBox(width: 16),
                _MiniStat('${_plant.treatmentLogs.length}',
                    'Treatments', Icons.healing_rounded),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _MiniStat(String value, String label, IconData icon) =>
    Row(children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 4),
      Text('$value $label',
          style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.75))),
    ]);

class _HealthRing extends StatelessWidget {
  final double score;
  const _HealthRing({required this.score});

  Color get _color {
    if (score >= 85) return const Color(0xFF4CAF50);
    if (score >= 70) return const Color(0xFF8BC34A);
    if (score >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      SizedBox(
        width: 64, height: 64,
        child: CircularProgressIndicator(
          value:           score / 100,
          strokeWidth:     5,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor:      AlwaysStoppedAnimation(_color),
        ),
      ),
      Text('${score.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: Colors.white)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1: HEALTH LOG
// Like Healthify Me food diary — each scan is a log entry
// ══════════════════════════════════════════════════════════════
class _HealthLogTab extends StatelessWidget {
  final Plant        plant;
  final VoidCallback onRefresh;
  const _HealthLogTab({required this.plant, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final logs = plant.healthLogs;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [

            // Health trend chart
            if (logs.length >= 2) ...[
              _SectionCard(
                title: 'Health Score Trend',
                child: SizedBox(
                  height: 140,
                  child: LineChart(LineChartData(
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(
                          color: AppColors.border, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, reservedSize: 32,
                        getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textHint)))),
                      bottomTitles: AxisTitles(sideTitles:
                          SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles:
                          SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles:
                          SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [LineChartBarData(
                      spots: logs.reversed.toList()
                          .asMap().entries.map((e) => FlSpot(
                              e.key.toDouble(),
                              e.value.healthScore))
                          .toList(),
                      isCurved:  true,
                      color:     AppColors.primary,
                      barWidth:  2.5,
                      dotData:   FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show:  true,
                        color: AppColors.primary.withOpacity(0.08)),
                    )],
                    minY: 0, maxY: 100,
                  )),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Summary row
            Row(children: [
              Expanded(child: _SummaryTile(
                label: 'Total Scans',
                value: '${logs.length}',
                icon:  Icons.document_scanner_rounded,
                color: AppColors.info,
              )),
              const SizedBox(width: 12),
              Expanded(child: _SummaryTile(
                label: 'Healthy Days',
                value: '${logs.where((l)=>l.isHealthy).length}',
                icon:  Icons.check_circle_outline_rounded,
                color: AppColors.healthy,
              )),
              const SizedBox(width: 12),
              Expanded(child: _SummaryTile(
                label: 'Disease Events',
                value: '${logs.where((l)=>!l.isHealthy).length}',
                icon:  Icons.warning_amber_rounded,
                color: AppColors.diseased,
              )),
            ]),
            const SizedBox(height: 16),

            // Log entries header
            Row(children: [
              const Text('Scan History',
                  style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.textPrimary)),
              const Spacer(),
              Text('${logs.length} entries',
                  style: const TextStyle(
                      fontSize: 12,
                      color:    AppColors.textHint)),
            ]),
            const SizedBox(height: 10),
          ]),
        )),

        // Log list
        logs.isEmpty
            ? SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  const Icon(Icons.history_rounded,
                      size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text('No scans yet',
                      style: TextStyle(color: AppColors.textSecond)),
                  const SizedBox(height: 8),
                  const Text('Scan a leaf and assign it to this plant',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint)),
                ]),
              ))
            : SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _HealthLogCard(log: logs[i]),
                ),
                childCount: logs.length,
              )),
      ],
    );
  }
}

class _HealthLogCard extends StatelessWidget {
  final PlantHealthLog log;
  const _HealthLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border),
        boxShadow:    AppShadow.sm,
      ),
      child: Row(children: [
        // Date column
        Column(children: [
          Text('${log.date.day}',
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          Text(_monthAbbr(log.date.month),
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecond)),
        ]),
        const SizedBox(width: 14),

        // Divider
        Container(width: 1.5, height: 48,
            color: AppColors.border),
        const SizedBox(width: 14),

        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log.isHealthy ? 'Healthy ✅' : log.cleanName,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: log.isHealthy
                    ? AppColors.healthy
                    : AppColors.diseased)),
            const SizedBox(height: 3),
            Text('Confidence: ${log.confidence.toStringAsFixed(1)}%',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ],
        )),

        // Health score
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:        log.isHealthy
                ? AppColors.healthy.withOpacity(0.08)
                : AppColors.diseased.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${log.healthScore.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: log.isHealthy
                  ? AppColors.healthy
                  : AppColors.diseased)),
        ),
      ]),
    );
  }

  String _monthAbbr(int m) => const [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ][m - 1];
}

// ══════════════════════════════════════════════════════════════
// TAB 2: NUTRIENT TRACKER
// Like Healthify Me macro tracker — N, P, K, pH, water, sunlight
// ══════════════════════════════════════════════════════════════
class _NutrientTab extends StatelessWidget {
  final Plant        plant;
  final VoidCallback onRefresh;
  const _NutrientTab({required this.plant, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final logs    = plant.nutrientLogs;
    final latest  = logs.isNotEmpty ? logs.first : null;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // Today's nutrient summary card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient:     AppColors.gradientCool,
              borderRadius: AppRadius.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Nutrients",
                    style: TextStyle(
                      color:      Colors.white,
                      fontSize:   14,
                      fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                if (latest != null) ...[
                  Row(children: [
                    _NutrientRing(
                        label: 'N',
                        value: latest.nitrogen,
                        max:   120,
                        color: const Color(0xFF4CAF50)),
                    const SizedBox(width: 16),
                    _NutrientRing(
                        label: 'P',
                        value: latest.phosphorus,
                        max:   60,
                        color: const Color(0xFFFF9800)),
                    const SizedBox(width: 16),
                    _NutrientRing(
                        label: 'K',
                        value: latest.potassium,
                        max:   100,
                        color: const Color(0xFF9C27B0)),
                    const SizedBox(width: 16),
                    _NutrientRing(
                        label: 'pH',
                        value: latest.soilPH,
                        max:   14,
                        color: const Color(0xFF03A9F4)),
                  ]),
                ] else
                  Text('No data logged yet. Add your first entry.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Add nutrient log button
          SizedBox(
            width:  double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showAddNutrientSheet(context),
              icon:  const Icon(Icons.add),
              label: const Text('Log Nutrients Today'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nutrient detail bars (like macro breakdown)
          if (latest != null) ...[
            _SectionCard(
              title: 'Nutrient Breakdown',
              child: Column(children: [
                _NutrientBar(
                  label:   'Nitrogen (N)',
                  value:   latest.nitrogen,
                  ideal:   100.0,
                  unit:    'kg/ha',
                  status:  latest.nitrogenStatus,
                  color:   const Color(0xFF4CAF50)),
                const SizedBox(height: 12),
                _NutrientBar(
                  label:   'Phosphorus (P)',
                  value:   latest.phosphorus,
                  ideal:   50.0,
                  unit:    'kg/ha',
                  status:  latest.phosphorusStatus,
                  color:   const Color(0xFFFF9800)),
                const SizedBox(height: 12),
                _NutrientBar(
                  label:   'Potassium (K)',
                  value:   latest.potassium,
                  ideal:   90.0,
                  unit:    'kg/ha',
                  status:  latest.potassiumStatus,
                  color:   const Color(0xFF9C27B0)),
                const SizedBox(height: 12),
                _NutrientBar(
                  label:   'Soil pH',
                  value:   latest.soilPH,
                  ideal:   6.5,
                  unit:    'pH',
                  status:  latest.phStatus,
                  color:   const Color(0xFF03A9F4)),
                const SizedBox(height: 12),
                _NutrientBar(
                  label:   'Watering',
                  value:   latest.wateringMM,
                  ideal:   30.0,
                  unit:    'mm/day',
                  status:  latest.wateringMM >= 20 &&
                      latest.wateringMM <= 40
                      ? 'Optimal' : 'Needs adjustment',
                  color:   const Color(0xFF00BCD4)),
                const SizedBox(height: 12),
                _NutrientBar(
                  label:   'Sunlight',
                  value:   latest.sunlightHours,
                  ideal:   7.0,
                  unit:    'hrs/day',
                  status:  latest.sunlightHours >= 6 &&
                      latest.sunlightHours <= 8
                      ? 'Optimal' : 'Needs adjustment',
                  color:   const Color(0xFFFFEB3B)),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // History
          _SectionCard(
            title: 'Nutrient Log History',
            child: logs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No logs yet',
                        style: TextStyle(
                            color: AppColors.textHint)),
                  )
                : Column(children: logs.take(5).map((log) =>
                    _NutrientHistoryTile(log: log)).toList()),
          ),
          const SizedBox(height: 80),
        ]),
      )),
    ]);
  }

  void _showAddNutrientSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _AddNutrientSheet(
        plantId:   plant.id,
        onSaved: onRefresh,
      ),
    );
  }
}

class _NutrientRing extends StatelessWidget {
  final String label;
  final double value, max;
  final Color  color;
  const _NutrientRing({
    required this.label, required this.value,
    required this.max,   required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 56, height: 56,
          child: CircularProgressIndicator(
            value:           (value / max).clamp(0, 1),
            strokeWidth:     4,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor:      AlwaysStoppedAnimation(color),
          ),
        ),
        Text(value <= 9.9
            ? value.toStringAsFixed(1)
            : value.toStringAsFixed(0),
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   12,
              fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11)),
    ]);
  }
}

class _NutrientBar extends StatelessWidget {
  final String label, unit, status;
  final double value, ideal;
  final Color  color;
  const _NutrientBar({
    required this.label, required this.value,
    required this.ideal, required this.unit,
    required this.status, required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final pct = (value / (ideal * 1.5)).clamp(0.0, 1.0);
    final statusColor = status == 'Optimal'
        ? AppColors.healthy
        : status == 'Low' || status == 'Very Low'
            ? AppColors.warning
            : AppColors.info;
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6)),
            child: Text(status,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: statusColor)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           pct,
                minHeight:       8,
                backgroundColor: AppColors.surfaceAlt,
                valueColor:      AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${value.toStringAsFixed(1)} $unit',
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textSecond)),
        ]),
        Text('Ideal: ${ideal.toStringAsFixed(ideal < 10 ? 1 : 0)} $unit',
            style: const TextStyle(
                fontSize: 9, color: AppColors.textHint)),
      ],
    );
  }
}

class _NutrientHistoryTile extends StatelessWidget {
  final NutrientLog log;
  const _NutrientHistoryTile({required this.log});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        AppColors.info.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.science_outlined,
              size: 18, color: AppColors.info),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('N:${log.nitrogen.toStringAsFixed(0)} '
                'P:${log.phosphorus.toStringAsFixed(0)} '
                'K:${log.potassium.toStringAsFixed(0)} '
                'pH:${log.soilPH.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
            Text('${log.date.day}/${log.date.month}/'
                '${log.date.year}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ],
        )),
        Text('${log.nutrientScore.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColors.info)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 3: TREATMENT TRACKER (Before/After)
// ══════════════════════════════════════════════════════════════
class _TreatmentTab extends StatelessWidget {
  final Plant        plant;
  final VoidCallback onRefresh;
  const _TreatmentTab({required this.plant, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final logs = plant.treatmentLogs;
    final ongoing   = logs.where((l) => l.status=='ongoing').length;
    final completed = logs.where((l) => l.status=='completed').length;
    final avgEffect = logs
        .where((l) => l.effectiveness != null)
        .map((l) => l.effectiveness!)
        .fold<double>(0, (a, b) => a + b);
    final effCount  = logs
        .where((l) => l.effectiveness != null).length;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // Treatment summary header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient:     AppColors.gradientWarm,
              borderRadius: AppRadius.xl,
            ),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Treatment Tracker',
                      style: TextStyle(
                        color:      Colors.white,
                        fontSize:   16,
                        fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Before & After Disease Monitoring',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _TreatmentStat('$ongoing',    'Ongoing'),
                    const SizedBox(width: 20),
                    _TreatmentStat('$completed',  'Completed'),
                    const SizedBox(width: 20),
                    _TreatmentStat(
                      effCount > 0
                          ? '${(avgEffect/effCount).toStringAsFixed(0)}%'
                          : 'N/A',
                      'Avg Effectiveness'),
                  ]),
                ],
              )),
              const Icon(Icons.healing_rounded,
                  size: 48, color: Colors.white38),
            ]),
          ),
          const SizedBox(height: 16),

          // Start treatment button
          SizedBox(
            width:  double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showAddTreatmentSheet(context),
              icon:  const Icon(Icons.add),
              label: const Text('Start New Treatment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE65100),
                side: const BorderSide(color: Color(0xFFE65100)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Treatment cards
          if (logs.isEmpty)
            _SectionCard(
              title: 'No Treatments Yet',
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.healing_outlined,
                      size: 40, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text('Start a treatment after detecting a disease',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint)),
                ]),
              ),
            )
          else
            ...logs.map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TreatmentCard(
                  log: log, plantId: plant.id,
                  onUpdate: onRefresh),
            )),

          const SizedBox(height: 80),
        ]),
      )),
    ]);
  }

  void _showAddTreatmentSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _AddTreatmentSheet(
          plantId: plant.id, onSaved: onRefresh),
    );
  }
}

Widget _TreatmentStat(String value, String label) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: Colors.white)),
        Text(label, style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7))),
      ]);

class _TreatmentCard extends StatelessWidget {
  final TreatmentLog log;
  final String       plantId;
  final VoidCallback onUpdate;
  const _TreatmentCard({
    required this.log, required this.plantId,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isOngoing = log.status == 'ongoing';
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.xl,
        border: Border.all(
          color: isOngoing
              ? const Color(0xFFE65100).withOpacity(0.3)
              : AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isOngoing
                ? const Color(0xFFE65100).withOpacity(0.06)
                : AppColors.surfaceAlt,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        const Color(0xFFE65100).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.healing_rounded,
                  color: Color(0xFFE65100), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.treatmentName,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
                Text('${log.treatmentType} · '
                    '${log.dosage}${log.dosageUnit}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecond)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOngoing
                    ? const Color(0xFFE65100).withOpacity(0.12)
                    : AppColors.healthy.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8)),
              child: Text(
                isOngoing ? 'Ongoing' : 'Completed',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: isOngoing
                      ? const Color(0xFFE65100)
                      : AppColors.healthy)),
            ),
          ]),
        ),

        // Before/After comparison
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [

            // Disease being treated
            Text(
              'Disease: ${log.diseaseTreated.replaceAll("_", " ")}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecond)),
            const SizedBox(height: 14),

            // Before / After severity bars
            Row(children: [
              Expanded(child: _SeverityIndicator(
                label:    'Before',
                value:    log.severityBefore,
                color:    AppColors.diseased,
                icon:     Icons.arrow_downward_rounded,
              )),
              const SizedBox(width: 16),
              Expanded(child: _SeverityIndicator(
                label:    'After',
                value:    log.severityAfter,
                color:    log.severityAfter != null
                    ? AppColors.healthy
                    : AppColors.textHint,
                icon:     Icons.arrow_upward_rounded,
                pending:  log.severityAfter == null,
              )),
            ]),
            const SizedBox(height: 14),

            // Effectiveness
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        log.effectivenessColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: log.effectivenessColor.withOpacity(0.25)),
              ),
              child: Row(children: [
                Icon(
                  log.effectiveness == null
                      ? Icons.hourglass_empty_rounded
                      : log.effectiveness! >= 80
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                  color: log.effectivenessColor, size: 18),
                const SizedBox(width: 8),
                Text(log.effectivenessLabel,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: log.effectivenessColor)),
                if (log.effectiveness != null) ...[
                  const Spacer(),
                  Text('${log.effectiveness!.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: log.effectivenessColor)),
                ],
              ]),
            ),

            // Add follow-up button if ongoing
            if (isOngoing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width:  double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _addFollowUp(context),
                  icon:  const Icon(Icons.document_scanner_rounded,
                      size: 16),
                  label: const Text('Add Follow-Up Scan',
                      style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],

            // Days since started
            const SizedBox(height: 8),
            Text(
              'Started ${log.daysSinceStart} days ago · '
              '${log.startDate.day}/${log.startDate.month}/'
              '${log.startDate.year}',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint)),
          ]),
        ),
      ]),
    );
  }

  void _addFollowUp(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _FollowUpSheet(
          log: log, plantId: plantId, onSaved: onUpdate),
    );
  }
}

class _SeverityIndicator extends StatelessWidget {
  final String  label;
  final double? value;
  final Color   color;
  final IconData icon;
  final bool    pending;
  const _SeverityIndicator({
    required this.label, required this.value,
    required this.color, required this.icon,
    this.pending = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
              fontSize: 11, color: color.withOpacity(0.7))),
          const SizedBox(height: 6),
          Text(pending
              ? 'Pending scan'
              : '${value!.toStringAsFixed(0)}% severity',
              style: TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      color)),
          if (!pending) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           (value! / 100).clamp(0, 1),
                minHeight:       6,
                backgroundColor: color.withOpacity(0.15),
                valueColor:      AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared Section Card ────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.border),
        boxShadow:    AppShadow.sm,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;
  const _SummaryTile({
    required this.label, required this.value,
    required this.icon,  required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(
            fontSize: 9, color: AppColors.textSecond),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Add Nutrient Sheet ─────────────────────────────────────────
class _AddNutrientSheet extends StatefulWidget {
  final String       plantId;
  final VoidCallback onSaved;
  const _AddNutrientSheet({required this.plantId, required this.onSaved});
  @override
  State<_AddNutrientSheet> createState() => _AddNutrientSheetState();
}

class _AddNutrientSheetState extends State<_AddNutrientSheet> {
  final _storage = StorageService();
  double _n    = 80,  _p   = 40,  _k   = 80;
  double _ph   = 6.5, _w   = 25,  _sun = 6;
  double _temp = 25,  _hum = 70;
  final _fertCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Log Nutrients',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _SliderField('Nitrogen (N)',     _n,   0, 200, 'kg/ha',
              (v) => setState(()=>_n=v)),
          _SliderField('Phosphorus (P)',   _p,   0, 100, 'kg/ha',
              (v) => setState(()=>_p=v)),
          _SliderField('Potassium (K)',    _k,   0, 200, 'kg/ha',
              (v) => setState(()=>_k=v)),
          _SliderField('Soil pH',         _ph,  4,  9,  'pH',
              (v) => setState(()=>_ph=v)),
          _SliderField('Watering',        _w,   0,  80, 'mm/day',
              (v) => setState(()=>_w=v)),
          _SliderField('Sunlight',        _sun, 0,  14, 'hrs/day',
              (v) => setState(()=>_sun=v)),
          _SliderField('Temperature',     _temp,10, 45, '°C',
              (v) => setState(()=>_temp=v)),
          _SliderField('Humidity',        _hum,  0, 100, '%',
              (v) => setState(()=>_hum=v)),
          const SizedBox(height: 8),
          TextField(
            controller: _fertCtrl,
            decoration: const InputDecoration(
              labelText:  'Fertilizer used (optional)',
              prefixIcon: Icon(Icons.grass_outlined)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final log = NutrientLog(
                  id:            const Uuid().v4(),
                  date:          DateTime.now(),
                  nitrogen:      _n,
                  phosphorus:    _p,
                  potassium:     _k,
                  soilPH:        _ph,
                  wateringMM:    _w,
                  sunlightHours: _sun,
                  temperature:   _temp,
                  humidity:      _hum,
                  fertilizerUsed: _fertCtrl.text.isEmpty
                      ? null : _fertCtrl.text,
                );
                await _storage.addNutrientLog(
                    widget.plantId, log);
                widget.onSaved();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save Nutrient Log'),
            ),
          ),
        ],
      )),
    );
  }
}

Widget _SliderField(String label, double value, double min,
    double max, String unit, ValueChanged<double> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: AppColors.textPrimary)),
          const Spacer(),
          Text('${value.toStringAsFixed(1)} $unit',
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
        ]),
        Slider(
          value: value, min: min, max: max,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
          onChanged: onChanged,
        ),
      ]),
  );
}

// ── Add Treatment Sheet ────────────────────────────────────────
class _AddTreatmentSheet extends StatefulWidget {
  final String       plantId;
  final VoidCallback onSaved;
  const _AddTreatmentSheet({
      required this.plantId, required this.onSaved});
  @override
  State<_AddTreatmentSheet> createState() => _AddTreatmentSheetState();
}

class _AddTreatmentSheetState extends State<_AddTreatmentSheet> {
  final _storage      = StorageService();
  final _nameCtrl     = TextEditingController();
  final _diseaseCtrl  = TextEditingController();
  String _type        = 'Fungicide';
  double _dosage      = 2.5;
  double _severity    = 50.0;

  final _types = ['Fungicide','Bactericide','Organic','Pesticide','Other'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Start Treatment',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          const SizedBox(height: 20),

          TextField(controller: _diseaseCtrl,
              decoration: const InputDecoration(
                labelText:  'Disease being treated',
                prefixIcon: Icon(Icons.bug_report_outlined))),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText:  'Treatment / medicine name',
                prefixIcon: Icon(Icons.healing_outlined))),
          const SizedBox(height: 12),

          // Treatment type
          const Text('Treatment Type',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.textSecond)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: _types.map((t) {
            final sel = t == _type;
            return GestureDetector(
              onTap: () => setState(() => _type = t),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:        sel
                      ? AppColors.primary
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? AppColors.primary
                        : AppColors.border)),
                child: Text(t,
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w500,
                      color:      sel
                          ? Colors.white
                          : AppColors.textSecond)),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),

          _SliderField('Dosage', _dosage, 0.5, 10, 'g/L or ml/L',
              (v) => setState(()=>_dosage=v)),
          _SliderField('Current Disease Severity',
              _severity, 0, 100, '%',
              (v) => setState(()=>_severity=v)),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () async {
                if (_nameCtrl.text.isEmpty ||
                    _diseaseCtrl.text.isEmpty) return;
                final log = TreatmentLog(
                  id:              const Uuid().v4(),
                  startDate:       DateTime.now(),
                  diseaseTreated:  _diseaseCtrl.text,
                  treatmentName:   _nameCtrl.text,
                  treatmentType:   _type,
                  dosage:          _dosage,
                  dosageUnit:      'g/L',
                  severityBefore:  _severity,
                );
                await _storage.addTreatmentLog(
                    widget.plantId, log);
                widget.onSaved();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Start Treatment'),
            ),
          ),
        ],
      )),
    );
  }
}

// ── Follow-Up Scan Sheet ───────────────────────────────────────
class _FollowUpSheet extends StatefulWidget {
  final TreatmentLog log;
  final String       plantId;
  final VoidCallback onSaved;
  const _FollowUpSheet({
    required this.log, required this.plantId,
    required this.onSaved,
  });
  @override
  State<_FollowUpSheet> createState() => _FollowUpSheetState();
}

class _FollowUpSheetState extends State<_FollowUpSheet> {
  final _storage    = StorageService();
  double _afterSeverity = 20.0;
  String _status    = 'completed';

  @override
  Widget build(BuildContext context) {
    final before = widget.log.severityBefore;
    final eff    = ((before - _afterSeverity) / before * 100)
        .clamp(0.0, 100.0);

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Follow-Up Scan Result',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Treatment: ${widget.log.treatmentName}',
              style: const TextStyle(
                  color: AppColors.textSecond, fontSize: 13)),
          const SizedBox(height: 20),

          Row(children: [
            Expanded(child: _SeverityIndicator(
              label: 'Before',
              value: widget.log.severityBefore,
              color: AppColors.diseased,
              icon:  Icons.arrow_downward_rounded,
            )),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward_rounded,
                color: AppColors.textHint, size: 20),
            const SizedBox(width: 16),
            Expanded(child: _SeverityIndicator(
              label: 'After',
              value: _afterSeverity,
              color: _afterSeverity < before
                  ? AppColors.healthy : AppColors.diseased,
              icon:  Icons.arrow_upward_rounded,
            )),
          ]),
          const SizedBox(height: 16),

          _SliderField('Current Severity After Treatment',
              _afterSeverity, 0, 100, '%',
              (v) => setState(()=>_afterSeverity=v)),

          // Live effectiveness preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        eff >= 50
                  ? AppColors.healthy.withOpacity(0.08)
                  : AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(eff >= 80
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
                  color: eff >= 50
                      ? AppColors.healthy : AppColors.warning,
                  size: 18),
              const SizedBox(width: 8),
              Text('Treatment Effectiveness: '
                  '${eff.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      eff >= 50
                        ? AppColors.healthy : AppColors.warning)),
            ]),
          ),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final updated = TreatmentLog(
                  id:              widget.log.id,
                  startDate:       widget.log.startDate,
                  endDate:         DateTime.now(),
                  diseaseTreated:  widget.log.diseaseTreated,
                  treatmentName:   widget.log.treatmentName,
                  treatmentType:   widget.log.treatmentType,
                  dosage:          widget.log.dosage,
                  dosageUnit:      widget.log.dosageUnit,
                  severityBefore:  widget.log.severityBefore,
                  severityAfter:   _afterSeverity,
                  beforeImagePath: widget.log.beforeImagePath,
                  status:          'completed',
                  notes:           widget.log.notes,
                );
                await _storage.updateTreatmentLog(
                    widget.plantId, updated);
                widget.onSaved();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save Follow-Up Result'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
