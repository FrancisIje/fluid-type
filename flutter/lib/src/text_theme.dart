import 'package:flutter/material.dart';

import 'fluid_type_role.dart';
import 'fluid_type_scale.dart';

/// Builds Flutter text styles and themes from a resolved scale.
extension FluidTypeStyles on FluidType {
  /// A [TextStyle] for [role], with a size from the scale and a line height
  /// from [FluidType.lineHeightFor].
  ///
  /// Pass [base] to keep a family, weight or colour and have only the metrics
  /// come from the scale — the common case when you already have a design
  /// system and want it to breathe with the viewport.
  TextStyle style(FluidTypeRole role, {TextStyle? base}) {
    final size = sizeOf(role);
    return (base ?? const TextStyle())
        .copyWith(fontSize: size, height: lineHeightFor(size));
  }

  /// A [TextTheme] with every slot driven by this scale.
  ///
  /// Material's thirteen slots are mapped onto the nine roles in the obvious
  /// way: the three display slots take [FluidTypeRole.h1] down to
  /// [FluidTypeRole.h3], headlines continue down the scale, and the label
  /// slots sit at or below the root.
  ///
  /// Pass [base] — typically `Theme.of(context).textTheme` — to inherit
  /// families and weights and override only sizes and line heights.
  TextTheme textTheme({TextTheme? base}) {
    final b = base ?? const TextTheme();
    return TextTheme(
      displayLarge: style(FluidTypeRole.h1, base: b.displayLarge),
      displayMedium: style(FluidTypeRole.h2, base: b.displayMedium),
      displaySmall: style(FluidTypeRole.h3, base: b.displaySmall),
      headlineLarge: style(FluidTypeRole.h3, base: b.headlineLarge),
      headlineMedium: style(FluidTypeRole.h4, base: b.headlineMedium),
      headlineSmall: style(FluidTypeRole.h5, base: b.headlineSmall),
      titleLarge: style(FluidTypeRole.h5, base: b.titleLarge),
      titleMedium: style(FluidTypeRole.h6, base: b.titleMedium),
      titleSmall: style(FluidTypeRole.body, base: b.titleSmall),
      bodyLarge: style(FluidTypeRole.h6, base: b.bodyLarge),
      bodyMedium: style(FluidTypeRole.body, base: b.bodyMedium),
      bodySmall: style(FluidTypeRole.small, base: b.bodySmall),
      labelLarge: style(FluidTypeRole.body, base: b.labelLarge),
      labelMedium: style(FluidTypeRole.small, base: b.labelMedium),
      labelSmall: style(FluidTypeRole.caption, base: b.labelSmall),
    );
  }
}
