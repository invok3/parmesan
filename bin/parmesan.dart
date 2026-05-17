import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:parmesan/src/commands/add_module_command.dart';
import 'package:parmesan/src/commands/add_platform_command.dart';
import 'package:parmesan/src/commands/generate_bindings_command.dart';

void main(List<String> args) async {
  final runner = ParmesanCommandRunner();
  runner.run(args).then((exitCode) {
    exit(exitCode ?? 0);
  }).catchError((Object e) {
    if (e is UsageException) {
      print(e);
    } else {
      print('Error: $e');
    }
    exit(1);
  });
}

class ParmesanCommandRunner extends CommandRunner<int> {
  ParmesanCommandRunner()
      : super('parmesan', 'Scaffold Flutter + C++ FFI projects') {
    addCommand(AddModuleCommand());
    addCommand(AddPlatformCommand());
    addCommand(GenerateBindingsCommand());
  }
}
