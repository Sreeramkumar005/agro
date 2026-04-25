// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import 'scan_screen.dart';
import 'my_plants_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int                _tab       = 0;
  final _storage             = StorageService();
  List<Plant>        _plants    = [];
  List<PredictionResult> _history = [];

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final plants  = await _storage.getPlants();
    final history = await _storage.getHistory();
    if (mounted) setState(() {
      _plants  = plants;
      _history = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardPage(
          plants: _plants,
          history: _history,
          onRefresh: _loadData),
      MyPlantsScreen(onRefresh: _loadData),
      const ScanScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap:   (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Dashboard page ─────────────────────────────────────────────
class _DashboardPage extends StatelessWidget {
  final List<Plant>            plants;
  final List<PredictionResult> history;
  final VoidCallback           onRefresh;

  const _DashboardPage({
    required this.plants,
    required this.history,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final diseased  = history.where((h) => !h.isHealthy).length;
    final healthy   = history.where((h) =>  h.isHealthy).length;
    final avgHealth = plants.isEmpty
        ? 100.0
        : plants.map((p) => p.healthScore).reduce((a,b)=>a+b)
              / plants.length;

    return CustomScrollView(
      slivers: [
        // ── Premium App Bar ─────────────────────────────────
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.primaryDark,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                  gradient: AppColors.gradientPrimary),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:  MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good Morning 👋',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13)),
                        const Text('Your Farm Dashboard',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   22,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 22),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: [

              // ── Stats row ──────────────────────────────────
              Row(children: [
                Expanded(child: _StatCard(
                  label:   'Total Plants',
                  value:   '${plants.length}',
                  icon:    Icons.eco_rounded,
                  color:   AppColors.primary,
                  subtitle: 'being tracked',
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label:   'Farm Health',
                  value:   '${avgHealth.toStringAsFixed(0)}%',
                  icon:    Icons.favorite_rounded,
                  color:   avgHealth >= 70
                      ? AppColors.healthy
                      : AppColors.warning,
                  subtitle: 'overall score',
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label:   'Total Scans',
                  value:   '${history.length}',
                  icon:    Icons.document_scanner_rounded,
                  color:   AppColors.info,
                  subtitle: 'all time',
                )),
              ]),
              const SizedBox(height: 20),

              // ── Quick scan card ────────────────────────────
              _QuickScanCard(context: context),
              const SizedBox(height: 20),

              // ── Disease overview ───────────────────────────
              if (history.isNotEmpty) ...[
                _SectionHeader('Disease Overview', ''),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _MiniStatCard(
                    label: 'Diseased',
                    value: '$diseased',
                    color: AppColors.diseased,
                    icon:  Icons.warning_amber_rounded,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _MiniStatCard(
                    label: 'Healthy',
                    value: '$healthy',
                    color: AppColors.healthy,
                    icon:  Icons.check_circle_outline_rounded,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _MiniStatCard(
                    label: 'Accuracy',
                    value: '99.68%',
                    color: AppColors.info,
                    icon:  Icons.verified_rounded,
                  )),
                ]),
                const SizedBox(height: 20),
              ],

              // ── My plants ──────────────────────────────────
              _SectionHeader('My Plants', 'See all'),
              const SizedBox(height: 12),
              if (plants.isEmpty)
                _EmptyPlantsCard(context: context)
              else
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: plants.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (_, i) =>
                        _PlantMiniCard(plant: plants[i]),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Recent scans ───────────────────────────────
              if (history.isNotEmpty) ...[
                _SectionHeader('Recent Scans', 'View all'),
                const SizedBox(height: 12),
                ...history.take(3).map(
                    (r) => _RecentScanTile(result: r)),
              ],
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String  label, value, subtitle;
  final IconData icon;
  final Color   color;
  const _StatCard({
    required this.label, required this.value,
    required this.icon,  required this.color,
    required this.subtitle,
  });
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: AppColors.textSecond)),
          Text(subtitle, style: const TextStyle(
            fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _QuickScanCard extends StatelessWidget {
  final BuildContext context;
  const _QuickScanCard({required this.context});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ScanScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient:     AppColors.gradientAccent,
          borderRadius: AppRadius.xl,
          boxShadow:    AppShadow.green,
        ),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Scan a Leaf',
                  style: TextStyle(
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                    color:      Colors.white)),
              const SizedBox(height: 4),
              Text('99.68% accuracy · 15 diseases',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Scan Now →',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      AppColors.primary)),
              ),
            ],
          )),
          const SizedBox(width: 16),
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.document_scanner_rounded,
                color: Colors.white, size: 38),
          ),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, action;
  const _SectionHeader(this.title, this.action);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary)),
      const Spacer(),
      if (action.isNotEmpty)
        Text(action, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: AppColors.primary)),
    ]);
  }
}

