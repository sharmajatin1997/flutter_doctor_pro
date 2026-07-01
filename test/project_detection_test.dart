import 'dart:io';
import 'package:flutter_doctor_pro/config/config.dart';
import 'package:flutter_doctor_pro/logger/logger.dart';
import 'package:flutter_doctor_pro/services/project_detection.dart';
import 'package:flutter_doctor_pro/exceptions/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectDetector', () {
    test('throws exception if not a flutter project', () async {
      final logger = Logger(silent: true);
      final detector = ProjectDetector(logger: logger);

      // Creating a temporary directory without pubspec.yaml
      final tempDir = await Directory.systemTemp.createTemp(
        'flutter_doctor_pro_test',
      );

      expect(
        () async => await detector.detect(tempDir.path, const AppConfig()),
        throwsA(isA<ProjectDoctorException>()),
      );

      await tempDir.delete(recursive: true);
    });
  });
}
