// lib/models/app_models.dart

import 'dart:convert';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// PREDICTION RESULT
// ══════════════════════════════════════════════════════════════
class PredictionResult {
  final String id;
  final String diseaseName;
  final String cleanName;
  final String cropType;
  final String cropEmoji;
  final double confidence;
  final bool   isHealthy;
  final List<TopPrediction> top5;
  final DateTime timestamp;
  final String? imagePath;
  final String? location;
  final double? latitude;
  final double? longitude;

  PredictionResult({
    required this.id,
    required this.diseaseName,
    required this.cleanName,
    required this.cropType,
    required this.cropEmoji,
    required this.confidence,
    required this.isHealthy,
    required this.top5,
    required this.timestamp,
    this.imagePath,
    this.location,
    this.latitude,
    this.longitude,
  });

  String get severityLevel {
    if (isHealthy) return 'Healthy';
    if (confidence >= 95) return 'Critical';
    if (confidence >= 80) return 'High Severity';
    if (confidence >= 60) return 'Moderate';
    return 'Low Severity';
  }

  Color get severityColor {
    if (isHealthy)        return const Color(0xFF2E7D32);
    if (confidence >= 95) return const Color(0xFFB71C1C);
    if (confidence >= 80) return const Color(0xFFE53935);
    if (confidence >= 60) return const Color(0xFFE65100);
    return const Color(0xFFF57F17);
  }

  String get treatmentSuggestion {
    final n = diseaseName.toLowerCase();
    if (isHealthy) return 'Your plant is in excellent health! Continue regular monitoring and maintain good agricultural practices to prevent future disease outbreaks.';
    if (n.contains('bacterial_spot') || n.contains('bacterial spot')) {
      return 'Apply copper-based bactericides such as Copper Oxychloride (3g/L). Remove and destroy infected leaves. Avoid overhead irrigation. Space plants adequately for airflow. Repeat spray every 7–10 days.';
    }
    if (n.contains('early_blight') || n.contains('early blight')) {
      return 'Apply fungicide containing Mancozeb (2.5g/L) or Chlorothalonil. Remove lower infected leaves. Mulch around plants. Rotate crops next season. Spray every 7 days during wet weather.';
    }
    if (n.contains('late_blight') || n.contains('late blight')) {
      return 'Apply Metalaxyl + Mancozeb (Ridomil) immediately. Remove and burn infected plant parts. Do NOT compost. Improve field drainage. Avoid working in fields when wet. Act within 24 hours.';
    }
    if (n.contains('leaf_mold') || n.contains('leaf mold')) {
      return 'Apply fungicide containing Chlorothalonil or Copper. Improve greenhouse ventilation. Reduce humidity below 85%. Remove infected leaves. Avoid wetting foliage when watering.';
    }
    if (n.contains('septoria')) {
      return 'Apply fungicide with Mancozeb or Azoxystrobin. Remove infected lower leaves. Stake plants for better air circulation. Avoid overhead irrigation. Mulch to prevent soil splash.';
    }
    if (n.contains('spider') || n.contains('mite')) {
      return 'Apply miticide (Abamectin or Spiromesifen) or neem oil spray (5ml/L). Increase humidity around plants. Remove heavily infested leaves. Spray undersides of leaves thoroughly.';
    }
    if (n.contains('target_spot') || n.contains('target spot')) {
      return 'Apply Azoxystrobin or Pyraclostrobin fungicide. Prune lower leaves for better airflow. Avoid overhead watering. Rotate crops. Monitor closely as disease spreads rapidly.';
    }
    if (n.contains('yellowleaf') || n.contains('yellow leaf') || n.contains('curl')) {
      return 'No direct cure for viral infection. Remove and destroy infected plants immediately. Control whitefly vectors using yellow sticky traps and imidacloprid. Use virus-resistant varieties next season.';
    }
    if (n.contains('mosaic') || n.contains('virus')) {
      return 'Remove infected plants to prevent spread. Control aphid vectors with insecticidal soap. Wash hands and tools after handling infected plants. Use certified disease-free seeds next season.';
    }
    return 'Consult your local agricultural extension officer. Document symptoms and treatment applied using this app\'s tracker for best results.';
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'diseaseName': diseaseName,
    'cleanName':   cleanName,
    'cropType':    cropType,
    'cropEmoji':   cropEmoji,
    'confidence':  confidence,
    'isHealthy':   isHealthy,
    'top5':        top5.map((e) => e.toJson()).toList(),
    'timestamp':   timestamp.toIso8601String(),
    'imagePath':   imagePath,
    'location':    location,
    'latitude':    latitude,
    'longitude':   longitude,
  };