class _MiniStatCard extends StatelessWidget {
  final String  label, value;
  final Color   color;
  final IconData icon;
  const _MiniStatCard({
    required this.label, required this.value,
    required this.color, required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.07),
        borderRadius: AppRadius.lg,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: color)),
        Text(label, style: const TextStyle(
            fontSize: 10, color: AppColors.textSecond)),
      ]),
    );
  }
}

class _PlantMiniCard extends StatelessWidget {
  final Plant plant;
  const _PlantMiniCard({required this.plant});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border),
        boxShadow:    AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(plant.cropEmoji,
                style: const TextStyle(fontSize: 28)),
            const Spacer(),
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color:  plant.healthColor,
                shape:  BoxShape.circle,
              ),
            ),
          ]),
          const Spacer(),
          Text(plant.name,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${plant.healthScore.toStringAsFixed(0)}% health',
              style: const TextStyle(
                fontSize: 11, color: AppColors.textSecond)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           plant.healthScore / 100,
              minHeight:       5,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(plant.healthColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlantsCard extends StatelessWidget {
  final BuildContext context;
  const _EmptyPlantsCard({required this.context});
  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:        AppColors.accentLight,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(children: [
        const Icon(Icons.eco_outlined,
            size: 40, color: AppColors.primary),
        const SizedBox(height: 10),
        const Text('No plants tracked yet',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.primary)),
        const SizedBox(height: 4),
        const Text('Add your first plant to start tracking',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecond)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
          ),
          child: const Text('Add Plant'),
        ),
      ]),
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  final PredictionResult result;
  const _RecentScanTile({required this.result});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border),
        boxShadow:    AppShadow.sm,
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: result.isHealthy
                ? AppColors.healthy.withOpacity(0.10)
                : AppColors.diseased.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(result.cropEmoji,
              style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.cleanName,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${result.cropType} · '
                '${result.confidence.toStringAsFixed(1)}% confidence',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecond)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: result.isHealthy
                ? AppColors.healthy.withOpacity(0.10)
                : AppColors.diseased.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            result.isHealthy ? 'Healthy' : 'Diseased',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: result.isHealthy
                  ? AppColors.healthy
                  : AppColors.diseased)),
        ),
      ]),
    );
  }
}

// ── Bottom Navigation ──────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded,       'label': 'Home'},
      {'icon': Icons.eco_rounded,        'label': 'Plants'},
      {'icon': Icons.document_scanner_rounded, 'label': 'Scan'},
      {'icon': Icons.bar_chart_rounded,  'label': 'Analytics'},
      {'icon': Icons.person_rounded,     'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(
          color:     Colors.black.withOpacity(0.07),
          blurRadius: 20, offset: const Offset(0, -4))],
        border: const Border(
            top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i      = e.key;
              final item   = e.value;
              final active = i == current;
              final isScan = i == 2;
              if (isScan) {
                return Expanded(child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Center(
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: AppShadow.green,
                      ),
                      child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ));
              }
              return Expanded(child: GestureDetector(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'] as IconData,
                      size:  22,
                      color: active
                          ? AppColors.primary
                          : AppColors.textHint),
                    const SizedBox(height: 3),
                    Text(item['label'] as String,
                        style: TextStyle(
                          fontSize:   10,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : AppColors.textHint)),
                  ],
                ),
              ));
            }).toList(),
          ),
        ),
      ),
    );
  }
}
