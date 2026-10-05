import type { TextStyle } from 'react-native';

import {
  FLUID_TYPE_ROLE_NAMES,
  stepForRole,
  type FluidTypeRole,
} from './roles.ts';
import {
  lineHeightFor,
  rootSizeFor,
  type FluidTypeScale,
} from './scale.ts';

/**
 * A scale resolved against one viewport width.
 *
 * This is what components read. The root size — the only part of the
 * computation that depends on the viewport — is cached, so a screen that asks
 * for a dozen sizes does the interpolation once.
 */
export interface FluidType {
  /** The scale this was resolved from. */
  readonly scale: FluidTypeScale;
  /** The viewport width it was resolved at, in dp. */
  readonly width: number;
  /** The root size at `width` — the `1rem` of this scale. */
  readonly rootSize: number;
  /** `multiplier` rem, in dp. Handy for padding and gaps, not just type. */
  rem(multiplier: number): number;
  /** The size at `step` on the modular scale, in dp. */
  sizeForStep(step: number): number;
  /** The size for a semantic role, in dp. */
  size(role: FluidTypeRole): number;
  /** A line-height *multiplier* for `fontSize`. */
  lineHeightFor(fontSize: number): number;
  /**
   * A ready-to-spread text style for `role`.
   *
   * React Native wants `lineHeight` in absolute dp rather than as a
   * multiplier, which is the single most common place hand-rolled fluid type
   * goes wrong on this platform. This does the multiplication for you.
   */
  style(role: FluidTypeRole): Pick<TextStyle, 'fontSize' | 'lineHeight'>;
}

/** Resolves `scale` at `width`. */
export function resolveScale(scale: FluidTypeScale, width: number): FluidType {
  const rootSize = rootSizeFor(scale, width);
  const sizeForStep = (step: number): number =>
    rootSize * Math.pow(scale.ratio, step);

  return {
    scale,
    width,
    rootSize,
    rem: (multiplier) => rootSize * multiplier,
    sizeForStep,
    size: (role) => sizeForStep(stepForRole(role)),
    lineHeightFor,
    style: (role) => {
      const fontSize = sizeForStep(stepForRole(role));
      return { fontSize, lineHeight: fontSize * lineHeightFor(fontSize) };
    },
  };
}

/** A `StyleSheet`-shaped object with one entry per role. */
export type FluidTextStyles = Record<
  FluidTypeRole,
  Pick<TextStyle, 'fontSize' | 'lineHeight'>
>;

/**
 * Every role as a style object at once.
 *
 * Useful when you would rather pass a styles object down than call `style()`
 * at each use site, and for merging into an existing design-system sheet:
 *
 * ```ts
 * const text = createTextStyles(fluid);
 * <Text style={[styles.heading, text.h2]}>…</Text>
 * ```
 */
export function createTextStyles(fluid: FluidType): FluidTextStyles {
  const out = {} as FluidTextStyles;
  for (const role of FLUID_TYPE_ROLE_NAMES) {
    out[role] = fluid.style(role);
  }
  return out;
}
