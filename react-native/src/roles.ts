/**
 * Semantic positions on a modular type scale.
 *
 * Roles exist so that application code says what a piece of text *is* rather
 * than how big it is. Changing the scale's `ratio` then reshapes the whole
 * hierarchy without touching a single component.
 *
 * The same nine roles, at the same steps, appear in the Flutter, Compose and
 * SwiftUI ports and in `css/fluid-type.scss`.
 */
export const FLUID_TYPE_ROLES = {
  /** Two steps below the root. Timestamps, footnotes, image credits. */
  caption: -2,
  /** One step below the root. Secondary copy, helper text under a field. */
  small: -1,
  /** The root size itself, and the size everything else is measured against. */
  body: 0,
  /** One step above the root. */
  h6: 1,
  /** Two steps above the root. */
  h5: 2,
  /** Three steps above the root. */
  h4: 3,
  /** Four steps above the root. */
  h3: 4,
  /** Five steps above the root. */
  h2: 5,
  /** Six steps above the root. Page titles and display type. */
  h1: 6,
} as const;

/** The name of a semantic role, e.g. `'body'` or `'h1'`. */
export type FluidTypeRole = keyof typeof FLUID_TYPE_ROLES;

/** Every role, ordered smallest to largest. */
export const FLUID_TYPE_ROLE_NAMES = Object.keys(
  FLUID_TYPE_ROLES,
) as FluidTypeRole[];

/** The step a role sits at, in steps from the root. */
export function stepForRole(role: FluidTypeRole): number {
  return FLUID_TYPE_ROLES[role];
}
