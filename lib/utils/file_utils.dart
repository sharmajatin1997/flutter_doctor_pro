import 'dart:io';
import 'package:path/path.dart' as p;

class FileUtils {
  static List<File> getDartFiles(String projectDir) {
    return _getFilesByExtension(projectDir, 'lib', '.dart');
  }

  static List<File> getArbFiles(String projectDir) {
    return _getFilesByExtension(projectDir, 'lib', '.arb');
  }

  static List<File> _getFilesByExtension(
    String projectDir,
    String subDir,
    String extension,
  ) {
    final dir = Directory(p.join(projectDir, subDir));
    if (!dir.existsSync()) return [];

    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith(extension))
        .toList();
  }
}
