import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/restore/restore_system.dart';

class UndoSystem {
  final ProjectContext context;
  late final RestoreSystem restoreSystem;

  UndoSystem(this.context) {
    restoreSystem = RestoreSystem(context);
  }

  Future<void> undoLastOperation() async {
    context.logger.info('Undoing last operation...');
    await restoreSystem.restore();
  }
}
