/// Semantic positions on a modular type scale.
///
/// Roles exist so that application code says what a piece of text *is* rather
/// than how big it is. Changing ``FluidTypeScale/ratio`` then reshapes the
/// whole hierarchy without touching a single view.
///
/// The raw value is the role's step from the root, which is why the cases are
/// declared from smallest to largest: `allCases` is then in visual order. The
/// same nine roles, at the same steps, appear in the Flutter, React Native and
/// Compose ports and in `css/fluid-type.scss`.
public enum FluidTypeRole: Int, CaseIterable, Sendable, Hashable {
    /// Two steps below the root. Timestamps, footnotes, image credits.
    case caption = -2
    /// One step below the root. Secondary copy, helper text under a field.
    case small = -1
    /// The root size itself, and the size everything else is measured against.
    case body = 0
    /// One step above the root.
    case h6 = 1
    /// Two steps above the root.
    case h5 = 2
    /// Three steps above the root.
    case h4 = 3
    /// Four steps above the root.
    case h3 = 4
    /// Five steps above the root.
    case h2 = 5
    /// Six steps above the root. Page titles and display type.
    case h1 = 6

    /// This role's position on the scale, in steps from the root.
    public var step: Int { rawValue }
}
