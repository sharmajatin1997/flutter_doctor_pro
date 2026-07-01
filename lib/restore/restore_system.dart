import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_doctor_pro/core/context.dart';

class RestoreSystem {
  final ProjectContext context;

  RestoreSystem(this.context);

  Future<void> restore({
    String? backupId,
    String? specificFile,
    bool dryRun = false,
  }) async {
    final backupsDir = Directory(
      p.join(context.directory, '.flutter_doctor_pro', 'backups'),
    );
    if (!backupsDir.existsSync()) {
      context.logger.error('No backups found.');
      return;
    }

    final backups = backupsDir.listSync().whereType<Directory>().toList();
    if (backups.isEmpty) {
      context.logger.error('No backups found.');
      return;
    }

    Directory targetBackupDir;
    if (backupId != null) {
      targetBackupDir = Directory(p.join(backupsDir.path, backupId));
      if (!targetBackupDir.existsSync()) {
        context.logger.error('Backup $backupId not found.');
        return;
      }
    } else {
      backups.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
      targetBackupDir = backups.first;
    }

    final metadataFile = File(p.join(targetBackupDir.path, 'metadata.json'));
    final manifestFile = File(p.join(targetBackupDir.path, 'manifest.json'));

    if (!metadataFile.existsSync() || !manifestFile.existsSync()) {
      context.logger.error(
        'Backup is corrupted: Missing metadata or manifest.',
      );
      return;
    }

    final metadata = jsonDecode(metadataFile.readAsStringSync());
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final checksums = metadata['checksums'] as Map<String, dynamic>;

    context.logger.info(
      'Restoring backup: ${metadata["id"]} (${metadata["operation"]})',
    );

    if (dryRun) {
      context.logger.info('-- DRY RUN MODE -- (No files will be changed)');
    }

    for (final entry in manifest.entries) {
      final originalPath = entry.key;
      if (specificFile != null && originalPath != specificFile) continue;

      final backupPath = p.join(targetBackupDir.path, entry.value);
      final backupFile = File(backupPath);

      if (!backupFile.existsSync()) {
        context.logger.error('Missing backup file: $originalPath');
        continue;
      }

      // Integrity validation
      final bytes = backupFile.readAsBytesSync();
      final hash = sha256.convert(bytes).toString();
      if (hash != checksums[originalPath]) {
        context.logger.error('Integrity check failed for: $originalPath');
        continue;
      }

      if (!dryRun) {
        final targetFile = File(p.join(context.directory, originalPath));
        targetFile.parent.createSync(recursive: true);
        backupFile.copySync(targetFile.path);
        context.logger.success('Restored: $originalPath');
      } else {
        context.logger.info('Would restore: $originalPath');
      }
    }
  }
}
