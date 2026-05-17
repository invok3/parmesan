import 'package:test/test.dart';
import 'package:parmesan/src/templates/template_engine.dart';

void main() {
  group('TemplateEngine', () {
    test('replaces single placeholder', () {
      final result = TemplateEngine.render(
        'Hello {{name}}!',
        {'name': 'World'},
      );
      expect(result, 'Hello World!');
    });

    test('replaces multiple placeholders', () {
      final result = TemplateEngine.render(
        '{{greeting}} {{name}}, welcome to {{project}}!',
        {
          'greeting': 'Hello',
          'name': 'Developer',
          'project': 'Parmesan',
        },
      );
      expect(result, 'Hello Developer, welcome to Parmesan!');
    });

    test('handles missing placeholders gracefully', () {
      final result = TemplateEngine.render(
        'Hello {{name}}!',
        {},
      );
      expect(result, 'Hello {{name}}!');
    });

    test('handles C++ code templates', () {
      const template = '''
#ifndef {{MODULE_NAME_UPPER}}_H
#define {{MODULE_NAME_UPPER}}_H

{{MODULE_EXPORTS}}

#endif
''';

      final result = TemplateEngine.render(
        template,
        {
          'MODULE_NAME_UPPER': 'MY_MODULE',
          'MODULE_EXPORTS': 'void my_function();',
        },
      );

      expect(result, contains('#ifndef MY_MODULE_H'));
      expect(result, contains('#define MY_MODULE_H'));
      expect(result, contains('void my_function();'));
    });
  });
}
