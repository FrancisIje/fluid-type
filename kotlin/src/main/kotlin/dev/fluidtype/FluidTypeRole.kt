package dev.fluidtype

/**
 * Semantic positions on a modular type scale.
 *
 * Roles exist so that application code says what a piece of text *is* rather
 * than how big it is. Changing [FluidTypeScale.ratio] then reshapes the whole
 * hierarchy without touching a single composable.
 *
 * The cases are declared smallest to largest, so `entries` is in visual order.
 * The same nine roles, at the same steps, appear in the Flutter, React Native
 * and SwiftUI ports and in `css/fluid-type.scss`.
 *
 * @property step this role's position on the scale, in steps from the root.
 */
public enum class FluidTypeRole(public val step: Int) {
    /** Two steps below the root. Timestamps, footnotes, image credits. */
    Caption(-2),

    /** One step below the root. Secondary copy, helper text under a field. */
    Small(-1),

    /** The root size itself, and the size everything else is measured against. */
    Body(0),

    /** One step above the root. */
    H6(1),

    /** Two steps above the root. */
    H5(2),

    /** Three steps above the root. */
    H4(3),

    /** Four steps above the root. */
    H3(4),

    /** Five steps above the root. */
    H2(5),

    /** Six steps above the root. Page titles and display type. */
    H1(6),
}
