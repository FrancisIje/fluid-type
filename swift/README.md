# FluidType

Viewport-responsive type scales for SwiftUI. One number — the width of the
window or the container — drives the whole type hierarchy, interpolating
smoothly instead of snapping at size classes.

Part of [fluid-type](https://github.com/FrancisIje/fluid-type), which ports the
same arithmetic to Flutter, React Native and Compose.

## Install

```swift
dependencies: [
    .package(url: "https://github.com/FrancisIje/fluid-type", from: "0.1.0")
]
```

The package lives in the `swift/` directory of that repository; Swift Package
Manager will find it. Requires iOS 15, macOS 12, tvOS 15 or watchOS 8.

## Use

```swift
import FluidType

FluidTypeReader(.mobile) { fluid in
    VStack(alignment: .leading, spacing: fluid.rem(0.5)) {
        Text("Grumpy wizards").fluidText(.h1, weight: .bold)
        Text("Body copy that follows along.").fluidText(.body)
    }
    .padding(fluid.rem(1.5))
}
```

`FluidTypeReader` resolves the scale against its own container and puts the
result in the environment, so views further down can read it without it being
threaded through:

```swift
struct Caption: View {
    @Environment(\.fluidType) private var fluid

    var body: some View {
        Text("Posted today")
            .font(fluid.font(.caption))
            .lineSpacing(fluid.lineSpacing(.caption))
    }
}
```

`.fluidText(_:)` applies both the font and the line spacing in one modifier,
which is almost always what you want.

### When you already know the width

`FluidTypeReader` is built on `GeometryReader`, so it claims the space offered
to it and aligns its content top-leading. That is right at the root of a screen
and wrong halfway down a `VStack`. When the width is already known, skip the
geometry:

```swift
content.fluidType(.mobile, at: windowWidth)
```

### Drive spacing too

`rem` is not only for type. Padding, gaps and corner radii in rem stay in
proportion to the text, which is most of what makes a layout feel considered at
two very different widths.

## The scale

```swift
let scale = FluidTypeScale(
    minWidth: 360,      // at or below this width, type stays at minRootSize
    maxWidth: 1024,     // at or above it, type stays at maxRootSize
    minRootSize: 15,
    maxRootSize: 22,
    ratio: 1.2          // geometric step between roles
)
```

The initialiser traps on an inverted range or a non-positive size. A scale
built from bad numbers produces type that is plausible-looking and wrong, which
is harder to find than a crash at launch.

`.mobile` (360–768pt, 14–18pt) is a reasonable starting point. `.reference`
(400–800, 12–24) is the scale the shared conformance fixtures are generated
from.

Nine roles sit at fixed steps from the root: `.caption` (−2), `.small` (−1),
`.body` (0), `.h6` (1) through `.h1` (6). `FluidTypeRole.allCases` is in visual
order. A role is a position, not a size — change `ratio` and the hierarchy
reshapes without touching a call site.

## Line spacing, not line height

`FluidType.lineSpacing(_:)` returns the *extra* space to put between lines,
because that is what SwiftUI's `lineSpacing(_:)` adds — it does not replace the
font's own line height. Handing it a multiplier, or a full line height, is the
single most common place hand-rolled fluid type goes wrong on Apple platforms.

The multiplier itself tightens from 1.5 to 1.1 as type grows from 16 to 48
points, because body-copy leading on a display heading looks accidental.

## Dynamic Type

`fluid.font(role)` returns a fixed-size system font and so does **not** grow
with the reader's Dynamic Type setting. That is a deliberate trade: this scale
already responds to the container, and stacking two independent scaling systems
tends to overflow layouts.

If you need both, use a custom family, which does scale:

```swift
fluid.font(.body, name: "Inter", relativeTo: .body)
```

Whichever you pick, pick it deliberately.

## Notes

- `@Environment(\.fluidType)` falls back to `.mobile` at its own `minWidth`
  when there is no provider, and trips an assertion in debug builds while it
  does so. Read `\.fluidTypeIfPresent` in a view that has to work either way.
- `FluidTypeScale` and `FluidType` are `Sendable` value types with no SwiftUI
  imports, so the arithmetic is usable anywhere — including to drive layout
  constants in UIKit code.
- `Example/FluidTypeSpecimen.swift` is a specimen screen, built as a real
  target so `swift build` keeps it honest.

## Tests

```sh
swift test
```

29 tests: the arithmetic, value semantics, and the shared conformance fixtures
in [`../spec`](../spec).
