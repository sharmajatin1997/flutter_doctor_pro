import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/report_model.dart';

class ReportGenerator {
  final ProjectContext context;

  ReportGenerator(this.context);

  Future<void> generateSpecific({
    required ReportModel report,
    required bool json,
    required bool html,
    required bool markdown,
    required bool csv,
  }) async {
    final reportsDir = Directory(
      p.join(context.directory, '.flutter_doctor_pro', 'reports'),
    );
    if (!reportsDir.existsSync()) {
      reportsDir.createSync(recursive: true);
    }

    if (json) await _generateJson(report, reportsDir);
    if (html) await _generateHtml(report, reportsDir);
    if (markdown) await _generateMarkdown(report, reportsDir);
    if (csv) await _generateCsv(report, reportsDir);
  }

  Future<void> generateAll(ReportModel report) async {
    await generateSpecific(
      report: report,
      json: context.config.reportJson,
      html: context.config.reportHtml,
      markdown: context.config.reportMarkdown,
      csv: context.config.reportCsv,
    );
  }

  Future<void> _generateJson(ReportModel report, Directory reportsDir) async {
    final file = File(p.join(reportsDir.path, 'report.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(report.toJson()));
  }

  Future<void> _generateHtml(ReportModel report, Directory reportsDir) async {
    final file = File(p.join(reportsDir.path, 'report.html'));

    final html =
        """
<!DOCTYPE html>
<html>
<head>
  <title>Flutter Doctor Pro Report</title>
  <style>
    body { font-family: sans-serif; padding: 2rem; background: #f8f9fa; }
    h1 { color: #02569B; }
    .score { font-size: 2rem; font-weight: bold; }
    .issue { background: white; padding: 1rem; margin-bottom: 1rem; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .critical { border-left: 4px solid #dc3545; }
    .high { border-left: 4px solid #fd7e14; }
    .medium { border-left: 4px solid #ffc107; }
    .low { border-left: 4px solid #17a2b8; }
  </style>
</head>
<body>
  <h1>Flutter Doctor Pro Report</h1>
  <p>Generated at: ${report.generatedAt}</p>
  <div class="score">Total Score: ${report.totalScore}/100</div>
  
  <h2>Categories</h2>
  <ul>
    ${report.categoryScores.values.map((c) => '<li>${c.category}: ${c.score}/100 (Weight: ${c.weight})</li>').join('\\n')}
  </ul>

  <h2>Issues</h2>
  ${report.issues.map((i) => """
    <div class="issue ${i.severity.name}">
      <h3>${i.title} (${i.severity.name.toUpperCase()})</h3>
      <p><strong>Category:</strong> ${i.category}</p>
      <p>${i.description}</p>
      ${i.file != null ? '<p><strong>File:</strong> ${i.file}</p>' : ''}
      ${i.suggestion != null ? '<p><strong>Suggestion:</strong> ${i.suggestion}</p>' : ''}
    </div>
  """).join('\\n')}
</body>
</html>
""";
    await file.writeAsString(html);
  }

  Future<void> _generateMarkdown(
    ReportModel report,
    Directory reportsDir,
  ) async {
    final file = File(p.join(reportsDir.path, 'report.md'));

    final buffer = StringBuffer();
    buffer.writeln('# Flutter Doctor Pro Report');
    buffer.writeln();
    buffer.writeln('**Generated at:** ${report.generatedAt}');
    buffer.writeln('**Total Score:** ${report.totalScore}/100');
    buffer.writeln();

    buffer.writeln('## Categories');
    for (final c in report.categoryScores.values) {
      buffer.writeln(
        '- **${c.category}**: ${c.score}/100 (Weight: ${c.weight})',
      );
    }
    buffer.writeln();

    buffer.writeln('## Issues');
    for (final i in report.issues) {
      buffer.writeln('### ${i.title} [${i.severity.name.toUpperCase()}]');
      buffer.writeln('**Category:** ${i.category}');
      buffer.writeln(i.description);
      if (i.file != null) buffer.writeln('**File:** `${i.file}`');
      if (i.suggestion != null) {
        buffer.writeln('**Suggestion:** ${i.suggestion}');
      }
      buffer.writeln();
    }

    await file.writeAsString(buffer.toString());
  }

  Future<void> _generateCsv(ReportModel report, Directory reportsDir) async {
    final file = File(p.join(reportsDir.path, 'report.csv'));
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Title,Category,Severity,Description,File,Line,Suggestion');

    // Rows
    for (final i in report.issues) {
      final title = _escapeCsv(i.title);
      final category = _escapeCsv(i.category);
      final severity = _escapeCsv(i.severity.name);
      final description = _escapeCsv(i.description);
      final f = _escapeCsv(i.file ?? '');
      final line = i.line?.toString() ?? '';
      final suggestion = _escapeCsv(i.suggestion ?? '');

      buffer.writeln(
        '$title,$category,$severity,$description,$f,$line,$suggestion',
      );
    }

    await file.writeAsString(buffer.toString());
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}
