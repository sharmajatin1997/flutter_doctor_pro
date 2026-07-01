import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_doctor_pro/core/context.dart';

class BackupSystem {
  final ProjectContext context;

  BackupSystem(this.context);

  Future<String?> createBackup(
    List<String> filesToBackup,
    String operationName,
  ) async {
    if (!context.config.backupEnabled) return null;

    final backupsDir = Directory(
      p.join(context.directory, '.flutter_doctor_pro', 'backups'),
    );
    if (!backupsDir.existsSync()) {
      backupsDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupId =
        'backup_${timestamp}_${operationName.replaceAll(" ", "_")}';
    final currentBackupDir = Directory(p.join(backupsDir.path, backupId));
    currentBackupDir.createSync();

    final manifest = <String, String>{}; // originalPath -> backupPath
    final checksums = <String, String>{}; // originalPath -> hash

    for (final relativePath in filesToBackup) {
      final file = File(p.join(context.directory, relativePath));
      if (file.existsSync()) {
        final backupFile = File(
          p.join(currentBackupDir.path, 'files', relativePath),
        );
        backupFile.parent.createSync(recursive: true);
        file.copySync(backupFile.path);

        manifest[relativePath] = p.join('files', relativePath);
        final bytes = file.readAsBytesSync();
        checksums[relativePath] = sha256.convert(bytes).toString();
      }
    }

    // Git commit hash
    String gitCommit = 'unknown';
    try {
      final gitResult = Process.runSync('git', [
        'rev-parse',
        'HEAD',
      ], workingDirectory: context.directory);
      if (gitResult.exitCode == 0) {
        gitCommit = gitResult.stdout.toString().trim();
      }
    } catch (_) {}

    final metadata = {
      'id': backupId,
      'timestamp': timestamp,
      'operation': operationName,
      'package_version': '2.0.0', // flutter_doctor_pro version
      'git_commit': gitCommit,
      'checksums': checksums,
    };

    File(
      p.join(currentBackupDir.path, 'metadata.json'),
    ).writeAsStringSync(jsonEncode(metadata));

    File(
      p.join(currentBackupDir.path, 'manifest.json'),
    ).writeAsStringSync(jsonEncode(manifest));

    _cleanupOldBackups(backupsDir);

    context.logger.info('Backup created: $backupId');
    return backupId;
  }

  void _cleanupOldBackups(Directory backupsDir) {
    final backups = backupsDir.listSync().whereType<Directory>().toList();
    if (backups.length > context.config.backupRetention) {
      backups.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );
      final toDelete = backups.take(
        backups.length - context.config.backupRetention,
      );
      for (final dir in toDelete) {
        dir.deleteSync(recursive: true);
      }
    }
  }
}
