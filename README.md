
# platform_file

[![Pub Version (including pre-releases)](https://img.shields.io/pub/v/platform_file?include_prereleases)](https://pub.flutter-io.cn/packages/platform_file) [![GitHub license](https://img.shields.io/github/license/jeremaihloo/platform_file)](https://github.com/jeremaihloo/platform_file/blob/master/LICENSE) [![GitHub stars](https://img.shields.io/github/stars/jeremaihloo/platform_file?style=social)](https://github.com/jeremaihloo/platform_file/stargazers)

An abstraction to allow working with files across multiple platforms.

Copied from https://github.com/miguelpruivo/flutter_file_picker/blob/master/lib/src/platform_file.dart

## Usage

```dart
PlatformFile({
    String? path,
    required this.name,
    required this.size,
    this.bytes,
    this.readStream,
    this.identifier,
  }) : _path = path;

  factory PlatformFile.fromMap(Map data, {Stream<List<int>>? readStream}) {
    return PlatformFile(
      name: data['name'],
      path: data['path'],
      bytes: data['bytes'],
      size: data['size'],
      identifier: data['identifier'],
      readStream: readStream,
    );
  }
```
