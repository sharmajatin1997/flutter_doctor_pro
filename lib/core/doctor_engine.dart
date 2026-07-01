import 'dart:io';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/plugins/scanner_plugin.dart';
import 'package:flutter_doctor_pro/scanners/asset_scanner_plugin.dart';
import 'package:flutter_doctor_pro/scanners/build_analyzer_plugin.dart';
import 'package:flutter_doctor_pro/scanners/code_quality_scanner_plugin.dart';
import 'package:flutter_doctor_pro/scanners/localization_scanner_plugin.dart';
import 'package:flutter_doctor_pro/scanners/package_scanner_plugin.dart';
import 'package:flutter_doctor_pro/scanners/performance_scanner_plugin.dart';
import 'package:flutter_doctor_pro/scanners/theme_scanner_plugin.dart';
import 'package:flutter_doctor_pro/scanners/widget_complexity_scanner_plugin.dart';
import 'package:flutter_doctor_pro/cache/cache_manager.dart';

class DoctorEngine {
  final ProjectContext context;
  final List<ScannerPlugin> _plugins = [];

  DoctorEngine(this.context) {
    _registerDefaultPlugins();
  }

  void _registerDefaultPlugins() {
    _plugins.addAll([
      AssetScannerPlugin(),
      LocalizationScannerPlugin(),
      CodeQualityScannerPlugin(),
      WidgetComplexityScannerPlugin(),
      ThemeScannerPlugin(),
      PerformanceScannerPlugin(),
      PackageScannerPlugin(),
      BuildAnalyzerPlugin(),
    ]);
  }

  void registerPlugin(ScannerPlugin plugin) {
    _plugins.add(plugin);
  }

  Future<ScannerResult> runAllScans() async {
    final allIssues = <Issue>[];
    final allMetrics = <String, dynamic>{};

    final cacheManager = CacheManager(context);
    await cacheManager.init();

    final activePlugins = _plugins.where((p) => p.isEnabled(context)).toList();

    if (context.config.parallelScanning) {
      final futures = activePlugins.map((plugin) => plugin.scan(context));
      final results = await Future.wait(futures);

      for (final result in results) {
        allIssues.addAll(result.issues);
        allMetrics.addAll(result.metrics);
      }
    } else {
      for (final plugin in activePlugins) {
        final result = await plugin.scan(context);
        allIssues.addAll(result.issues);
        allMetrics.addAll(result.metrics);
      }
    }

    // Populate cache with current state of files
    if (context.config.cacheEnabled) {
      String getPriority(String absPath) {
        final fileIssues = allIssues.where((i) => i.file == absPath).toList();
        if (fileIssues.isEmpty) return 'perfect';
        if (fileIssues.any((i) => i.severity == IssueSeverity.critical)) {
          return 'critical';
        }
        if (fileIssues.any((i) => i.severity == IssueSeverity.high)) {
          return 'high';
        }
        if (fileIssues.any((i) => i.severity == IssueSeverity.medium)) {
          return 'medium';
        }
        if (fileIssues.any((i) => i.severity == IssueSeverity.low)) {
          return 'low';
        }
        return 'perfect';
      }

      final libDir = Directory('${context.directory}/lib');
      if (libDir.existsSync()) {
        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));
        for (final f in dartFiles) {
          final relPath = f.path.replaceFirst('${context.directory}/', '');
          final fileIssues = allIssues.where((i) => i.file == f.path).toList();
          final mappedIssues = fileIssues
              .map(
                (i) => {
                  'title': i.title,
                  'description': i.description,
                  'suggestion': i.suggestion,
                },
              )
              .toList();
          await cacheManager.updateCache(
            relPath,
            priority: getPriority(f.path),
            issues: mappedIssues,
          );
        }
      }
      final pubspecPath = '${context.directory}/pubspec.yaml';
      final pubspecIssues = allIssues
          .where((i) => i.file == pubspecPath)
          .toList();
      final mappedPubspecIssues = pubspecIssues
          .map(
            (i) => {
              'title': i.title,
              'description': i.description,
              'suggestion': i.suggestion,
            },
          )
          .toList();
      await cacheManager.updateCache(
        'pubspec.yaml',
        priority: getPriority(pubspecPath),
        issues: mappedPubspecIssues,
      );
    }

    await cacheManager.save();

    return ScannerResult(issues: allIssues, metrics: allMetrics);
  }
}
