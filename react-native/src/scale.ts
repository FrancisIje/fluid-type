import { stepForRole, type FluidTypeRole } from './roles.ts';

/** Line-height anchors shared by every port. See `spec/line-height.tsv`. */
const LOOSE_AT = 16;
const TIGHT_AT = 48;
const LOOSE = 1.5;
const TIGHT = 1.1;

/** The numbers that define a scale. */
export interface FluidTypeScaleOptions {
  /** Width at or below which the root size stays at `minRootSize`, in dp. */
  minWidth: number;
  /** Width at or above which the root size stays at `maxRootSize`, in dp. */
  maxWidth: number;
  /** The root size at `minWidth`, in dp. */
  minRootSize: number;
  /** The root size at `maxWidth`, in dp. */
  maxRootSize: number;
  /**
   * The geometric ratio between adjacent steps.
   *
   * Defaults to 1.2 (a major second), which stays readable on a phone. 1.25
   * and 1.333 open up nicely on larger screens but turn `h1` into a billboard
   * at 360dp.
   */
  ratio?: number;
}

/** A fully specified scale: {@link FluidTypeScaleOptions} with `ratio` filled in. */
export type FluidTypeScale = Required<FluidTypeScaleOptions>;

const clamp = (value: number, lo: number, hi: number): number =>
  value < lo ? lo : value > hi ? hi : value;

/**
 * Validates and fills in a scale.
 *
 * Throws on an inverted viewport range or a non-positive size, because a scale
 * built from bad numbers produces type that is plausible-looking and wrong,
 * which is worse than a crash at startup.
 */
export function createScale(options: FluidTypeScaleOptions): FluidTypeScale {
  const { minWidth, maxWidth, minRootSize, maxRootSize, ratio = 1.2 } = options;

  if (!Number.isFinite(minWidth) || !Number.isFinite(maxWidth)) {
    throw new RangeError('minWidth and maxWidth must be finite');
  }
  if (minWidth > maxWidth) {
    throw new RangeError(`minWidth (${minWidth}) must be <= maxWidth (${maxWidth})`);
  }
  if (!(minRootSize > 0) || !(maxRootSize > 0)) {
    throw new RangeError('root sizes must be positive');
  }
  if (!(ratio > 0)) {
    throw new RangeError('ratio must be positive');
  }

  return { minWidth, maxWidth, minRootSize, maxRootSize, ratio };
}

/** The scale from the original SCSS: 400–800px viewport, 12–24px root. */
export const REFERENCE_SCALE: FluidTypeScale = createScale({
  minWidth: 400,
  maxWidth: 800,
  minRootSize: 12,
  maxRootSize: 24,
});

/** A scale tuned for phone-to-tablet layouts: 360–768dp, 14–18dp root. */
export const MOBILE_SCALE: FluidTypeScale = createScale({
  minWidth: 360,
  maxWidth: 768,
  minRootSize: 14,
  maxRootSize: 18,
});

/**
 * The root size for `width`, clamped at both ends.
 *
 * The upper plateau is tested first on purpose: when `minWidth === maxWidth`
 * the scale degenerates to a single breakpoint, and this ordering makes it step
 * up to `maxRootSize` there rather than down. It also guarantees the division
 * below never sees a zero denominator.
 */
export function rootSizeFor(scale: FluidTypeScale, width: number): number {
  if (width >= scale.maxWidth) return scale.maxRootSize;
  if (width <= scale.minWidth) return scale.minRootSize;
  const t = (width - scale.minWidth) / (scale.maxWidth - scale.minWidth);
  return scale.minRootSize + (scale.maxRootSize - scale.minRootSize) * t;
}

/** `multiplier` times the root size — the direct analogue of a CSS `rem`. */
export function rem(
  scale: FluidTypeScale,
  multiplier: number,
  width: number,
): number {
  return rootSizeFor(scale, width) * multiplier;
}

/**
 * The size at `step` on the modular scale.
 *
 * Step 0 is the root size; positive steps grow by `ratio`, negative steps
 * shrink by it. Steps need not be whole numbers.
 */
export function sizeForStep(
  scale: FluidTypeScale,
  step: number,
  width: number,
): number {
  return rootSizeFor(scale, width) * Math.pow(scale.ratio, step);
}

/** The size for a semantic role. */
export function sizeForRole(
  scale: FluidTypeScale,
  role: FluidTypeRole,
  width: number,
): number {
  return sizeForStep(scale, stepForRole(role), width);
}

/**
 * A line-height multiplier for `fontSize`.
 *
 * Leading that works for body copy is too airy for a display heading, so this
 * tightens from 1.5 to 1.1 as type grows from 16 to 48dp. React Native's
 * `lineHeight` wants absolute dp, not a multiplier, so multiply the two
 * yourself — or use {@link resolveScale} and let `style()` do it.
 */
export function lineHeightFor(fontSize: number): number {
  const t = clamp((fontSize - LOOSE_AT) / (TIGHT_AT - LOOSE_AT), 0, 1);
  return LOOSE + (TIGHT - LOOSE) * t;
}
