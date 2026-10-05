import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'fluid_type_role.dart';

/// Line-height anchors shared by every port. See `spec/line-height.tsv`.
const double _looseAt = 16;
const double _tightAt = 48;
const double _loose = 1.5;
const double _tight = 1.1;

/// A viewport-driven type scale.
///
/// The root size interpolates linearly from [minRootSize] to [maxRootSize] as
/// the viewport grows from [minWidth] to [maxWidth], and holds flat outside
/// that range. Every other size in the scale is derived from the root by
/// powers of [ratio], which is what makes a single number — the viewport
/// width — move an entire type hierarchy in step.
///
/// A scale is immutable and cheap to construct, so it is fine to build one in
/// a `build` method, though hoisting it to a `static const` reads better:
///
/// ```dart
/// const scale = FluidTypeScale(
///   minWidth: 400,
///   maxWidth: 800,
///   minRootSize: 12,
///   maxRootSize: 24,
/// );
///
/// final body = scale.sizeOf(FluidTypeRole.body, width);
/// ```
@immutable
class FluidTypeScale {
  /// Creates a scale.
  ///
  /// [minWidth] must not exceed [maxWidth], and both root sizes must be
  /// finite and positive. A scale where `minWidth == maxWidth` is permitted
  /// and behaves as a single hard breakpoint.
  const FluidTypeScale({
    required this.minWidth,
    required this.maxWidth,
    required this.minRootSize,
    required this.maxRootSize,
    this.ratio = 1.2,
  })  : assert(
          minWidth <= maxWidth,
          'minWidth ($minWidth) must be <= maxWidth ($maxWidth)',
        ),
        assert(
          minRootSize > 0 && maxRootSize > 0,
          'root sizes must be positive',
        ),
        assert(ratio > 0, 'ratio must be positive');

  /// The viewport width at or below which the root size stays at
  /// [minRootSize], in logical pixels.
  final double minWidth;

  /// The viewport width at or above which the root size stays at
  /// [maxRootSize], in logical pixels.
  final double maxWidth;

  /// The root size at [minWidth], in logical pixels.
  final double minRootSize;

  /// The root size at [maxWidth], in logical pixels.
  final double maxRootSize;

  /// The geometric ratio between adjacent steps of the scale.
  ///
  /// 1.2 (a major second) is the default because it stays readable on a phone;
  /// 1.25 and 1.333 open up nicely on larger screens but turn `h1` into a
  /// billboard at 360dp.
  final double ratio;

  /// The scale from the original SCSS: 400–800px viewport, 12–24px root.
  ///
  /// Useful as a starting point and as the scale the conformance fixtures in
  /// `spec/` are generated from.
  static const FluidTypeScale reference = FluidTypeScale(
    minWidth: 400,
    maxWidth: 800,
    minRootSize: 12,
    maxRootSize: 24,
  );

  /// A scale tuned for phone-to-tablet layouts: 360–768dp, 14–18dp root.
  static const FluidTypeScale mobile = FluidTypeScale(
    minWidth: 360,
    maxWidth: 768,
    minRootSize: 14,
    maxRootSize: 18,
  );

  /// The root size for [width], clamped at both ends.
  ///
  /// The upper plateau is tested first on purpose: when [minWidth] equals
  /// [maxWidth] the scale degenerates to a single breakpoint, and this
  /// ordering makes it step up to [maxRootSize] there rather than down. It
  /// also guarantees the division below never sees a zero denominator.
  double rootSizeFor(double width) {
    if (width >= maxWidth) return maxRootSize;
    if (width <= minWidth) return minRootSize;
    final t = (width - minWidth) / (maxWidth - minWidth);
    return minRootSize + (maxRootSize - minRootSize) * t;
  }

  /// [multiplier] times the root size for [width] — the direct analogue of a
  /// CSS `rem` value.
  double rem(double multiplier, double width) =>
      rootSizeFor(width) * multiplier;

