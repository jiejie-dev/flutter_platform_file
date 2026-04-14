import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:platform_file/platform_file.dart';

void main() {
  // =========================================================================
  // Constructor
  // =========================================================================
  group('Constructor', () {
    test('creates with path', () {
      final file = PlatformFile(path: '/tmp/a.txt', name: 'a.txt', size: 10);
      expect(file.name, 'a.txt');
      expect(file.size, 10);
      expect(file.path, '/tmp/a.txt');
      expect(file.isWeb, isFalse);
      expect(file.bytes, isNull);
      expect(file.readStream, isNull);
      expect(file.identifier, isNull);
    });

    test('creates with bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final file = PlatformFile(name: 'b.bin', size: 3, bytes: bytes);
      expect(file.bytes, bytes);
    });

    test('creates with readStream', () {
      final stream = Stream<List<int>>.fromIterable([
        [1, 2]
      ]);
      final file =
          PlatformFile(name: 'c.bin', size: 2, readStream: stream);
      expect(file.readStream, isNotNull);
    });

    test('creates web file with bytes', () {
      final bytes = Uint8List(0);
      final file =
          PlatformFile(name: 'web.txt', size: 0, bytes: bytes, isWeb: true);
      expect(file.isWeb, isTrue);
    });

    test('assert fails when all data sources are null', () {
      expect(
        () => PlatformFile(name: 'empty.txt', size: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('isWeb is final and immutable', () {
      final file =
          PlatformFile(name: 'f.txt', size: 0, bytes: Uint8List(0));
      expect(file.isWeb, isFalse);
    });
  });

  // =========================================================================
  // fromMap factory
  // =========================================================================
  group('fromMap', () {
    test('creates from valid map with path', () {
      final file = PlatformFile.fromMap({
        'name': 'test.txt',
        'path': '/tmp/test.txt',
        'size': 42,
        'identifier': 'uri://file',
        'isWeb': false,
      });
      expect(file.name, 'test.txt');
      expect(file.path, '/tmp/test.txt');
      expect(file.size, 42);
      expect(file.identifier, 'uri://file');
      expect(file.isWeb, isFalse);
    });

    test('creates from valid map with bytes', () {
      final bytes = Uint8List.fromList([10, 20]);
      final file = PlatformFile.fromMap({
        'name': 'b.bin',
        'size': 2,
        'bytes': bytes,
      });
      expect(file.bytes, bytes);
    });

    test('creates from valid map with readStream', () {
      final stream = Stream<List<int>>.fromIterable([
        [0]
      ]);
      final file = PlatformFile.fromMap(
        {'name': 's.bin', 'size': 1, 'path': '/p'},
        readStream: stream,
      );
      expect(file.readStream, stream);
    });

    test('defaults isWeb to false when missing', () {
      final file = PlatformFile.fromMap({
        'name': 'f.txt',
        'size': 0,
        'path': '/p',
      });
      expect(file.isWeb, isFalse);
    });

    test('throws ArgumentError when name is null', () {
      expect(
        () => PlatformFile.fromMap({'size': 0, 'path': '/p'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when name is not String', () {
      expect(
        () => PlatformFile.fromMap({'name': 123, 'size': 0, 'path': '/p'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when size is null', () {
      expect(
        () => PlatformFile.fromMap({'name': 'f.txt', 'path': '/p'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when size is not int', () {
      expect(
        () => PlatformFile.fromMap(
            {'name': 'f.txt', 'size': '10', 'path': '/p'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when bytes is wrong type', () {
      expect(
        () => PlatformFile.fromMap({
          'name': 'f.txt',
          'size': 0,
          'bytes': 'not bytes',
          'path': '/p',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // =========================================================================
  // path getter
  // =========================================================================
  group('path getter', () {
    test('returns path for non-web file', () {
      final file =
          PlatformFile(path: '/tmp/f.txt', name: 'f.txt', size: 0);
      expect(file.path, '/tmp/f.txt');
    });

    test('returns null when path not provided for non-web file', () {
      final file =
          PlatformFile(name: 'f.txt', size: 3, bytes: Uint8List(3));
      expect(file.path, isNull);
    });

    test('throws UnsupportedError for web file', () {
      final file = PlatformFile(
          name: 'f.txt', size: 0, bytes: Uint8List(0), isWeb: true);
      expect(() => file.path, throwsA(isA<UnsupportedError>()));
    });
  });

  // =========================================================================
  // extension getter
  // =========================================================================
  group('extension getter', () {
    test('returns extension for normal filename', () {
      final file =
          PlatformFile(path: '/p/a.txt', name: 'a.txt', size: 0);
      expect(file.extension, 'txt');
    });

    test('returns last extension for multi-dot filename', () {
      final file =
          PlatformFile(path: '/p/a.tar.gz', name: 'a.tar.gz', size: 0);
      expect(file.extension, 'gz');
    });

    test('returns null for filename without extension', () {
      final file =
          PlatformFile(path: '/p/README', name: 'README', size: 0);
      expect(file.extension, isNull);
    });

    test('returns null for dot-only hidden file', () {
      final file =
          PlatformFile(path: '/p/.gitignore', name: '.gitignore', size: 0);
      expect(file.extension, isNull);
    });

    test('returns extension for hidden file with extension', () {
      final file = PlatformFile(
          path: '/p/.config.json', name: '.config.json', size: 0);
      expect(file.extension, 'json');
    });

    test('returns null for empty name', () {
      final file =
          PlatformFile(path: '/p', name: '', size: 0);
      expect(file.extension, isNull);
    });
  });

  // =========================================================================
  // operator == and hashCode
  // =========================================================================
  group('equality and hashCode', () {
    test('identical objects are equal', () {
      final file =
          PlatformFile(path: '/p/a.txt', name: 'a.txt', size: 10);
      expect(file == file, isTrue);
    });

    test('equal non-web files', () {
      final a = PlatformFile(path: '/p/a.txt', name: 'a.txt', size: 10);
      final b = PlatformFile(path: '/p/a.txt', name: 'a.txt', size: 10);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('different path means not equal', () {
      final a = PlatformFile(path: '/p/a.txt', name: 'a.txt', size: 10);
      final b = PlatformFile(path: '/p/b.txt', name: 'a.txt', size: 10);
      expect(a == b, isFalse);
    });

    test('different name means not equal', () {
      final a = PlatformFile(path: '/p/a.txt', name: 'a.txt', size: 10);
      final b = PlatformFile(path: '/p/a.txt', name: 'b.txt', size: 10);
      expect(a == b, isFalse);
    });

    test('different size means not equal', () {
      final a = PlatformFile(path: '/p/a.txt', name: 'a.txt', size: 10);
      final b = PlatformFile(path: '/p/a.txt', name: 'a.txt', size: 20);
      expect(a == b, isFalse);
    });

    test('different bytes means not equal', () {
      final a = PlatformFile(
          name: 'a.txt', size: 1, bytes: Uint8List.fromList([1]));
      final b = PlatformFile(
          name: 'a.txt', size: 1, bytes: Uint8List.fromList([2]));
      expect(a == b, isFalse);
    });

    test('different identifier means not equal', () {
      final a = PlatformFile(
          path: '/p', name: 'a.txt', size: 0, identifier: 'id1');
      final b = PlatformFile(
          path: '/p', name: 'a.txt', size: 0, identifier: 'id2');
      expect(a == b, isFalse);
    });

    test('different readStream means not equal', () {
      final s1 = Stream<List<int>>.fromIterable([]);
      final s2 = Stream<List<int>>.fromIterable([]);
      final a = PlatformFile(name: 'a.txt', size: 0, readStream: s1);
      final b = PlatformFile(name: 'a.txt', size: 0, readStream: s2);
      expect(a == b, isFalse);
    });

    test('equal web files', () {
      final bytes = Uint8List(0);
      final a = PlatformFile(
          name: 'a.txt', size: 0, bytes: bytes, isWeb: true);
      final b = PlatformFile(
          name: 'a.txt', size: 0, bytes: bytes, isWeb: true);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('web files with different bytes have different hashCodes', () {
      final a = PlatformFile(
          name: 'a.txt',
          size: 1,
          bytes: Uint8List.fromList([1]),
          isWeb: true);
      final b = PlatformFile(
          name: 'a.txt',
          size: 1,
          bytes: Uint8List.fromList([2]),
          isWeb: true);
      expect(a == b, isFalse);
    });

    test('symmetry: web vs non-web are not equal', () {
      final bytes = Uint8List(0);
      final web = PlatformFile(
          name: 'a.txt', size: 0, bytes: bytes, isWeb: true);
      final native = PlatformFile(
          name: 'a.txt', size: 0, bytes: bytes, isWeb: false);
      expect(web == native, isFalse);
      expect(native == web, isFalse);
    });

    test('not equal to non-PlatformFile object', () {
      final file =
          PlatformFile(path: '/p', name: 'a.txt', size: 0);
      expect(file == Object(), isFalse);
    });
  });

  // =========================================================================
  // copy method
  // =========================================================================
  group('copy', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pf_copy_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('copies via file path', () async {
      final source = File('${tempDir.path}/src.txt');
      await source.writeAsString('hello');

      final pf = PlatformFile(
          path: source.path, name: 'src.txt', size: 5);
      final target = '${tempDir.path}/dst.txt';
      final copied = await pf.copy(target);

      expect(await copied.exists(), isTrue);
      expect(await copied.readAsString(), 'hello');
    });

    test('falls through to bytes when path file missing', () async {
      final pf = PlatformFile(
        path: '${tempDir.path}/nonexistent.txt',
        name: 'ne.txt',
        size: 3,
        bytes: Uint8List.fromList([65, 66, 67]),
      );
      final target = '${tempDir.path}/dst.txt';
      final copied = await pf.copy(target);

      expect(await copied.readAsString(), 'ABC');
    });

    test('copies via bytes', () async {
      final bytes = Uint8List.fromList('bytes data'.codeUnits);
      final pf = PlatformFile(name: 'b.txt', size: bytes.length, bytes: bytes);

      final target = '${tempDir.path}/b_dst.txt';
      final copied = await pf.copy(target);

      expect(await copied.readAsString(), 'bytes data');
    });

    test('copies via readStream', () async {
      final data = Uint8List.fromList('stream data'.codeUnits);
      final stream = Stream<List<int>>.fromIterable([data]);

      final pf = PlatformFile(
          name: 's.txt', size: data.length, readStream: stream);
      final target = '${tempDir.path}/s_dst.txt';
      final copied = await pf.copy(target);

      expect(await copied.readAsString(), 'stream data');
    });

    test('copies web file via bytes', () async {
      final bytes = Uint8List.fromList('web'.codeUnits);
      final pf = PlatformFile(
          name: 'w.txt', size: 3, bytes: bytes, isWeb: true);

      final target = '${tempDir.path}/w_dst.txt';
      final copied = await pf.copy(target);

      expect(await copied.readAsString(), 'web');
    });

    test('creates nested target directories', () async {
      final bytes = Uint8List.fromList([1]);
      final pf = PlatformFile(name: 'd.bin', size: 1, bytes: bytes);

      final target = '${tempDir.path}/a/b/c/d.bin';
      await pf.copy(target);

      expect(await Directory('${tempDir.path}/a/b/c').exists(), isTrue);
    });

    test('prioritizes path over bytes', () async {
      final source = File('${tempDir.path}/pri.txt');
      await source.writeAsString('from path');

      final pf = PlatformFile(
        path: source.path,
        name: 'pri.txt',
        size: 9,
        bytes: Uint8List.fromList('from bytes'.codeUnits),
      );

      final target = '${tempDir.path}/pri_dst.txt';
      final copied = await pf.copy(target);

      expect(await copied.readAsString(), 'from path');
    });

    test('prioritizes bytes over readStream', () async {
      final bytes = Uint8List.fromList('from bytes'.codeUnits);
      final stream = Stream<List<int>>.fromIterable(
          [Uint8List.fromList('from stream'.codeUnits)]);

      final pf = PlatformFile(
        name: 'pri2.txt',
        size: bytes.length,
        bytes: bytes,
        readStream: stream,
      );

      final target = '${tempDir.path}/pri2_dst.txt';
      final copied = await pf.copy(target);

      expect(await copied.readAsString(), 'from bytes');
    });

    test('copies via readStream with multiple chunks', () async {
      final chunk1 = Uint8List.fromList('chunk1-'.codeUnits);
      final chunk2 = Uint8List.fromList('chunk2'.codeUnits);
      final stream = Stream<List<int>>.fromIterable([chunk1, chunk2]);

      final pf = PlatformFile(
        name: 'multi.txt',
        size: chunk1.length + chunk2.length,
        readStream: stream,
      );

      final target = '${tempDir.path}/multi_dst.txt';
      final copied = await pf.copy(target);

      expect(await copied.readAsString(), 'chunk1-chunk2');
    });
  });

  // =========================================================================
  // exists method
  // =========================================================================
  group('exists', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pf_exists_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns true for existing file path', () async {
      final f = File('${tempDir.path}/exists.txt');
      await f.writeAsString('hi');

      final pf = PlatformFile(path: f.path, name: 'exists.txt', size: 2);
      expect(await pf.exists(), isTrue);
    });

    test('returns false for non-existent file path without fallback', () async {
      final pf = PlatformFile(
        path: '${tempDir.path}/nope.txt',
        name: 'nope.txt',
        size: 0,
      );
      expect(await pf.exists(), isFalse);
    });

    test('falls through to bytes when path file missing', () async {
      final pf = PlatformFile(
        path: '${tempDir.path}/missing.txt',
        name: 'missing.txt',
        size: 3,
        bytes: Uint8List(3),
      );
      expect(await pf.exists(), isTrue);
    });

    test('falls through to readStream when path file missing and no bytes',
        () async {
      final stream = Stream<List<int>>.fromIterable([
        [1]
      ]);
      final pf = PlatformFile(
        path: '${tempDir.path}/missing2.txt',
        name: 'missing2.txt',
        size: 1,
        readStream: stream,
      );
      expect(await pf.exists(), isTrue);
    });

    test('returns true for bytes-only file', () async {
      final pf =
          PlatformFile(name: 'mem.txt', size: 1, bytes: Uint8List(1));
      expect(await pf.exists(), isTrue);
    });

    test('returns true for stream-only file', () async {
      final stream = Stream<List<int>>.fromIterable([
        [1]
      ]);
      final pf =
          PlatformFile(name: 'stream.txt', size: 1, readStream: stream);
      expect(await pf.exists(), isTrue);
    });

    test('returns true for web file with bytes', () async {
      final pf = PlatformFile(
          name: 'web.txt', size: 0, bytes: Uint8List(0), isWeb: true);
      expect(await pf.exists(), isTrue);
    });

    test('returns false after source file is deleted', () async {
      final f = File('${tempDir.path}/del.txt');
      await f.writeAsString('data');

      final pf = PlatformFile(path: f.path, name: 'del.txt', size: 4);
      expect(await pf.exists(), isTrue);

      await f.delete();
      expect(await pf.exists(), isFalse);
    });

    test('consistency: exists and copy agree when path deleted but has bytes',
        () async {
      final f = File('${tempDir.path}/consist.txt');
      await f.writeAsString('data');

      final pf = PlatformFile(
        path: f.path,
        name: 'consist.txt',
        size: 4,
        bytes: Uint8List.fromList('data'.codeUnits),
      );

      await f.delete();

      expect(await pf.exists(), isTrue);
      final copied = await pf.copy('${tempDir.path}/consist_dst.txt');
      expect(await copied.readAsString(), 'data');
    });
  });

  // =========================================================================
  // toString
  // =========================================================================
  group('toString', () {
    test('non-web file with path', () {
      final file =
          PlatformFile(path: '/tmp/a.txt', name: 'a.txt', size: 100);
      final str = file.toString();
      expect(str, contains('path: /tmp/a.txt'));
      expect(str, contains('name: a.txt'));
      expect(str, contains('size: 100'));
    });

    test('non-web file without path', () {
      final file = PlatformFile(
          name: 'a.txt', size: 3, bytes: Uint8List.fromList([1, 2, 3]));
      final str = file.toString();
      expect(str, contains('path: null'));
      expect(str, contains('3 bytes'));
    });

    test('web file', () {
      final file = PlatformFile(
          name: 'w.txt', size: 0, bytes: Uint8List(0), isWeb: true);
      final str = file.toString();
      expect(str, contains('web'));
      expect(str, isNot(contains('path:')));
    });

    test('file with readStream', () {
      final stream = Stream<List<int>>.fromIterable([]);
      final file =
          PlatformFile(name: 'r.txt', size: 0, readStream: stream);
      final str = file.toString();
      expect(str, contains('readStream: present'));
    });

    test('file without readStream', () {
      final file =
          PlatformFile(name: 'r.txt', size: 0, bytes: Uint8List(0));
      final str = file.toString();
      expect(str, contains('readStream: null'));
    });
  });
}
