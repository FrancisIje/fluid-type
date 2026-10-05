import React, { useState } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useColorScheme,
} from 'react-native';

import {
  createScale,
  FLUID_TYPE_ROLE_NAMES,
  FluidTypeProvider,
  useFluidType,
  type FluidTypeScale,
} from '../src/index.ts';

/**
 * A type specimen that responds to the window size.
 *
 * Rotate the device, or drag the window edge on a simulator that allows it,
 * and every size on the page moves together. The readout at the bottom prints
 * the width and the root size so the interpolation is visible rather than
 * merely felt.
 */

// 360->1024dp is a sensible phone-to-tablet range; 15->22dp keeps body copy
// comfortable at both ends.
const SCALE: FluidTypeScale = createScale({
  minWidth: 360,
  maxWidth: 1024,
  minRootSize: 15,
  maxRootSize: 22,
});

export default function App(): React.JSX.Element {
  const [scale] = useState(SCALE);
  return (
    <FluidTypeProvider scale={scale}>
      <Specimen />
    </FluidTypeProvider>
  );
}

function Specimen(): React.JSX.Element {
  const fluid = useFluidType();
  const dark = useColorScheme() === 'dark';
  const ink = dark ? '#f5f5f7' : '#16161a';
  const muted = dark ? '#8b8b95' : '#74747e';

  return (
    <SafeAreaView
      style={[styles.root, { backgroundColor: dark ? '#0d0d10' : '#ffffff' }]}
    >
      <ScrollView contentContainerStyle={{ padding: fluid.rem(1.5) }}>
        <Text style={[fluid.style('h3'), { color: ink }]}>Fluid type</Text>
        <Text style={[fluid.style('body'), { color: muted }]}>
          One number drives the hierarchy. Rotate the device.
        </Text>

        <View style={{ height: fluid.rem(1.5) }} />

        {[...FLUID_TYPE_ROLE_NAMES].reverse().map((role) => (
          <View
            key={role}
            style={[styles.row, { marginBottom: fluid.rem(0.4) }]}
          >
            <Text
              style={[
                fluid.style('caption'),
                styles.label,
                { color: muted, width: fluid.rem(4) },
              ]}
            >
              {role}
            </Text>
            <Text
              numberOfLines={1}
              style={[fluid.style(role), styles.sample, { color: ink }]}
            >
              Grumpy wizards make toxic brew
            </Text>
            <Text style={[fluid.style('caption'), { color: muted }]}>
              {fluid.size(role).toFixed(1)}dp
            </Text>
          </View>
        ))}

        <View
          style={[
            styles.card,
            {
              padding: fluid.rem(0.75),
              borderRadius: fluid.rem(0.5),
              borderColor: dark ? '#2a2a31' : '#e6e6ea',
            },
          ]}
        >
          <Text style={[fluid.style('small'), { color: muted }]}>
            {`viewport ${fluid.width.toFixed(0)}dp  ->  root ` +
              `${fluid.rootSize.toFixed(2)}dp  (clamped ` +
              `${scaleRange(fluid.scale)})`}
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const scaleRange = (scale: FluidTypeScale): string =>
  `${scale.minWidth}-${scale.maxWidth}dp`;

const styles = StyleSheet.create({
  root: { flex: 1 },
  row: { flexDirection: 'row', alignItems: 'baseline' },
  label: { textTransform: 'uppercase' },
  sample: { flex: 1 },
  card: { borderWidth: StyleSheet.hairlineWidth },
});
