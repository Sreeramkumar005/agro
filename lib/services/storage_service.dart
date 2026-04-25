// lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class StorageService {
  static const _plantsKey     = 'plants_v1';
  static const _historyKey    = 'scan_history_v1';
  static const _settingsKey   = 'app_settings_v1';

  // ── PLANTS ──────────────────────────────────────────────────
  Future<List<Plant>> getPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_plantsKey) ?? [];
    return raw.map((e) =>
        Plant.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePlant(Plant plant) async {
    final prefs  = await SharedPreferences.getInstance();
    final plants = await getPlants();
    final idx    = plants.indexWhere((p) => p.id == plant.id);
    if (idx >= 0) {
      plants[idx] = plant;
    } else {
      plants.add(plant);
    }
    await prefs.setStringList(
        _plantsKey,
        plants.map((p) => jsonEncode(p.toJson())).toList());
  }

  Future<void> deletePlant(String plantId) async {
    final prefs  = await SharedPreferences.getInstance();
    final plants = await getPlants();
    plants.removeWhere((p) => p.id == plantId);
    await prefs.setStringList(
        _plantsKey,
        plants.map((p) => jsonEncode(p.toJson())).toList());
  }

  // Add a health log to a plant
  Future<void> addHealthLog(
      String plantId, PlantHealthLog log) async {
    final plants = await getPlants();
    final plant  = plants.firstWhere((p) => p.id == plantId,
        orElse: () => throw Exception('Plant not found'));
    plant.healthLogs.insert(0, log);
    await savePlant(plant);
  }

  // Add a nutrient log to a plant
  Future<void> addNutrientLog(
      String plantId, NutrientLog log) async {
    final plants = await getPlants();
    final plant  = plants.firstWhere((p) => p.id == plantId,
        orElse: () => throw Exception('Plant not found'));
    plant.nutrientLogs.insert(0, log);
    await savePlant(plant);
  }

  // Add a treatment log to a plant
  Future<void> addTreatmentLog(
      String plantId, TreatmentLog log) async {
    final plants = await getPlants();
    final plant  = plants.firstWhere((p) => p.id == plantId,
        orElse: () => throw Exception('Plant not found'));
    plant.treatmentLogs.insert(0, log);
    await savePlant(plant);
  }

  // Update treatment log (after follow-up scan)
  Future<void> updateTreatmentLog(
      String plantId, TreatmentLog updated) async {
    final plants = await getPlants();
    final plant  = plants.firstWhere((p) => p.id == plantId,
        orElse: () => throw Exception('Plant not found'));
    final idx    = plant.treatmentLogs
        .indexWhere((t) => t.id == updated.id);
    if (idx >= 0) plant.treatmentLogs[idx] = updated;
    await savePlant(plant);
  }

  // ── SCAN HISTORY ─────────────────────────────────────────────
  Future<List<PredictionResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_historyKey) ?? [];
    return raw.map((e) =>
        PredictionResult.fromJson(
            jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToHistory(PredictionResult result) async {
    final prefs   = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, result);
    // Keep last 200 scans
    final trimmed = history.take(200).toList();
    await prefs.setStringList(
        _historyKey,
        trimmed.map((r) => jsonEncode(r.toJson())).toList());
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // ── SETTINGS ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_settingsKey);
    if (raw == null) return _defaultSettings();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Map<String, dynamic> _defaultSettings() => {
    'notifications': true,
    'weeklyReminder': true,
    'language': 'English',
    'units': 'metric',
    'scanReminder': 7, // days
  };
}
