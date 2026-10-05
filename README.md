# fluid-type

One number — the width of the thing your text sits in — drives the whole type
hierarchy. Type grows and shrinks smoothly with the viewport instead of
snapping at breakpoints.

Four implementations, one arithmetic: **Flutter**, **React Native**,
**Compose**, **SwiftUI**. Plus the CSS the idea came from.

```
                  24pt ┤                      ╭───────────────
                       │                   ╭──╯
   root size           │                ╭──╯
                       │             ╭──╯
                  12pt ┤─────────────╯
                       └──────┬──────┬──────┬──────┬──────
                             320    400    600    800   1024
                                     viewport width
```

## The idea

In 2015 Mike Riethmuller [pointed out][pen] that you can interpolate a CSS
`font-size` between two viewport widths with one `calc()`, and that if the
value you interpolate is the *root* size, every `rem` in the document comes
along for the ride. One expression, a whole responsive type system, no
breakpoints.

CSS got `clamp()` and the technique became a one-liner there — `css/` has both
the original and the modern version. The native platforms never got it. They
have no `rem`, no `vw` unit, and no `clamp()`, so the usual approach is a
`when`/`switch` over screen-size buckets that makes type jump as a window
resizes and leaves tablets looking like stretched phones.

These four ports do the interpolation explicitly:

```
rootSize(width) = clamp(minRootSize, lerp(width), maxRootSize)
size(role)      = rootSize * ratio^step(role)
```

That is the whole library. The rest is making it feel native on each platform.

[pen]: https://codepen.io/MadeByMike/pen/vNrvdZ

## Pick your platform

| | Package | Install | Docs |
| --- | --- | --- | --- |
| Flutter | `fluid_type` | `flutter pub add fluid_type` | [flutter/](flutter/) |
| React Native | `@fluid-type/react-native` | `npm i @fluid-type/react-native` | [react-native/](react-native/) |
| Compose | `dev.fluidtype:fluid-type-compose` | Gradle | [kotlin/](kotlin/) |
| SwiftUI | `FluidType` | Swift Package Manager | [swift/](swift/) |
| CSS | — | copy the file | [css/](css/) |

### Flutter

```dart
FluidTypeScope(
  scale: FluidTypeScale.mobile,
  child: Builder(
    builder: (context) => Text(
      'Grumpy wizards',
      style: context.fluidType.style(FluidTypeRole.h1),
    ),
  ),
)
```

Or wire it into your theme once and let every `Text` follow:

```dart
theme: ThemeData(textTheme: context.fluidType.textTheme())
```

### React Native

```tsx
<FluidTypeProvider scale={MOBILE_SCALE}>
  <App />
</FluidTypeProvider>;

const Title = () => {
  const fluid = useFluidType();
  return <Text style={fluid.style('h1')}>Grumpy wizards</Text>;
};
```

### Compose

```kotlin
FluidTypeProvider(FluidTypeScale.Mobile) {
    MaterialTheme(typography = fluidTypography(MaterialTheme.typography)) {
        Text("Grumpy wizards", style = MaterialTheme.typography.displayLarge)
    }
}
```

### SwiftUI

```swift
FluidTypeReader(.mobile) { fluid in
    VStack(alignment: .leading, spacing: fluid.rem(0.5)) {
        Text("Grumpy wizards").fluidText(.h1, weight: .bold)
        Text("Body copy").fluidText(.body)
    }
}
```

## The API, four ways

The same five operations everywhere, spelled the way each language spells
things:

| | Flutter | React Native | Compose | SwiftUI |
| --- | --- | --- | --- | --- |
| root size at a width | `scale.rootSizeFor(w)` | `rootSizeFor(scale, w)` | `scale.rootSizeAt(w)` | `scale.rootSize(at: w)` |
| n rem | `scale.rem(n, w)` | `rem(scale, n, w)` | `scale.rem(n, w)` | `scale.rem(n, at: w)` |
| a step on the scale | `scale.sizeForStep(n, w)` | `sizeForStep(scale, n, w)` | `scale.sizeAtStep(n, w)` | `scale.size(step: n, at: w)` |
| a semantic role | `scale.sizeOf(role, w)` | `sizeForRole(scale, role, w)` | `scale.sizeOf(role, w)` | `scale.size(role, at: w)` |
| resolve once, read often | `scale.resolve(w)` | `resolveScale(scale, w)` | `scale.resolvedAt(w)` | `scale.resolved(at: w)` |

