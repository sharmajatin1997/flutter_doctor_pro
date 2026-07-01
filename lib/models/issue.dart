enum IssueSeverity { critical, high, medium, low }

class Issue {
  final String title;
  final String description;
  final String? suggestion;
  final String category;
  final String? file;
  final int? line;
  final IssueSeverity severity;

  const Issue({
    required this.title,
    required this.description,
    this.suggestion,
    required this.category,
    this.file,
    this.line,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'suggestion': suggestion,
      'category': category,
      'file': file,
      'line': line,
      'severity': severity.name,
    };
  }
}