  /// The size at [step] on the modular scale, for [width].
  ///
  /// Step 0 is the root size; positive steps grow by [ratio], negative steps
  /// shrink by it. Steps need not be whole numbers.
  double sizeForStep(num step, double width) =>
      rootSizeFor(width) * math.pow(ratio, step);

  /// The size for a semantic [role], for [width].
  double sizeOf(FluidTypeRole role, double width) =>
      sizeForStep(role.step, width);

  /// A line-height multiplier for [fontSize].
  ///
  /// Leading that works for body copy is too airy for a display heading, so
  /// this tightens from 1.5 to 1.1 as type grows from 16 to 48 logical pixels.
  /// Multiply by the font size to get a line height in pixels, or hand it
  /// straight to `TextStyle.height`, which already expects a multiplier.
  double lineHeightFor(double fontSize) {
    final t = ((fontSize - _looseAt) / (_tightAt - _looseAt)).clamp(0.0, 1.0);
    return _loose + (_tight - _loose) * t;
  }

  /// Resolves this scale against a single [width].
  ///
  /// The result caches the root size, which is the only part of the
  /// computation that depends on the viewport, so a widget tree that asks for
  /// a dozen sizes does the interpolation once.
  FluidType resolve(double width) => FluidType(scale: this, width: width);

  /// A copy of this scale with the given fields replaced.
  FluidTypeScale copyWith({
    double? minWidth,
    double? maxWidth,
    double? minRootSize,
    double? maxRootSize,
    double? ratio,
  }) {
    return FluidTypeScale(
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minRootSize: minRootSize ?? this.minRootSize,
      maxRootSize: maxRootSize ?? this.maxRootSize,
      ratio: ratio ?? this.ratio,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FluidTypeScale &&
      other.minWidth == minWidth &&
      other.maxWidth == maxWidth &&
      other.minRootSize == minRootSize &&
      other.maxRootSize == maxRootSize &&
      other.ratio == ratio;

  @override
  int get hashCode =>
      Object.hash(minWidth, maxWidth, minRootSize, maxRootSize, ratio);

  @override
  String toString() => 'FluidTypeScale($minWidth..$maxWidth px -> '
      '$minRootSize..$maxRootSize px, ratio $ratio)';
}

/// A [FluidTypeScale] resolved against one viewport width.
///
/// This is what widgets actually read. `FluidTypeScope` puts one in the tree
/// and rebuilds it when the viewport changes, so `context.fluidType` is a
/// lookup rather than a calculation.
@immutable
class FluidType {
  /// Resolves [scale] at [width].
  FluidType({required this.scale, required this.width})
      : rootSize = scale.rootSizeFor(width);

  /// The scale this was resolved from.
  final FluidTypeScale scale;

  /// The viewport width it was resolved at, in logical pixels.
  final double width;

  /// The root size at [width] — the `1rem` of this scale.
  final double rootSize;

  /// [multiplier] rem, in logical pixels.
  double rem(double multiplier) => rootSize * multiplier;

  /// The size at [step] on the modular scale.
  double sizeForStep(num step) => rootSize * math.pow(scale.ratio, step);

  /// The size for a semantic [role].
  double sizeOf(FluidTypeRole role) => sizeForStep(role.step);

  /// A line-height multiplier for [fontSize]; see
  /// [FluidTypeScale.lineHeightFor].
  double lineHeightFor(double fontSize) => scale.lineHeightFor(fontSize);

  /// Shorthand for the [FluidTypeRole.body] size.
  double get body => sizeOf(FluidTypeRole.body);

  @override
  bool operator ==(Object other) =>
      other is FluidType && other.scale == scale && other.width == width;

  @override
  int get hashCode => Object.hash(scale, width);

  @override
  String toString() =>
      'FluidType(width: $width, rootSize: ${rootSize.toStringAsFixed(2)})';
}
