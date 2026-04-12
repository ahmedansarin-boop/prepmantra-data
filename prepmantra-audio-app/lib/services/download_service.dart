import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService {
  final Dio _dio;
  final SharedPreferences _prefs;

  DownloadService(this._prefs, {Dio? dio}) : _dio = dio ?? Dio();

  String _sanitizeKey(String id) => 'download_$id';

  /// Check if an episode is fully downloaded and available on the file system
  bool isDownloaded(String episodeId) {
    final path = _prefs.getString(_sanitizeKey(episodeId));
    if (path != null) {
      return File(path).existsSync();
    }
    return false;
  }

  /// Retrieve the local file path if available
  String? getLocalPath(String episodeId) {
    final path = _prefs.getString(_sanitizeKey(episodeId));
    if (path != null && File(path).existsSync()) {
      return path;
    }
    return null;
  }

  /// Download the audio file and save the reference to SharedPreferences
  Future<String?> downloadAudio(String url, String episodeId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      
      // Determine file extension
      final extension = url.split('.').last.split('?').first;
      final safeExt = (extension.isNotEmpty && extension.length <= 4) ? extension : 'mp3';
      
      // Sanitize fileName to prevent path traversal
      final safeId = episodeId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = '${safeId}_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final savedPath = '${dir.path}/$fileName';

      debugPrint('Starting download for episode: $episodeId');

      await _dio.download(
        url,
        savedPath,
        deleteOnError: true, // Cleans up partial downloads automatically
      );

      if (File(savedPath).existsSync()) {
        await _prefs.setString(_sanitizeKey(episodeId), savedPath);
        debugPrint('Download complete. Saved at: $savedPath');
        return savedPath;
      }
      return null;
    } catch (e) {
      debugPrint('Download failure for episode $episodeId: $e');
      return null;
    }
  }
}
