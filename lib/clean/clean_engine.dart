import 'dart:io';
import 'package:interact/interact.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/core/doctor_engine.dart';
import 'package:flutter_doctor_pro/backup/backup_system.dart';

class CleanEngine {
  final ProjectContext context;
  late final BackupSystem backupSystem;

  CleanEngine(this.context) {
    backupSystem = BackupSystem(context);
  }

  Future<void> clean() async {
    // 1. Scan
    context.logger.info('Starting full scan to find unused files...');
    final doctor = DoctorEngine(context);
    final report = await doctor.runAllScans();

    // Find deletable files (Unused Assets, Duplicate Assets, Unused Fonts)
    final deletableIssues = report.issues.where((i) {
      return (i.title == 'Unused Asset' ||
              i.title == 'Duplicate Asset' ||
              i.title == 'Duplicate Font' ||
              i.title == 'Empty Directory') &&
          i.file != null;
    }).toList();

    if (deletableIssues.isEmpty) {
      context.logger.success('No deletable files found. Project is clean.');
      return;
    }

    // 2. Show report
    context.logger.warning(
      'Found ${deletableIssues.length} files that can be cleaned.',
    );

    // 3. Ask confirmation (Interactive cleanup)
    List<String> filesToDelete = [];

    // Auto interact disabled for test environment unless specified, but for now we follow old logic:
    final options = deletableIssues
        .map((i) => '${i.file} (${i.title})')
        .toList();

    context.logger.info(
      'Select files to delete (Space to select, Enter to confirm):',
    );
    final selection = MultiSelect(
      prompt: 'Files to delete:',
      options: options,
    ).interact();

    if (selection.isEmpty) {
      context.logger.info('No files selected. Aborting cleanup.');
      return;
    }

    filesToDelete = selection.map((idx) => deletableIssues[idx].file!).toList();

    // 4. Create backup
    await backupSystem.createBackup(filesToDelete, 'cleanup');

    // 5. Delete selected files
    context.logger.startSpinner('Deleting files...');
    int deletedCount = 0;
    for (final filePath in filesToDelete) {
      final file = File(p.join(context.directory, filePath));
      if (await file.exists()) {
        await file.delete();
        deletedCount++;
      } else {
        final dir = Directory(p.join(context.directory, filePath));
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          deletedCount++;
        }
      }
    }
    context.logger.stopSpinner();

    // 6. Generate summary
    context.logger.success('Successfully deleted $deletedCount files.');
    context.logger.info(
      'If you made a mistake, run `flutter_doctor_pro undo`.',
    );
  }
}
