# fluid_type

Viewport-responsive type scales for Flutter. One number — the width of the
window or the pane — drives the whole type hierarchy, interpolating smoothly
instead of snapping at breakpoints.

Part of [fluid-type](https://github.com/FrancisIje/fluid-type), which ports the
same arithmetic to React Native, Compose and SwiftUI.

## Install

```sh
flutter pub add fluid_type
```

## Use

Put a scope above the widgets that need it, usually once, at the root:

```dart
import 'package:fluid_type/fluid_type.dart';

FluidTypeScope(
  scale: FluidTypeScale.mobile,
  child: MaterialApp(home: HomePage()),
)
```

Then read it from any descendant:

```dart
Text('Grumpy wizards', style: context.fluidType.style(FluidTypeRole.h1))
```

### Wire it into the theme

Usually better than styling individual widgets: build a `TextTheme` once and
every `Text` that uses the theme follows along.

```dart
FluidTypeScope(
  scale: FluidTypeScale.mobile,
  child: Builder(
    builder: (context) => MaterialApp(
      theme: ThemeData(
        textTheme: context.fluidType.textTheme(
          base: Theme.of(context).textTheme, // keep families and weights
        ),
      ),
      home: const HomePage(),
    ),
  ),
)
```

### Drive spacing too

`rem` is not only for type. Padding and gaps expressed in rem stay in
proportion to the text, which is most of what makes a layout feel considered at
two very different widths.

```dart
Padding(
  padding: EdgeInsets.all(context.fluidType.rem(1.5)),
  child: ...,
)
```

### Respond to a pane, not the window

A master-detail layout wants the list's type to follow the list, not the
window. Pass the width explicitly:

```dart
LayoutBuilder(
  builder: (context, constraints) => FluidTypeScope(
    scale: FluidTypeScale.mobile,
    width: constraints.maxWidth,
    child: const ListPane(),
  ),
)
```

## The scale

```dart
const scale = FluidTypeScale(
  minWidth: 360,      // at or below this width, type stays at minRootSize
  maxWidth: 1024,     // at or above it, type stays at maxRootSize
  minRootSize: 15,
  maxRootSize: 22,
  ratio: 1.2,         // geometric step between roles
);
```

`FluidTypeScale.mobile` (360–768dp, 14–18dp) is a reasonable starting point.
`FluidTypeScale.reference` (400–800, 12–24) is the scale the shared
conformance fixtures are generated from.

Nine roles sit at fixed steps from the root:

| role | step | at root 18 |
| --- | --- | --- |
| `caption` | −2 | 12.5 |
| `small` | −1 | 15.0 |
| `body` | 0 | 18.0 |
| `h6` | 1 | 21.6 |
| `h5` | 2 | 25.9 |
| `h4` | 3 | 31.1 |
| `h3` | 4 | 37.3 |
| `h2` | 5 | 44.8 |
| `h1` | 6 | 53.7 |

A role is a position, not a size: change `ratio` and the hierarchy reshapes
without touching a call site.

## Line height

`FluidType.lineHeightFor` returns a *multiplier*, which is what
`TextStyle.height` expects, and it tightens from 1.5 to 1.1 as type grows from
16 to 48dp — body-copy leading on a display heading looks accidental.
`style()` applies it for you.

## Notes

- `context.fluidType` throws a `FlutterError` in debug builds when there is no
  `FluidTypeScope` above it. Use `context.maybeFluidType` in a widget that has
  to work either way.
- The resolved value compares equal when the width is unchanged, so dependents
  do not rebuild when an unrelated `MediaQuery` field changes.
- `FluidTypeScale` is a `const`-constructible value type with no Flutter
  imports, so you can use it in pure-Dart code and plain unit tests.
- Text sizes here are logical pixels and do not follow the platform's font-size
  accessibility setting. If you need that too, scale the result — and be aware
  you are then composing two independent multipliers.

## Tests

```sh
flutter test
```

40 tests: the arithmetic, the widget layer, and the shared conformance
fixtures in [`../spec`](../spec).
