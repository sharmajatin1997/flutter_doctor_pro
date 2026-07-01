import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/models/issue.dart';

/// The result returned by a [ScannerPlugin].
class ScannerResult {
  final List<Issue> issues;
  final Map<String, dynamic> metrics;

  ScannerResult({required this.issues, this.metrics = const {}});
}

/// Abstract interface for all scanners in Flutter Doctor Pro.
/// Every scanner must be completely independent and communicate only through shared models.
abstract class ScannerPlugin {
  /// The unique name of the scanner.
  String get name;

  /// Determines if the scanner should run based on the given [ProjectContext].
  /// This can be overridden to disable a scanner globally or conditionally.
  bool isEnabled(ProjectContext context) => true;

  /// Executes the scan and returns a [ScannerResult].
  Future<ScannerResult> scan(ProjectContext context);
}
