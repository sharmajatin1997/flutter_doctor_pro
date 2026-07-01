import 'package:flutter_doctor_pro/core/project_command.dart';
import 'package:flutter_doctor_pro/restore/restore_system.dart';

class RestoreCommand extends ProjectCommand {
  RestoreCommand() {
    argParser.addOption(
      'id',
      help:
          'The backup ID to restore. If not provided, restores the latest backup.',
    );
    argParser.addFlag(
      'dry-run',
      help:
          'Preview which files will be restored without actually modifying them.',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'restore';

  @override
  String get description => 'Restores files from a previous backup.';

  @override
  Future<void> runProjectCommand() async {
    final restoreSystem = RestoreSystem(context);
    final backupId = argResults?['id'] as String?;
    final dryRun = argResults?['dry-run'] as bool? ?? false;

    await restoreSystem.restore(backupId: backupId, dryRun: dryRun);
  }
}
