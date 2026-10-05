import 'package:flutter_test/flutter_test.dart';
import 'package:fluid_type/fluid_type.dart';

void main() {
  const scale = FluidTypeScale.reference;

  group('rootSizeFor', () {
    test('holds at minRootSize below and at minWidth', () {
      expect(scale.rootSizeFor(0), 12);
      expect(scale.rootSizeFor(320), 12);
      expect(scale.rootSizeFor(400), 12);
    });

    test('holds at maxRootSize at and above maxWidth', () {
      expect(scale.rootSizeFor(800), 24);
      expect(scale.rootSizeFor(1280), 24);
      expect(scale.rootSizeFor(double.maxFinite), 24);
    });

    test('interpolates linearly in between', () {
      expect(scale.rootSizeFor(500), closeTo(15, 1e-12));
      expect(scale.rootSizeFor(600), closeTo(18, 1e-12));
      expect(scale.rootSizeFor(700), closeTo(21, 1e-12));
    });

    test('is continuous at the breakpoints', () {
      expect(scale.rootSizeFor(400.0001), closeTo(12, 1e-5));
      expect(scale.rootSizeFor(799.9999), closeTo(24, 1e-5));
    });

    test('is monotonically non-decreasing', () {
      var previous = double.negativeInfinity;
      for (var w = 0.0; w <= 1200; w += 0.5) {
        final size = scale.rootSizeFor(w);
        expect(size, greaterThanOrEqualTo(previous));
        previous = size;
      }
    });

    test('a zero-width range behaves as a hard breakpoint', () {
      const step = FluidTypeScale(
        minWidth: 600,
        maxWidth: 600,
        minRootSize: 12,
        maxRootSize: 24,
      );
      expect(step.rootSizeFor(599), 12);
      expect(step.rootSizeFor(600), 24);
      expect(step.rootSizeFor(601), 24);
    });

    test('a descending scale shrinks type as the viewport grows', () {
      // Unusual but legal: some designs want tighter type on wide screens.
      const descending = FluidTypeScale(
        minWidth: 400,
        maxWidth: 800,
        minRootSize: 20,
        maxRootSize: 16,
      );
      expect(descending.rootSizeFor(400), 20);
      expect(descending.rootSizeFor(600), closeTo(18, 1e-12));
      expect(descending.rootSizeFor(800), 16);
    });
  });

  group('the modular scale', () {
    test('step 0 is the root size', () {
      expect(scale.sizeForStep(0, 600), closeTo(18, 1e-12));
    });

    test('each step multiplies by the ratio', () {
      final root = scale.rootSizeFor(600);
      expect(scale.sizeForStep(1, 600), closeTo(root * 1.2, 1e-12));
      expect(scale.sizeForStep(2, 600), closeTo(root * 1.2 * 1.2, 1e-12));
      expect(scale.sizeForStep(-1, 600), closeTo(root / 1.2, 1e-12));
    });

    test('accepts fractional steps', () {
      final half = scale.sizeForStep(0.5, 600);
      expect(half, greaterThan(scale.sizeForStep(0, 600)));
      expect(half, lessThan(scale.sizeForStep(1, 600)));
    });

    test('roles sit where the spec says they do', () {
      expect(FluidTypeRole.caption.step, -2);
      expect(FluidTypeRole.small.step, -1);
      expect(FluidTypeRole.body.step, 0);
      expect(FluidTypeRole.h1.step, 6);
      expect(
        scale.sizeOf(FluidTypeRole.h1, 600),
        closeTo(scale.sizeForStep(6, 600), 1e-12),
      );
    });

    test('roles are ordered smallest to largest', () {
      final sizes =
          FluidTypeRole.values.map((role) => scale.sizeOf(role, 600)).toList();
      for (var i = 1; i < sizes.length; i++) {
        expect(sizes[i], greaterThan(sizes[i - 1]));
      }
    });

    test('rem matches a step of the same multiplier', () {
      expect(scale.rem(2, 600), closeTo(36, 1e-12));
      expect(scale.rem(0.5, 800), closeTo(12, 1e-12));
    });
  });

  group('lineHeightFor', () {
    test('is loose for small type and tight for display type', () {
      expect(scale.lineHeightFor(8), closeTo(1.5, 1e-12));
      expect(scale.lineHeightFor(16), closeTo(1.5, 1e-12));
      expect(scale.lineHeightFor(48), closeTo(1.1, 1e-12));
      expect(scale.lineHeightFor(96), closeTo(1.1, 1e-12));
    });

    test('tightens monotonically in between', () {
      var previous = double.infinity;
      for (var size = 16.0; size <= 48; size += 0.25) {
        final height = scale.lineHeightFor(size);
        expect(height, lessThanOrEqualTo(previous));
        previous = height;
      }
    });

    test('is the midpoint at the midpoint', () {
      expect(scale.lineHeightFor(32), closeTo(1.3, 1e-12));
    });
  });

  group('resolve', () {
    test('caches the root size for one width', () {
      final resolved = scale.resolve(600);
      expect(resolved.rootSize, closeTo(18, 1e-12));
      expect(resolved.width, 600);
      expect(resolved.body, closeTo(18, 1e-12));
    });

    test('agrees with the unresolved scale', () {
      final resolved = scale.resolve(537);
      for (final role in FluidTypeRole.values) {
        expect(resolved.sizeOf(role), closeTo(scale.sizeOf(role, 537), 1e-12));
      }
      expect(resolved.rem(3), closeTo(scale.rem(3, 537), 1e-12));
      expect(resolved.lineHeightFor(20), scale.lineHeightFor(20));
    });
  });

  group('value semantics', () {
    test('equal scales compare and hash equal', () {
      const a = FluidTypeScale(
        minWidth: 400,
        maxWidth: 800,
        minRootSize: 12,
        maxRootSize: 24,
      );
      expect(a, FluidTypeScale.reference);
      expect(a.hashCode, FluidTypeScale.reference.hashCode);
    });

    test('a different ratio is a different scale', () {
      expect(
        FluidTypeScale.reference.copyWith(ratio: 1.25),
        isNot(FluidTypeScale.reference),
      );
    });

    test('resolved values differ by width', () {
      expect(scale.resolve(600), isNot(scale.resolve(601)));
      expect(scale.resolve(600), scale.resolve(600));
    });

    test('copyWith replaces only what it is given', () {
      final wider = scale.copyWith(maxWidth: 1200);
      expect(wider.maxWidth, 1200);
      expect(wider.minWidth, scale.minWidth);
      expect(wider.ratio, scale.ratio);
    });

    test('toString is readable', () {
      expect(FluidTypeScale.reference.toString(), contains('400.0..800.0'));
    });
  });

  group('assertions', () {
    test('rejects an inverted viewport range', () {
      expect(
        () => FluidTypeScale(
          minWidth: 800,
          maxWidth: 400,
          minRootSize: 12,
          maxRootSize: 24,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a non-positive root size', () {
      expect(
        () => FluidTypeScale(
          minWidth: 400,
          maxWidth: 800,
          minRootSize: 0,
          maxRootSize: 24,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a non-positive ratio', () {
      expect(
        () => FluidTypeScale(
          minWidth: 400,
          maxWidth: 800,
          minRootSize: 12,
          maxRootSize: 24,
          ratio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
