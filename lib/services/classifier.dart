// lib/services/classifier.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import '../models/app_models.dart';

class DiseaseClassifier {
  static final DiseaseClassifier _instance =
      DiseaseClassifier._internal();
  factory DiseaseClassifier() => _instance;
  DiseaseClassifier._internal();

  OrtSession?  _session;
  List<String> _labels   = [];
  bool         _isLoaded = false;

  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std  = [0.229, 0.224, 0.225];
  static const int          _size = 224;

  // ── Load model ────────────────────────────────────────────
  Future<void> loadModel() async {
    if (_isLoaded) return;

    OrtEnv.instance.init();

    final raw  = await rootBundle.load(
        'assets/models/hybridcropnet.onnx');
    final opts = OrtSessionOptions()
      ..setInterOpNumThreads(2)
      ..setIntraOpNumThreads(2);

    _session = OrtSession.fromBuffer(
        raw.buffer.asUint8List(), opts);

    final lbl = await rootBundle.loadString(
        'assets/models/labels.txt');
    _labels = lbl
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    _isLoaded = true;
  }

  // ── Preprocess image ──────────────────────────────────────
  Float32List _preprocess(File file) {
    final bytes   = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes)!;
    final resized = img.copyResize(
      decoded,
      width:  _size,
      height: _size,
    );

    final input = Float32List(3 * _size * _size);
    int idx = 0;

    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < _size; y++) {
        for (int x = 0; x < _size; x++) {
          final p   = resized.getPixel(x, y);
          final raw = c == 0
              ? p.r / 255.0
              : c == 1
                  ? p.g / 255.0
                  : p.b / 255.0;
          input[idx++] = (raw - _mean[c]) / _std[c];
        }
      }
    }
    return input;
  }

  // ── Softmax ───────────────────────────────────────────────
  List<double> _softmax(List<double> logits) {
    final mx   = logits.reduce(max);
    final exps = logits.map((l) => exp(l - mx)).toList();
    final sum  = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  // ── Clean label ───────────────────────────────────────────
  String _clean(String raw) => raw
      .replaceAll('___', ' → ')
      .replaceAll('__', ' ')
      .replaceAll('_', ' ')
      .trim();

  // ── Crop info ─────────────────────────────────────────────
  Map<String, String> _cropInfo(String label) {
    final l = label.toLowerCase();
    if (l.contains('tomato')) return {'t': 'Tomato', 'e': '🍅'};
    if (l.contains('potato')) return {'t': 'Potato', 'e': '🥔'};
    return {'t': 'Pepper', 'e': '🌶️'};
  }

  // ── Run inference ─────────────────────────────────────────
  Future<PredictionResult> predict(
      File file, String resultId) async {
    if (!_isLoaded) await loadModel();

    // Preprocess
    final data   = _preprocess(file);
    final tensor = OrtValueTensor.createTensorWithDataList(
        data, [1, 3, _size, _size]);

    // Run model
    final feeds   = <String, OrtValue>{'image': tensor};
    final runOpts = OrtRunOptions();
    final outputs = await _session!.runAsync(runOpts, feeds);

    // Get logits
    final logits = List<double>.from(
        (outputs![0]?.value as List)[0]);

    // Softmax
    final probs = _softmax(logits);

    // Sort by probability
    final indexed = List.generate(
        _labels.length, (i) => {'i': i, 'p': probs[i]});
    indexed.sort((a, b) =>
        (b['p'] as double).compareTo(a['p'] as double));

    // Top 5
    final top5 = indexed.take(5).map((e) {
      final i = e['i'] as int;
      return TopPrediction(
        name:        _labels[i],
        cleanName:   _clean(_labels[i]),
        probability: (e['p'] as double) * 100,
        isHealthy:   _labels[i]
            .toLowerCase()
            .contains('healthy'),
      );
    }).toList();

    // Top result
    final topIdx   = indexed[0]['i'] as int;
    final topLabel = _labels[topIdx];
    final info     = _cropInfo(topLabel);

    // Release
    tensor.release();
    for (final o in outputs) {
      o?.release();
    }
    runOpts.release();

    return PredictionResult(
      id:          resultId,
      diseaseName: topLabel,
      cleanName:   _clean(topLabel),
      cropType:    info['t']!,
      cropEmoji:   info['e']!,
      confidence:  (indexed[0]['p'] as double) * 100,
      isHealthy:   topLabel.toLowerCase().contains('healthy'),
      top5:        top5,
      timestamp:   DateTime.now(),
      imagePath:   file.path,
    );
  }

  // ── Dispose ───────────────────────────────────────────────
  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
    _isLoaded = false;
  }
}