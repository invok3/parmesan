import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../templates/template_engine.dart';
import '../utils/file_utils.dart';
import '../utils/package_path_resolver.dart';
import '../utils/string_utils.dart';

class AddModuleCommand extends Command<int> {
  @override
  final name = 'add:module';

  @override
  final description = 'Add a new C++ module to the project';

  AddModuleCommand() {
    argParser.addOption(
      'functions',
      abbr: 'f',
      help: 'Comma-separated function signatures (e.g., "int foo(int32_t x),void bar()")',
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
    final moduleName = args.rest.isEmpty ? null : args.rest.first;

    if (moduleName == null || moduleName.isEmpty) {
      print('Usage: parmesan add:module <module_name> [--functions "returnType name(params)"]');
      return 1;
    }

    final projectPath = args['path'] as String? ?? Directory.current.path;

    final functionsStr = args['functions'] as String?;
    final functions = functionsStr != null
        ? _parseFunctions(functionsStr)
        : await _promptForFunctions();

    if (functions.isEmpty) {
      functions.add(_createDefaultFunction(moduleName));
    }

    print('Adding module: $moduleName');
    print('Functions: ${functions.map((f) => f.toString()).join(", ")}');
    print('');

    await _addModule(projectPath, moduleName, functions);

    return 0;
  }

  List<ModuleFunction> _parseFunctions(String functionsStr) {
    final functions = <ModuleFunction>[];
    final parts = _splitFunctions(functionsStr);

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      final match = RegExp(r'(\w+)\s+(\w+)\s*\(([^)]*)\)').firstMatch(trimmed);
      if (match != null) {
        functions.add(ModuleFunction(
          returnType: match.group(1)!,
          name: match.group(2)!,
          parameters: match.group(3)!.trim(),
        ));
      }
    }

    return functions;
  }

  List<String> _splitFunctions(String input) {
    final parts = <String>[];
    var depth = 0;
    final buffer = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '(') {
        depth++;
        buffer.write(char);
      } else if (char == ')') {
        depth--;
        buffer.write(char);
      } else if (char == ',' && depth == 0) {
        parts.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }

  Future<List<ModuleFunction>> _promptForFunctions() async {
    final functions = <ModuleFunction>[];

    print('Enter function signatures (empty line to finish):');
    print('Format: returnType functionName(paramType paramName, ...)');
    print('Example: int32_t compute_something(int32_t input, double factor)');
    print('');

    while (true) {
      stdout.write('Function: ');
      final input = stdin.readLineSync()?.trim() ?? '';

      if (input.isEmpty) {
        if (functions.isEmpty) {
          functions.add(_createDefaultFunction('module'));
        }
        break;
      }

      final match = RegExp(r'(\w+)\s+(\w+)\s*\(([^)]*)\)').firstMatch(input);
      if (match != null) {
        functions.add(ModuleFunction(
          returnType: match.group(1)!,
          name: match.group(2)!,
          parameters: match.group(3)!.trim(),
        ));
        print('  Added: ${match.group(0)}');
      } else {
        print('  Invalid format. Try again.');
      }
    }

    return functions;
  }

  ModuleFunction _createDefaultFunction(String moduleName) {
    return ModuleFunction(
      returnType: 'int32_t',
      name: '${StringUtils.toSnakeCase(moduleName)}_process',
      parameters: 'int32_t input',
    );
  }

