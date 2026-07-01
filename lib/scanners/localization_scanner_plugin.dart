import 'dart:convert';
import 'package:flutter_doctor_pro/utils/file_utils.dart';

import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/plugins/scanner_plugin.dart';

class LocalizationScannerPlugin implements ScannerPlugin {
  @override
  String get name => 'Localization Scanner';

  @override
  bool isEnabled(ProjectContext context) =>
      context.config.rules['localization_scanner'] ?? true;

  @override
  Future<ScannerResult> scan(ProjectContext context) async {
    context.logger.startSpinner('Scanning Localizations...');
    final issues = <Issue>[];

    final arbFiles = FileUtils.getArbFiles(context.directory);
    if (arbFiles.isEmpty) {
      context.logger.stopSpinner();
      return ScannerResult(issues: issues);
    }

    final Map<String, Set<String>> keysPerLanguage = {};
    for (final file in arbFiles) {
      try {
        final content = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(content);
        final keys = json.keys.where((k) => !k.startsWith('@')).toSet();
        keysPerLanguage[file.path] = keys;
      } catch (e) {
        issues.add(
          Issue(
            title: 'Invalid ARB File',
            description: 'Could not parse ARB file: $e',
            category: 'Localization',
            severity: IssueSeverity.critical,
            file: file.path,
          ),
        );
      }
    }

    if (keysPerLanguage.isEmpty) {
      context.logger.stopSpinner();
      return ScannerResult(issues: issues);
    }

    // Find the base language (usually max keys or app_en.arb)
    final baseKeys = keysPerLanguage.values.reduce(
      (a, b) => a.length > b.length ? a : b,
    );

    // Check missing translations
    keysPerLanguage.forEach((path, keys) {
      final missing = baseKeys.difference(keys);
      if (missing.isNotEmpty) {
        issues.add(
          Issue(
            title: 'Missing Translations',
            description:
                'File is missing ${missing.length} translations (e.g. ${missing.take(3).join(', ')}).',
            category: 'Localization',
            severity: IssueSeverity.high,
            file: path,
            suggestion: 'Add translations for missing keys.',
          ),
        );
      }

      final extra = keys.difference(baseKeys);
      if (extra.isNotEmpty) {
        issues.add(
          Issue(
            title: 'Extra Translations',
            description:
                'File has ${extra.length} extra translations not in base language (e.g. ${extra.take(3).join(', ')}).',
            category: 'Localization',
            severity: IssueSeverity.low,
            file: path,
            suggestion: 'Remove extra keys or add them to the base language.',
          ),
        );
      }
    });

    // Check for unused keys in code
    final dartFiles = FileUtils.getDartFiles(context.directory);
    final allDartCode = dartFiles.map((f) => f.readAsStringSync()).join('\n');

    for (final key in baseKeys) {
      if (!allDartCode.contains(key)) {
        issues.add(
          Issue(
            title: 'Unused Translation Key',
            description:
                'Key "$key" is defined in ARB but never used in Dart code.',
            category: 'Localization',
            severity: IssueSeverity.medium,
            suggestion: 'Remove the key if it is truly unused.',
          ),
        );
      }
    }

    context.logger.stopSpinner();
    return ScannerResult(
      issues: issues,
      metrics: {
        'localization_files': arbFiles.length,
        'total_base_keys': baseKeys.length,
      },
    );
  }
}
