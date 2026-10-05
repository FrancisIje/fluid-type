import 'package:flutter/widgets.dart';

import 'fluid_type_scale.dart';

/// Provides a [FluidType] to the subtree, resolved against the current
/// viewport width.
///
/// Wrap it around your app — above `MaterialApp.builder` or inside it, either
/// works — and read it with `context.fluidType`:
///
/// ```dart
/// FluidTypeScope(
///   scale: FluidTypeScale.mobile,
///   child: MaterialApp(home: HomePage()),
/// )
/// ```
///
/// The scope watches [MediaQueryData.size] and rebuilds dependents only when
/// the resolved [FluidType] actually changes, so rotating a device rebuilds
/// your text once rather than on every frame of the animation.
class FluidTypeScope extends StatelessWidget {
  /// Creates a scope that resolves [scale] against the ambient media query.
  const FluidTypeScope({
    required this.scale,
    required this.child,
    this.width,
    super.key,
  });

  /// The scale to resolve.
  final FluidTypeScale scale;

  /// The width to resolve against, in logical pixels.
  ///
  /// Defaults to the ambient [MediaQueryData.size] width. Pass it explicitly
  /// when type should respond to a pane rather than the window — a list beside
  /// a detail view, say — usually by reading `LayoutBuilder`'s constraints.
  final double? width;

  /// The subtree that can read the resolved scale.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolved = scale.resolve(width ?? MediaQuery.sizeOf(context).width);
    return _FluidTypeInherited(fluidType: resolved, child: child);
  }
}

class _FluidTypeInherited extends InheritedWidget {
  const _FluidTypeInherited({required this.fluidType, required super.child});

  final FluidType fluidType;

  @override
  bool updateShouldNotify(_FluidTypeInherited oldWidget) =>
      oldWidget.fluidType != fluidType;
}

/// Reads the nearest [FluidTypeScope].
extension FluidTypeContext on BuildContext {
  /// The [FluidType] from the nearest enclosing [FluidTypeScope].
  ///
  /// Throws a [FlutterError] in debug mode when there is no scope above this
  /// context, because silently falling back to a default scale produces type
  /// that is subtly wrong everywhere and obviously wrong nowhere.
  FluidType get fluidType {
    final inherited = dependOnInheritedWidgetOfExactType<_FluidTypeInherited>();
    assert(() {
      if (inherited == null) {
        throw FlutterError.fromParts([
          ErrorSummary('No FluidTypeScope found above this context.'),
          ErrorDescription(
            'context.fluidType was called from a widget with no '
            'FluidTypeScope ancestor.',
          ),
          ErrorHint(
            'Wrap your app — or at least the subtree that reads fluid type — '
            'in a FluidTypeScope:\n\n'
            '  FluidTypeScope(\n'
            '    scale: FluidTypeScale.mobile,\n'
            '    child: MaterialApp(...),\n'
            '  )',
          ),
        ]);
      }
      return true;
    }());
    return inherited!.fluidType;
  }

  /// The [FluidType] from the nearest [FluidTypeScope], or null if there is
  /// none.
  ///
  /// For widgets that want to work either way — a shared component published
  /// to other teams, for instance.
  FluidType? get maybeFluidType =>
      dependOnInheritedWidgetOfExactType<_FluidTypeInherited>()?.fluidType;
}
