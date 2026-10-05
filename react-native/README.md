# @fluid-type/react-native

Viewport-responsive type scales for React Native. One number — the window or
pane width — drives the whole type hierarchy, interpolating smoothly instead of
snapping at breakpoints.

Part of [fluid-type](https://github.com/FrancisIje/fluid-type), which ports the
same arithmetic to Flutter, Compose and SwiftUI.

## Install

```sh
npm install @fluid-type/react-native
```

No runtime dependencies; `react` and `react-native` are peers.

## Use

Wrap the app once:

```tsx
import { FluidTypeProvider, MOBILE_SCALE } from '@fluid-type/react-native';

export default () => (
  <FluidTypeProvider scale={MOBILE_SCALE}>
    <App />
  </FluidTypeProvider>
);
```

Then read it anywhere below:

```tsx
import { useFluidType } from '@fluid-type/react-native';

function Title() {
  const fluid = useFluidType();
  return <Text style={fluid.style('h1')}>Grumpy wizards</Text>;
}
```

`style(role)` returns `{ fontSize, lineHeight }` with `lineHeight` already in
absolute dp — React Native's `lineHeight` is not a multiplier, and that is the
single most common place hand-rolled fluid type goes wrong on this platform.

### A styles object instead

```tsx
const text = createTextStyles(useFluidType());

<Text style={[styles.heading, text.h2]}>…</Text>;
```

Handy for merging into a design-system sheet, where you want its families and
colours and only the metrics from the scale.

### Drive spacing too

```tsx
<View style={{ padding: fluid.rem(1.5), gap: fluid.rem(0.5) }} />
```

### Without a provider

For one screen or a quick spike:

```tsx
const fluid = useFluidScale(MOBILE_SCALE);
```

Prefer the provider in a real app: it resolves once per window change rather
than once per component.

### Respond to a pane, not the window

```tsx
<View onLayout={(e) => setWidth(e.nativeEvent.layout.width)}>
  <FluidTypeProvider scale={MOBILE_SCALE} width={width}>
    <ListPane />
  </FluidTypeProvider>
</View>
```

## The scale

```ts
const scale = createScale({
  minWidth: 360,      // at or below this width, type stays at minRootSize
  maxWidth: 1024,     // at or above it, type stays at maxRootSize
  minRootSize: 15,
  maxRootSize: 22,
  ratio: 1.2,         // geometric step between roles
});
```

`createScale` throws a `RangeError` on an inverted range or a non-positive
size. A scale built from bad numbers produces type that is plausible-looking
and wrong, which is harder to find than a crash at startup.

`MOBILE_SCALE` (360–768, 14–18) is a reasonable starting point.
`REFERENCE_SCALE` (400–800, 12–24) is the scale the shared conformance
fixtures are generated from.

Nine roles sit at fixed steps from the root: `caption` (−2), `small` (−1),
`body` (0), `h6` (1) through `h1` (6). A role is a position, not a size —
change `ratio` and the hierarchy reshapes without touching a call site.

## Notes

- `useFluidType()` throws outside a provider. Use `useMaybeFluidType()` in a
  component that has to work either way.
- The resolved value is memoised on the scale and width, so rotating a device
  re-renders consumers once rather than on every frame.
- `scale.ts` and `roles.ts` import nothing from React or React Native, so the
  arithmetic is usable in plain Node — which is how the tests run.
- Sizes are dp and do not follow the OS font-size setting. React Native's
  `allowFontScaling` applies that on top if you want both; be aware you are
  then composing two independent multipliers.

## Development

```sh
npm install
npm test        # 30 tests, Node's built-in runner
npm run typecheck
npm run build   # CommonJS + .d.ts into dist/
```

Source files carry explicit `.ts` extensions on relative imports so that
`node --test` can resolve them directly, with no build step and no test
framework to install. `tsconfig.build.json` rewrites them to `.js` on emit,
which needs TypeScript 5.7 or newer.

Tests include the shared conformance fixtures in [`../spec`](../spec).
