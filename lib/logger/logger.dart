import 'dart:io';
import 'package:interact/interact.dart';
import 'package:flutter_doctor_pro/models/issue.dart';

class Logger {
  final bool verbose;
  final bool silent;
  final Stopwatch _stopwatch = Stopwatch();
  SpinnerState? _currentSpinner;

  Logger({this.verbose = false, this.silent = false});

  void startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  void stopTimerAndLog(String taskName) {
    _stopwatch.stop();
    if (!silent) {
      info('$taskName completed in ${_stopwatch.elapsedMilliseconds}ms');
    }
  }

  void logIssue(Issue issue) {
    if (silent) return;
    _clearSpinner();

    final color = switch (issue.severity) {
      IssueSeverity.critical => '\x1B[31m', // Red
      IssueSeverity.high => '\x1B[33m', // Yellow
      IssueSeverity.medium => '\x1B[34m', // Blue
      IssueSeverity.low => '\x1B[37m', // White
    };

    stdout.writeln(
      '$color[${issue.severity.name.toUpperCase()}]\x1B[0m ${issue.title}',
    );
    stdout.writeln('  ${issue.description}');
    if (issue.suggestion != null) {
      stdout.writeln('  \x1B[32mSuggestion:\x1B[0m ${issue.suggestion}');
    }
    if (issue.file != null) {
      stdout.writeln(
        '  \x1B[90mFile:\x1B[0m ${issue.file}${issue.line != null ? ":${issue.line}" : ""}',
      );
    }
    stdout.writeln('');
  }

  void info(String message) {
    if (silent) return;
    _clearSpinner();
    stdout.writeln('ℹ️ $message');
  }

  void success(String message) {
    if (silent) return;
    _clearSpinner();
    stdout.writeln('\x1B[32m✓\x1B[0m $message'); // Green check
  }

  void warning(String message) {
    if (silent) return;
    _clearSpinner();
    stdout.writeln('\x1B[33m⚠\x1B[0m $message'); // Yellow warning
  }

  void error(String message) {
    _clearSpinner();
    stderr.writeln('\x1B[31m✗\x1B[0m $message'); // Red X
  }

  void verboseLog(String message) {
    if (verbose && !silent) {
      _clearSpinner();
      stdout.writeln('\x1B[90m[DEBUG] $message\x1B[0m'); // Gray
    }
  }

  void startSpinner(String message) {
    if (silent) return;
    _clearSpinner();
    final spinner = Spinner(
      icon: '🔄',
      leftPrompt: (done) => '',
      rightPrompt: (done) => done ? ' \x1B[32m✓\x1B[0m $message' : ' $message',
    );
    _currentSpinner = spinner.interact();
  }

  void stopSpinner() {
    if (silent) return;
    _clearSpinner();
  }

  void _clearSpinner() {
    if (_currentSpinner != null) {
      _currentSpinner?.done();
      _currentSpinner = null;
    }
  }

  void printTable(List<String> headers, List<List<String>> rows) {
    if (silent) return;
    _clearSpinner();

    // Very basic table formatting for now
    if (rows.isEmpty) {
      stdout.writeln('No data available.');
      return;
    }

    List<int> columnWidths = List.filled(headers.length, 0);
    for (int i = 0; i < headers.length; i++) {
      columnWidths[i] = headers[i].length;
    }

    for (var row in rows) {
      for (int i = 0; i < row.length; i++) {
        if (i < columnWidths.length && row[i].length > columnWidths[i]) {
          columnWidths[i] = row[i].length;
        }
      }
    }

    String formatRow(List<String> row) {
      String result = '|';
      for (int i = 0; i < row.length; i++) {
        if (i < columnWidths.length) {
          result += ' ${row[i].padRight(columnWidths[i])} |';
        }
      }
      return result;
    }

    String separator = '+';
    for (var width in columnWidths) {
      separator += '${''.padRight(width + 2, '-')}+';
    }

    stdout.writeln(separator);
    stdout.writeln(formatRow(headers));
    stdout.writeln(separator);
    for (var row in rows) {
      stdout.writeln(formatRow(row));
    }
    stdout.writeln(separator);
  }
}