  factory PredictionResult.fromJson(Map<String, dynamic> j) =>
      PredictionResult(
        id:          j['id'] ?? '',
        diseaseName: j['diseaseName'] ?? '',
        cleanName:   j['cleanName'] ?? '',
        cropType:    j['cropType'] ?? '',
        cropEmoji:   j['cropEmoji'] ?? '🌿',
        confidence:  (j['confidence'] ?? 0.0).toDouble(),
        isHealthy:   j['isHealthy'] ?? false,
        top5: (j['top5'] as List? ?? [])
            .map((e) => TopPrediction.fromJson(e))
            .toList(),
        timestamp:  DateTime.parse(
            j['timestamp'] ?? DateTime.now().toIso8601String()),
        imagePath:  j['imagePath'],
        location:   j['location'],
        latitude:   j['latitude']?.toDouble(),
        longitude:  j['longitude']?.toDouble(),
      );
}

class TopPrediction {
  final String name;
  final String cleanName;
  final double probability;
  final bool   isHealthy;

  TopPrediction({
    required this.name,
    required this.cleanName,
    required this.probability,
    required this.isHealthy,
  });

  Map<String, dynamic> toJson() => {
    'name':        name,
    'cleanName':   cleanName,
    'probability': probability,
    'isHealthy':   isHealthy,
  };

  factory TopPrediction.fromJson(Map<String, dynamic> j) =>
      TopPrediction(
        name:        j['name'] ?? '',
        cleanName:   j['cleanName'] ?? '',
        probability: (j['probability'] ?? 0.0).toDouble(),
        isHealthy:   j['isHealthy'] ?? false,
      );
}

// ══════════════════════════════════════════════════════════════
// PLANT (like a patient profile in health apps)
// ══════════════════════════════════════════════════════════════
class Plant {
  final String   id;
  String         name;          // e.g. "Tomato Row A"
  String         cropType;      // Tomato / Potato / Pepper
  String         cropEmoji;
  DateTime       plantedDate;
  String?        fieldLocation;
  String?        imagePath;
  List<PlantHealthLog> healthLogs;
  List<NutrientLog>    nutrientLogs;
  List<TreatmentLog>   treatmentLogs;
  String         notes;

  Plant({
    required this.id,
    required this.name,
    required this.cropType,
    required this.cropEmoji,
    required this.plantedDate,
    this.fieldLocation,
    this.imagePath,
    List<PlantHealthLog>? healthLogs,
    List<NutrientLog>?    nutrientLogs,
    List<TreatmentLog>?   treatmentLogs,
    this.notes = '',
  })  : healthLogs    = healthLogs    ?? [],
        nutrientLogs  = nutrientLogs  ?? [],
        treatmentLogs = treatmentLogs ?? [];

  // Days since planted
  int get daysOld =>
      DateTime.now().difference(plantedDate).inDays;

  // Current health score 0-100 based on recent scans
  double get healthScore {
    if (healthLogs.isEmpty) return 100.0;
    final recent = healthLogs.take(3).toList();
    double sum = 0;
    for (final log in recent) {
      sum += log.isHealthy
          ? 100.0
          : (100.0 - log.diseaseSeverity);
    }
    return sum / recent.length;
  }

