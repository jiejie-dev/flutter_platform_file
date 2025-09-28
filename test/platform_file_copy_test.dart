import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:platform_file/platform_file.dart';

void main() {
  group('PlatformFile copy method tests', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('platform_file_test_');
    });

    tearDownAll(() async {
      await tempDir.delete(recursive: true);
    });

    test('copy with path (non-web)', () async {
      // Create a test file
      final sourceFile = File('${tempDir.path}/source.txt');
      const content = 'Hello, World!';
      await sourceFile.writeAsString(content);

      // Create PlatformFile with path
      final platformFile = PlatformFile(
        path: sourceFile.path,
        name: 'source.txt',
        size: content.length,
      );

      // Copy to target
      final targetPath = '${tempDir.path}/target.txt';
      final copiedFile = await platformFile.copy(targetPath);

      // Verify copy
      expect(await copiedFile.exists(), isTrue);
      expect(await copiedFile.readAsString(), equals(content));
    });

    test('copy with bytes', () async {
      const content = 'Test content for bytes copy';
      final bytes = Uint8List.fromList(content.codeUnits);

      // Create PlatformFile with bytes
      final platformFile = PlatformFile(
        name: 'bytes_file.txt',
        size: bytes.length,
        bytes: bytes,
      );

      // Copy to target
      final targetPath = '${tempDir.path}/bytes_target.txt';
      final copiedFile = await platformFile.copy(targetPath);

      // Verify copy
      expect(await copiedFile.exists(), isTrue);
      expect(await copiedFile.readAsString(), equals(content));
    });

    test('copy with readStream', () async {
      const content = 'Test content for stream copy';
      final bytes = Uint8List.fromList(content.codeUnits);
      final stream = Stream<List<int>>.fromIterable([bytes]);

      // Create PlatformFile with readStream
      final platformFile = PlatformFile(
        name: 'stream_file.txt',
        size: bytes.length,
        readStream: stream,
      );

      // Copy to target
      final targetPath = '${tempDir.path}/stream_target.txt';
      final copiedFile = await platformFile.copy(targetPath);

      // Verify copy
      expect(await copiedFile.exists(), isTrue);
      expect(await copiedFile.readAsString(), equals(content));
    });

    test('copy with web platform (no path)', () async {
      const content = 'Web platform test content';
      final bytes = Uint8List.fromList(content.codeUnits);

      // Create PlatformFile for web (isWeb = true)
      final platformFile = PlatformFile(
        name: 'web_file.txt',
        size: bytes.length,
        bytes: bytes,
        isWeb: true,
      );

      // Copy to target
      final targetPath = '${tempDir.path}/web_target.txt';
      final copiedFile = await platformFile.copy(targetPath);

      // Verify copy
      expect(await copiedFile.exists(), isTrue);
      expect(await copiedFile.readAsString(), equals(content));
    });

    test('copy creates target directory if not exists', () async {
      const content = 'Test directory creation';
      final bytes = Uint8List.fromList(content.codeUnits);

      final platformFile = PlatformFile(
        name: 'dir_test.txt',
        size: bytes.length,
        bytes: bytes,
      );

      // Copy to nested directory that doesn't exist
      final targetPath = '${tempDir.path}/nested/deep/target.txt';
      final copiedFile = await platformFile.copy(targetPath);

      // Verify copy and directory creation
      expect(await copiedFile.exists(), isTrue);
      expect(await copiedFile.readAsString(), equals(content));
      expect(await Directory('${tempDir.path}/nested/deep').exists(), isTrue);
    });

    test('copy throws StateError when no data source available', () async {
      // Create PlatformFile with no data source
      final platformFile = PlatformFile(
        name: 'empty_file.txt',
        size: 0,
      );

      // Attempt to copy should throw StateError
      expect(
        () => platformFile.copy('${tempDir.path}/should_fail.txt'),
        throwsA(isA<StateError>()),
      );
    });

    test('copy prioritizes path over bytes when both available', () async {
      // Create a test file
      final sourceFile = File('${tempDir.path}/priority_source.txt');
      const pathContent = 'Content from path';
      await sourceFile.writeAsString(pathContent);

      const bytesContent = 'Content from bytes';
      final bytes = Uint8List.fromList(bytesContent.codeUnits);

      // Create PlatformFile with both path and bytes
      final platformFile = PlatformFile(
        path: sourceFile.path,
        name: 'priority_file.txt',
        size: pathContent.length,
        bytes: bytes,
      );

      // Copy to target
      final targetPath = '${tempDir.path}/priority_target.txt';
      final copiedFile = await platformFile.copy(targetPath);

      // Should use path content (not bytes content)
      expect(await copiedFile.readAsString(), equals(pathContent));
    });

    test('copy prioritizes bytes over readStream when both available',
        () async {
      const bytesContent = 'Content from bytes';
      final bytes = Uint8List.fromList(bytesContent.codeUnits);

      const streamContent = 'Content from stream';
      final streamBytes = Uint8List.fromList(streamContent.codeUnits);
      final stream = Stream<List<int>>.fromIterable([streamBytes]);

      // Create PlatformFile with both bytes and readStream
      final platformFile = PlatformFile(
        name: 'priority_file2.txt',
        size: bytes.length,
        bytes: bytes,
        readStream: stream,
      );

      // Copy to target
      final targetPath = '${tempDir.path}/priority_target2.txt';
      final copiedFile = await platformFile.copy(targetPath);

      // Should use bytes content (not stream content)
      expect(await copiedFile.readAsString(), equals(bytesContent));
    });
  });
}
