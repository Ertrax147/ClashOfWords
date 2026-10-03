import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('CardClass', () {
    test('two classes with the same name are equal', () {
      expect(CardClass('Wild'), CardClass('Wild'));
      expect({CardClass('Wild'), CardClass('Wild')}, hasLength(1));
    });

    test('classes with different names are not equal', () {
      expect(CardClass('Wild'), isNot(CardClass('Smart')));
    });

    test('surrounding spaces are removed from the name', () {
      expect(CardClass('  Cosmic ').name, 'Cosmic');
      expect(CardClass(' Cosmic'), CardClass('Cosmic'));
    });

    test('an empty name is rejected', () {
      expect(() => CardClass(''), throwsArgumentError);
      expect(() => CardClass('   '), throwsArgumentError);
    });
  });
}
