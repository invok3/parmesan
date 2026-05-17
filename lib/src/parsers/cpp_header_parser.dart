class CppFunction {
  final String name;
  final String returnType;
  final List<CppParameter> parameters;

  CppFunction({
    required this.name,
    required this.returnType,
    required this.parameters,
  });

  @override
  String toString() {
    final params = parameters.map((p) => '${p.type} ${p.name}').join(', ');
    return '$returnType $name($params)';
  }
}

class CppParameter {
  final String type;
  final String name;

  CppParameter({required this.type, required this.name});
}

class CppHeaderParser {
  static final _typeMapping = {
    'int8_t': 'Int8',
    'uint8_t': 'Uint8',
    'int16_t': 'Int16',
    'uint16_t': 'Uint16',
    'int32_t': 'Int32',
    'uint32_t': 'Uint32',
    'int64_t': 'Int64',
    'uint64_t': 'Uint64',
    'int': 'Int32',
    'unsigned int': 'Uint32',
    'float': 'Float',
    'double': 'Double',
    'void': 'Void',
    'bool': 'Bool',
    'char': 'Char',
  };

  static final _dartNativeMapping = {
    'int8_t': 'int',
    'uint8_t': 'int',
    'int16_t': 'int',
    'uint16_t': 'int',
    'int32_t': 'int',
    'uint32_t': 'int',
    'int64_t': 'int',
    'uint64_t': 'int',
    'int': 'int',
    'unsigned int': 'int',
    'float': 'double',
    'double': 'double',
    'void': 'void',
    'bool': 'bool',
    'char': 'int',
  };

  static List<CppFunction> parse(String headerContent) {
    final functions = <CppFunction>[];

    final externCRegex = RegExp(r'extern\s+"C"\s*\{([^}]*)\}', dotAll: true);
    final externMatches = externCRegex.allMatches(headerContent);

    for (final match in externMatches) {
      final block = match.group(1)!;
      functions.addAll(_parseFunctionBlock(block));
    }

    final standaloneRegex = RegExp(
      r'extern\s+"C"\s+(?:__declspec\(dllexport\)\s+)?([\w\*]+)\s+(\w+)\s*\(([^)]*)\)',
    );
    for (final match in standaloneRegex.allMatches(headerContent)) {
      final lineStart = headerContent.substring(0, match.start).split('\n').last.trim();
      if (lineStart.startsWith('#')) continue;

      final returnType = match.group(1)!.trim();
      final name = match.group(2)!.trim();
      final paramsStr = match.group(3)!.trim();

      if (_isCppKeyword(name)) continue;

      if (!functions.any((f) => f.name == name)) {
        functions.add(CppFunction(
          name: name,
          returnType: returnType,
          parameters: _parseParameters(paramsStr),
        ));
      }
    }

    final macroExportRegex = RegExp(
      r'(?:MODULE_EXPORT|FFI_EXPORT|EXPORT)\s+([\w\*]+)\s+(\w+)\s*\(([^)]*)\)',
    );
    for (final match in macroExportRegex.allMatches(headerContent)) {
      final lineStart = headerContent.substring(0, match.start).split('\n').last.trim();
      if (lineStart.startsWith('#')) continue;

      final returnType = match.group(1)!.trim();
      final name = match.group(2)!.trim();
      final paramsStr = match.group(3)!.trim();

      if (_isCppKeyword(name)) continue;

      if (!functions.any((f) => f.name == name)) {
        functions.add(CppFunction(
          name: name,
          returnType: returnType,
          parameters: _parseParameters(paramsStr),
        ));
      }
    }

    return functions;
  }

  static List<CppFunction> _parseFunctionBlock(String block) {
    final functions = <CppFunction>[];
    final functionRegex = RegExp(
      r'(?:__declspec\(dllexport\)\s+)?([\w\*]+)\s+(\w+)\s*\(([^)]*)\)',
    );

    for (final match in functionRegex.allMatches(block)) {
      final lineStart = block.substring(0, match.start).split('\n').last.trim();
      if (lineStart.startsWith('#')) continue;

      final returnType = match.group(1)!.trim();
      final name = match.group(2)!.trim();
      final paramsStr = match.group(3)!.trim();

      if (_isCppKeyword(name)) continue;

      functions.add(CppFunction(
        name: name,
        returnType: returnType,
        parameters: _parseParameters(paramsStr),
      ));
    }

    return functions;
  }

