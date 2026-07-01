/// Provides the [AssetScannerPlugin] which analyzes Flutter assets.
/// 
/// It checks for unused assets, oversized assets, missing assets,
/// and duplicate image files by hashing them.

import 'dart:io';
import 'package:flutter_doctor_pro/utils/file_utils.dart';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/plugins/scanner_plugin.dart';

/// A scanner plugin that analyzes the `assets` declared in `pubspec.yaml`.
/// 
/// This plugin will flag:
/// * Missing assets (declared but file not found).
/// * Unused assets (file exists but not referenced in Dart code).
/// * Duplicate assets (multiple files with identical MD5 hash).
/// * Oversized assets (files larger than the configured limit).
class AssetScannerPlugin implements ScannerPlugin {
  @override
  String get name => 'Asset Scanner';

  @override
  bool isEnabled(ProjectContext context) =>
      context.config.rules['asset_scanner'] ?? true;

  @override
  Future<ScannerResult> scan(ProjectContext context) async {
    context.logger.startSpinner('Scanning Assets...');

    final issues = <Issue>[];
    int totalAssets = 0;
    double totalSizeMb = 0.0;

    final flutterMap = context.pubspec?['flutter'] as Map?;
    final assetsList = flutterMap?['assets'];
    if (assetsList == null || assetsList is! List) {
      context.logger.stopSpinner();
      return ScannerResult(issues: issues, metrics: {});
    }

    final declaredAssets = <String>{};
    for (final asset in assetsList) {
      declaredAssets.add(asset.toString());
    }

    // Expand directories to actual files
    final actualAssetFiles = <File>[];
    for (final assetPath in declaredAssets) {
      if (assetPath.endsWith('/')) {
        final dir = Directory(p.join(context.directory, assetPath));
        if (dir.existsSync()) {
          actualAssetFiles.addAll(
            dir.listSync(recursive: false).whereType<File>(),
          );
        }
      } else {
        final file = File(p.join(context.directory, assetPath));
        if (file.existsSync()) {
          actualAssetFiles.add(file);
        } else {
          issues.add(
            Issue(
              title: 'Missing Asset',
              description:
                  'Asset "$assetPath" is declared in pubspec.yaml but does not exist.',
              category: 'Assets',
              severity: IssueSeverity.high,
              suggestion:
                  'Remove it from pubspec.yaml or add the missing file.',
            ),
          );
        }
      }
    }

    // Find all strings in dart code (simple regex for now, AST is more complex for pure string finding across whole codebase quickly, but let's do a fast regex + AST combined approach)
    final dartFiles = FileUtils.getDartFiles(context.directory);
    final allDartCode = dartFiles.map((f) => f.readAsStringSync()).join('\n');

    final assetHashes = <String, String>{}; // hash -> path

    for (final file in actualAssetFiles) {
      totalAssets++;
      final fileSize = file.lengthSync() / (1024 * 1024);
      totalSizeMb += fileSize;

      final relPath = p.relative(file.path, from: context.directory);

      // Check if it's used in code
      // We look for Exact String references, Image.asset(), etc.
      // Easiest robust way for asset usages is checking if the exact relative path string exists anywhere in Dart code.
      if (!allDartCode.contains(relPath) &&
          !allDartCode.contains(p.basename(relPath))) {
        issues.add(
          Issue(
            title: 'Unused Asset',
            description: 'Asset "$relPath" is not referenced in any Dart file.',
            category: 'Assets',
            severity: IssueSeverity.medium,
            file: relPath,
            suggestion: 'Delete the asset to save space.',
          ),
        );
      }

      // Check duplicates
      final bytes = file.readAsBytesSync();
      final hash = md5.convert(bytes).toString();

      if (assetHashes.containsKey(hash)) {
        issues.add(
          Issue(
            title: 'Duplicate Asset',
            description:
                'Asset "$relPath" is identical to "${assetHashes[hash]}".',
            category: 'Assets',
            severity: IssueSeverity.medium,
            file: relPath,
            suggestion:
                'Use a single asset reference and delete the duplicate.',
          ),
        );
      } else {
        assetHashes[hash] = relPath;
      }

      // Check sizes
      if (fileSize > context.config.maxImageSizeMb) {
        issues.add(
          Issue(
            title: 'Oversized Asset',
            description:
                'Asset "$relPath" is ${fileSize.toStringAsFixed(2)}MB (Limit: ${context.config.maxImageSizeMb}MB).',
            category: 'Assets',
            severity: IssueSeverity.high,
            file: relPath,
            suggestion: 'Compress the asset or use a vector format (SVG).',
          ),
        );
      }
    }

    context.logger.stopSpinner();
    return ScannerResult(
      issues: issues,
      metrics: {
        'total_assets': totalAssets,
        'total_assets_size_mb': totalSizeMb,
      },
    );
  }
}
