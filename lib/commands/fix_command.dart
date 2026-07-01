import 'package:flutter_doctor_pro/core/project_command.dart';
import 'package:flutter_doctor_pro/autofix/autofix_engine.dart';

class FixCommand extends ProjectCommand {
  @override
  String get name => 'fix';

  @override
  String get description =>
      'Automatically apply recommended fixes to the project.';

  @override
  Future<void> runProjectCommand() async {
    final fixEngine = AutoFixEngine(context);
    await fixEngine.runFixes();
  }
}
