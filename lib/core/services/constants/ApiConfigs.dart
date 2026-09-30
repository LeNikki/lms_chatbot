import 'dart:convert';

import 'package:flutter/services.dart';

class ApiConfigs {
  ApiConfigs._();

  static const _dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _envAssetPath = 'env.json';

  static String? _apiKey;

  static String get apiKey => _apiKey ?? '';

  static bool get isConfigured => (_apiKey ?? '').isNotEmpty;

  static Future<void> load() async {
    if (_dartDefineKey.isNotEmpty) {
      _apiKey = _dartDefineKey;
      return;
    }

    try {
      final raw = await rootBundle.loadString(_envAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _apiKey = decoded['API_KEY'] as String? ?? '';
      } else {
        _apiKey = '';
      }
    } catch (_) {
      _apiKey = '';
    }
  }
}
