import 'dart:math';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';

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
    int deductions = 0;

    for (final issue in catIssues) {
      switch (issue.severity) {
        case IssueSeverity.critical:
          deductions += 25;
          break;
        case IssueSeverity.high:
          deductions += 10;
          break;
        case IssueSeverity.medium:
          deductions += 5;
          break;
        case IssueSeverity.low:
          deductions += 2;
          break;
      }
    }

    return max(0, 100 - deductions);
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