  static bool _isCppKeyword(String word) {
    const keywords = {
      'if', 'else', 'endif', 'ifdef', 'ifndef', 'define', 'undef',
      'include', 'pragma', 'error', 'line', 'warning',
      'class', 'struct', 'enum', 'union', 'namespace', 'typedef',
      'public', 'private', 'protected', 'virtual', 'override',
      'const', 'static', 'extern', 'inline', 'volatile',
      'new', 'delete', 'this', 'friend', 'template',
      'try', 'catch', 'throw', 'noexcept',
    };
    return keywords.contains(word);
  }

  static List<CppParameter> _parseParameters(String paramsStr) {
    if (paramsStr.trim().isEmpty || paramsStr.trim() == 'void') {
      return [];
    }

    final params = <CppParameter>[];
    final parts = paramsStr.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      final tokens = trimmed.split(RegExp(r'\s+'));
      if (tokens.length >= 2) {
        final type = tokens.sublist(0, tokens.length - 1).join(' ').trim();
        final name = tokens.last.trim();
        params.add(CppParameter(type: type, name: name));
      }
    }

    return params;
  }

  static String toDartFfiType(String cppType) {
    final baseType = cppType.replaceAll('*', '').trim();

    if (cppType.contains('*')) {
      final innerType = _typeMapping[baseType];
      if (innerType != null) {
        return 'Pointer<$innerType>';
      }
      if (cppType == 'const char*' || cppType == 'char*') {
        return 'Pointer<Utf8>';
      }
      return 'Pointer<Void>';
    }

    return _typeMapping[baseType] ?? 'IntPtr';
  }

  static String toDartNativeType(String cppType) {
    final baseType = cppType.replaceAll('*', '').trim();

    if (cppType.contains('*')) {
      if (cppType == 'const char*' || cppType == 'char*') {
        return 'String';
      }
      final innerType = _typeMapping[baseType];
      if (innerType != null) {
        return 'Pointer<$innerType>';
      }
      return 'Pointer';
    }

    return _dartNativeMapping[baseType] ?? 'int';
  }

  static String generateDartBindings(
    List<CppFunction> functions,
    String libraryName,
  ) {
    final buffer = StringBuffer();

    buffer.writeln("import 'dart:ffi';");
    buffer.writeln("import 'package:ffi/ffi.dart';");
    buffer.writeln('');
    buffer.writeln("// Auto-generated FFI bindings for $libraryName");
    buffer.writeln("// Generated by parmesan_cli");
    buffer.writeln('');
    buffer.writeln("final DynamicLibrary nativeLib = DynamicLibrary.open('$libraryName');");
    buffer.writeln('');

    for (final func in functions) {
      final dartReturnType = toDartNativeType(func.returnType);
      final ffiReturnType = toDartFfiType(func.returnType);

      final cParams = func.parameters
          .map((p) => toDartFfiType(p.type))
          .join(', ');
      final dartParams = func.parameters
          .map((p) => toDartNativeType(p.type))
          .join(', ');

      buffer.writeln('typedef ${_pascalCase(func.name)}C = '
          '$ffiReturnType Function(${cParams.isEmpty ? "" : cParams});');
      buffer.writeln('typedef ${_pascalCase(func.name)}Dart = '
          '$dartReturnType Function(${dartParams.isEmpty ? "" : dartParams});');
      buffer.writeln('');

      final funcVarName = _camelCase(func.name);
      buffer.writeln('final ${_pascalCase(func.name)}Dart $funcVarName = nativeLib');
      buffer.writeln("    .lookupFunction<${_pascalCase(func.name)}C, ${_pascalCase(func.name)}Dart>(");
      buffer.writeln("        '${func.name}',");
      buffer.writeln('    );');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  static String _pascalCase(String input) {
    final parts = input.split('_');
    return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  static String _camelCase(String input) {
    final pascal = _pascalCase(input);
    return pascal[0].toLowerCase() + pascal.substring(1);
  }
}
