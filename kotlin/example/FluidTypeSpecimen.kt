package dev.fluidtype.example

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import dev.fluidtype.FluidTypeRole
import dev.fluidtype.FluidTypeScale
import dev.fluidtype.compose.FluidTypeProvider
import dev.fluidtype.compose.LocalFluidType
import dev.fluidtype.compose.fluidTypography
import dev.fluidtype.compose.remDp
import dev.fluidtype.compose.textStyle

/**
 * A type specimen that responds to the window size.
 *
 * Rotate the device, or drag a split-screen divider, and every size on the
 * page moves together. The readout at the bottom prints the width and the root
 * size so the interpolation is visible rather than merely felt.
 *
 * This file is not part of the library module — drop it into an app and call
 * [FluidTypeSpecimen] from your activity.
 */

// 360->1024dp is a sensible phone-to-tablet range; 15->22dp keeps body copy
// comfortable at both ends.
private val SpecimenScale = FluidTypeScale(
    minWidth = 360.0,
    maxWidth = 1024.0,
    minRootSize = 15.0,
    maxRootSize = 22.0,
)

@Composable
public fun FluidTypeSpecimen() {
    var ratio by remember { mutableFloatStateOf(1.2f) }

    FluidTypeProvider(SpecimenScale.copy(ratio = ratio.toDouble())) {
        MaterialTheme(typography = fluidTypography(MaterialTheme.typography)) {
            val fluid = LocalFluidType.current
            Surface {
                Column(
                    modifier = Modifier
                        .verticalScroll(rememberScrollState())
                        .padding(fluid.remDp(1.5)),
                    verticalArrangement = Arrangement.spacedBy(fluid.remDp(0.4)),
                ) {
                    Text("Fluid type", style = MaterialTheme.typography.displaySmall)
                    Text(
                        "One number drives the hierarchy. Rotate the device.",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )

                    HorizontalDivider(Modifier.padding(vertical = fluid.remDp(0.5)))

                    for (role in FluidTypeRole.entries.reversed()) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(fluid.remDp(0.5)),
                            verticalAlignment = Alignment.Bottom,
                        ) {
                            Text(
                                text = role.name.uppercase(),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.outline,
                                modifier = Modifier.width(fluid.remDp(3.5)),
                            )
                            Text(
                                text = "Grumpy wizards make toxic brew",
                                style = fluid.textStyle(role),
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f),
                            )
                            Text(
                                text = "%.1fdp".format(fluid.sizeOf(role)),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.outline,
                            )
                        }
                    }

                    Text(
                        text = "Ratio %.3f".format(ratio),
                        style = MaterialTheme.typography.labelLarge,
                        modifier = Modifier.padding(top = fluid.remDp(1)),
                    )
                    Slider(
                        value = ratio,
                        onValueChange = { ratio = it },
                        valueRange = 1.05f..1.4f,
                    )

                    Text(
                        text = "viewport %.0fdp  ->  root %.2fdp  (clamped %.0f-%.0fdp)".format(
                            fluid.width,
                            fluid.rootSize,
                            fluid.scale.minWidth,
                            fluid.scale.maxWidth,
                        ),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}

@Preview(widthDp = 360)
@Preview(widthDp = 768)
@Composable
private fun SpecimenPreview() {
    FluidTypeSpecimen()
}
