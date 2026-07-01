import 'package:flutter_doctor_pro/utils/file_utils.dart';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/plugins/scanner_plugin.dart';
import 'package:flutter_doctor_pro/utils/ast_utils.dart';

class PerformanceScannerPlugin implements ScannerPlugin {
  @override
  String get name => 'Performance Scanner';

  @override
  bool isEnabled(ProjectContext context) =>
      context.config.rules['performance_scanner'] ?? true;

  @override
  Future<ScannerResult> scan(ProjectContext context) async {
    context.logger.startSpinner('Scanning Performance...');
    final issues = <Issue>[];

    final dartFiles = FileUtils.getDartFiles(context.directory);
    final parser = AstParser(context);

    for (final file in dartFiles) {
      final content = await file.readAsString();
      final unit = parser.parseFile(file.path, content);
      if (unit == null) continue;

      final visitor = _PerformanceVisitor(file.path, issues);
      unit.visitChildren(visitor);
    }

    context.logger.stopSpinner();
    return ScannerResult(issues: issues);
  }
}

class _PerformanceVisitor extends BaseAstVisitor {
  _PerformanceVisitor(super.filePath, super.issues);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type.toString();

    if (type == 'Opacity') {
      addIssue(
        title: 'Opacity Misuse',
        description:
            'Consider using AnimatedOpacity or fading colors directly instead of Opacity widget for better performance.',
        category: 'Performance',
        severity: IssueSeverity.medium,
        suggestion: 'Avoid Opacity if possible, especially in animations.',
      );
    } else if (type == 'ClipRRect') {
      addIssue(
        title: 'ClipRRect Overuse',
        description:
            'ClipRRect can be expensive. Check if Container with BoxDecoration can achieve the same result.',
        category: 'Performance',
        severity: IssueSeverity.low,
        suggestion:
            'Use Container shape clipping if no complex children need clipping.',
      );
    } else if (type == 'IntrinsicHeight' || type == 'IntrinsicWidth') {
      addIssue(
        title: 'Intrinsic Layout Used',
        description:
            '$type is very expensive as it adds a speculative layout pass.',
        category: 'Performance',
        severity: IssueSeverity.high,
        suggestion: 'Try to achieve the layout without Intrinsic widgets.',
      );
    } else if (type == 'ListView') {
      // Check if it's not a builder
      if (node.constructorName.name == null) {
        // Default constructor, not .builder
        addIssue(
          title: 'ListView without Builder',
          description:
              'Using ListView directly instead of ListView.builder for large lists can cause memory issues.',
          category: 'Performance',
          severity: IssueSeverity.medium,
          suggestion: 'Switch to ListView.builder if the list has many items.',
        );
      }
    }
    super.visitInstanceCreationExpression(node);
  }
}
