import 'dart:math';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/utils/file_utils.dart';

class CategoryScore {
  final String category;
  final int score;
  final int weight;

  CategoryScore(this.category, this.score, this.weight);
}

class ScoreEngine {
  final ProjectContext context;

  ScoreEngine(this.context);

  int _calculateCategoryScore(List<Issue> issues, String category) {
    final catIssues = issues.where((i) => i.category == category).toList();
    double deductions = 0;

    // Calculate scale factor based on project size
    int totalDartFiles = FileUtils.getDartFiles(context.directory).length;
    if (totalDartFiles == 0) totalDartFiles = 1;
    
    // Assume base project size is 5 files. 
    // E.g., a 50-file app will have a scale factor of 10.
    double scaleFactor = (totalDartFiles / 5.0).clamp(1.0, 50.0);

    for (final issue in catIssues) {
      double issuePoints = 0;
      switch (issue.severity) {
        case IssueSeverity.critical:
          issuePoints = 25.0;
          break;
        case IssueSeverity.high:
          issuePoints = 10.0;
          break;
        case IssueSeverity.medium:
          issuePoints = 5.0;
          break;
        case IssueSeverity.low:
          issuePoints = 2.0;
          break;
      }

      // Make Code Quality and Complexity fair for larger apps
      if (category == 'Code Quality' || category == 'Complexity') {
        issuePoints = issuePoints / scaleFactor;
      }

      deductions += issuePoints;
    }

    return max(0, 100 - deductions.round());
  }

  Map<String, CategoryScore> calculateDetailedScore(List<Issue> issues) {
    final weights = context.config.scoreWeights;

    // Group categories mapping to config weights
    final scores = {
      'Assets': CategoryScore(
        'Assets',
        _calculateCategoryScore(issues, 'Assets'),
        weights.assets,
      ),
      'Code Quality': CategoryScore(
        'Code Quality',
        _calculateCategoryScore(issues, 'Code Quality'),
        weights.codeQuality,
      ),
      'Complexity': CategoryScore(
        'Complexity',
        _calculateCategoryScore(issues, 'Complexity'),
        weights.complexity,
      ),
      'Theme': CategoryScore(
        'Theme',
        _calculateCategoryScore(issues, 'Theme'),
        weights.theme,
      ),
      'Performance': CategoryScore(
        'Performance',
        _calculateCategoryScore(issues, 'Performance'),
        weights.performance,
      ),
      'Dependencies': CategoryScore(
        'Dependencies',
        _calculateCategoryScore(issues, 'Dependencies'),
        weights.dependencies,
      ),
      'Localization': CategoryScore(
        'Localization',
        _calculateCategoryScore(issues, 'Localization'),
        weights.localization,
      ),
    };

    // The architecture says:
    // Assets: 20%, Code Quality: 25%, Performance: 20%, Dependencies: 15%, Project Structure: 10%, Documentation: 10%
    return scores;
  }

  int calculateTotalScore(Map<String, CategoryScore> categoryScores) {
    int totalWeightedScore = 0;
    int totalWeights = 0;

    for (final cat in categoryScores.values) {
      totalWeightedScore += cat.score * cat.weight;
      totalWeights += cat.weight;
    }

    if (totalWeights == 0) return 100;

    return (totalWeightedScore / totalWeights).round();
  }
}
