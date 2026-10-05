package dev.fluidtype

import kotlin.math.pow

/** Line-height anchors shared by every port. See `spec/line-height.tsv`. */
private const val LOOSE_AT = 16.0
private const val TIGHT_AT = 48.0
private const val LOOSE = 1.5
private const val TIGHT = 1.1

/**
 * A viewport-driven type scale.
 *
 * The root size interpolates linearly from [minRootSize] to [maxRootSize] as
 * the container grows from [minWidth] to [maxWidth], and holds flat outside
 * that range. Every other size is derived from the root by powers of [ratio],
 * which is what makes a single number — the container width — move an entire
 * type hierarchy in step.
 *
 * Sizes are plain [Double] density-independent pixels rather than `Dp` or
 * `TextUnit`, which keeps this class usable from unit tests, shared Kotlin
 * Multiplatform code and anything that is not Compose. The `compose` package
 * wraps it for Compose, where the dp-versus-sp distinction actually matters.
 *
 * Doubles rather than floats, incidentally, because the conformance fixtures
 * in `spec/` are checked to within 1e-9 and a float cannot hold that.
 *
 * ```kotlin
 * val scale = FluidTypeScale(
 *     minWidth = 360.0, maxWidth = 1024.0,
 *     minRootSize = 15.0, maxRootSize = 22.0,
 * )
 * val body = scale.sizeOf(FluidTypeRole.Body, width = 768.0)
 * ```
 *
 * @property minWidth width at or below which the root size stays at [minRootSize].
 * @property maxWidth width at or above which the root size stays at [maxRootSize].
 * @property minRootSize the root size at [minWidth].
 * @property maxRootSize the root size at [maxWidth].
 * @property ratio the geometric ratio between adjacent steps. 1.2 (a major
 *   second) stays readable on a phone; 1.25 and 1.333 open up nicely on larger
 *   screens but turn [FluidTypeRole.H1] into a billboard at 360dp.
 */
public data class FluidTypeScale(
    public val minWidth: Double,
    public val maxWidth: Double,
    public val minRootSize: Double,
    public val maxRootSize: Double,
    public val ratio: Double = 1.2,
) {
    init {
        require(minWidth.isFinite() && maxWidth.isFinite()) {
            "minWidth and maxWidth must be finite, got $minWidth and $maxWidth"
        }
        require(minWidth <= maxWidth) {
            "minWidth ($minWidth) must be <= maxWidth ($maxWidth)"
        }
        require(minRootSize > 0 && maxRootSize > 0) {
            "root sizes must be positive, got $minRootSize and $maxRootSize"
        }
        require(ratio > 0) { "ratio must be positive, got $ratio" }
    }

    /**
     * The root size for [width], clamped at both ends.
     *
     * The upper plateau is tested first on purpose: when [minWidth] equals
     * [maxWidth] the scale degenerates to a single breakpoint, and this
     * ordering makes it step up to [maxRootSize] there rather than down. It
     * also guarantees the division below never sees a zero denominator.
     */
    public fun rootSizeAt(width: Double): Double {
        if (width >= maxWidth) return maxRootSize
        if (width <= minWidth) return minRootSize
        val t = (width - minWidth) / (maxWidth - minWidth)
        return minRootSize + (maxRootSize - minRootSize) * t
    }

    /**
     * [multiplier] times the root size at [width] — the direct analogue of a
     * CSS `rem`. Handy for padding and spacing, not just type.
     */
    public fun rem(multiplier: Double, width: Double): Double =
        rootSizeAt(width) * multiplier

    /**
     * The size at [step] on the modular scale, at [width].
     *
     * Step 0 is the root size; positive steps grow by [ratio], negative steps
     * shrink by it. Steps need not be whole numbers.
     */
    public fun sizeAtStep(step: Double, width: Double): Double =
        rootSizeAt(width) * ratio.pow(step)

    /** The size for a semantic [role], at [width]. */
    public fun sizeOf(role: FluidTypeRole, width: Double): Double =
        sizeAtStep(role.step.toDouble(), width)

    /**
     * A line-height *multiplier* for [fontSize].
     *
     * Leading that works for body copy is too airy for a display heading, so
     * this tightens from 1.5 to 1.1 as type grows from 16 to 48dp. Compose's
     * `TextStyle.lineHeight` wants an absolute [androidx.compose.ui.unit.TextUnit],
     * not a multiplier, so let the `compose` package do that arithmetic.
     */
    public fun lineHeightFor(fontSize: Double): Double {
        val t = ((fontSize - LOOSE_AT) / (TIGHT_AT - LOOSE_AT)).coerceIn(0.0, 1.0)
        return LOOSE + (TIGHT - LOOSE) * t
    }

    /**
     * Resolves this scale against a single [width].
     *
     * The result caches the root size, which is the only part of the
     * computation that depends on the container, so a screen that asks for a
     * dozen sizes does the interpolation once.
     */
    public fun resolvedAt(width: Double): FluidType = FluidType(this, width)

    public companion object {
        /**
         * The scale from the original SCSS: 400–800dp wide, 12–24dp root.
         *
         * Useful as a starting point, and the scale the conformance fixtures
         * in `spec/` are generated from.
         */
        public val Reference: FluidTypeScale = FluidTypeScale(
            minWidth = 400.0,
            maxWidth = 800.0,
            minRootSize = 12.0,
            maxRootSize = 24.0,
        )

        /** A scale tuned for phone-to-tablet layouts: 360–768dp, 14–18dp root. */
        public val Mobile: FluidTypeScale = FluidTypeScale(
            minWidth = 360.0,
            maxWidth = 768.0,
            minRootSize = 14.0,
            maxRootSize = 18.0,
        )
    }
}

/**
 * A [FluidTypeScale] resolved against one container width.
 *
 * This is what UI code reads. `FluidTypeProvider` puts one in a
 * `CompositionLocal` and updates it when the container resizes, so
 * `LocalFluidType.current` is a lookup rather than a calculation.
 */
public class FluidType(
    public val scale: FluidTypeScale,
    public val width: Double,
) {
    /** The root size at [width] — the `1rem` of this scale. */
    public val rootSize: Double = scale.rootSizeAt(width)

    /** [multiplier] rem. */
    public fun rem(multiplier: Double): Double = rootSize * multiplier

    /** The size at [step] on the modular scale. */
    public fun sizeAtStep(step: Double): Double = rootSize * scale.ratio.pow(step)

    /** The size for a semantic [role]. */
    public fun sizeOf(role: FluidTypeRole): Double = sizeAtStep(role.step.toDouble())

    /** A line-height multiplier for [fontSize]; see [FluidTypeScale.lineHeightFor]. */
    public fun lineHeightFor(fontSize: Double): Double = scale.lineHeightFor(fontSize)

    /** The [FluidTypeRole.Body] size. */
    public val body: Double get() = sizeOf(FluidTypeRole.Body)

    /** The absolute line height for [role], ready to become a `TextUnit`. */
    public fun lineHeightOf(role: FluidTypeRole): Double {
        val fontSize = sizeOf(role)
        return fontSize * lineHeightFor(fontSize)
    }

    override fun equals(other: Any?): Boolean =
        this === other ||
            (other is FluidType && other.scale == scale && other.width == width)

    override fun hashCode(): Int = 31 * scale.hashCode() + width.hashCode()

    override fun toString(): String = "FluidType(width=$width, rootSize=$rootSize)"
}
