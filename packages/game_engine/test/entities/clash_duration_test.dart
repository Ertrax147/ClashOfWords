import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('ClashDuration', () {
    test('one lasts a single clash', () {
      expect(ClashDuration.one.clashes, 1);
      expect(ClashDuration.one.isInfinite, isFalse);
      expect(ClashDuration(1), ClashDuration.one);
    });

    test('infinite has no clash count', () {
      expect(ClashDuration.infinite.isInfinite, isTrue);
      expect(ClashDuration.infinite.clashes, isNull);
    });

    test('a duration shorter than one clash is rejected', () {
      expect(() => ClashDuration(0), throwsArgumentError);
      expect(() => ClashDuration(-2), throwsArgumentError);
    });

    test('compares finite durations by clash count', () {
      expect(ClashDuration(4).isLongerThan(ClashDuration(2)), isTrue);
      expect(ClashDuration(2).isLongerThan(ClashDuration(4)), isFalse);
      expect(ClashDuration(3).isLongerThan(ClashDuration(3)), isFalse);
    });

    test('infinite is longer than any finite duration', () {
      expect(ClashDuration.infinite.isLongerThan(ClashDuration(99)), isTrue);
      expect(ClashDuration(99).isLongerThan(ClashDuration.infinite), isFalse);
      expect(
        ClashDuration.infinite.isLongerThan(ClashDuration.infinite),
        isFalse,
      );
    });

    test('max keeps the longer duration', () {
      // Unicorn Queen (4) con Diamond Sword (2) conserva 4.
      expect(ClashDuration(4).max(ClashDuration(2)), ClashDuration(4));
      expect(ClashDuration(2).max(ClashDuration(4)), ClashDuration(4));
      // Gift of Eternity otorga una Duration infinita.
      expect(
        ClashDuration.one.max(ClashDuration.infinite),
        ClashDuration.infinite,
      );
    });
  });
}
