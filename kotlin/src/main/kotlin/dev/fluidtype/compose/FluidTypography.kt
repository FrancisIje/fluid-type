package dev.fluidtype.compose

import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.TextStyle
import dev.fluidtype.FluidType
import dev.fluidtype.FluidTypeRole

/**
 * A Material 3 [Typography] with every slot driven by the resolved scale.
 *
 * Material's fifteen slots are mapped onto the nine roles in the obvious way:
 * the display slots take [FluidTypeRole.H1] down to [FluidTypeRole.H3],
 * headlines continue down the scale, and the label slots sit at or below the
 * root.
 *
 * ```kotlin
 * FluidTypeProvider {
 *     MaterialTheme(typography = fluidTypography(MaterialTheme.typography)) {
 *         App()
 *     }
 * }
 * ```
 *
 * Pass [base] to inherit families, weights and letter spacing and override
 * only sizes and line heights.
 */
@Composable
public fun fluidTypography(base: Typography = Typography()): Typography {
    val fluid = LocalFluidType.current
    fun slot(role: FluidTypeRole, from: TextStyle): TextStyle =
        fluid.textStyle(role, from)

    return Typography(
        displayLarge = slot(FluidTypeRole.H1, base.displayLarge),
        displayMedium = slot(FluidTypeRole.H2, base.displayMedium),
        displaySmall = slot(FluidTypeRole.H3, base.displaySmall),
        headlineLarge = slot(FluidTypeRole.H3, base.headlineLarge),
        headlineMedium = slot(FluidTypeRole.H4, base.headlineMedium),
        headlineSmall = slot(FluidTypeRole.H5, base.headlineSmall),
        titleLarge = slot(FluidTypeRole.H5, base.titleLarge),
        titleMedium = slot(FluidTypeRole.H6, base.titleMedium),
        titleSmall = slot(FluidTypeRole.Body, base.titleSmall),
        bodyLarge = slot(FluidTypeRole.H6, base.bodyLarge),
        bodyMedium = slot(FluidTypeRole.Body, base.bodyMedium),
        bodySmall = slot(FluidTypeRole.Small, base.bodySmall),
        labelLarge = slot(FluidTypeRole.Body, base.labelLarge),
        labelMedium = slot(FluidTypeRole.Small, base.labelMedium),
        labelSmall = slot(FluidTypeRole.Caption, base.labelSmall),
    )
}

/** Shorthand for `LocalFluidType.current`. */
public val fluidType: FluidType
    @Composable get() = LocalFluidType.current
