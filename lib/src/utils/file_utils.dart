import 'dart:io';

class FileUtils {
  static Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  static Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  static Future<bool> exists(String path) async {
    return await FileSystemEntity.type(path) != FileSystemEntityType.notFound;
  }

  static Future<bool> isFile(String path) async {
    return await FileSystemEntity.isFile(path);
  }
}
