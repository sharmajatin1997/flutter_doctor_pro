import 'package:args/command_runner.dart';
import 'package:flutter_doctor_pro/commands/check_command.dart';
import 'package:flutter_doctor_pro/commands/doctor_command.dart';
import 'package:flutter_doctor_pro/commands/score_command.dart';
import 'package:flutter_doctor_pro/commands/report_command.dart';
import 'package:flutter_doctor_pro/commands/backup_command.dart';
import 'package:flutter_doctor_pro/commands/restore_command.dart';
import 'package:flutter_doctor_pro/commands/undo_command.dart';
import 'package:flutter_doctor_pro/commands/clean_command.dart';
import 'package:flutter_doctor_pro/commands/fix_command.dart';
import 'package:flutter_doctor_pro/commands/version_command.dart';

class FlutterDoctorProRunner extends CommandRunner<int> {
  FlutterDoctorProRunner()
    : super(
        'flutter_doctor_pro',
        'A production-ready comprehensive health scanner for Flutter projects.',
      ) {
    addCommand(CheckCommand());
    addCommand(DoctorCommand());
    addCommand(ScoreCommand());
    addCommand(ReportCommand());
    addCommand(BackupCommand());
    addCommand(RestoreCommand());
    addCommand(UndoCommand());
    addCommand(CleanCommand());
    addCommand(FixCommand());
    addCommand(VersionCommand());
  }
}
