package dev.fluidtype

import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

/** Asserts [actual] is within [tolerance] of [expected]. */
internal fun assertNear(
    expected: Double,
    actual: Double,
    tolerance: Double = 1e-12,
    what: String = "",
) {
    assertTrue(
        kotlin.math.abs(actual - expected) <= tolerance,
        "$what expected $expected, got $actual (tolerance $tolerance)",
    )
}

class FluidTypeScaleTest {
    private val scale = FluidTypeScale.Reference

    @Nested
    inner class RootSize {
        @Test
        fun `holds at minRootSize below and at minWidth`() {
            assertEquals(12.0, scale.rootSizeAt(0.0))
            assertEquals(12.0, scale.rootSizeAt(320.0))
            assertEquals(12.0, scale.rootSizeAt(400.0))
        }

        @Test
        fun `holds at maxRootSize at and above maxWidth`() {
            assertEquals(24.0, scale.rootSizeAt(800.0))
            assertEquals(24.0, scale.rootSizeAt(1280.0))
            assertEquals(24.0, scale.rootSizeAt(Double.MAX_VALUE))
        }

        @Test
        fun `interpolates linearly in between`() {
            assertNear(15.0, scale.rootSizeAt(500.0))
            assertNear(18.0, scale.rootSizeAt(600.0))
            assertNear(21.0, scale.rootSizeAt(700.0))
        }

        @Test
        fun `is continuous at the breakpoints`() {
            assertNear(12.0, scale.rootSizeAt(400.0001), 1e-5)
            assertNear(24.0, scale.rootSizeAt(799.9999), 1e-5)
        }

        @Test
        fun `is monotonically non-decreasing`() {
            var previous = Double.NEGATIVE_INFINITY
            var width = 0.0
            while (width <= 1200) {
                val size = scale.rootSizeAt(width)
                assertTrue(size >= previous, "dipped at width $width")
                previous = size
                width += 0.5
            }
        }

        @Test
        fun `a zero-width range is a hard breakpoint`() {
            val step = FluidTypeScale(
                minWidth = 600.0,
                maxWidth = 600.0,
                minRootSize = 12.0,
                maxRootSize = 24.0,
            )
            assertEquals(12.0, step.rootSizeAt(599.0))
            assertEquals(24.0, step.rootSizeAt(600.0))
            assertEquals(24.0, step.rootSizeAt(601.0))
            assertFalse(step.rootSizeAt(600.0).isNaN())
        }

        @Test
        fun `a descending scale shrinks type as the container grows`() {
            // Unusual but legal: some designs want tighter type on wide screens.
            val descending = FluidTypeScale(
                minWidth = 400.0,
                maxWidth = 800.0,
                minRootSize = 20.0,
                maxRootSize = 16.0,
            )
            assertEquals(20.0, descending.rootSizeAt(400.0))
            assertNear(18.0, descending.rootSizeAt(600.0))
            assertEquals(16.0, descending.rootSizeAt(800.0))
        }
    }

    @Nested
    inner class Validation {
        @Test
        fun `rejects an inverted viewport range`() {
            assertThrows<IllegalArgumentException> {
                FluidTypeScale(
                    minWidth = 800.0,
                    maxWidth = 400.0,
                    minRootSize = 12.0,
                    maxRootSize = 24.0,
                )
            }
        }

        @Test
        fun `rejects a non-positive root size`() {
            assertThrows<IllegalArgumentException> {
                FluidTypeScale(
                    minWidth = 400.0,
                    maxWidth = 800.0,
                    minRootSize = 0.0,
                    maxRootSize = 24.0,
                )
            }
            assertThrows<IllegalArgumentException> {
                FluidTypeScale(
                    minWidth = 400.0,
                    maxWidth = 800.0,
                    minRootSize = 12.0,
                    maxRootSize = -24.0,
                )
            }
        }

        @Test
        fun `rejects a non-positive ratio`() {
            assertThrows<IllegalArgumentException> {
                FluidTypeScale(
                    minWidth = 400.0,
                    maxWidth = 800.0,
                    minRootSize = 12.0,
                    maxRootSize = 24.0,
                    ratio = 0.0,
                )
            }
        }

        @Test
        fun `rejects a non-finite width`() {
            assertThrows<IllegalArgumentException> {
                FluidTypeScale(
                    minWidth = Double.NaN,
                    maxWidth = 800.0,
                    minRootSize = 12.0,
                    maxRootSize = 24.0,
                )
            }
        }

        @Test
        fun `defaults the ratio to a major second`() {
            assertEquals(
                1.2,
                FluidTypeScale(
                    minWidth = 400.0,
                    maxWidth = 800.0,
                    minRootSize = 12.0,
                    maxRootSize = 24.0,
                ).ratio,
            )
        }
    }

