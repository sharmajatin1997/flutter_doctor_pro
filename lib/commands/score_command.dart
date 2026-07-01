import 'dart:io';
import 'dart:convert';
import 'package:flutter_doctor_pro/core/project_command.dart';
import 'package:flutter_doctor_pro/core/doctor_engine.dart';
import 'package:flutter_doctor_pro/score/score_engine.dart';

class ScoreCommand extends ProjectCommand {
  @override
  String get name => 'score';

  @override
  String get description =>
      'Calculates and displays the project health score, and generates score_report.json.';

  @override
  Future<void> runProjectCommand() async {
    final engine = DoctorEngine(context);
    final result = await engine.runAllScans();

    final scoreEngine = ScoreEngine(context);
    final catScores = scoreEngine.calculateDetailedScore(result.issues);
    final totalScore = scoreEngine.calculateTotalScore(catScores);

    context.logger.info('');
    context.logger.info('========== HEALTH SCORE ==========');
    context.logger.info('Total Score: $totalScore/100');
    context.logger.info('');

    context.logger.info(
      '${'Category'.padRight(20)}${'Health'.padRight(12)}Points Earned',
    );
    context.logger.info('-' * 47);

    for (final categoryScore in catScores.values) {
      final earnedPoints = (categoryScore.score / 100 * categoryScore.weight)
          .round();
      final catName = categoryScore.category.padRight(20);
      final scoreStr = '${categoryScore.score}%'.padRight(12);
      final pointsStr = '$earnedPoints out of ${categoryScore.weight}';

      context.logger.info('$catName$scoreStr$pointsStr');
    }

    // Save score report to JSON
    final reportDir = Directory(
      '${context.directory}/.flutter_doctor_pro/reports',
    );
    if (!reportDir.existsSync()) {
      reportDir.createSync(recursive: true);
    }

    final Map<String, dynamic> categoriesJson = {};
    for (final categoryScore in catScores.values) {
      final earnedPoints = (categoryScore.score / 100 * categoryScore.weight)
          .round();
      categoriesJson[categoryScore.category] = {
        'score': categoryScore.score,
        'earned_points': earnedPoints,
        'max_points': categoryScore.weight,
      };
    }

    final jsonReport = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'date': DateTime.now().toIso8601String(),
      'total_score': totalScore,
      'max_score': 100,
      'categories': categoriesJson,
    };

    final reportFile = File('${reportDir.path}/score_report.json');
    reportFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(jsonReport),
    );

    context.logger.info('');
    context.logger.success(
      'Score report saved to .flutter_doctor_pro/reports/score_report.json',
    );
  }
}
