import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluid_type/fluid_type.dart';

void main() {
  /// Pumps [child] inside a scope at a given logical window width.
  Future<void> pumpAtWidth(
    WidgetTester tester,
    double width,
    Widget child, {
    FluidTypeScale scale = FluidTypeScale.reference,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FluidTypeScope(scale: scale, child: child),
        ),
      ),
    );
  }

  testWidgets('resolves against the ambient media query', (tester) async {
    late FluidType seen;
    await pumpAtWidth(
      tester,
      600,
      Builder(
        builder: (context) {
          seen = context.fluidType;
          return const SizedBox();
        },
      ),
    );
    expect(seen.width, 600);
    expect(seen.rootSize, closeTo(18, 1e-12));
  });

  testWidgets('an explicit width wins over the media query', (tester) async {
    late FluidType seen;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1200, 800)),
        child: FluidTypeScope(
          scale: FluidTypeScale.reference,
          width: 500,
          child: Builder(
            builder: (context) {
              seen = context.fluidType;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(seen.width, 500);
    expect(seen.rootSize, closeTo(15, 1e-12));
  });

  testWidgets('rebuilds dependents when the viewport changes', (tester) async {
    var builds = 0;
    final sizes = <double>[];

    // One widget instance, reused across pumps, so the only thing that can
    // trigger a rebuild is the inherited scale changing.
    final subject = Builder(
      builder: (context) {
        builds++;
        sizes.add(context.fluidType.rootSize);
        return const SizedBox();
      },
    );

    await pumpAtWidth(tester, 400, subject);
    expect(builds, 1);
    expect(sizes.last, 12);

    await pumpAtWidth(tester, 800, subject);
    expect(builds, 2);
    expect(sizes.last, 24);
  });

  testWidgets('does not rebuild dependents when the width is unchanged',
      (tester) async {
    var builds = 0;
    final subject = Builder(
      builder: (context) {
        builds++;
        context.fluidType;
        return const SizedBox();
      },
    );

    await pumpAtWidth(tester, 640, subject);
    expect(builds, 1);

    // The scope rebuilds and hands down a new _FluidTypeInherited, but the
    // FluidType inside it is equal, so updateShouldNotify returns false.
    await pumpAtWidth(tester, 640, subject);
    expect(builds, 1, reason: 'equal FluidType should not notify dependents');
  });

  testWidgets('maybeFluidType is null without a scope', (tester) async {
    FluidType? seen = FluidTypeScale.reference.resolve(1);
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = context.maybeFluidType;
          return const SizedBox();
        },
      ),
    );
    expect(seen, isNull);
  });

  testWidgets('fluidType throws a helpful error without a scope',
      (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          context.fluidType;
          return const SizedBox();
        },
      ),
    );
    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(error.toString(), contains('No FluidTypeScope found'));
  });

  testWidgets('style() carries size and line height', (tester) async {
    late TextStyle style;
    await pumpAtWidth(
      tester,
      800,
      Builder(
        builder: (context) {
          style = context.fluidType.style(FluidTypeRole.body);
          return const SizedBox();
        },
      ),
    );
    expect(style.fontSize, 24);
    expect(style.height, closeTo(1.4, 1e-12));
  });

  testWidgets('style() keeps the base family and weight', (tester) async {
    late TextStyle style;
    await pumpAtWidth(
      tester,
      800,
      Builder(
        builder: (context) {
          style = context.fluidType.style(
            FluidTypeRole.h2,
            base: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 99,
            ),
          );
          return const SizedBox();
        },
      ),
    );
    expect(style.fontFamily, 'Inter');
    expect(style.fontWeight, FontWeight.w700);
    expect(style.fontSize, closeTo(24 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2, 1e-12));
  });

  testWidgets('textTheme fills every slot and inherits the base',
      (tester) async {
    late TextTheme theme;
    await pumpAtWidth(
      tester,
      600,
      Builder(
        builder: (context) {
          theme = context.fluidType.textTheme(
            base: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Inter'),
            ),
          );
          return const SizedBox();
        },
      ),
    );
    expect(theme.bodyMedium!.fontFamily, 'Inter');
    expect(theme.bodyMedium!.fontSize, closeTo(18, 1e-12));
    expect(
      theme.displayLarge!.fontSize,
      greaterThan(theme.bodyMedium!.fontSize!),
    );
    expect(theme.labelSmall!.fontSize, lessThan(theme.bodyMedium!.fontSize!));
    for (final style in [
      theme.displayLarge,
      theme.displayMedium,
      theme.displaySmall,
      theme.headlineLarge,
      theme.headlineMedium,
      theme.headlineSmall,
      theme.titleLarge,
      theme.titleMedium,
      theme.titleSmall,
      theme.bodyLarge,
      theme.bodyMedium,
      theme.bodySmall,
      theme.labelLarge,
      theme.labelMedium,
      theme.labelSmall,
    ]) {
      expect(style?.fontSize, isNotNull);
      expect(style?.height, isNotNull);
    }
  });

  testWidgets('text actually renders larger on a wider viewport',
      (tester) async {
    Widget subject() => Builder(
          builder: (context) => Text(
            'Fluid',
            style: context.fluidType.style(FluidTypeRole.h1),
          ),
        );

    await pumpAtWidth(tester, 400, Center(child: subject()));
    final narrow = tester.getSize(find.text('Fluid'));

    await pumpAtWidth(tester, 800, Center(child: subject()));
    final wide = tester.getSize(find.text('Fluid'));

    expect(wide.width, greaterThan(narrow.width));
    expect(wide.height, greaterThan(narrow.height));
  });
}
