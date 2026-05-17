class StringUtils {
  static String toSnakeCase(String input) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '_' || char == '-' || char == ' ') {
        if (buffer.length > 0 && buffer.toString().endsWith('_')) continue;
        buffer.write('_');
      } else if (char == char.toUpperCase() && i > 0 && buffer.length > 0 && !buffer.toString().endsWith('_')) {
        buffer.write('_');
        buffer.write(char.toLowerCase());
      } else {
        buffer.write(char.toLowerCase());
      }
    }
    return buffer.toString();
  }

  static String toCamelCase(String input) {
    final parts = input.replaceAll(RegExp(r'[-_\s]+'), ' ').trim().split(' ');
    if (parts.isEmpty) return '';
    return parts.first.toLowerCase() +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase()).join();
  }

  static String toPascalCase(String input) {
    final camel = toCamelCase(input);
    if (camel.isEmpty) return '';
    return camel[0].toUpperCase() + camel.substring(1);
  }

  static String toScreamingSnake(String input) {
    return toSnakeCase(input).toUpperCase();
  }

  static String toKebabCase(String input) {
    return toSnakeCase(input).replaceAll('_', '-');
  }

  static String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}
