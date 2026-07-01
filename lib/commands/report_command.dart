import 'package:flutter_doctor_pro/core/project_command.dart';
import 'package:flutter_doctor_pro/core/doctor_engine.dart';
import 'package:flutter_doctor_pro/score/score_engine.dart';
import 'package:flutter_doctor_pro/reports/report_generator.dart';
import 'package:flutter_doctor_pro/models/report_model.dart';

class ReportCommand extends ProjectCommand {
  @override
  String get name => 'report';

  @override
  String get description =>
      'Generates reports (JSON, HTML, Markdown, CSV). If no format is specified, generates all.';

  ReportCommand() {
    argParser.addFlag('json', help: 'Generate JSON report', negatable: false);
    argParser.addFlag('html', help: 'Generate HTML report', negatable: false);
    argParser.addFlag(
      'markdown',
      help: 'Generate Markdown report',
      negatable: false,
    );
    argParser.addFlag('csv', help: 'Generate CSV report', negatable: false);
  }

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

    bool genJson = argResults?['json'] as bool? ?? false;
    bool genHtml = argResults?['html'] as bool? ?? false;
    bool genMarkdown = argResults?['markdown'] as bool? ?? false;
    bool genCsv = argResults?['csv'] as bool? ?? false;

    // Fallback to config if no flags provided
    if (!genJson && !genHtml && !genMarkdown && !genCsv) {
      genJson = context.config.reportJson;
      genHtml = context.config.reportHtml;
      genMarkdown = context.config.reportMarkdown;
      genCsv = context.config.reportCsv;
    }

    // Default to all if still nothing is selected
    if (!genJson && !genHtml && !genMarkdown && !genCsv) {
      genJson = true;
      genHtml = true;
      genMarkdown = true;
      genCsv = true;
    }

    final reporter = ReportGenerator(context);
    await reporter.generateSpecific(
      report: report,
      json: genJson,
      html: genHtml,
      markdown: genMarkdown,
      csv: genCsv,
    );

    context.logger.success(
      'Reports generated successfully in .flutter_doctor_pro/reports/',
    );
  }
}
