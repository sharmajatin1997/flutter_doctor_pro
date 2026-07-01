import 'package:flutter_doctor_pro/core/project_command.dart';
import 'package:flutter_doctor_pro/core/doctor_engine.dart';

class CheckCommand extends ProjectCommand {
  @override
  String get name => 'check';

  @override
  String get description =>
      'Runs a quick, non-intrusive scan without failing on scores.';

  @override
  Future<void> runProjectCommand() async {
    final engine = DoctorEngine(context);
    final result = await engine.runAllScans();

    if (result.issues.isEmpty) {
      context.logger.success('No issues found!');
    } else {
      context.logger.info('--- Issues Found ---');
      for (final issue in result.issues) {
        context.logger.logIssue(issue);
      }
    }
  }
}
