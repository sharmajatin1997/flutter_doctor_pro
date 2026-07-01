import 'dart:io';
import 'package:interact/interact.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/core/doctor_engine.dart';
import 'package:flutter_doctor_pro/backup/backup_system.dart';

class AutoFixEngine {
  final ProjectContext context;
  late final BackupSystem backupSystem;

  AutoFixEngine(this.context) {
    backupSystem = BackupSystem(context);
  }

  Future<void> runFixes() async {
    context.logger.info('Starting full scan to find auto-fixable issues...');
    final doctor = DoctorEngine(context);
    final report = await doctor.runAllScans();

    final fixableIssues = report.issues.where((i) {
      if (i.title == 'Unused Package') return true;
      if (i.title == 'Unused Asset') return true;
      if (i.suggestion != null && i.file != null && i.file!.endsWith('.dart')) {
        return true;
      }
      return false;
    }).toList();

    if (fixableIssues.isEmpty) {
      context.logger.success('No auto-fixable issues found.');
      return;
    }

    context.logger.warning(
      'Found ${fixableIssues.length} auto-fixable issues.',
    );

    final unusedCount = fixableIssues
        .where((i) => i.title == 'Unused Package')
        .length;
    final unusedAssetCount = fixableIssues
        .where((i) => i.title == 'Unused Asset')
        .length;
    final lintCount = fixableIssues.length - unusedCount - unusedAssetCount;

    final List<String> fixTypes = [];
    if (lintCount > 0) fixTypes.add('$lintCount safe Code Lints');
    if (unusedCount > 0) fixTypes.add('$unusedCount Unused Packages');
    if (unusedAssetCount > 0) fixTypes.add('$unusedAssetCount Unused Assets');

    final confirm = Confirm(
      prompt: 'Do you want to auto-fix ${fixTypes.join(', ')}?',
      defaultValue: false,
    ).interact();

    if (!confirm) {
      context.logger.info('Aborting autofix.');
      return;
    }

    final filesToBackup = fixableIssues
        .map((i) => i.file)
        .whereType<String>()
        .toSet()
        .toList();

    // Always backup pubspec.yaml if we might modify it
    if (fixableIssues.any((i) => i.title == 'Unused Package')) {
      filesToBackup.add('${context.directory}/pubspec.yaml');
    }

    await backupSystem.createBackup(filesToBackup, 'autofix');

    context.logger.startSpinner('Applying fixes...');
    int fixCount = 0;

    // 1. Fix unused packages
    final unusedPackageIssues = fixableIssues
        .where((i) => i.title == 'Unused Package')
        .toList();
    if (unusedPackageIssues.isNotEmpty) {
      final pubspecFile = File('${context.directory}/pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final content = pubspecFile.readAsStringSync();
        final editor = YamlEditor(content);

        for (final issue in unusedPackageIssues) {
          final regex = RegExp(r'Package "([^"]+)" is declared');
          final match = regex.firstMatch(issue.description);
          if (match != null) {
            final pkgName = match.group(1)!;
            try {
              // We try to remove it from dependencies
              final depsNode = editor.parseAt(['dependencies']);
              if (depsNode.value is Map &&
                  (depsNode.value as Map).containsKey(pkgName)) {
                editor.remove(['dependencies', pkgName]);
                fixCount++;
              } else {
                final devDepsNode = editor.parseAt(['dev_dependencies']);
                if (devDepsNode.value is Map &&
                    (devDepsNode.value as Map).containsKey(pkgName)) {
                  editor.remove(['dev_dependencies', pkgName]);
                  fixCount++;
                }
              }
            } catch (e) {
              // Ignore if node not found
            }
          }
        }
        pubspecFile.writeAsStringSync(editor.toString());
      }
    }

    // 2. Fix unused assets
    final unusedAssetIssues = fixableIssues
        .where((i) => i.title == 'Unused Asset')
        .toList();
    if (unusedAssetIssues.isNotEmpty) {
      context.logger.info('\nRemoving unused assets...');
      for (final issue in unusedAssetIssues) {
        if (issue.file != null) {
          final file = File('${context.directory}/${issue.file}');
          if (file.existsSync()) {
            file.deleteSync();
            fixCount++;
          }
        }
      }
    }

    // 3. Fix dart files using `dart fix --apply`
    final dartIssues = fixableIssues
        .where((i) => i.file != null && i.file!.endsWith('.dart'))
        .toList();
    if (dartIssues.isNotEmpty) {
      context.logger.info(
        '\nRunning `dart fix --apply` to resolve code quality issues...',
      );
      final result = await Process.run('dart', [
        'fix',
        '--apply',
      ], workingDirectory: context.directory);
      if (result.exitCode == 0) {
        // dart fix output often says "Made X fixes" or similar.
        // We'll just count the dart issues as fixed if it succeeds.
        fixCount += dartIssues.length;
      } else {
        context.logger.verboseLog('dart fix failed: ${result.stderr}');
      }
    }

    // Sync packages if pubspec was changed
    if (unusedPackageIssues.isNotEmpty) {
      context.logger.info('\nSyncing dependencies via `flutter pub get`...');
      await Process.run('flutter', [
        'pub',
        'get',
      ], workingDirectory: context.directory);
    }

    context.logger.stopSpinner();
    context.logger.success('Applied approx $fixCount fixes successfully.');

    final manualCount = report.issues.length - fixableIssues.length;
    if (manualCount > 0) {
      context.logger.info(
        'Note: $manualCount complex issues require manual resolution. Run `flutter_doctor_pro check` to view them.',
      );
    }

    context.logger.info(
      'If you made a mistake, run `flutter_doctor_pro undo`.',
    );
  }
}
