/**
 * Fluid, viewport-responsive type scales for React Native.
 *
 * A single number — the window width — drives the whole type hierarchy,
 * interpolating smoothly between a small-screen scale and a large-screen one
 * instead of snapping at breakpoints.
 *
 * ```tsx
 * import { FluidTypeProvider, useFluidType, MOBILE_SCALE } from '@fluid-type/react-native';
 *
 * const Title = () => {
 *   const fluid = useFluidType();
 *   return <Text style={fluid.style('h1')}>Hello</Text>;
 * };
 * ```
 *
 * See the repository README for the arithmetic, and `spec/` for the fixtures
 * shared with the Flutter, Compose and SwiftUI ports.
 */
export {
  FLUID_TYPE_ROLES,
  FLUID_TYPE_ROLE_NAMES,
  stepForRole,
  type FluidTypeRole,
} from './roles.ts';

export {
  createScale,
  lineHeightFor,
  MOBILE_SCALE,
  REFERENCE_SCALE,
  rem,
  rootSizeFor,
  sizeForRole,
  sizeForStep,
  type FluidTypeScale,
  type FluidTypeScaleOptions,
} from './scale.ts';

export {
  createTextStyles,
  resolveScale,
  type FluidTextStyles,
  type FluidType,
} from './resolved.ts';

export {
  FluidTypeProvider,
  useFluidScale,
  useFluidType,
  useMaybeFluidType,
  type FluidTypeProviderProps,
} from './useFluidType.tsx';
