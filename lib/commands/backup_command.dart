import 'package:flutter_doctor_pro/core/project_command.dart';
import 'package:flutter_doctor_pro/backup/backup_system.dart';

class BackupCommand extends ProjectCommand {
  @override
  String get name => 'backup';

  @override
  String get description =>
      'Manually create a backup of important project files.';

  @override
  Future<void> runProjectCommand() async {
    final backupSystem = BackupSystem(context);
    final id = await backupSystem.createBackup([
      'pubspec.yaml',
    ], 'manual_backup');
    if (id != null) {
      context.logger.success('Backup created successfully: $id');
    } else {
      context.logger.warning('Backups are disabled in configuration.');
    }
  }
}
