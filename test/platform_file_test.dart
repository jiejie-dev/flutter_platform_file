import 'package:flutter_test/flutter_test.dart';

import 'package:platform_file/platform_file.dart';

void main() {
  test('create new file', () {
    final file = PlatformFile(name: "test", size: 0);
    expect(file.name, "test");
    expect(file.size, 0);
  });
}
