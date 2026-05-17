import 'dart:io';
import 'package:path/path.dart' as p;

class ProjectValidator {
  static String detectExecutableName(String projectPath) {
    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    if (File(pubspecPath).existsSync()) {
      final content = File(pubspecPath).readAsStringSync();
      final match = RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(content);
      if (match != null) {
        final name = match.group(1)!.trim();
        return Platform.isWindows ? '$name.exe' : name;
      }
    }
    return 'app.exe';
  }
}
