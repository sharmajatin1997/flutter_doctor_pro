import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_doctor_pro/core/context.dart';

class CacheManager {
  final ProjectContext context;
  late final File _cacheFile;
  Map<String, dynamic> _cache = {};
  bool _initialized = false;

  CacheManager(this.context) {
    final cacheDir = Directory(
      p.join(context.directory, '.flutter_doctor_pro', 'cache'),
    );
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    _cacheFile = File(p.join(cacheDir.path, 'scan_cache.json'));
  }

  Future<void> init() async {
    if (!context.config.cacheEnabled) return;

    if (await _cacheFile.exists()) {
      try {
        var content = await _cacheFile.readAsString();
        final rawJson = jsonDecode(content) as Map<String, dynamic>;

        _cache = {};
        if (rawJson.containsKey('issues_found')) {
          _cache.addAll(rawJson['issues_found'] as Map<String, dynamic>);
        }
        if (rawJson.containsKey('perfect_files')) {
          _cache.addAll(rawJson['perfect_files'] as Map<String, dynamic>);
        }

        // Fallback for old cache format
        if (!rawJson.containsKey('issues_found') &&
            !rawJson.containsKey('perfect_files')) {
          _cache = rawJson;
        }
      } catch (e) {
        context.logger.verboseLog('Failed to read cache: $e');
        _cache = {};
      }
    }
    _initialized = true;
  }

  Future<bool> isModified(String filePath) async {
    if (!context.config.cacheEnabled || !_initialized) return true;

    final file = File(p.join(context.directory, filePath));
    if (!await file.exists()) {
      // If it doesn't exist anymore, it's a modification (deletion)
      return true;
    }

    final stat = await file.stat();
    final lastModified = stat.modified.millisecondsSinceEpoch;

    // Quick check based on modification time
    if (_cache.containsKey(filePath)) {
      final cachedEntry = _cache[filePath] as Map<String, dynamic>;
      final cachedTime = cachedEntry['timestamp'] as int?;

      if (cachedTime != null && cachedTime == lastModified) {
        return false;
      }

      // If timestamp doesn't match, verify hash
      final currentHash = await _calculateHash(file);
      final cachedHash = cachedEntry['hash'] as String?;

      if (currentHash == cachedHash) {
        // Update timestamp in cache to avoid future hash calculations
        cachedEntry['timestamp'] = lastModified;
        return false;
      }
    }

    return true;
  }

  Future<void> updateCache(
    String filePath, {
    String? priority,
    List<Map<String, dynamic>>? issues,
  }) async {
    if (!context.config.cacheEnabled || !_initialized) return;

    final file = File(p.join(context.directory, filePath));
    if (await file.exists()) {
      final stat = await file.stat();
      final hash = await _calculateHash(file);

      _cache[filePath] = {
        'timestamp': stat.modified.millisecondsSinceEpoch,
        'hash': hash,
        'priority': ?priority,
        if (issues != null && issues.isNotEmpty) 'issues': issues,
      };
    } else {
      _cache.remove(filePath);
    }
  }

  Future<void> save() async {
    if (!context.config.cacheEnabled || !_initialized) return;

    try {
      final issuesFound = <String, dynamic>{};
      final perfectFiles = <String, dynamic>{};

      for (final entry in _cache.entries) {
        final value = entry.value as Map<String, dynamic>;
        if (value['priority'] == 'perfect') {
          perfectFiles[entry.key] = value;
        } else {
          issuesFound[entry.key] = value;
        }
      }

      final output = {
        'issues_found': issuesFound,
        'perfect_files': perfectFiles,
      };

      final encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(output);

      await _cacheFile.writeAsString(jsonString);
    } catch (e) {
      context.logger.verboseLog('Failed to save cache: $e');
    }
  }

  Future<String> _calculateHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}
