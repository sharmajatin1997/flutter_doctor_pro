import 'package:args/command_runner.dart';

abstract class BaseCommand extends Command<int> {
  @override
  String get description;

  @override
  String get name;

  // We can add common getters like logger, config here later
  bool get verbose => globalResults?['verbose'] == true;
  bool get silent => globalResults?['silent'] == true;
}
