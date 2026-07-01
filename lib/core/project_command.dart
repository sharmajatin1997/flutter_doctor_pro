import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:flutter_doctor_pro/core/context.dart';
import 'package:flutter_doctor_pro/services/project_detection.dart';
import 'package:flutter_doctor_pro/config/config.dart';
import 'package:flutter_doctor_pro/logger/logger.dart';

abstract class ProjectCommand extends Command<int> {
  late final ProjectContext context;

  Future<void> initContext() async {
    final logger = Logger();
    final detector = ProjectDetector(logger: logger);
    const config = AppConfig(); // Or load from file dynamically
    context = await detector.detect(Directory.current.path, config);
  }

  @override
  Future<int> run() async {
    await initContext();
    await runProjectCommand();
    return 0;
  }

  Future<void> runProjectCommand();
}
