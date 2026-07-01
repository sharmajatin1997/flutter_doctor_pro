import 'dart:io';
import 'package:flutter_doctor_pro/core/base_command.dart';

class VersionCommand extends BaseCommand {
  @override
  String get name => 'version';

  @override
  String get description => 'Print the current version.';

  @override
  Future<int> run() async {
    stdout.writeln('flutter_doctor_pro version: 1.0.0');
    return 0;
  }
}
