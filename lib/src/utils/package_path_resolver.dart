import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class PackagePathResolver {
  static String resolveTemplatesDir() {
    final scriptDir = p.dirname(Platform.script.toFilePath());

    final candidates = [
      p.join(scriptDir, '..', 'package_config.json'),
      p.join(scriptDir, '..', '..', '..', 'package_config.json'),
      p.join(scriptDir, '..', '.dart_tool', 'package_config.json'),
    ];

    for (final candidate in candidates) {
      final normalized = p.normalize(candidate);
      final file = File(normalized);
      if (file.existsSync()) {
        final packageConfig = jsonDecode(file.readAsStringSync());
        for (final pkg in packageConfig['packages'] as List) {
          if (pkg['name'] == 'parmesan') {
            var rootUri = pkg['rootUri'] as String;
            if (rootUri.startsWith('file://')) {
              rootUri = Uri.parse(rootUri).toFilePath();
            } else if (rootUri.startsWith('../') || rootUri.startsWith('./')) {
              final packageConfigDir = p.dirname(normalized);
              rootUri = p.normalize(p.join(packageConfigDir, rootUri));
            }
            return p.join(rootUri, 'lib', 'src', 'templates');
          }
        }
      }
    }

    return p.join(scriptDir, '..', 'lib', 'src', 'templates');
  }
}
