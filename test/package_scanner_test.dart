import 'dart:io';
import 'package:test/test.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/config/config.dart';
import 'package:flutter_doctor_pro/logger/logger.dart';
import 'package:flutter_doctor_pro/scanners/package_scanner_plugin.dart';

void main() {
  group('PackageScannerPlugin AST Regression Tests', () {
    late Directory tempDir;
    late ProjectContext context;
    late PackageScannerPlugin scanner;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('package_scanner_test_');
      final libDir = Directory('${tempDir.path}/lib')..createSync();

      // Create a dummy dart file simulating imports
      final mainFile = File('${libDir.path}/main.dart');
      mainFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import "package:firebase_core/firebase_core.dart";
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  runApp(MyApp());
}
      ''');

      context = ProjectContext(
        directory: tempDir.path,
        config: const AppConfig(),
        logger: Logger(silent: true),
        isFlutterProject: true,
        flutterVersion: '3.22.0',
        dartVersion: '3.4.0',
        hasGit: true,
        pubspec: {
          'dependencies': {
            'flutter': {'sdk': 'flutter'},
            'firebase_core': '^2.0.0',
            'package_info_plus': '^4.0.0',
            'unused_package': '^1.0.0', // This one should be flagged
          },
        },
      );

      scanner = PackageScannerPlugin();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
      'should correctly identify firebase_core and package_info_plus as used via AST',
      () async {
        final result = await scanner.scan(context);

        final unusedPackages = result.issues.map((i) => i.description).toList();

        expect(
          unusedPackages.any((desc) => desc.contains('"firebase_core"')),
          isFalse,
          reason:
              'firebase_core should be considered USED since it is imported',
        );

        expect(
          unusedPackages.any((desc) => desc.contains('"package_info_plus"')),
          isFalse,
          reason:
              'package_info_plus should be considered USED since it is imported',
        );

        expect(
          unusedPackages.any((desc) => desc.contains('"unused_package"')),
          isTrue,
          reason: 'unused_package should be flagged as UNUSED',
        );
      },
    );
  });
}