  Future<void> _addModule(
    String projectPath,
    String moduleName,
    List<ModuleFunction> functions,
  ) async {
    final snakeName = StringUtils.toSnakeCase(moduleName);
    final upperName = StringUtils.toScreamingSnake(moduleName);

    print('Creating module files...');

    final moduleDir = p.join(projectPath, 'src', snakeName);
    await FileUtils.createDirectory(moduleDir);

    final exports = functions.map((f) {
      final params = f.parameters.isEmpty ? 'void' : f.parameters;
      return 'MODULE_EXPORT ${f.returnType} ${f.name}($params);';
    }).join('\n\n');

    final implementations = functions.map((f) {
      final params = f.parameters.isEmpty ? 'void' : f.parameters;
      return '${f.returnType} ${f.name}($params) {\n    // TODO: Implementation\n    return 0;\n}';
    }).join('\n\n');

    final moduleH = await _loadTemplate('module/module.h.tmpl');
    await FileUtils.writeFile(
      p.join(moduleDir, '$snakeName.h'),
      TemplateEngine.render(moduleH, {
        'MODULE_NAME_UPPER': upperName,
        'MODULE_EXPORTS': exports,
        'module_name': snakeName,
      }),
    );

    final moduleCpp = await _loadTemplate('module/module.cpp.tmpl');
    await FileUtils.writeFile(
      p.join(moduleDir, '$snakeName.cpp'),
      TemplateEngine.render(moduleCpp, {
        'MODULE_IMPLEMENTATIONS': implementations,
        'module_name': snakeName,
      }),
    );

    print('  Created: src/$snakeName/$snakeName.h');
    print('  Created: src/$snakeName/$snakeName.cpp');
    print('');

    await _configureCMakeLists(projectPath);
  }

  Future<void> _configureCMakeLists(String projectPath) async {
    print('Configuring CMake...');

    final platforms = ['windows', 'linux'];

    for (final platform in platforms) {
      final cmakePath = p.join(projectPath, platform, 'runner', 'CMakeLists.txt');

      if (!await FileUtils.exists(cmakePath)) {
        continue;
      }

      await _configurePlatformCMake(cmakePath, platform);
    }
  }

  Future<void> _configurePlatformCMake(String cmakePath, String platform) async {
    var content = await File(cmakePath).readAsString();

    final bridgeHInExecutable = content.contains('"../../src/bridge/bridge.h"') &&
        _hasBridgeHInAddExecutable(content);

    if (!bridgeHInExecutable) {
      print('  $platform: not active (bridge.h not in add_executable). Skipping.');
      return;
    }

    if (content.contains('# PARMESAN_MODULE_LOOP')) {
      print('  $platform: module loop already configured.');
      return;
    }

    final moduleLoop = '''

# PARMESAN_MODULE_LOOP - Auto-discover and build C++ modules
set(PARMESAN_SOURCES "\${CMAKE_CURRENT_SOURCE_DIR}/../../src")

file(GLOB CHILDREN RELATIVE "\${PARMESAN_SOURCES}" "\${PARMESAN_SOURCES}/*")

foreach(CHILD \${CHILDREN})
    if(CHILD STREQUAL "bridge")
        continue()
    endif()

    set(MODULE_PATH "\${PARMESAN_SOURCES}/\${CHILD}")

    if(IS_DIRECTORY "\${MODULE_PATH}")
        file(GLOB_RECURSE MODULE_SOURCES
            "\${MODULE_PATH}/*.cpp"
            "\${MODULE_PATH}/*.h"
        )

        if(MODULE_SOURCES)
            add_library(\${CHILD} SHARED \${MODULE_SOURCES})
            target_include_directories(\${CHILD} PRIVATE "\${PARMESAN_SOURCES}")
            set_target_properties(\${CHILD} PROPERTIES
                LIBRARY_OUTPUT_DIRECTORY "\${CMAKE_BINARY_DIR}/runner/\$<CONFIG>/modules"
                RUNTIME_OUTPUT_DIRECTORY "\${CMAKE_BINARY_DIR}/runner/\$<CONFIG>/modules"
            )
        endif()
    endif()
endforeach()
''';

    content += moduleLoop;
    await File(cmakePath).writeAsString(content);
    print('  $platform: module loop injected.');
  }

  bool _hasBridgeHInAddExecutable(String content) {
    final regex = RegExp(r'add_executable\s*\([^)]*"\.\./\.\./src/bridge/bridge\.h"[^)]*\)', dotAll: true);
    return regex.hasMatch(content);
  }

  Future<String> _loadTemplate(String path) async {
    final templatePath = p.join(_templatesDir, path);
    return await File(templatePath).readAsString();
  }

  String get _templatesDir => PackagePathResolver.resolveTemplatesDir();
}

class ModuleFunction {
  final String returnType;
  final String name;
  final String parameters;

  ModuleFunction({
    required this.returnType,
    required this.name,
    required this.parameters,
  });

  @override
  String toString() => '$returnType $name($parameters)';
}
