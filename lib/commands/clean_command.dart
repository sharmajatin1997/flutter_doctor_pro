import 'package:flutter_doctor_pro/core/project_command.dart';
import 'package:flutter_doctor_pro/clean/clean_engine.dart';

class CleanCommand extends ProjectCommand {
  @override
  String get name => 'clean';

  @override
  String get description =>
      'Interactively clean unused or duplicate files from the project.';

  @override
  Future<void> runProjectCommand() async {
    final cleanEngine = CleanEngine(context);
    await cleanEngine.clean();
  }
}
