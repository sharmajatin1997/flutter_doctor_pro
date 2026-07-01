import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

class ScoreWeights {
  final int assets;
  final int codeQuality;
  final int complexity;
  final int theme;
  final int performance;
  final int dependencies;
  final int localization;

  const ScoreWeights({
    this.assets = 15,
    this.codeQuality = 25,
    this.complexity = 10,
    this.theme = 10,
    this.performance = 15,
    this.dependencies = 15,
    this.localization = 10,
  });

  factory ScoreWeights.fromYaml(YamlMap? yaml) {
    if (yaml == null) return const ScoreWeights();
    return ScoreWeights(
      assets: _parseInt(yaml['assets']) ?? 15,
      codeQuality: _parseInt(yaml['code_quality']) ?? 25,
      complexity: _parseInt(yaml['complexity']) ?? 10,
      theme: _parseInt(yaml['theme']) ?? 10,
      performance: _parseInt(yaml['performance']) ?? 15,
      dependencies: _parseInt(yaml['dependencies']) ?? 15,
      localization: _parseInt(yaml['localization']) ?? 10,
    );
  }
}

class AppConfig {
  final List<String> ignore;
  final double maxImageSizeMb;

  // Reports
  final bool reportHtml;
  final bool reportJson;
  final bool reportMarkdown;
  final bool reportCsv;

  // Scoring
  final int scoreMinimum;
  final ScoreWeights scoreWeights;

  // Scanners / Rules
  final Map<String, bool> rules;
  final Map<String, String> severityLevels;

  // Systems
  final bool backupEnabled;
  final int backupRetention;
  final bool cacheEnabled;
  final bool parallelScanning;
  final bool interactiveEnabled;

  const AppConfig({
    this.ignore = const [
      'build/**',
      'ios/**',
      'android/**',
      'web/**',
      'macos/**',
      'linux/**',
      'windows/**',
      '.dart_tool/**',
    ],
    this.maxImageSizeMb = 1.0,
    this.reportHtml = false,
    this.reportJson = false,
    this.reportMarkdown = false,
    this.reportCsv = false,
    this.scoreMinimum = 80,
    this.scoreWeights = const ScoreWeights(),
    this.rules = const {},
    this.severityLevels = const {},
    this.backupEnabled = true,
    this.backupRetention = 5,
    this.cacheEnabled = true,
    this.parallelScanning = true,
    this.interactiveEnabled = true,
  });

  factory AppConfig.fromYaml(String yamlString) {
    try {
      final yaml = loadYaml(yamlString) as YamlMap;
      return AppConfig(
        ignore:
            _parseStringList(yaml['ignore']) ??
            const [
              'build/**',
              'ios/**',
              'android/**',
              'web/**',
              'macos/**',
              'linux/**',
              'windows/**',
              '.dart_tool/**',
            ],
        maxImageSizeMb: _parseDouble(yaml['max_image_size_mb']) ?? 1.0,
        reportHtml: _parseBool(yaml['report']?['html']) ?? false,
        reportJson: _parseBool(yaml['report']?['json']) ?? false,
        reportMarkdown: _parseBool(yaml['report']?['markdown']) ?? false,
        reportCsv: _parseBool(yaml['report']?['csv']) ?? false,
        scoreMinimum: _parseInt(yaml['score']?['minimum']) ?? 80,
        scoreWeights: ScoreWeights.fromYaml(
          yaml['score']?['weights'] as YamlMap?,
        ),
        rules: _parseMap<bool>(yaml['rules']),
        severityLevels: _parseMap<String>(yaml['severity']),
        backupEnabled: _parseBool(yaml['backup']?['enabled']) ?? true,
        backupRetention: _parseInt(yaml['backup']?['retention']) ?? 5,
        cacheEnabled: _parseBool(yaml['cache']?['enabled']) ?? true,
        parallelScanning: _parseBool(yaml['parallel_scanning']) ?? true,
        interactiveEnabled: _parseBool(yaml['interactive']?['enabled']) ?? true,
      );
    } catch (e) {
      return const AppConfig();
    }
  }

  static Future<AppConfig> load([String directory = '.']) async {
    final file = File(p.join(directory, 'flutter_doctor_pro.yaml'));
    if (await file.exists()) {
      final content = await file.readAsString();
      return AppConfig.fromYaml(content);
    }
    return const AppConfig();
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  static Map<String, T> _parseMap<T>(dynamic value) {
    if (value is YamlMap) {
      return value.map((key, val) => MapEntry(key.toString(), val as T));
    }
    return {};
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }
}

int? _parseInt(dynamic value) => AppConfig._parseInt(value);
