import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('the engine does not depend on Flutter (RNF-09)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, isNot(contains('flutter')));
  });
}