    @Nested
    inner class ModularScale {
        @Test
        fun `step zero is the root size`() {
            assertNear(18.0, scale.sizeAtStep(0.0, 600.0))
        }

        @Test
        fun `each step multiplies by the ratio`() {
            val root = scale.rootSizeAt(600.0)
            assertNear(root * 1.2, scale.sizeAtStep(1.0, 600.0))
            assertNear(root * 1.2 * 1.2, scale.sizeAtStep(2.0, 600.0))
            assertNear(root / 1.2, scale.sizeAtStep(-1.0, 600.0))
        }

        @Test
        fun `accepts fractional steps`() {
            val half = scale.sizeAtStep(0.5, 600.0)
            assertTrue(half > scale.sizeAtStep(0.0, 600.0))
            assertTrue(half < scale.sizeAtStep(1.0, 600.0))
        }

        @Test
        fun `roles sit where the spec says they do`() {
            assertEquals(-2, FluidTypeRole.Caption.step)
            assertEquals(-1, FluidTypeRole.Small.step)
            assertEquals(0, FluidTypeRole.Body.step)
            assertEquals(6, FluidTypeRole.H1.step)
            assertNear(
                scale.sizeAtStep(6.0, 600.0),
                scale.sizeOf(FluidTypeRole.H1, 600.0),
            )
        }

        @Test
        fun `roles are ordered smallest to largest`() {
            val sizes = FluidTypeRole.entries.map { scale.sizeOf(it, 600.0) }
            for (index in 1 until sizes.size) {
                assertTrue(
                    sizes[index] > sizes[index - 1],
                    "role at index $index is not larger",
                )
            }
        }

        @Test
        fun `rem matches a step of the same multiplier`() {
            assertNear(36.0, scale.rem(2.0, 600.0))
            assertNear(12.0, scale.rem(0.5, 800.0))
        }
    }

    @Nested
    inner class LineHeight {
        @Test
        fun `is loose for small type and tight for display type`() {
            assertNear(1.5, scale.lineHeightFor(8.0))
            assertNear(1.5, scale.lineHeightFor(16.0))
            assertNear(1.1, scale.lineHeightFor(48.0))
            assertNear(1.1, scale.lineHeightFor(96.0))
        }

        @Test
        fun `tightens monotonically in between`() {
            var previous = Double.POSITIVE_INFINITY
            var size = 16.0
            while (size <= 48) {
                val height = scale.lineHeightFor(size)
                assertTrue(height <= previous, "loosened at size $size")
                previous = height
                size += 0.25
            }
        }

        @Test
        fun `is the midpoint at the midpoint`() {
            assertNear(1.3, scale.lineHeightFor(32.0))
        }

        @Test
        fun `absolute line height is the size times the multiplier`() {
            val fluid = scale.resolvedAt(800.0)
            // 24dp body sits a quarter of the way from 16 to 48, multiplier 1.4.
            assertNear(24.0, fluid.sizeOf(FluidTypeRole.Body))
            assertNear(24.0 * 1.4, fluid.lineHeightOf(FluidTypeRole.Body))
            assertTrue(fluid.lineHeightOf(FluidTypeRole.Body) > fluid.body)
        }
    }

    @Nested
    inner class Resolving {
        @Test
        fun `caches the root size`() {
            val fluid = scale.resolvedAt(600.0)
            assertNear(18.0, fluid.rootSize)
            assertEquals(600.0, fluid.width)
            assertNear(18.0, fluid.body)
            assertEquals(scale, fluid.scale)
        }

        @Test
        fun `agrees with the unresolved scale`() {
            val fluid = scale.resolvedAt(537.0)
            for (role in FluidTypeRole.entries) {
                assertNear(scale.sizeOf(role, 537.0), fluid.sizeOf(role))
            }
            assertNear(scale.rem(3.0, 537.0), fluid.rem(3.0))
            assertNear(scale.sizeAtStep(2.5, 537.0), fluid.sizeAtStep(2.5))
            assertEquals(scale.lineHeightFor(20.0), fluid.lineHeightFor(20.0))
        }
    }

    @Nested
    inner class ValueSemantics {
        @Test
        fun `equal scales compare and hash equal`() {
            val other = FluidTypeScale(
                minWidth = 400.0,
                maxWidth = 800.0,
                minRootSize = 12.0,
                maxRootSize = 24.0,
            )
            assertEquals(FluidTypeScale.Reference, other)
            assertEquals(FluidTypeScale.Reference.hashCode(), other.hashCode())
        }

        @Test
        fun `a different ratio is a different scale`() {
            assertNotEquals(scale, scale.copy(ratio = 1.25))
        }

        @Test
        fun `copy replaces only what it is given`() {
            val wider = scale.copy(maxWidth = 1200.0)
            assertEquals(1200.0, wider.maxWidth)
            assertEquals(scale.minWidth, wider.minWidth)
            assertEquals(scale.ratio, wider.ratio)
        }

        @Test
        fun `resolved values differ by width`() {
            assertNotEquals(scale.resolvedAt(600.0), scale.resolvedAt(601.0))
            assertEquals(scale.resolvedAt(600.0), scale.resolvedAt(600.0))
            assertEquals(
                scale.resolvedAt(600.0).hashCode(),
                scale.resolvedAt(600.0).hashCode(),
            )
        }

        @Test
        fun `toString is readable`() {
            assertTrue(scale.toString().contains("400.0"))
            assertTrue(scale.resolvedAt(600.0).toString().contains("rootSize="))
        }
    }
}
