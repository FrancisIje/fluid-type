import React, {
  createContext,
  useContext,
  useMemo,
  type ReactNode,
} from 'react';
import { useWindowDimensions } from 'react-native';

import { resolveScale, type FluidType } from './resolved.ts';
import { MOBILE_SCALE, type FluidTypeScale } from './scale.ts';

const FluidTypeContext = createContext<FluidType | null>(null);

/** Props for {@link FluidTypeProvider}. */
export interface FluidTypeProviderProps {
  /** The scale to resolve. Defaults to {@link MOBILE_SCALE}. */
  scale?: FluidTypeScale;
  /**
   * The width to resolve against, in dp.
   *
   * Defaults to the window width. Pass it explicitly when type should respond
   * to a pane rather than the window — a list beside a detail view, say —
   * usually from an `onLayout` measurement.
   */
  width?: number;
  children?: ReactNode;
}

/**
 * Provides a resolved scale to the tree.
 *
 * Wrap your app once:
 *
 * ```tsx
 * <FluidTypeProvider scale={MOBILE_SCALE}>
 *   <App />
 * </FluidTypeProvider>
 * ```
 *
 * The resolved value is memoised on the scale and the width, so rotating a
 * device re-renders consumers once rather than on every frame.
 */
export function FluidTypeProvider({
  scale = MOBILE_SCALE,
  width,
  children,
}: FluidTypeProviderProps): React.JSX.Element {
  const window = useWindowDimensions();
  const effectiveWidth = width ?? window.width;
  const value = useMemo(
    () => resolveScale(scale, effectiveWidth),
    [scale, effectiveWidth],
  );

  return (
    <FluidTypeContext.Provider value={value}>
      {children}
    </FluidTypeContext.Provider>
  );
}

/**
 * Reads the nearest {@link FluidTypeProvider}.
 *
 * Throws when there is no provider above the component, because silently
 * falling back to a default scale produces type that is subtly wrong
 * everywhere and obviously wrong nowhere.
 */
export function useFluidType(): FluidType {
  const value = useContext(FluidTypeContext);
  if (value === null) {
    throw new Error(
      'useFluidType() was called outside a <FluidTypeProvider>. Wrap your ' +
        'app — or at least the subtree that reads fluid type — in one:\n\n' +
        '  <FluidTypeProvider scale={MOBILE_SCALE}>\n' +
        '    <App />\n' +
        '  </FluidTypeProvider>',
    );
  }
  return value;
}

/**
 * Reads the nearest provider, or `null` if there is none.
 *
 * For components that must work either way — a shared component published to
 * other teams, for instance.
 */
export function useMaybeFluidType(): FluidType | null {
  return useContext(FluidTypeContext);
}

/**
 * Resolves a scale against the window without needing a provider.
 *
 * Convenient for a single screen or a quick spike. Prefer the provider in a
 * real app: it resolves once per window change instead of once per component.
 */
export function useFluidScale(scale: FluidTypeScale = MOBILE_SCALE): FluidType {
  const { width } = useWindowDimensions();
  return useMemo(() => resolveScale(scale, width), [scale, width]);
}
