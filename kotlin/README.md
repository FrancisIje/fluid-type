# fluid-type-compose

Viewport-responsive type scales for Jetpack Compose. One number — the window or
pane width — drives the whole type hierarchy, interpolating smoothly instead of
snapping at breakpoints.

Part of [fluid-type](https://github.com/FrancisIje/fluid-type), which ports the
same arithmetic to Flutter, React Native and SwiftUI.

## Install

```kotlin
dependencies {
    implementation("dev.fluidtype:fluid-type-compose:0.1.0")
}
```

## Use

Wrap your theme once:

```kotlin
import dev.fluidtype.FluidTypeScale
import dev.fluidtype.compose.FluidTypeProvider
import dev.fluidtype.compose.fluidTypography

FluidTypeProvider(FluidTypeScale.Mobile) {
    MaterialTheme(typography = fluidTypography(MaterialTheme.typography)) {
        App()
    }
}
```

`fluidTypography` fills all fifteen Material 3 slots from the scale while
inheriting families, weights and letter spacing from whatever you pass as the
base. Every `Text` that reads the theme now follows the window.

For one-off text, read the resolved scale directly:

```kotlin
val fluid = LocalFluidType.current

Text("Grumpy wizards", style = fluid.textStyle(FluidTypeRole.H1))
```

### Drive spacing too

`rem` is not only for type. Padding and gaps in rem stay in proportion to the
text, which is most of what makes a layout feel considered at two very
different widths.

```kotlin
Column(
    modifier = Modifier.padding(fluid.remDp(1.5)),
    verticalArrangement = Arrangement.spacedBy(fluid.remDp(0.5)),
) { … }
```

### Respond to a pane, not the window

`FluidTypeProvider` reads `LocalConfiguration.screenWidthDp`, which is the
window. In a split pane that is the wrong number, so use `FluidTypeBox`, which
measures itself:

```kotlin
FluidTypeBox(FluidTypeScale.Mobile) {
    ListPane()
}
```

It is built on `BoxWithConstraints`, so it subcomposes — fine for a pane root,
not something to put in a hot list item.

## The scale

```kotlin
val scale = FluidTypeScale(
    minWidth = 360.0,     // at or below this width, type stays at minRootSize
    maxWidth = 1024.0,    // at or above it, type stays at maxRootSize
    minRootSize = 15.0,
    maxRootSize = 22.0,
    ratio = 1.2,          // geometric step between roles
)
```

Construction throws `IllegalArgumentException` on an inverted range or a
non-positive size.

`FluidTypeScale.Mobile` (360–768dp, 14–18dp) is a reasonable starting point.
`FluidTypeScale.Reference` (400–800, 12–24) is the scale the shared conformance
fixtures are generated from.

Nine roles sit at fixed steps from the root: `Caption` (−2), `Small` (−1),
`Body` (0), `H6` (1) through `H1` (6). A role is a position, not a size —
change `ratio` and the hierarchy reshapes without touching a call site.

## sp or dp

`fontSize(role)` returns `sp`, so the reader's system font-size setting still
applies on top of the fluid scale. That is the right default: ignoring the
accessibility setting to protect a layout is a regression dressed up as a
feature. It does mean two multipliers compose, and a reader at 200% on a
tablet will see very large type.

`fontSizeIgnoringUserScale(role)` converts through `LocalDensity` so only the
fluid scale applies. Reach for it sparingly, and never for body copy.

## Layout

```
src/main/kotlin/dev/fluidtype/
├── FluidTypeScale.kt      the arithmetic — plain Kotlin, no Compose, no Android
├── FluidTypeRole.kt
└── compose/
    ├── FluidType.kt       CompositionLocal, providers, TextUnit conversions
    └── FluidTypography.kt Material 3 Typography
example/
└── FluidTypeSpecimen.kt   a specimen screen; drop it into an app
```

The core uses `Double` rather than `Float` or `Dp`, which keeps it usable from
plain unit tests and Kotlin Multiplatform code — and a `Float` cannot hold the
`1e-9` precision the shared fixtures are checked to.

## Tests

```sh
gradle test
```

33 tests: the arithmetic, validation, and the shared conformance fixtures in
[`../spec`](../spec). The core tests are plain JVM tests and need no
emulator. No Gradle wrapper is committed — use your own Gradle 8.7+, or run
`gradle wrapper` once to add one.
