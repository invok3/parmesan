import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../templates/template_engine.dart';
import '../utils/file_utils.dart';

class AddPlatformCommand extends Command<int> {
  @override
  final name = 'add:platform';

  @override
  final description = 'Add platform-specific build configuration';

  AddPlatformCommand() {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Path to the Parmesan project (default: current directory)',
    );
  }

  @override
  Future<int> run() async {
    final args = argResults!;
    final platformArg = args.rest.isEmpty ? null : args.rest.first;

    if (platformArg == null || platformArg.isEmpty) {
      print('Usage: parmesan add:platform <windows|linux|all>');
      print('');
      print('Available platforms:');
      print('  windows - Windows');
      print('  linux   - Linux');
      print('  all     - Windows and Linux');
      return 1;
    }

    final platforms = _resolvePlatforms(platformArg);
    if (platforms.isEmpty) {
      print('Error: Unsupported platform "$platformArg"');
      print('Supported platforms: windows, linux, all');
      return 1;
    }

    final projectPath = args['path'] as String? ?? Directory.current.path;

    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    if (!File(pubspecPath).existsSync()) {
      print('Error: pubspec.yaml not found at $projectPath');
      return 1;
    }
    final pubspecContent = File(pubspecPath).readAsStringSync();
    final match = RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(pubspecContent);
    final projectName = match?.group(1)?.trim() ?? 'app';

    await _ensureBridgeFiles(projectPath, projectName);

    for (final platform in platforms) {
      await _configurePlatform(projectPath, platform);
    }

    return 0;
  }

  List<String> _resolvePlatforms(String arg) {
    final normalized = arg.toLowerCase();
    if (normalized == 'all') return ['windows', 'linux'];
    if (normalized == 'windows') return ['windows'];
    if (normalized == 'linux') return ['linux'];
    return [];
  }

  Future<void> _ensureBridgeFiles(String projectPath, String projectName) async {
    final bridgeH = p.join(projectPath, 'src', 'bridge', 'bridge.h');
    final bridgeCpp = p.join(projectPath, 'src', 'bridge', 'bridge.cpp');

    if (await FileUtils.exists(bridgeH) && await FileUtils.exists(bridgeCpp)) {
      print('Bridge files already exist.');
      return;
    }

    print('Creating bridge files...');

    if (!await FileUtils.exists(bridgeH)) {
      final template = await _loadTemplate('project/bridge.h.tmpl');
      await FileUtils.writeFile(bridgeH, TemplateEngine.render(template, {
        'projectName': projectName,
      }));
      print('  Created: src/bridge/bridge.h');
    }

    if (!await FileUtils.exists(bridgeCpp)) {
      final template = await _loadTemplate('project/bridge.cpp.tmpl');
      await FileUtils.writeFile(bridgeCpp, TemplateEngine.render(template, {
        'projectName': projectName,
      }));
      print('  Created: src/bridge/bridge.cpp');
    }
  }

  Future<void> _configurePlatform(String projectPath, String platform) async {
    final cmakePath = _getCMakeListsPath(projectPath, platform);

    if (!await FileUtils.exists(cmakePath)) {
      print('$platform: CMakeLists.txt not found. Skipping.');
      return;
    }

    await _injectBridgeSources(cmakePath, platform);
  }

  String _getCMakeListsPath(String projectPath, String platform) {
    return p.join(projectPath, platform, 'runner', 'CMakeLists.txt');
  }

  Future<void> _injectBridgeSources(String cmakePath, String platform) async {
    var content = await File(cmakePath).readAsString();

    if (content.contains('# PARMESAN_BRIDGE_SOURCES')) {
      print('$platform: bridge sources already configured.');
      return;
    }

    final bridgeH = '"../../src/bridge/bridge.h"';
    final bridgeCpp = '"../../src/bridge/bridge.cpp"';

    final addExecutableRegex = RegExp(r'(add_executable\s*\(\s*\$\{BINARY_NAME\}(?:\s+WIN32)?\s+)([^\)]*\))', dotAll: true);
    final match = addExecutableRegex.firstMatch(content);

    if (match == null) {
      print('$platform: could not find add_executable() block. Skipping.');
      return;
    }

    final before = match.group(1)!;
    final after = match.group(2)!;
    final replacement = '$before$bridgeH\n  $bridgeCpp\n  # PARMESAN_BRIDGE_SOURCES\n  $after';

    content = content.replaceFirst(addExecutableRegex, replacement);
    await File(cmakePath).writeAsString(content);

    print('$platform: injected bridge sources into ${p.relative(cmakePath)}.');
  }

  Future<String> _loadTemplate(String path) async {
    final templatePath = p.join(_templatesDir, path);
    return await File(templatePath).readAsString();
  }

  String get _templatesDir {
    final scriptDir = p.dirname(Platform.script.toFilePath());
    final packageConfigPath = p.join(scriptDir, '..', '..', '..', 'package_config.json');
    final normalizedPath = p.normalize(packageConfigPath);
    final packageConfigFile = File(normalizedPath);
    if (packageConfigFile.existsSync()) {
      final packageConfig = jsonDecode(packageConfigFile.readAsStringSync());
      for (final pkg in packageConfig['packages'] as List) {
        if (pkg['name'] == 'parmesan') {
          var rootUri = pkg['rootUri'] as String;
          if (rootUri.startsWith('file://')) {
            rootUri = rootUri.substring(7);
          } else if (rootUri.startsWith('../') || rootUri.startsWith('./')) {
            final packageConfigDir = p.dirname(normalizedPath);
            rootUri = p.normalize(p.join(packageConfigDir, rootUri));
          }
          return p.join(rootUri, 'lib', 'src', 'templates');
        }
      }
    }
    final currentDir = p.dirname(Platform.script.toFilePath());
    return p.join(currentDir, '..', 'lib', 'src', 'templates');
  }
}
