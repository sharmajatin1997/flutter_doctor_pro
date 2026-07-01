import 'package:flutter_doctor_pro/config/config.dart';
import 'package:flutter_doctor_pro/logger/logger.dart';

class ProjectContext {
  final String directory;
  final AppConfig config;
  final Logger logger;
  final bool isFlutterProject;
  final String? flutterVersion;
  final String? dartVersion;
  final bool hasGit;
  final Map<String, dynamic>? pubspec;

  ProjectContext({
    required this.directory,
    required this.config,
    required this.logger,
    required this.isFlutterProject,
    required this.flutterVersion,
    required this.dartVersion,
    required this.hasGit,
    required this.pubspec,
  });
}
