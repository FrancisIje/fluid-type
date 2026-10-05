/// Fluid, viewport-responsive type scales for Flutter.
///
/// A single number — the viewport width — drives the whole type hierarchy,
/// interpolating smoothly between a small-screen scale and a large-screen one
/// instead of snapping at breakpoints.
///
/// ```dart
/// FluidTypeScope(
///   scale: FluidTypeScale.mobile,
///   child: Builder(
///     builder: (context) => Text(
///       'Hello',
///       style: context.fluidType.style(FluidTypeRole.h1),
///     ),
///   ),
/// )
/// ```
///
/// See the repository README for the arithmetic, and `spec/` for the fixtures
/// shared with the React Native, Compose and SwiftUI ports.
library;

export 'src/fluid_type_role.dart';
export 'src/fluid_type_scale.dart';
export 'src/fluid_type_scope.dart';
export 'src/text_theme.dart';
