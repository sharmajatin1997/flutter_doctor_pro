import 'dart:io';
import 'package:flutter_doctor_pro/utils/file_utils.dart';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/plugins/scanner_plugin.dart';
import 'package:flutter_doctor_pro/utils/ast_utils.dart';

class CodeQualityScannerPlugin implements ScannerPlugin {
  @override
  String get name => 'Code Quality Scanner';

  @override
  bool isEnabled(ProjectContext context) =>
      context.config.rules['code_quality'] ?? true;

  @override
  Future<ScannerResult> scan(ProjectContext context) async {
    context.logger.startSpinner('Scanning Code Quality...');
    final issues = <Issue>[];

    final dartFiles = FileUtils.getDartFiles(context.directory);
    final parser = AstParser(context);

    final stringLiterals = <String, List<String>>{};
    int totalClasses = 0;
    int totalMethods = 0;

    // 1. Run dart analyze to catch standard lints (unused imports, etc.)
    try {
      final result = await Process.run('dart', [
        'analyze',
        '--format=machine',
      ], workingDirectory: context.directory);
      // dart analyze exits with non-zero if issues are found, which is expected.
      final output = '${result.stdout}\n${result.stderr}';
      final lines = output.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|');
        if (parts.length >= 8) {
          final severityStr = parts[0];
          
          final errorCode = parts[2];
          final filePath = parts[3];
          final lineNum = int.tryParse(parts[4]) ?? 0;
          final message = parts[7];

          IssueSeverity severity = IssueSeverity.low;
          if (severityStr == 'ERROR') severity = IssueSeverity.critical;
          if (severityStr == 'WARNING') severity = IssueSeverity.high;
          if (severityStr == 'INFO') severity = IssueSeverity.medium;

          issues.add(
            Issue(
              title: errorCode,
              description: message,
              category: 'Code Quality',
              severity: severity,
              file: filePath,
              line: lineNum,
              suggestion:
                  'Run `flutter_doctor_pro fix` to attempt automatic resolution.',
            ),
          );
        }
      }
    } catch (e) {
      context.logger.verboseLog('Failed to run dart analyze: $e');
    }

    // 2. Run AST parser for structural issues
    for (final file in dartFiles) {
      final content = await file.readAsString();
      final lines = content.split('\n');

      // Fast check for TODO/FIXME
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('TODO:') ||
            line.contains('TODO ') ||
            line.contains('TODO(')) {
          issues.add(
            Issue(
              title: 'TODO Comment',
              description: 'Found TODO comment: ${line.trim()}',
              category: 'Code Quality',
              severity: IssueSeverity.low,
              file: file.path,
              line: i + 1,
              suggestion: 'Resolve the TODO.',
            ),
          );
        }
      }

      final unit = parser.parseFile(file.path, content);
      if (unit == null) continue;

      final visitor = _QualityVisitor(file.path, issues, stringLiterals);
      unit.visitChildren(visitor);

      totalClasses += visitor.classCount;
      totalMethods += visitor.methodCount;
    }

    // Process duplicate strings
    stringLiterals.forEach((str, paths) {
      if (paths.length >= 3) {
        issues.add(
          Issue(
            title: 'Duplicate String',
            description: 'String "$str" is duplicated ${paths.length} times.',
            category: 'Code Quality',
            severity: IssueSeverity.low,
            suggestion: 'Extract to a constant or localization.',
          ),
        );
      }
    });

    context.logger.stopSpinner();
    return ScannerResult(
      issues: issues,
      metrics: {'total_classes': totalClasses, 'total_methods': totalMethods},
    );
  }
}

class _QualityVisitor extends BaseAstVisitor {
  final Map<String, List<String>> stringLiterals;
  int classCount = 0;
  int methodCount = 0;

  _QualityVisitor(super.filePath, super.issues, this.stringLiterals);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    classCount++;
    final length = node.end - node.offset;
    if (length > 15000) {
      addIssue(
        title: 'Large Class',
        description: 'Class ${node.safeName} is too large.',
        category: 'Code Quality',
        severity: IssueSeverity.medium,
        suggestion: 'Refactor into smaller classes.',
      );
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    methodCount++;
    final length = node.end - node.offset;
    if (length > 3000) {
      addIssue(
        title: 'Large Method',
        description: 'Method ${node.safeName} is too large.',
        category: 'Code Quality',
        severity: IssueSeverity.medium,
        suggestion: 'Extract logic into smaller methods.',
      );
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // Ignore import/export URIs
    if (node.parent is UriBasedDirective) {
      super.visitSimpleStringLiteral(node);
      return;
    }
    
    if (node.value.length > 5) {
      stringLiterals.putIfAbsent(node.value, () => []).add(filePath);
    }
    super.visitSimpleStringLiteral(node);
  }
}
