import 'package:flutter_test/flutter_test.dart';
import 'package:ai_survilance/services/storage_service.dart';

void main() {
  group('StorageService', () {
    group('formatBytes', () {
      test('should format bytes correctly', () {
        expect(StorageService.formatBytes(0), '0 B');
        expect(StorageService.formatBytes(500), '500 B');
        expect(StorageService.formatBytes(1023), '1023 B');
      });

      test('should format kilobytes correctly', () {
        expect(StorageService.formatBytes(1024), '1.0 KB');
        expect(StorageService.formatBytes(1536), '1.5 KB');
        expect(StorageService.formatBytes(10240), '10.0 KB');
        expect(StorageService.formatBytes(102399), '100.0 KB');
      });

      test('should format megabytes correctly', () {
        expect(StorageService.formatBytes(1048576), '1.0 MB');
        expect(StorageService.formatBytes(1572864), '1.5 MB');
        expect(StorageService.formatBytes(10485760), '10.0 MB');
        expect(StorageService.formatBytes(104857600), '100.0 MB');
      });

      test('should format gigabytes correctly', () {
        expect(StorageService.formatBytes(1073741824), '1.00 GB');
        expect(StorageService.formatBytes(2147483648), '2.00 GB');
      });

      test('should handle negative values', () {
        expect(StorageService.formatBytes(-1), '0 B');
        expect(StorageService.formatBytes(-100), '0 B');
      });
    });

    group('StorageInfo', () {
      test('should create StorageInfo with correct values', () {
        const info = StorageInfo(
          totalBytes: 1048576,
          snapshotsBytes: 524288,
          videosBytes: 262144,
          personsBytes: 131072,
          databaseBytes: 131072,
          snapshotCount: 100,
          videoCount: 10,
          personCount: 5,
          eventCount: 100,
        );

        expect(info.totalBytes, 1048576);
        expect(info.totalFormatted, '1.0 MB');
        expect(info.snapshotsFormatted, '512.0 KB');
        expect(info.snapshotCount, 100);
        expect(info.videoCount, 10);
        expect(info.personCount, 5);
        expect(info.eventCount, 100);
      });

      test('should format all size properties', () {
        const info = StorageInfo(
          totalBytes: 2147483648,
          snapshotsBytes: 1048576,
          videosBytes: 524288,
          personsBytes: 1024,
          databaseBytes: 512,
          snapshotCount: 0,
          videoCount: 0,
          personCount: 0,
          eventCount: 0,
        );

        expect(info.totalFormatted, '2.00 GB');
        expect(info.snapshotsFormatted, '1.0 MB');
        expect(info.videosFormatted, '512.0 KB');
        expect(info.personsFormatted, '1.0 KB');
        expect(info.databaseFormatted, '512 B');
      });
    });
  });
}
