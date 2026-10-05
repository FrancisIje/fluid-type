package dev.fluidtype.compose

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.fluidtype.FluidType
import dev.fluidtype.FluidTypeRole
import dev.fluidtype.FluidTypeScale

/**
 * The resolved scale for the current composition.
 *
 * Reading this without a [FluidTypeProvider] above it throws, because silently
 * falling back to a default scale produces type that is subtly wrong
 * everywhere and obviously wrong nowhere.
 */
public val LocalFluidType: ProvidableCompositionLocal<FluidType> =
    compositionLocalOf {
        error(
            "No FluidTypeProvider found. Wrap your content — or at least the " +
                "subtree that reads fluid type — in one:\n\n" +
                "  FluidTypeProvider(FluidTypeScale.Mobile) { /* content */ }",
        )
    }

/**
 * Resolves [scale] against the screen width and provides it to [content].
 *
 * Wrap your theme once:
 *
 * ```kotlin
 * FluidTypeProvider(FluidTypeScale.Mobile) {
 *     MaterialTheme(typography = fluidTypography()) { App() }
 * }
 * ```
 *
 * The width comes from `LocalConfiguration.screenWidthDp`, which is the window
 * rather than this composable's own slot. That is the right default on a phone
 * and the wrong one inside a split pane, so use [FluidTypeBox] when type
 * should respond to a container instead of the window.
 */
@Composable
public fun FluidTypeProvider(
    scale: FluidTypeScale = FluidTypeScale.Mobile,
    content: @Composable () -> Unit,
) {
    val widthDp = LocalConfiguration.current.screenWidthDp.toDouble()
    ProvideFluidType(scale, widthDp, content)
}

/**
 * Resolves [scale] against this composable's own width and provides it to
 * [content].
 *
 * Use it for a pane, a card or a resizable window — anywhere the window width
 * is not the width that should drive the type. It is built on
 * [BoxWithConstraints], so it participates in layout like a `Box` and will
 * subcompose its content.
 */
@Composable
public fun FluidTypeBox(
    scale: FluidTypeScale = FluidTypeScale.Mobile,
    content: @Composable () -> Unit,
) {
    BoxWithConstraints {
        ProvideFluidType(scale, maxWidth.value.toDouble(), content)
    }
}

/** Provides [scale] resolved at an explicit [width] in dp. */
@Composable
public fun ProvideFluidType(
    scale: FluidTypeScale,
    width: Double,
    content: @Composable () -> Unit,
) {
    val resolved = remember(scale, width) { scale.resolvedAt(width) }
    CompositionLocalProvider(LocalFluidType provides resolved, content = content)
}

/**
 * The font size for [role].
 *
 * Returned in `sp`, so the reader's system font-size setting still applies on
 * top of the fluid scale. That is usually what you want — ignoring the
 * accessibility setting to protect a layout is a regression dressed up as a
 * feature — but it does mean two scaling systems compose, and a reader at 200%
 * on a tablet will see very large type. [fontSizeIgnoringUserScale] opts out
 * where a layout genuinely cannot take it.
 */
public fun FluidType.fontSize(role: FluidTypeRole): TextUnit =
    sizeOf(role).toFloat().sp

/**
 * The font size for [role] in `sp` units that cancel out the user's font
 * scale, leaving only the fluid scale.
 *
 * Reach for this sparingly, and never for body copy.
 */
@Composable
public fun FluidType.fontSizeIgnoringUserScale(role: FluidTypeRole): TextUnit =
    with(LocalDensity.current) { sizeOf(role).toFloat().dp.toSp() }

/** The absolute line height for [role], for `TextStyle.lineHeight`. */
public fun FluidType.lineHeight(role: FluidTypeRole): TextUnit =
    lineHeightOf(role).toFloat().sp

/** [multiplier] rem as a [Dp] — for padding, gaps and corner radii. */
public fun FluidType.remDp(multiplier: Double): Dp = rem(multiplier).toFloat().dp

/**
 * A [TextStyle] for [role], with the size and line height from the scale.
 *
 * Pass [base] to keep a family, weight or colour and have only the metrics
 * come from the scale — the common case when you already have a design system
 * and want it to breathe with the window.
 */
public fun FluidType.textStyle(
    role: FluidTypeRole,
    base: TextStyle = TextStyle.Default,
): TextStyle = base.copy(fontSize = fontSize(role), lineHeight = lineHeight(role))
