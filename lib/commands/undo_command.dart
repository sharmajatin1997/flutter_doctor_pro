import 'package:flutter_doctor_pro/core/project_command.dart';
import 'package:flutter_doctor_pro/undo/undo_system.dart';

class UndoCommand extends ProjectCommand {
  @override
  String get name => 'undo';

  @override
  String get description =>
      'Undoes the last operation that modified files (like autofix or clean).';

  @override
  Future<void> runProjectCommand() async {
    final undoSystem = UndoSystem(context);
    await undoSystem.undoLastOperation();
  }
}
