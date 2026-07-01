class CategoryScore {
  final String category;
  final int score;
  final int maxScore;

  CategoryScore({
    required this.category,
    required this.score,
    required this.maxScore,
  });

  double get percentage => maxScore == 0 ? 100 : (score / maxScore) * 100;
}

class HealthScore {
  final int totalScore;
  final List<CategoryScore> categoryScores;
  final String explanation;
  final bool passed;

  HealthScore({
    required this.totalScore,
    required this.categoryScores,
    required this.explanation,
    required this.passed,
  });
}
