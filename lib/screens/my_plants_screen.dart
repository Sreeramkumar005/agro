// lib/screens/my_plants_screen.dart
// Like Healthify Me food diary — but for plants

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import 'plant_detail_screen.dart';

class MyPlantsScreen extends StatefulWidget {
  final VoidCallback onRefresh;
  const MyPlantsScreen({required this.onRefresh, super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final _storage = StorageService();
  List<Plant>  _plants  = [];
  bool         _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plants = await _storage.getPlants();
    if (mounted) setState(() { _plants = plants; _loading = false; });
  }

  Future<void> _addPlant() async {
    final result = await showModalBottomSheet<Plant>(
      context:          context,
      isScrollControlled: true,
      backgroundColor:  Colors.transparent,
      builder: (_)      => const _AddPlantSheet(),
    );
    if (result != null) {
      await _storage.savePlant(result);
      _load();
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Plants'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:        AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add,
                  color: Colors.white, size: 18),
            ),
            onPressed: _addPlant,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plants.isEmpty
              ? _buildEmpty()
              : _buildPlantList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color:        AppColors.accentLight,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.eco_outlined,
                size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No plants yet',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Add your first plant to start\ntracking its health and nutrition',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecond,
                height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addPlant,
            icon:  const Icon(Icons.add),
            label: const Text('Add First Plant'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantList() {
    return RefreshIndicator(
      onRefresh: _load,
      color:     AppColors.primary,
      child: ListView.separated(
        padding:          const EdgeInsets.all(AppSpacing.md),
        itemCount:        _plants.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) => _PlantCard(
          plant:     _plants[i],
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) =>
                  PlantDetailScreen(plant: _plants[i])));
            _load();
          },
        ),
      ),
    );
  }
}

// ── Plant Card ─────────────────────────────────────────────────
class _PlantCard extends StatelessWidget {
  final Plant        plant;
  final VoidCallback onTap;
  const _PlantCard({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: AppRadius.xl,
          border: Border.all(color: AppColors.border),
          boxShadow:    AppShadow.sm,
        ),
        child: Column(children: [
          Row(children: [
            // Crop emoji
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color:        plant.healthColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(plant.cropEmoji,
                  style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),

            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plant.name,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text('${plant.cropType} · ${plant.daysOld} days old',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecond)),
                if (plant.fieldLocation != null)
                  Text('📍 ${plant.fieldLocation}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
              ],
            )),

            // Health score badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${plant.healthScore.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize:   24,
                      fontWeight: FontWeight.w800,
                      color:      plant.healthColor)),
                const Text('/ 100',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ]),
          const SizedBox(height: 14),

          // Health progress bar with label
          Row(children: [
            Text(plant.healthStatus,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: plant.healthColor)),
            const Spacer(),
            Text('${plant.healthLogs.length} scans',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value:           plant.healthScore / 100,
              minHeight:       8,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(plant.healthColor),
            ),
          ),
          const SizedBox(height: 12),

          // Last disease + nutrient score row
          Row(children: [
            // Last disease
            Expanded(child: _InfoChip(
              icon:  Icons.bug_report_outlined,
              label: 'Last issue',
              value: plant.lastDisease != null
                  ? plant.lastDisease!
                      .replaceAll('___', ' → ')
                      .replaceAll('_', ' ')
                  : 'No disease detected',
              color: plant.lastDisease != null
                  ? AppColors.diseased
                  : AppColors.healthy,
            )),
            const SizedBox(width: 10),
            // Latest nutrient score
            if (plant.nutrientLogs.isNotEmpty)
              _InfoChip(
                icon:  Icons.science_outlined,
                label: 'Nutrients',
                value: '${plant.nutrientLogs.first.nutrientScore.toStringAsFixed(0)}% optimal',
                color: AppColors.info,
              ),
          ]),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Color    color;
  const _InfoChip({
    required this.icon, required this.label,
    required this.value, required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(
                fontSize: 9, color: color.withOpacity(0.7))),
            Text(value, style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    );
  }
}

// ── Add Plant Bottom Sheet ─────────────────────────────────────
class _AddPlantSheet extends StatefulWidget {
  const _AddPlantSheet();
  @override
  State<_AddPlantSheet> createState() => _AddPlantSheetState();
}

class _AddPlantSheetState extends State<_AddPlantSheet> {
  final _nameCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  String   _cropType  = 'Tomato';
  String   _cropEmoji = '🍅';
  DateTime _planted   = DateTime.now();

  final _crops = [
    {'type': 'Tomato',  'emoji': '🍅'},
    {'type': 'Potato',  'emoji': '🥔'},
    {'type': 'Pepper',  'emoji': '🌶️'},
  ];

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        AppColors.border,
              borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),

          const Text('Add New Plant',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          const SizedBox(height: 20),

          // Crop type selector
          const Text('Crop Type',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textSecond)),
          const SizedBox(height: 8),
          Row(children: _crops.map((c) {
            final sel = c['type'] == _cropType;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() {
                _cropType  = c['type']!;
                _cropEmoji = c['emoji']!;
              }),
              child: Container(
                margin:  const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:        sel
                      ? AppColors.primary
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? AppColors.primary
                        : AppColors.border),
                ),
                child: Column(children: [
                  Text(c['emoji']!,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(c['type']!,
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      sel
                            ? Colors.white
                            : AppColors.textSecond)),
                ]),
              ),
            ));
          }).toList()),
          const SizedBox(height: 16),

          // Plant name
          TextField(
            controller:  _nameCtrl,
            decoration: const InputDecoration(
              labelText:  'Plant Name (e.g. Tomato Row A)',
              prefixIcon: Icon(Icons.eco_outlined),
            ),
          ),
          const SizedBox(height: 12),

          // Field location
          TextField(
            controller:  _locationCtrl,
            decoration: const InputDecoration(
              labelText:  'Field Location (optional)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),

          // Planted date
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context:     context,
                initialDate: _planted,
                firstDate:   DateTime(2020),
                lastDate:    DateTime.now(),
              );
              if (date != null) setState(() => _planted = date);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.textSecond),
                const SizedBox(width: 12),
                Text(
                  'Planted: ${_planted.day}/${_planted.month}/${_planted.year}',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary)),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width:  double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                final plant = Plant(
                  id:            const Uuid().v4(),
                  name:          _nameCtrl.text.trim(),
                  cropType:      _cropType,
                  cropEmoji:     _cropEmoji,
                  plantedDate:   _planted,
                  fieldLocation: _locationCtrl.text.trim().isEmpty
                      ? null
                      : _locationCtrl.text.trim(),
                );
                Navigator.pop(context, plant);
              },
              child: const Text('Add Plant'),
            ),
          ),
        ],
      ),
    );
  }
}
