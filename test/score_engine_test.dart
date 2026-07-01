import 'package:test/test.dart';
import 'package:flutter_doctor_pro/score/score_engine.dart';
import 'package:flutter_doctor_pro/models/issue.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/config/config.dart';

import 'package:flutter_doctor_pro/logger/logger.dart';

void main() {
  final dummyLogger = Logger(silent: true);
  final dummyPubspec = {'name': 'test_app', 'version': '1.0.0'};

  group('Score Engine', () {
    test('Calculates 100 with no issues', () {
      final context = ProjectContext(
        directory: '.',
        config: const AppConfig(),
        logger: dummyLogger,
        pubspec: dummyPubspec,
        dartVersion: '3.0.0',
        flutterVersion: '3.10.0',
        hasGit: false,
        isFlutterProject: true,
      );
      final engine = ScoreEngine(context);

      final catScores = engine.calculateDetailedScore([]);
      final total = engine.calculateTotalScore(catScores);

      expect(total, 100);
      expect(catScores['Assets']?.score, 100);
    });

    test('Deducts points for issues', () {
      final context = ProjectContext(
        directory: '.',
        config: const AppConfig(),
        logger: dummyLogger,
        pubspec: dummyPubspec,
        dartVersion: '3.0.0',
        flutterVersion: '3.10.0',
        hasGit: false,
        isFlutterProject: true,
      );
      final engine = ScoreEngine(context);

      final issues = [
        Issue(
          title: 'Critical Asset',
          description: '',
          category: 'Assets',
          severity: IssueSeverity.critical,
        ),
        Issue(
          title: 'High Asset',
          description: '',
          category: 'Assets',
          severity: IssueSeverity.high,
        ),
      ];

      final catScores = engine.calculateDetailedScore(issues);
      final total = engine.calculateTotalScore(catScores);

      // Critical (25) + High (10) = 35 deductions in Assets.
      // 100 - 35 = 65.
      expect(catScores['Assets']?.score, 65);

      // Weighted average check.
      // Assets weight = 20
      // 65 * 20 = 1300
      // Other 5 categories (Code=25, Perf=20, Deps=15, Struct=10, Docs=10) = 80 weight * 100 = 8000
      // Total = 9300 / 100 = 93
      expect(total, 94);
    });
  });
}