  String get healthStatus {
    final s = healthScore;
    if (s >= 85) return 'Excellent';
    if (s >= 70) return 'Good';
    if (s >= 50) return 'Fair';
    if (s >= 30) return 'Poor';
    return 'Critical';
  }

  Color get healthColor {
    final s = healthScore;
    if (s >= 85) return const Color(0xFF2E7D32);
    if (s >= 70) return const Color(0xFF558B2F);
    if (s >= 50) return const Color(0xFFF57F17);
    if (s >= 30) return const Color(0xFFE65100);
    return const Color(0xFFB71C1C);
  }

  // Last disease detected
  String? get lastDisease {
    final diseased = healthLogs
        .where((l) => !l.isHealthy)
        .toList();
    if (diseased.isEmpty) return null;
    diseased.sort((a, b) => b.date.compareTo(a.date));
    return diseased.first.diseaseName;
  }

  Map<String, dynamic> toJson() => {
    'id':            id,
    'name':          name,
    'cropType':      cropType,
    'cropEmoji':     cropEmoji,
    'plantedDate':   plantedDate.toIso8601String(),
    'fieldLocation': fieldLocation,
    'imagePath':     imagePath,
    'healthLogs':    healthLogs.map((e) => e.toJson()).toList(),
    'nutrientLogs':  nutrientLogs.map((e) => e.toJson()).toList(),
    'treatmentLogs': treatmentLogs.map((e) => e.toJson()).toList(),
    'notes':         notes,
  };

  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
    id:            j['id'] ?? '',
    name:          j['name'] ?? '',
    cropType:      j['cropType'] ?? '',
    cropEmoji:     j['cropEmoji'] ?? '🌿',
    plantedDate:   DateTime.parse(j['plantedDate'] ??
                       DateTime.now().toIso8601String()),
    fieldLocation: j['fieldLocation'],
    imagePath:     j['imagePath'],
    healthLogs: (j['healthLogs'] as List? ?? [])
        .map((e) => PlantHealthLog.fromJson(e)).toList(),
    nutrientLogs: (j['nutrientLogs'] as List? ?? [])
        .map((e) => NutrientLog.fromJson(e)).toList(),
    treatmentLogs: (j['treatmentLogs'] as List? ?? [])
        .map((e) => TreatmentLog.fromJson(e)).toList(),
    notes: j['notes'] ?? '',
  );
}

// ══════════════════════════════════════════════════════════════
// PLANT HEALTH LOG (like food diary in nutrition app)
// Each scan creates one log entry
// ══════════════════════════════════════════════════════════════
class PlantHealthLog {
  final String   id;
  final DateTime date;
  final bool     isHealthy;
  final String   diseaseName;
  final String   cleanName;
  final double   confidence;
  final double   diseaseSeverity;  // 0-100
  final double   healthScore;      // 0-100
  final String?  imagePath;
  final String?  notes;

  PlantHealthLog({
    required this.id,
    required this.date,
    required this.isHealthy,
    required this.diseaseName,
    required this.cleanName,
    required this.confidence,
    required this.diseaseSeverity,
    required this.healthScore,
    this.imagePath,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id':               id,
    'date':             date.toIso8601String(),
    'isHealthy':        isHealthy,
    'diseaseName':      diseaseName,
    'cleanName':        cleanName,
    'confidence':       confidence,
    'diseaseSeverity':  diseaseSeverity,
    'healthScore':      healthScore,
    'imagePath':        imagePath,
    'notes':            notes,
  };

  factory PlantHealthLog.fromJson(Map<String, dynamic> j) =>
      PlantHealthLog(
        id:              j['id'] ?? '',
        date:            DateTime.parse(j['date'] ??
                             DateTime.now().toIso8601String()),
        isHealthy:       j['isHealthy'] ?? true,
        diseaseName:     j['diseaseName'] ?? '',
        cleanName:       j['cleanName'] ?? '',
        confidence:      (j['confidence'] ?? 0.0).toDouble(),
        diseaseSeverity: (j['diseaseSeverity'] ?? 0.0).toDouble(),
        healthScore:     (j['healthScore'] ?? 100.0).toDouble(),
        imagePath:       j['imagePath'],
        notes:           j['notes'],
      );
}

// ══════════════════════════════════════════════════════════════
// NUTRIENT LOG (like nutrition tracking in Healthify Me)
// Tracks plant nutrients: N, P, K, pH, water, sunlight
// ══════════════════════════════════════════════════════════════
class NutrientLog {
  final String   id;
  final DateTime date;
  final double   nitrogen;       // kg/ha (ideal: 80-120)
  final double   phosphorus;     // kg/ha (ideal: 40-60)
  final double   potassium;      // kg/ha (ideal: 80-100)
  final double   soilPH;        // ideal: 6.0-7.0
  final double   wateringMM;    // mm per day (ideal: 20-40)
  final double   sunlightHours; // hours per day (ideal: 6-8)
  final double   temperature;   // °C (ideal: 20-30)
  final double   humidity;      // % (ideal: 60-80)
  final String?  fertilizerUsed;
  final String?  notes;

