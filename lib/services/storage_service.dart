import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/movement_event.dart';

class StorageService {
  static final StorageService instance = StorageService._init();

  StorageService._init();

  /// Get storage usage information
  Future<StorageInfo> getStorageInfo() async {
    final appDir = await getApplicationDocumentsDirectory();

    final snapshotsSize = await _getDirectorySize('${appDir.path}/snapshots');
    final videosSize = await _getDirectorySize('${appDir.path}/videos');
    final personsSize = await _getDirectorySize('${appDir.path}/known_persons');

    final dbFile = File('${await getDatabasesPath()}/movements.db');
    final dbSize = await dbFile.exists() ? await dbFile.length() : 0;

    final totalSize = snapshotsSize + videosSize + personsSize + dbSize;

    final snapshotCount = await _countFiles('${appDir.path}/snapshots');
    final videoCount = await _countFiles('${appDir.path}/videos');
    final personCount = await _countFiles('${appDir.path}/known_persons');

    final eventCount = await DatabaseHelper.instance.readAll(limit: 10000).then((list) => list.length);

    return StorageInfo(
      totalBytes: totalSize,
      snapshotsBytes: snapshotsSize,
      videosBytes: videosSize,
      personsBytes: personsSize,
      databaseBytes: dbSize,
      snapshotCount: snapshotCount,
      videoCount: videoCount,
      personCount: personCount,
      eventCount: eventCount,
    );
  }

  /// Get size of a directory in bytes
  Future<int> _getDirectorySize(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  /// Count files in a directory
  Future<int> _countFiles(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;

    int count = 0;
    await for (final entity in dir.list()) {
      if (entity is File) count++;
    }
    return count;
  }

  /// Auto-delete events older than [days] days
  Future<int> autoDeleteOldEvents(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final allEvents = await DatabaseHelper.instance.readAll(limit: 10000);

    int deleted = 0;
    for (final event in allEvents) {
      if (event.timestamp.isBefore(cutoff)) {
        await _deleteEvent(event);
        deleted++;
      }
    }

    return deleted;
  }

  /// Clear all snapshots
  Future<int> clearAllSnapshots() async {
    final appDir = await getApplicationDocumentsDirectory();
    final snapshotsDir = Directory('${appDir.path}/snapshots');

    if (!await snapshotsDir.exists()) return 0;

    int deleted = 0;
    await for (final entity in snapshotsDir.list()) {
      if (entity is File) {
        await entity.delete();
        deleted++;
      }
    }
    return deleted;
  }

  /// Clear all videos
  Future<int> clearAllVideos() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videosDir = Directory('${appDir.path}/videos');

    if (!await videosDir.exists()) return 0;

    int deleted = 0;
    await for (final entity in videosDir.list()) {
      if (entity is File) {
        await entity.delete();
        deleted++;
      }
    }
    return deleted;
  }

  /// Delete a single event including its snapshot file
  Future<void> deleteEvent(MovementEvent event) async {
    await _deleteEvent(event);
  }

  Future<void> _deleteEvent(MovementEvent event) async {
    // Delete snapshot file
    final snapshotFile = File(event.snapshotPath);
    if (await snapshotFile.exists()) {
      await snapshotFile.delete();
    }

    // Delete video file if exists
    if (event.videoPath != null) {
      final videoFile = File(event.videoPath!);
      if (await videoFile.exists()) {
        await videoFile.delete();
      }
    }

    // Delete from database
    if (event.id != null) {
      await DatabaseHelper.instance.delete(event.id!);
    }
  }

  /// Format bytes to human-readable string
  static String formatBytes(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Storage usage information
class StorageInfo {
  final int totalBytes;
  final int snapshotsBytes;
  final int videosBytes;
  final int personsBytes;
  final int databaseBytes;
  final int snapshotCount;
  final int videoCount;
  final int personCount;
  final int eventCount;

  const StorageInfo({
    required this.totalBytes,
    required this.snapshotsBytes,
    required this.videosBytes,
    required this.personsBytes,
    required this.databaseBytes,
    required this.snapshotCount,
    required this.videoCount,
    required this.personCount,
    required this.eventCount,
  });

  String get totalFormatted => StorageService.formatBytes(totalBytes);
  String get snapshotsFormatted => StorageService.formatBytes(snapshotsBytes);
  String get videosFormatted => StorageService.formatBytes(videosBytes);
  String get personsFormatted => StorageService.formatBytes(personsBytes);
  String get databaseFormatted => StorageService.formatBytes(databaseBytes);
}
