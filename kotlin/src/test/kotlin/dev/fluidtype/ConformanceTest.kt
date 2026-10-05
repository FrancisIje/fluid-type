package dev.fluidtype

import java.io.File
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import org.junit.jupiter.api.Test

/**
 * Asserts this port against the fixtures in `spec/`, which are shared with the
 * Flutter, React Native and SwiftUI ports. See `spec/README.md`.
 */
class ConformanceTest {
    private val scale = FluidTypeScale.Reference
    private val tolerance = 1e-9

    @Test
    fun `matches root-size tsv`() {
        val rows = fixture("root-size.tsv")
        assertTrue(rows.isNotEmpty(), "fixture is empty")
        for ((width, expected) in rows.map { it[0].toDouble() to it[1].toDouble() }) {
            assertNear(
                expected,
                scale.rootSizeAt(width),
                tolerance,
                "rootSizeAt($width)",
            )
        }
    }

    @Test
    fun `matches scale-steps tsv`() {
        val rows = fixture("scale-steps.tsv")
        assertTrue(rows.isNotEmpty(), "fixture is empty")
        for (row in rows) {
            val width = row[0].toDouble()
            val step = row[1].toDouble()
            val expected = row[2].toDouble()
            assertNear(
                expected,
                scale.sizeAtStep(step, width),
                tolerance,
                "sizeAtStep($step, $width)",
            )
        }
    }

    @Test
    fun `matches line-height tsv`() {
        val rows = fixture("line-height.tsv")
        assertTrue(rows.isNotEmpty(), "fixture is empty")
        for ((fontSize, expected) in rows.map { it[0].toDouble() to it[1].toDouble() }) {
            assertNear(
                expected,
                scale.lineHeightFor(fontSize),
                tolerance,
                "lineHeightFor($fontSize)",
            )
        }
    }

    @Test
    fun `resolves to the same numbers it computes directly`() {
        for (row in fixture("root-size.tsv")) {
            val width = row[0].toDouble()
            assertEquals(row[1].toDouble(), scale.resolvedAt(width).rootSize)
        }
    }

    /** Parses a fixture into rows of columns, dropping comments and the header. */
    private fun fixture(name: String): List<List<String>> =
        File(specDirectory, name)
            .readLines()
            .filter { it.isNotEmpty() && !it.startsWith("#") }
            .drop(1)
            .map { it.split("\t") }

    /**
     * Walks up from the working directory to find the repository's `spec/`.
     *
     * The fixtures are a plain committed directory shared with the other three
     * ports rather than a test resource copied into this module, so they are
     * located by search instead of by classpath.
     */
    private val specDirectory: File by lazy {
        var directory: File? = File(
            System.getProperty("fluidtype.repoRoot") ?: System.getProperty("user.dir"),
        ).absoluteFile
        repeat(6) {
            val current = directory ?: return@repeat
            val candidate = File(current, "spec")
            if (File(candidate, "root-size.tsv").isFile) return@lazy candidate
            directory = current.parentFile
        }
        error(
            "Could not find spec/root-size.tsv above ${System.getProperty("user.dir")}. " +
                "Generate the fixtures with `node spec/generate.mjs`.",
        )
    }
}
