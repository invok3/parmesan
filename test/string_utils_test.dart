import 'package:test/test.dart';
import 'package:parmesan/src/utils/string_utils.dart';

void main() {
  group('StringUtils', () {
    test('toSnakeCase converts camelCase', () {
      expect(StringUtils.toSnakeCase('myModule'), 'my_module');
      expect(StringUtils.toSnakeCase('MandelbrotSet'), 'mandelbrot_set');
    });

    test('toSnakeCase converts PascalCase', () {
      expect(StringUtils.toSnakeCase('MyModule'), 'my_module');
    });

    test('toCamelCase converts snake_case', () {
      expect(StringUtils.toCamelCase('my_module'), 'myModule');
      expect(StringUtils.toCamelCase('mandelbrot_set'), 'mandelbrotSet');
    });

    test('toCamelCase converts kebab-case', () {
      expect(StringUtils.toCamelCase('my-module'), 'myModule');
    });

    test('toPascalCase converts snake_case', () {
      expect(StringUtils.toPascalCase('my_module'), 'MyModule');
      expect(StringUtils.toPascalCase('mandelbrot_set'), 'MandelbrotSet');
    });

    test('toScreamingSnake converts camelCase', () {
      expect(StringUtils.toScreamingSnake('myModule'), 'MY_MODULE');
    });

    test('toKebabCase converts camelCase', () {
      expect(StringUtils.toKebabCase('myModule'), 'my-module');
    });

    test('capitalize capitalizes first letter', () {
      expect(StringUtils.capitalize('hello'), 'Hello');
      expect(StringUtils.capitalize('Hello'), 'Hello');
    });
  });
}
