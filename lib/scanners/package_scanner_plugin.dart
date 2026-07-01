import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/plugins/scanner_plugin.dart';

class PackageScannerPlugin implements ScannerPlugin {
  @override
  String get name => 'Package Scanner';

  @override
  bool isEnabled(ProjectContext context) =>
      context.config.rules['package_scanner'] ?? true;

  @override
  Future<ScannerResult> scan(ProjectContext context) async {
    context.logger.startSpinner('Scanning Packages...');
    final issues = <Issue>[];

    final dependencies = context.pubspec?['dependencies'];
    if (dependencies == null || dependencies is! Map) {
      context.logger.stopSpinner();
      return ScannerResult(issues: issues);
    }

    final declaredPackages = dependencies.keys
        .where((k) => k != 'flutter')
        .cast<String>()
        .toList();

    // Find all imports in dart code
    final libDir = Directory('${context.directory}/lib');
    List<File> dartFiles = [];
    if (libDir.existsSync()) {
      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    }

    final allDartCodeBuffer = StringBuffer();
    final Set<String> importedUris = {};

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      allDartCodeBuffer.writeln(content);

      try {
        final unit = parseString(content: content, path: file.path).unit;
        for (final directive in unit.directives) {
          if (directive is ImportDirective) {
            final uri = directive.uri.stringValue;
            if (uri != null) importedUris.add(uri);
          } else if (directive is ExportDirective) {
            final uri = directive.uri.stringValue;
            if (uri != null) importedUris.add(uri);
          }
        }
      } catch (e) {
        context.logger.verboseLog('AST parsing failed for ${file.path}: $e');
      }
    }

    final allDartCode = allDartCodeBuffer.toString();

    // Known tooling packages that might not be imported directly
    final knownToolingPackages = {
      'flutter_launcher_icons',
      'flutter_native_splash',
      'build_runner',
      'json_serializable',
      'freezed',
      'freezed_annotation',
      'rename',
      'pigeon',
      'ffi',
      'slang',
      'envied_generator',
      'json_annotation',
      'lints',
      'flutter_lints',
    };

    // Firebase packages group
    final firebasePackages = declaredPackages
        .where((p) => p.startsWith('firebase_') || p == 'cloud_firestore')
        .toList();

    for (final package in declaredPackages) {
      bool isUsed = false;

      // 1. Check if directly imported via AST
      if (importedUris.any((uri) => uri.startsWith('package:$package/'))) {
        isUsed = true;
      }

      // 2. Check if it's a known tooling package
      if (!isUsed && knownToolingPackages.contains(package)) {
        isUsed = true;
      }

      // 3. Check if configured in pubspec.yaml (e.g. flutter_launcher_icons: ...)
      if (!isUsed && context.pubspec!.containsKey(package)) {
        isUsed = true;
      }

      // 4. Special cases (e.g. firebase_core indirectly referenced)
      if (!isUsed && package == 'firebase_core') {
        if (allDartCode.contains('Firebase.initializeApp') ||
            allDartCode.contains('firebase_options.dart') ||
            firebasePackages.length > 1) {
          // If other firebase packages exist, core is implicitly needed
          isUsed = true;
        }
      }

      // 5. Special case: if another package implies this one is used
      // For instance, google_sign_in with firebase_auth
      if (!isUsed &&
          package == 'google_sign_in' &&
          firebasePackages.isNotEmpty) {
        isUsed = true;
      }

      if (!isUsed) {
        issues.add(
          Issue(
            title: 'Unused Package',
            description:
                'Package "$package" is declared in pubspec.yaml but appears unused in the project.',
            category: 'Dependencies',
            severity: IssueSeverity.medium,
            suggestion:
                'Remove it from pubspec.yaml to speed up builds and reduce size. If it is a tool, ensure it is configured.',
          ),
        );
      }
    }

    context.logger.stopSpinner();
    return ScannerResult(issues: issues);
  }
}
