import 'package:flutter_doctor_pro/utils/file_utils.dart';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/plugins/scanner_plugin.dart';
import 'package:flutter_doctor_pro/utils/ast_utils.dart';

class ThemeScannerPlugin implements ScannerPlugin {
  @override
  String get name => 'Theme Scanner';

  @override
  bool isEnabled(ProjectContext context) =>
      context.config.rules['theme_scanner'] ?? true;

  @override
  Future<ScannerResult> scan(ProjectContext context) async {
    context.logger.startSpinner('Scanning Themes...');
    final issues = <Issue>[];

    final dartFiles = FileUtils.getDartFiles(context.directory);
    final parser = AstParser(context);

    final textStyles = <String, int>{};
    final boxDecorations = <String, int>{};

    for (final file in dartFiles) {
      final content = await file.readAsString();
      final unit = parser.parseFile(file.path, content);
      if (unit == null) continue;

      final visitor = _ThemeVisitor(
        file.path,
        issues,
        textStyles,
        boxDecorations,
      );
      unit.visitChildren(visitor);
    }

    textStyles.forEach((style, count) {
      if (count >= 3) {
        issues.add(
          Issue(
            title: 'Duplicate TextStyle',
            description: 'A similar TextStyle is duplicated $count times.',
            category: 'Theme',
            severity: IssueSeverity.low,
            suggestion: 'Extract to a centralized AppTheme or TextTheme.',
          ),
        );
      }
    });

    boxDecorations.forEach((decoration, count) {
      if (count >= 3) {
        issues.add(
          Issue(
            title: 'Duplicate BoxDecoration',
            description: 'A similar BoxDecoration is duplicated $count times.',
            category: 'Theme',
            severity: IssueSeverity.low,
            suggestion: 'Extract to a centralized Theme or constant.',
          ),
        );
      }
    });

    context.logger.stopSpinner();
    return ScannerResult(issues: issues);
  }
}

class _ThemeVisitor extends BaseAstVisitor {
  final Map<String, int> textStyles;
  final Map<String, int> boxDecorations;

  _ThemeVisitor(
    super.filePath,
    super.issues,
    this.textStyles,
    this.boxDecorations,
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type.toString();
    if (type == 'TextStyle') {
      final args = node.argumentList.toString();
      textStyles[args] = (textStyles[args] ?? 0) + 1;
    } else if (type == 'BoxDecoration') {
      final args = node.argumentList.toString();
      boxDecorations[args] = (boxDecorations[args] ?? 0) + 1;
    }
    super.visitInstanceCreationExpression(node);
  }
}
