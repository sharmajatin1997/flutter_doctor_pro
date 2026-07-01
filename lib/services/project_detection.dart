import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_doctor_pro/config/config.dart';
import 'package:flutter_doctor_pro/logger/logger.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/exceptions/exceptions.dart';

class ProjectDetector {
  final Logger logger;

  ProjectDetector({required this.logger});

  Future<ProjectContext> detect(String directory, AppConfig config) async {
    logger.startSpinner('Detecting project environment...');

    final pubspecFile = File(p.join(directory, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      logger.stopSpinner();
      throw ProjectDoctorException(
        'No pubspec.yaml found in $directory. Are you in a Flutter project?',
      );
    }

    Map<String, dynamic>? pubspecMap;
    bool isFlutterProject = false;

    try {
      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content);
      if (yaml is YamlMap) {
        pubspecMap = _convertYamlMap(yaml);
        final dependencies = pubspecMap['dependencies'];
        if (dependencies is Map && dependencies.containsKey('flutter')) {
          isFlutterProject = true;
        }
      }
    } catch (e) {
      logger.stopSpinner();
      throw ProjectDoctorException('Failed to parse pubspec.yaml: $e');
    }

    if (!isFlutterProject) {
      logger.stopSpinner();
      throw ProjectDoctorException(
        'Not a Flutter project (missing flutter dependency in pubspec.yaml).',
      );
    }

    // Detect SDKs
    final flutterVersion = await _getCommandOutput('flutter', ['--version']);
    final dartVersion = await _getCommandOutput('dart', ['--version']);
    final hasGit = await _checkGit(directory);

    logger.stopSpinner();
    logger.success('Project detected as a Flutter project.');

    return ProjectContext(
      directory: directory,
      config: config,
      logger: logger,
      isFlutterProject: isFlutterProject,
      flutterVersion: flutterVersion,
      dartVersion: dartVersion,
      hasGit: hasGit,
      pubspec: pubspecMap,
    );
  }

  Map<String, dynamic> _convertYamlMap(YamlMap yamlMap) {
    final map = <String, dynamic>{};
    for (final entry in yamlMap.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is YamlMap) {
        map[key] = _convertYamlMap(value);
      } else if (value is YamlList) {
        map[key] = value
            .map((e) => e)
            .toList(); // Basic conversion, may need deep conversion if needed
      } else {
        map[key] = value;
      }
    }
    return map;
  }

  Future<String?> _getCommandOutput(String command, List<String> args) async {
    try {
      final result = await Process.run(command, args, runInShell: true);
      if (result.exitCode == 0) {
        return result.stdout.toString().split('\n').first.trim();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _checkGit(String directory) async {
    try {
      final result = await Process.run(
        'git',
        ['rev-parse', '--is-inside-work-tree'],
        workingDirectory: directory,
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
