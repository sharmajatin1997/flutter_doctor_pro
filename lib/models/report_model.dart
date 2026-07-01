import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/score/score_engine.dart';

class ReportModel {
  final int totalScore;
  final Map<String, CategoryScore> categoryScores;
  final List<Issue> issues;
  final Map<String, dynamic> metrics;
  final DateTime generatedAt;

  ReportModel({
    required this.totalScore,
    required this.categoryScores,
    required this.issues,
    required this.metrics,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt.toIso8601String(),
      'score': {
        'total': totalScore,
        'categories': categoryScores.map(
          (k, v) => MapEntry(k, {'score': v.score, 'weight': v.weight}),
        ),
      },
      'metrics': metrics,
      'issues': issues.map((i) => i.toJson()).toList(),
    };
  }
}
