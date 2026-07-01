/// Utilities for parsing and traversing Dart ASTs.
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';

/// A simple wrapper around the analyzer to parse a Dart file into an AST.
class AstParser {
  final ProjectContext context;

  AstParser(this.context);

  CompilationUnit? parseFile(String filePath, String content) {
    try {
      final result = parseString(content: content, path: filePath);
      return result.unit;
    } catch (e) {
      context.logger.verboseLog('AST parsing failed for $filePath: $e');
      return null;
    }
  }
}

/// A base visitor that traverses an AST and collects issues.
class BaseAstVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final List<Issue> issues;

  BaseAstVisitor(this.filePath, this.issues);

  /// Adds a new issue to the list of collected issues.
  void addIssue({
    required String title,
    required String description,
    required String category,
    required IssueSeverity severity,
    String? suggestion,
    int? line,
  }) {
    issues.add(
      Issue(
        title: title,
        description: description,
        category: category,
        severity: severity,
        file: filePath,
        suggestion: suggestion,
        line: line,
      ),
    );
  }
}

/// Utility extension to extract common names/values safely across analyzer versions.
extension AstNodeExtensions on AstNode {
  /// Safely extracts the name of an AST node.
  String get safeName {
    if (this is ClassDeclaration) {
      return (this as ClassDeclaration).namePart.toString();
    } else if (this is MethodDeclaration) {
      return (this as MethodDeclaration).name.lexeme;
    } else if (this is FunctionDeclaration) {
      return (this as FunctionDeclaration).name.lexeme;
    } else if (this is VariableDeclaration) {
      return (this as VariableDeclaration).name.lexeme;
    }
    return toString().split(' ').first;
  }
}
