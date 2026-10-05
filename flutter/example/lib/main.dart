import 'package:fluid_type/fluid_type.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// A specimen page that shows the scale responding to the window.
///
/// Resize the window (or rotate the device) and every size on the page moves
/// together. The readout at the bottom prints the width and root size so the
/// interpolation is visible rather than merely felt.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // 360->1024dp is a sensible phone-to-tablet range; 15->22dp keeps body copy
  // comfortable at both ends.
  FluidTypeScale _scale = const FluidTypeScale(
    minWidth: 360,
    maxWidth: 1024,
    minRootSize: 15,
    maxRootSize: 22,
  );

  @override
  Widget build(BuildContext context) {
    return FluidTypeScope(
      scale: _scale,
      child: Builder(
        builder: (context) {
          final fluid = context.fluidType;
          return MaterialApp(
            title: 'fluid_type',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF3D5AFE),
              // The whole point: one line wires the scale into every
              // Text widget that uses the theme.
              textTheme: fluid.textTheme(base: Theme.of(context).textTheme),
            ),
            home: _Specimen(
              scale: _scale,
              onRatioChanged: (ratio) =>
                  setState(() => _scale = _scale.copyWith(ratio: ratio)),
            ),
          );
        },
      ),
    );
  }
}

class _Specimen extends StatelessWidget {
  const _Specimen({required this.scale, required this.onRatioChanged});

  final FluidTypeScale scale;
  final ValueChanged<double> onRatioChanged;

  @override
  Widget build(BuildContext context) {
    final fluid = context.fluidType;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(fluid.rem(1.5)),
          children: [
            Text('Fluid type', style: text.displaySmall),
            SizedBox(height: fluid.rem(0.5)),
            Text(
              'One number drives the hierarchy. Drag the window edge.',
              style: text.bodyLarge,
            ),
            SizedBox(height: fluid.rem(1.5)),
            for (final role in FluidTypeRole.values.reversed)
              Padding(
                padding: EdgeInsets.only(bottom: fluid.rem(0.4)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: fluid.rem(4),
                      child: Text(
                        role.name,
                        style: text.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Grumpy wizards make toxic brew',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fluid.style(role),
                      ),
                    ),
                    Text(
                      '${fluid.sizeOf(role).toStringAsFixed(1)}dp',
                      style: text.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: fluid.rem(1)),
            Text('Ratio ${scale.ratio.toStringAsFixed(3)}',
                style: text.labelLarge),
            Slider(
              value: scale.ratio,
              min: 1.05,
              max: 1.4,
              onChanged: onRatioChanged,
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(fluid.rem(0.75)),
                child: Text(
                  'viewport ${fluid.width.toStringAsFixed(0)}dp  ->  '
                  'root ${fluid.rootSize.toStringAsFixed(2)}dp  '
                  '(clamped ${scale.minWidth.toStringAsFixed(0)}'
                  '-${scale.maxWidth.toStringAsFixed(0)}dp)',
                  style: text.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
