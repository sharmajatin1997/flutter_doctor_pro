import 'package:flutter_doctor_pro/utils/file_utils.dart';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/plugins/scanner_plugin.dart';
import 'package:flutter_doctor_pro/utils/ast_utils.dart';

class WidgetComplexityScannerPlugin implements ScannerPlugin {
  @override
  String get name => 'Widget Complexity Scanner';

  @override
  bool isEnabled(ProjectContext context) =>
      context.config.rules['complexity_scanner'] ?? true;

  @override
  Future<ScannerResult> scan(ProjectContext context) async {
    context.logger.startSpinner('Scanning Widget Complexity...');
    final issues = <Issue>[];

    final dartFiles = FileUtils.getDartFiles(context.directory);
    final parser = AstParser(context);

    for (final file in dartFiles) {
      final content = await file.readAsString();
      final unit = parser.parseFile(file.path, content);
      if (unit == null) continue;

      final visitor = _ComplexityVisitor(file.path, issues);
      unit.visitChildren(visitor);
    }

    context.logger.stopSpinner();
    return ScannerResult(issues: issues);
  }
}

class _ComplexityVisitor extends BaseAstVisitor {
  _ComplexityVisitor(super.filePath, super.issues);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'build' &&
        node.returnType?.toString() == 'Widget') {
      final length = node.end - node.offset;
      if (length > 5000) {
        addIssue(
          title: 'Complex Build Method',
          description: 'Build method is extremely large and complex.',
          category: 'Complexity',
          severity: IssueSeverity.high,
          suggestion:
              'Extract widgets into smaller, independent StatelessWidgets.',
        );
      }

      // Simple nested builder check
      int builderCount = 0;
      node.visitChildren(
        _BuilderCounterVisitor((count) => builderCount = count),
      );
      if (builderCount > 2) {
        addIssue(
          title: 'Nested Builders',
          description:
              'Found $builderCount nested Builders (FutureBuilder/StreamBuilder/Builder) in one build method.',
          category: 'Complexity',
          severity: IssueSeverity.medium,
          suggestion: 'Flatten builders or extract them into separate widgets.',
        );
      }
    }
    super.visitMethodDeclaration(node);
  }
}

class _BuilderCounterVisitor extends RecursiveAstVisitor<void> {
  int count = 0;
  final void Function(int) onCountUpdate;

  _BuilderCounterVisitor(this.onCountUpdate);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type.toString();
    if (type.contains('Builder') ||
        type.contains('FutureBuilder') ||
        type.contains('StreamBuilder')) {
      count++;
      onCountUpdate(count);
    }
    super.visitInstanceCreationExpression(node);
  }
}
