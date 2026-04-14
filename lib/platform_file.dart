library platform_file;

/// copied from https://github.com/miguelpruivo/flutter_file_picker/blob/master/lib/src/platform_file.dart
import 'dart:async';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'dart:io';

class PlatformFile {
  PlatformFile({
    String? path,
    required this.name,
    required this.size,
    this.bytes,
    this.readStream,
    this.identifier,
    this.isWeb = false,
  })  : _path = path,
        assert(
          path != null || bytes != null || readStream != null,
          'At least one data source (path, bytes, or readStream) must be provided.',
        );

  factory PlatformFile.fromMap(Map<String, dynamic> data,
      {Stream<List<int>>? readStream}) {
    final name = data['name'];
    final size = data['size'];

    if (name is! String) {
      throw ArgumentError.value(name, 'name', 'must be a non-null String');
    }
    if (size is! int) {
      throw ArgumentError.value(size, 'size', 'must be a non-null int');
    }

    final bytes = data['bytes'];
    if (bytes != null && bytes is! Uint8List) {
      throw ArgumentError.value(bytes, 'bytes', 'must be a Uint8List or null');
    }

    return PlatformFile(
      name: name,
      path: data['path'] as String?,
      bytes: bytes as Uint8List?,
      size: size,
      identifier: data['identifier'] as String?,
      readStream: readStream,
      isWeb: (data['isWeb'] as bool?) ?? false,
    );
  }

  final bool isWeb;

  /// The absolute path for a cached copy of this file. It can be used to create a
  /// file instance with a descriptor for the given path.
  /// ```
  /// final File myFile = File(platformFile.path);
  /// ```
  /// On web this is always `null`. You should access `bytes` property instead.
  /// Read more about it [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
  final String? _path;

  String? get path {
    if (isWeb) {
      /// https://github.com/miguelpruivo/flutter_file_picker/issues/751
      throw UnsupportedError(
        'On web `path` is always `null`. '
        'You should access `bytes` property instead. '
        'Read more about it: https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ',
      );
    }
    return _path;
  }

  /// File name including its extension.
  final String name;

  /// Byte data for this file. Particularly useful if you want to manipulate its data
  /// or easily upload to somewhere else.
  /// [Check here in the FAQ](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ) an example on how to use it to upload on web.
  final Uint8List? bytes;

  /// File content as stream
  ///
  /// Note: A regular [Stream] can only be listened to once. If you call [copy]
  /// using the stream strategy, subsequent calls will fail. Consider providing
  /// [bytes] instead if you need to read the data multiple times.
  final Stream<List<int>>? readStream;

  /// The file size in bytes. Defaults to `0` if the file size could not be
  /// determined.
  final int size;

  /// The platform identifier for the original file, refers to an [Uri](https://developer.android.com/reference/android/net/Uri) on Android and
  /// to a [NSURL](https://developer.apple.com/documentation/foundation/nsurl) on iOS.
  /// Is set to `null` on all other platforms since those are all already referencing the original file content.
  ///
  /// Note: You can't use this to create a Dart `File` instance since this is a safe-reference for the original platform files, for
  /// that the [path] property should be used instead.
  final String? identifier;

  /// File extension for this file, or `null` if the file has no extension.
  String? get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0) return null;
    return name.substring(dotIndex + 1);
  }

  bool get _hasPath => !isWeb && _path != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PlatformFile) return false;

    if (isWeb != other.isWeb) return false;

    if (!isWeb && _path != other._path) return false;

    return other.name == name &&
        other.bytes == bytes &&
        other.readStream == readStream &&
        other.identifier == identifier &&
        other.size == size;
  }

  @override
  int get hashCode {
    return Object.hash(
      isWeb,
      isWeb ? null : _path,
      name,
      bytes,
      readStream,
      identifier,
      size,
    );
  }

  /// Copies this file to the specified target path.
  ///
  /// The copy method intelligently chooses the best copying strategy based on available data:
  /// - If [path] is available and not web: uses File.copy() for efficient file system copy
  /// - If [bytes] is available: writes bytes directly to target file
  /// - If [readStream] is available: streams data to target file
  /// - If none are available: throws StateError
  ///
  /// Returns a [Future<File>] representing the copied file.
  ///
  /// Throws:
  /// - [StateError] if no valid data source is available
  /// - [FileSystemException] if the copy operation fails
  Future<File> copy(String targetPath) async {
    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);

    if (_hasPath) {
      final sourceFile = File(_path!);
      if (await sourceFile.exists()) {
        return await sourceFile.copy(targetPath);
      }
    }

    if (bytes != null) {
      await targetFile.writeAsBytes(bytes!);
      return targetFile;
    }

    if (readStream != null) {
      final sink = targetFile.openWrite();
      try {
        await for (final chunk in readStream!) {
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      return targetFile;
    }

    throw StateError('Cannot copy file: no valid data source available. '
        'File must have either a valid path (non-web), bytes, or readStream.');
  }

  /// Checks if the file has accessible data.
  ///
  /// - If [path] is available and not web: checks if the file exists at the given path;
  ///   if not, falls through to check [bytes] and [readStream].
  /// - If [bytes] is available: returns true (data exists in memory)
  /// - If [readStream] is available: returns true (stream data exists)
  /// - If none are available: returns false
  Future<bool> exists() async {
    if (_hasPath) {
      final file = File(_path!);
      if (await file.exists()) return true;
    }

    if (bytes != null) return true;

    if (readStream != null) return true;

    return false;
  }

  @override
  String toString() {
    final pathPart = isWeb ? 'web' : 'path: $_path';
    return 'PlatformFile($pathPart, name: $name, bytes: ${bytes != null ? '${bytes!.length} bytes' : 'null'}, readStream: ${readStream != null ? 'present' : 'null'}, size: $size)';
  }
}
