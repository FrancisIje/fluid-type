/// Semantic positions on a modular type scale.
///
/// Roles exist so that application code says what a piece of text *is* rather
/// than how big it is. Changing [FluidTypeScale.ratio] then reshapes the whole
/// hierarchy without touching a single widget.
///
/// The steps mirror the CSS classes in `css/fluid-type.scss`, and the same
/// enum appears in the React Native, Compose and SwiftUI ports.
enum FluidTypeRole {
  /// Two steps below the root. Timestamps, footnotes, image credits.
  caption(-2),

  /// One step below the root. Secondary copy, helper text under a field.
  small(-1),

  /// The root size itself. Body copy, and the size everything else is
  /// measured against.
  body(0),

  /// One step above the root.
  h6(1),

  /// Two steps above the root.
  h5(2),

  /// Three steps above the root.
  h4(3),

  /// Four steps above the root.
  h3(4),

  /// Five steps above the root.
  h2(5),

  /// Six steps above the root. Page titles and display type.
  h1(6);

  const FluidTypeRole(this.step);

  /// This role's position on the scale, in steps from the root.
  final int step;
}
