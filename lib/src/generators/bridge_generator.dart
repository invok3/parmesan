import 'dart:io';
import 'package:path/path.dart' as p;
import '../parsers/cpp_header_parser.dart';
import '../templates/template_engine.dart';

class ModuleInfo {
  final String name;
  final List<CppFunction> functions;

  ModuleInfo({required this.name, required this.functions});
}

class BridgeGenerator {
  static String generateBridgeHeader(
    List<ModuleInfo> modules,
    String bridgeTemplate,
  ) {
    final typedefs = <String>[];
    final getters = <String>[];
    final handles = <String>[];
    final ffiExports = <String>[];

    for (final module in modules) {
      final snakeName = module.name;

      handles.add('    ModuleHandle ${snakeName}_handle;');

      for (final func in module.functions) {
        final params = func.parameters
            .map((p) => '${p.type} ${p.name}')
            .join(', ');
        final paramsVoid = params.isEmpty ? 'void' : params;

        typedefs.add(
          'typedef ${func.returnType} (*${snakeName}_${func.name}_fn)($paramsVoid);',
        );

        getters.add(
          '    ${snakeName}_${func.name}_fn get_${snakeName}_${func.name}();',
        );

        ffiExports.add(
          '    FFI_EXPORT ${func.returnType} parmesan_${snakeName}_${func.name}($paramsVoid);',
        );
      }
    }

    return TemplateEngine.render(bridgeTemplate, {
      'MODULE_TYPEDEFS': typedefs.join('\n'),
      'MODULE_GETTERS': getters.join('\n\n'),
      'MODULE_HANDLES': handles.join('\n'),
      'FFI_EXPORTS': ffiExports.join('\n\n'),
    });
  }

  static String generateBridgeCpp(
    List<ModuleInfo> modules,
    String bridgeCppTemplate,
  ) {
    final loads = <String>[];
    final unloads = <String>[];
    final getters = <String>[];
    final ffiImpls = <String>[];

    for (final module in modules) {
      final snakeName = module.name;

      final loadLines = [
        '    // $snakeName',
        '    ${snakeName}_handle = load_module("modules/$snakeName");',
        '    if (!${snakeName}_handle) {',
        '        std::cerr << "Failed to load module: $snakeName" << std::endl;',
        '        return false;',
        '    }',
      ];
      loads.add(loadLines.join('\n'));

      unloads.add('    unload_module(${snakeName}_handle);');

      for (final func in module.functions) {
        final params = func.parameters
            .map((p) => '${p.type} ${p.name}')
            .join(', ');
        final paramsVoid = params.isEmpty ? 'void' : params;
        final argNames = func.parameters.map((p) => p.name).join(', ');
        final argsVoid = argNames.isEmpty ? '' : argNames;

        getters.add(
          '${snakeName}_${func.name}_fn ModuleBridge::get_${snakeName}_${func.name}() {\n'
          '    return (${snakeName}_${func.name}_fn)resolve_symbol(${snakeName}_handle, "${func.name}");\n'
          '}',
        );

        final callExpr = 'ModuleBridge::instance().get_${snakeName}_${func.name}()($argsVoid)';
        final body = func.returnType == 'void' ? callExpr : 'return $callExpr';

        ffiImpls.add(
          'FFI_EXPORT ${func.returnType} parmesan_${snakeName}_${func.name}($paramsVoid) {\n'
          '    $body;\n'
          '}',
        );
      }
    }

    return TemplateEngine.render(bridgeCppTemplate, {
      'MODULE_LOADS': loads.join('\n\n'),
      'MODULE_UNLOADS': unloads.join('\n'),
      'MODULE_GETTERS_IMPLS': getters.join('\n\n'),
      'FFI_IMPLS': ffiImpls.join('\n\n'),
    });
  }

  static String generateDartBindings(
    List<ModuleInfo> modules,
    String libraryName,
  ) {
    final buffer = StringBuffer();

    buffer.writeln("import 'dart:ffi';");
    buffer.writeln('');
    buffer.writeln("// Auto-generated FFI bindings by parmesan_cli");
    buffer.writeln("// Do not edit manually. Run 'parmesan generate:bindings' to regenerate.");
    buffer.writeln('');
    buffer.writeln("final DynamicLibrary nativeLib = DynamicLibrary.open('$libraryName');");
    buffer.writeln('');

    for (final module in modules) {
      final snakeName = module.name;

      buffer.writeln('// === Module: $snakeName ===');
      buffer.writeln('');

      for (final func in module.functions) {
        final dartReturnType = CppHeaderParser.toDartNativeType(func.returnType);
        final ffiReturnType = CppHeaderParser.toDartFfiType(func.returnType);

        final cParams = func.parameters
            .map((p) => CppHeaderParser.toDartFfiType(p.type))
            .join(', ');
        final dartParams = func.parameters
            .map((p) => CppHeaderParser.toDartNativeType(p.type))
            .join(', ');

        final pascalName = _pascalCase('parmesan_${snakeName}_${func.name}');
        final camelName = _camelCase('parmesan_${snakeName}_${func.name}');

        buffer.writeln('typedef ${pascalName}C = '
            '$ffiReturnType Function(${cParams.isEmpty ? "Void" : cParams});');
        buffer.writeln('typedef ${pascalName}Dart = '
            '$dartReturnType Function(${dartParams.isEmpty ? "" : dartParams});');
        buffer.writeln('');

        buffer.writeln('final ${pascalName}Dart $camelName = nativeLib');
        buffer.writeln("    .lookupFunction<${pascalName}C, ${pascalName}Dart>(");
        buffer.writeln("        'parmesan_${snakeName}_${func.name}',");
        buffer.writeln('    );');
        buffer.writeln('');
      }
    }

    return buffer.toString();
  }

  static Future<List<ModuleInfo>> scanModules(String projectPath) async {
    final modules = <ModuleInfo>[];
    final srcDir = Directory(p.join(projectPath, 'src'));

    if (!srcDir.existsSync()) {
      return modules;
    }

    await for (final entity in srcDir.list()) {
      if (entity is Directory) {
        final dirName = p.basename(entity.path);
        if (dirName == 'bridge') continue;

        final headerFile = File(p.join(entity.path, '$dirName.h'));
        if (!headerFile.existsSync()) continue;

        final content = headerFile.readAsStringSync();
        final functions = CppHeaderParser.parse(content);

        if (functions.isNotEmpty) {
          modules.add(ModuleInfo(name: dirName, functions: functions));
        }
      }
    }

    return modules;
  }

  static String _pascalCase(String input) {
    final parts = input.split('_');
    return parts.map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
  }

  static String _camelCase(String input) {
    final pascal = _pascalCase(input);
    if (pascal.isEmpty) return '';
    return pascal[0].toLowerCase() + pascal.substring(1);
  }
}
