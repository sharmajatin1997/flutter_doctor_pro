import 'dart:io';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/plugins/scanner_plugin.dart';

class BuildAnalyzerPlugin implements ScannerPlugin {
  @override
  String get name => 'Build Analyzer';

  @override
  bool isEnabled(ProjectContext context) =>
      context.config.rules['build_analyzer'] ?? true;

  @override
  Future<ScannerResult> scan(ProjectContext context) async {
    context.logger.startSpinner('Analyzing Builds...');
    final issues = <Issue>[];

    final androidBuildDir = Directory(
      '${context.directory}/build/app/outputs/flutter-apk/',
    );
    double totalApkSizeMb = 0;

    if (androidBuildDir.existsSync()) {
      final apks = androidBuildDir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.apk'),
      );
      for (final apk in apks) {
        final sizeMb = apk.lengthSync() / (1024 * 1024);
        totalApkSizeMb += sizeMb;

        if (sizeMb > 50) {
          issues.add(
            Issue(
              title: 'Large APK Size',
              description:
                  'APK ${apk.path.split('/').last} is ${sizeMb.toStringAsFixed(2)}MB.',
              category: 'Performance',
              severity: IssueSeverity.medium,
              suggestion:
                  'Use AppBundles (.aab) for production. Compress assets and use ProGuard.',
            ),
          );
        }
      }
    }

    context.logger.stopSpinner();
    return ScannerResult(
      issues: issues,
      metrics: {'total_apk_size_mb': totalApkSizeMb},
    );
  }
}
