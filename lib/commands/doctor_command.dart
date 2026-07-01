import 'package:flutter_doctor_pro/core/project_command.dart';
import 'package:flutter_doctor_pro/core/doctor_engine.dart';
import 'package:flutter_doctor_pro/score/score_engine.dart';
import 'package:flutter_doctor_pro/reports/report_generator.dart';
import 'package:flutter_doctor_pro/models/report_model.dart';
import 'package:flutter_doctor_pro/exceptions/exceptions.dart';

class DoctorCommand extends ProjectCommand {
  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Runs a comprehensive health check on your Flutter project.';

  @override
  Future<void> runProjectCommand() async {
    final engine = DoctorEngine(context);
    final result = await engine.runAllScans();

    final scoreEngine = ScoreEngine(context);
    final catScores = scoreEngine.calculateDetailedScore(result.issues);
    final totalScore = scoreEngine.calculateTotalScore(catScores);

    final report = ReportModel(
      totalScore: totalScore,
      categoryScores: catScores,
      issues: result.issues,
      metrics: result.metrics,
    );

    context.logger.info('');
    context.logger.info('========== FLUTTER DOCTOR PRO ==========');
    context.logger.info('Project: ${context.pubspec?["name"] ?? "Unknown"}');
    context.logger.info('Total Score: $totalScore/100');
    context.logger.info('');

    for (final categoryScore in catScores.values) {
      context.logger.info(
        '${categoryScore.category}: ${categoryScore.score}/100 (Weight: ${categoryScore.weight})',
      );
    }
    context.logger.info('');

    if (result.issues.isEmpty) {
      context.logger.success(
        'No issues found! Your project is perfectly healthy.',
      );
    } else {
      context.logger.info('--- Issues Found ---');
      for (final issue in result.issues) {
        context.logger.logIssue(issue);
      }
    }

    final reporter = ReportGenerator(context);
    await reporter.generateAll(report);

    if (totalScore < context.config.scoreMinimum) {
      context.logger.error(
        'Project score $totalScore is below the required minimum of ${context.config.scoreMinimum}.',
      );
      throw ProjectDoctorException('Score below minimum threshold.');
    }
  }
}