Nine semantic roles, from `caption` at two steps below the root to `h1` at six
above:

```
caption  small  body   h6     h5     h4     h3     h2     h1
  -2      -1     0      1      2      3      4      5      6
```

A role is a position, not a size. Change the `ratio` and the whole hierarchy
reshapes; nothing at the call site changes.

## Getting the defaults right

**Line height is part of the scale.** Leading that reads well for body copy is
too airy for a display heading, so every port tightens the multiplier from 1.5
to 1.1 as type grows from 16 to 48 units. Each platform wants this in a
different form, which is where hand-rolled fluid type usually goes wrong, so
each port hands you the right one:

- Flutter: a multiplier, which is what `TextStyle.height` expects.
- React Native: absolute dp, because `lineHeight` is not a multiplier there.
- Compose: an absolute `TextUnit` for `TextStyle.lineHeight`.
- SwiftUI: the *extra* space between lines, because that is what
  `lineSpacing(_:)` adds.

**Pick a modest ratio.** 1.2 is the default. It looks timid in a specimen and
correct in an app. 1.25 and 1.333 are lovely on a desktop and turn `h1` into a
billboard at 360dp.

**Clamp narrower than you think.** The useful range on mobile is roughly
360–1024. Below 360 there is nothing to gain; above 1024 you usually want a
column width limit rather than bigger type.

**Decide about the reader's text-size setting.** A fluid scale and the OS
accessibility setting are two independent multipliers, and they compose. The
ports take the platform-appropriate default — Compose returns `sp`, so the
reader's setting still applies; SwiftUI's system-font path does not scale, with
a documented opt-in that does — and each says so at the call site. Whichever
you choose, choose it deliberately: silently ignoring the setting to protect a
layout is a regression dressed up as a feature.

## One arithmetic, four ports

Four independent implementations of the same formula drift apart in ways nobody
notices until a heading is two points off on one platform. So the formula lives
in [`spec/`](spec/) once, as data: `spec/generate.mjs` emits tab-separated
fixtures, and all four test suites read those same files and assert against
them to within `1e-9`.

Change a formula, regenerate, and four test suites fail until every port is
brought back in line. That is the intended workflow.

```sh
node spec/generate.mjs
```

The fixtures also pin down the cases that are easy to get subtly different:
both plateaus, the exact breakpoints, fractional steps, and a degenerate scale
where `minWidth == maxWidth` (it steps up, and never divides by zero).

## Running the tests

```sh
cd flutter       && flutter test          # 40 tests
cd react-native  && npm test              # 30 tests
cd kotlin        && gradle test            # 33 tests
cd swift         && swift test            # 29 tests
```

Each suite includes the shared conformance fixtures. The React Native tests run
on Node's built-in runner with no test framework to install, and the sources
carry explicit `.ts` extensions so Node can resolve them directly — the build
rewrites those to `.js`.

## Repository layout

```
spec/            the formulas, as generated fixtures, plus the generator
css/             the original SCSS and the modern clamp() one-liner
flutter/         fluid_type: scale, InheritedWidget scope, TextTheme builder
react-native/    @fluid-type/react-native: scale, context, hooks, styles
kotlin/          dev.fluidtype: pure-Kotlin core + a Compose layer
swift/           FluidType: core + SwiftUI environment, modifiers, fonts
```

In every port the arithmetic is a plain value type with no platform imports,
and the platform integration sits on top of it. That is deliberate: it is what
lets the core be tested against shared fixtures, and it means you can use the
scale to drive padding, gaps and corner radii — which is what `rem` is for —
without pulling in a UI framework.

## Credit

The technique is Mike Riethmuller's, from
[Precise control over responsive typography][article] and the pen linked above.
These are ports, not an invention.

[article]: https://madebymike.com.au/writing/precise-control-responsive-typography/

## License

MIT. See [LICENSE](LICENSE).