  NutrientLog({
    required this.id,
    required this.date,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.soilPH,
    required this.wateringMM,
    required this.sunlightHours,
    required this.temperature,
    required this.humidity,
    this.fertilizerUsed,
    this.notes,
  });

  // Overall nutrient score 0-100
  double get nutrientScore {
    double score = 0;
    score += _scoreRange(nitrogen,       80,  120) * 20;
    score += _scoreRange(phosphorus,     40,   60) * 20;
    score += _scoreRange(potassium,      80,  100) * 20;
    score += _scoreRange(soilPH,        6.0,  7.0) * 20;
    score += _scoreRange(wateringMM,     20,   40) * 10;
    score += _scoreRange(sunlightHours,   6,    8) * 10;
    return score.clamp(0, 100);
  }

  double _scoreRange(double val, double min, double max) {
    if (val >= min && val <= max) return 1.0;
    if (val < min) return (val / min).clamp(0, 1);
    return (max / val).clamp(0, 1);
  }

  // Nutrient status labels
  String get nitrogenStatus => _status(nitrogen, 80, 120);
  String get phosphorusStatus => _status(phosphorus, 40, 60);
  String get potassiumStatus => _status(potassium, 80, 100);
  String get phStatus => _status(soilPH, 6.0, 7.0);

  String _status(double val, double min, double max) {
    if (val < min * 0.7) return 'Very Low';
    if (val < min)       return 'Low';
    if (val <= max)      return 'Optimal';
    if (val <= max * 1.3) return 'High';
    return 'Very High';
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Optimal': return const Color(0xFF2E7D32);
      case 'Low':     return const Color(0xFFE65100);
      case 'High':    return const Color(0xFF01579B);
      case 'Very Low':  return const Color(0xFFB71C1C);
      case 'Very High': return const Color(0xFF0D47A1);
      default:        return const Color(0xFF757575);
    }
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'date':           date.toIso8601String(),
    'nitrogen':       nitrogen,
    'phosphorus':     phosphorus,
    'potassium':      potassium,
    'soilPH':         soilPH,
    'wateringMM':     wateringMM,
    'sunlightHours':  sunlightHours,
    'temperature':    temperature,
    'humidity':       humidity,
    'fertilizerUsed': fertilizerUsed,
    'notes':          notes,
  };

  factory NutrientLog.fromJson(Map<String, dynamic> j) =>
      NutrientLog(
        id:             j['id'] ?? '',
        date:           DateTime.parse(j['date'] ??
                            DateTime.now().toIso8601String()),
        nitrogen:       (j['nitrogen'] ?? 80.0).toDouble(),
        phosphorus:     (j['phosphorus'] ?? 40.0).toDouble(),
        potassium:      (j['potassium'] ?? 80.0).toDouble(),
        soilPH:         (j['soilPH'] ?? 6.5).toDouble(),
        wateringMM:     (j['wateringMM'] ?? 25.0).toDouble(),
        sunlightHours:  (j['sunlightHours'] ?? 6.0).toDouble(),
        temperature:    (j['temperature'] ?? 25.0).toDouble(),
        humidity:       (j['humidity'] ?? 70.0).toDouble(),
        fertilizerUsed: j['fertilizerUsed'],
        notes:          j['notes'],
      );
}

