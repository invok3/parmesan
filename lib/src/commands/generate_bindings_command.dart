import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../generators/bridge_generator.dart';
import '../utils/file_utils.dart';
import '../utils/package_path_resolver.dart';
import '../validators/project_validator.dart';

class GenerateBindingsCommand extends Command<int> {
  @override
  final name = 'generate:bindings';

  @override
  final description = 'Generate bridge files and Dart FFI bindings from all modules';

  GenerateBindingsCommand() {
    argParser.addOption(
      'library',
      abbr: 'l',
      help: 'Native library name (default: detected from pubspec.yaml)',
    );
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Path to the Parmesan project (default: current directory)',
    );
  }

  @override
  Future<int> run() async {
    final args = argResults!;
    final projectPath = args['path'] as String? ?? Directory.current.path;
    final libraryName = args['library'] as String?;

    print('Scanning modules...');
    final modules = await BridgeGenerator.scanModules(projectPath);

    if (modules.isEmpty) {
      print('No modules found in src/.');
      print('Add a module first: parmesan add:module <name>');
      return 1;
    }

    print('Found ${modules.length} module(s):');
    for (final module in modules) {
      print('  - ${module.name} (${module.functions.length} function(s))');
    }
    print('');

    final actualLibraryName = libraryName ??
        ProjectValidator.detectExecutableName(projectPath);

    final bridgeHPath = p.join(projectPath, 'src', 'bridge', 'bridge.h');
    final bridgeCppPath = p.join(projectPath, 'src', 'bridge', 'bridge.cpp');

    print('Resetting bridge files...');

    final bridgeHTemplate = await _loadTemplate(projectPath, 'project/bridge.h.tmpl');
    final bridgeCppTemplate = await _loadTemplate(projectPath, 'project/bridge.cpp.tmpl');

    final bridgeHContent = BridgeGenerator.generateBridgeHeader(modules, bridgeHTemplate);
    final bridgeCppContent = BridgeGenerator.generateBridgeCpp(modules, bridgeCppTemplate);

    await FileUtils.writeFile(bridgeHPath, bridgeHContent);
    await FileUtils.writeFile(bridgeCppPath, bridgeCppContent);

    print('  Updated: src/bridge/bridge.h');
    print('  Updated: src/bridge/bridge.cpp');
    print('');

    print('Generating Dart bindings...');
    final bindingsDir = p.join(projectPath, 'lib', 'bindings');
    await FileUtils.createDirectory(bindingsDir);
    final bindingsPath = p.join(bindingsDir, 'parmesan_bindings.dart');

    final dartBindings = BridgeGenerator.generateDartBindings(modules, actualLibraryName);
    await FileUtils.writeFile(bindingsPath, dartBindings);

    print('  Generated: lib/bindings/parmesan_bindings.dart');
    print('');

    print('Import in your Dart code:');
    print("  import 'package:${p.basename(projectPath)}/bindings/parmesan_bindings.dart';");

    return 0;
  }

  Future<String> _loadTemplate(String projectPath, String path) async {
    final templatesDir = PackagePathResolver.resolveTemplatesDir();
    return await File(p.join(templatesDir, path)).readAsString();
  }
}
