import 'dart:io';
import 'package:flutter_doctor_pro/core/runner.dart';

void main(List<String> args) async {
  try {
    final runner = FlutterDoctorProRunner();
    final exitCode = await runner.run(args);

    exit(exitCode ?? 0);
  } catch (e, stackTrace) {
    stderr.writeln('An unexpected error occurred: $e');
    stderr.writeln(stackTrace);
    exit(1);
  }
}
