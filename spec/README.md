# The spec

Fluid type is a small amount of arithmetic, which means four independent ports
can drift apart in ways nobody notices until a heading is two pixels off on one
platform. So the arithmetic lives here once, as data.

`generate.mjs` is the only place the formulas are written down in executable
form. It emits three tab-separated fixtures, and the Dart, TypeScript, Kotlin
and Swift test suites all read these same files and assert against them. If a
port disagrees with the fixture by more than `1e-9`, its tests fail.

| File | Columns | What it pins down |
| --- | --- | --- |
| `root-size.tsv` | `width`, `rootSize` | The clamped interpolation, including both plateaus and the exact boundaries |
| `scale-steps.tsv` | `width`, `step`, `size` | The modular scale, `rootSize * ratio^step`, for steps -3..6 |
| `line-height.tsv` | `fontSize`, `lineHeight` | The leading curve that tightens as type grows |

All fixtures use one reference scale, chosen to match the original SCSS so the
numbers can be checked by hand:

```
minWidth = 400   maxWidth = 800
minRootSize = 12 maxRootSize = 24
ratio = 1.2
```

Values are written with ten decimal places. That is more precision than any
layout needs, but it means the fixtures catch a port that reorders the
interpolation in a way that changes rounding, which is usually the first sign
someone has rewritten the formula from memory.

## The formulas

```
rootSize(width) =
  maxRootSize                                                  when width >= maxWidth
  minRootSize                                                  when width <= minWidth
  minRootSize + (maxRootSize - minRootSize) * t                otherwise,
                                                               t = (width - minWidth)
                                                                 / (maxWidth - minWidth)

size(step, width)  = rootSize(width) * ratio^step

lineHeight(size)   = 1.5 + (1.1 - 1.5) * clamp((size - 16) / (48 - 16), 0, 1)
```

The clauses are ordered, and the order is load-bearing. Degenerate scales are
defined rather than left to chance: when `minWidth == maxWidth` the function is
a step, and testing the upper plateau first makes `rootSize` return
`maxRootSize` for any width at or above that single breakpoint. It also means
the division can never see a zero denominator, so no port needs a guard
against NaN. Every port tests this case.

## Regenerating

```sh
node spec/generate.mjs
```

Changing a formula means changing `generate.mjs`, regenerating, and watching
four test suites fail until every port is brought back in line. That is the
intended workflow, and the reason the fixtures are committed.
