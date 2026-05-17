import 'package:test/test.dart';
import 'package:parmesan/src/parsers/cpp_header_parser.dart';

void main() {
  group('CppHeaderParser', () {
    test('parses simple extern C function', () {
      const header = '''
#ifdef __cplusplus
extern "C" {
#endif

int add(int32_t a, int32_t b);

#ifdef __cplusplus
}
#endif
''';

      final functions = CppHeaderParser.parse(header);
      expect(functions, hasLength(1));
      expect(functions[0].name, 'add');
      expect(functions[0].returnType, 'int');
      expect(functions[0].parameters, hasLength(2));
      expect(functions[0].parameters[0].type, 'int32_t');
      expect(functions[0].parameters[0].name, 'a');
      expect(functions[0].parameters[1].type, 'int32_t');
      expect(functions[0].parameters[1].name, 'b');
    });

    test('parses function with no parameters', () {
      const header = '''
extern "C" {
    void initialize();
}
''';

      final functions = CppHeaderParser.parse(header);
      expect(functions, hasLength(1));
      expect(functions[0].name, 'initialize');
      expect(functions[0].returnType, 'void');
      expect(functions[0].parameters, isEmpty);
    });

    test('parses multiple functions', () {
      const header = '''
extern "C" {
    int32_t compute(int32_t input);
    void process(uint8_t* buffer, int32_t size);
    double calculate(double x, double y);
}
''';

      final functions = CppHeaderParser.parse(header);
      expect(functions, hasLength(3));
      expect(functions[0].name, 'compute');
      expect(functions[1].name, 'process');
      expect(functions[2].name, 'calculate');
    });

    test('parses dllexport decorated functions', () {
      const header = '''
extern "C" {
    __declspec(dllexport) int32_t my_function(int32_t input);
}
''';

      final functions = CppHeaderParser.parse(header);
      expect(functions, hasLength(1));
      expect(functions[0].name, 'my_function');
      expect(functions[0].returnType, 'int32_t');
    });

    test('parses macro-based export functions', () {
      const header = '''
#define MODULE_EXPORT extern "C" __declspec(dllexport)

MODULE_EXPORT void compute_mandelbrot(
    uint8_t* buffer,
    int width,
    int height
);
''';

      final functions = CppHeaderParser.parse(header);
      expect(functions, hasLength(1));
      expect(functions[0].name, 'compute_mandelbrot');
      expect(functions[0].returnType, 'void');
      expect(functions[0].parameters, hasLength(3));
    });

    test('maps C++ types to Dart FFI types', () {
      expect(CppHeaderParser.toDartFfiType('int32_t'), 'Int32');
      expect(CppHeaderParser.toDartFfiType('uint32_t'), 'Uint32');
      expect(CppHeaderParser.toDartFfiType('int64_t'), 'Int64');
      expect(CppHeaderParser.toDartFfiType('float'), 'Float');
      expect(CppHeaderParser.toDartFfiType('double'), 'Double');
      expect(CppHeaderParser.toDartFfiType('void'), 'Void');
      expect(CppHeaderParser.toDartFfiType('uint8_t*'), 'Pointer<Uint8>');
      expect(CppHeaderParser.toDartFfiType('const char*'), 'Pointer<Utf8>');
    });

    test('maps C++ types to Dart native types', () {
      expect(CppHeaderParser.toDartNativeType('int32_t'), 'int');
      expect(CppHeaderParser.toDartNativeType('float'), 'double');
      expect(CppHeaderParser.toDartNativeType('double'), 'double');
      expect(CppHeaderParser.toDartNativeType('void'), 'void');
      expect(CppHeaderParser.toDartNativeType('const char*'), 'String');
    });

    test('generates Dart bindings', () {
      const header = '''
extern "C" {
    int32_t add(int32_t a, int32_t b);
}
''';

      final functions = CppHeaderParser.parse(header);
      final bindings = CppHeaderParser.generateDartBindings(functions, 'myapp.exe');

      expect(bindings, contains("import 'dart:ffi';"));
      expect(bindings, contains("DynamicLibrary.open('myapp.exe')"));
      expect(bindings, contains('typedef AddC'));
      expect(bindings, contains('typedef AddDart'));
      expect(bindings, contains('final AddDart add'));
    });
  });
}