// ══════════════════════════════════════════════════════════════
// TREATMENT LOG (Before/After tracker)
// ══════════════════════════════════════════════════════════════
class TreatmentLog {
  final String   id;
  final DateTime startDate;
  DateTime?      endDate;
  final String   diseaseTreated;
  final String   treatmentName;     // e.g. "Mancozeb spray"
  final String   treatmentType;     // Fungicide / Bactericide / Organic
  final double   dosage;            // ml or g
  final String   dosageUnit;        // ml/L or g/L
  final double   severityBefore;   // 0-100
  double?        severityAfter;    // filled after follow-up scan
  final String?  beforeImagePath;
  String?        afterImagePath;
  String         status;            // ongoing / completed / failed
  final String?  notes;

  TreatmentLog({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.diseaseTreated,
    required this.treatmentName,
    required this.treatmentType,
    required this.dosage,
    required this.dosageUnit,
    required this.severityBefore,
    this.severityAfter,
    this.beforeImagePath,
    this.afterImagePath,
    this.status = 'ongoing',
    this.notes,
  });

  // Treatment effectiveness %
  double? get effectiveness {
    if (severityAfter == null || severityBefore == 0) return null;
    return ((severityBefore - severityAfter!) / severityBefore * 100)
        .clamp(0, 100);
  }

  String get effectivenessLabel {
    final e = effectiveness;
    if (e == null) return 'Pending follow-up scan';
    if (e >= 80) return 'Highly Effective ✅';
    if (e >= 50) return 'Moderately Effective';
    if (e >= 20) return 'Low Effectiveness ⚠️';
    return 'Not Effective ❌';
  }

  Color get effectivenessColor {
    final e = effectiveness;
    if (e == null)  return const Color(0xFF757575);
    if (e >= 80)    return const Color(0xFF2E7D32);
    if (e >= 50)    return const Color(0xFFE65100);
    if (e >= 20)    return const Color(0xFFE53935);
    return const Color(0xFFB71C1C);
  }

  int get daysSinceStart =>
      DateTime.now().difference(startDate).inDays;

  Map<String, dynamic> toJson() => {
    'id':               id,
    'startDate':        startDate.toIso8601String(),
    'endDate':          endDate?.toIso8601String(),
    'diseaseTreated':   diseaseTreated,
    'treatmentName':    treatmentName,
    'treatmentType':    treatmentType,
    'dosage':           dosage,
    'dosageUnit':       dosageUnit,
    'severityBefore':   severityBefore,
    'severityAfter':    severityAfter,
    'beforeImagePath':  beforeImagePath,
    'afterImagePath':   afterImagePath,
    'status':           status,
    'notes':            notes,
  };

  factory TreatmentLog.fromJson(Map<String, dynamic> j) =>
      TreatmentLog(
        id:              j['id'] ?? '',
        startDate:       DateTime.parse(j['startDate'] ??
                             DateTime.now().toIso8601String()),
        endDate:         j['endDate'] != null
                             ? DateTime.parse(j['endDate'])
                             : null,
        diseaseTreated:  j['diseaseTreated'] ?? '',
        treatmentName:   j['treatmentName'] ?? '',
        treatmentType:   j['treatmentType'] ?? 'Fungicide',
        dosage:          (j['dosage'] ?? 2.5).toDouble(),
        dosageUnit:      j['dosageUnit'] ?? 'g/L',
        severityBefore:  (j['severityBefore'] ?? 0.0).toDouble(),
        severityAfter:   j['severityAfter']?.toDouble(),
        beforeImagePath: j['beforeImagePath'],
        afterImagePath:  j['afterImagePath'],
        status:          j['status'] ?? 'ongoing',
        notes:           j['notes'],
      );
}
