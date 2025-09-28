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
  }) : _path = path;

  factory PlatformFile.fromMap(Map data, {Stream<List<int>>? readStream}) {
    return PlatformFile(
      name: data['name'],
      path: data['path'],
      bytes: data['bytes'],
      size: data['size'],
      identifier: data['identifier'],
      readStream: readStream,
      isWeb: data['isWeb'] ?? false,
    );
  }

  bool isWeb = false;

  /// The absolute path for a cached copy of this file. It can be used to create a
  /// file instance with a descriptor for the given path.
  /// ```
  /// final File myFile = File(platformFile.path);
  /// ```
  /// On web this is always `null`. You should access `bytes` property instead.
  /// Read more about it [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
  String? _path;

  String? get path {
    if (isWeb) {
      /// https://github.com/miguelpruivo/flutter_file_picker/issues/751
      throw '''
      On web `path` is always `null`,
      You should access `bytes` property instead,
      Read more about it [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
      ''';
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

  /// File extension for this file.
  String? get extension => name.split('.').last;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PlatformFile &&
        (isWeb || other.path == path) &&
        other.name == name &&
        other.bytes == bytes &&
        other.readStream == readStream &&
        other.identifier == identifier &&
        other.size == size;
  }

  @override
  int get hashCode {
    return isWeb
        ? 0
        : path.hashCode ^
            name.hashCode ^
            bytes.hashCode ^
            readStream.hashCode ^
            identifier.hashCode ^
            size.hashCode;
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
    // Ensure target directory exists
    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);

    // Strategy 1: Use file path if available (most efficient for non-web)
    if (!isWeb && _path != null) {
      final sourceFile = File(_path!);
      if (await sourceFile.exists()) {
        return await sourceFile.copy(targetPath);
      }
    }

    // Strategy 2: Use bytes if available
    if (bytes != null) {
      await targetFile.writeAsBytes(bytes!);
      return targetFile;
    }

    // Strategy 3: Use readStream if available
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

    // No valid data source available
    throw StateError('Cannot copy file: no valid data source available. '
        'File must have either a valid path (non-web), bytes, or readStream.');
  }

  /// Checks if the file exists.
  ///
  /// The exists method checks file existence based on available data:
  /// - If [path] is available and not web: checks if the file exists at the given path
  /// - If [bytes] is available: returns true (data exists in memory)
  /// - If [readStream] is available: returns true (stream data exists)
  /// - If none are available: returns false
  ///
  /// Returns a [Future<bool>] indicating whether the file exists.
  Future<bool> exists() async {
    // Strategy 1: Check file path if available (most reliable for non-web)
    if (!isWeb && _path != null) {
      final file = File(_path!);
      return await file.exists();
    }

    // Strategy 2: Check if bytes are available
    if (bytes != null) {
      return true; // Data exists in memory
    }

    // Strategy 3: Check if readStream is available
    if (readStream != null) {
      return true; // Stream data exists
    }

    // No valid data source available
    return false;
  }

  @override
  String toString() {
    return 'PlatformFile(${isWeb ? '' : 'path $path'}, name: $name, bytes: $bytes, readStream: $readStream, size: $size)';
  }
}
