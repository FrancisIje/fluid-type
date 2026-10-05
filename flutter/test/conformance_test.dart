import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluid_type/fluid_type.dart';

/// Asserts this port against the fixtures in `spec/`, which are shared with
/// the React Native, Compose and SwiftUI ports. See `spec/README.md`.
void main() {
  const scale = FluidTypeScale.reference;
  const tolerance = 1e-9;

  late Directory specDir;

  setUpAll(() {
    specDir = _findSpecDir();
  });

  test('root-size.tsv', () {
    final rows = _readFixture(specDir, 'root-size.tsv');
    expect(rows, isNotEmpty);
    for (final row in rows) {
      final width = double.parse(row[0]);
      final expected = double.parse(row[1]);
      expect(
        scale.rootSizeFor(width),
        closeTo(expected, tolerance),
        reason: 'rootSizeFor($width)',
      );
    }
  });

  test('scale-steps.tsv', () {
    final rows = _readFixture(specDir, 'scale-steps.tsv');
    expect(rows, isNotEmpty);
    for (final row in rows) {
      final width = double.parse(row[0]);
      final step = int.parse(row[1]);
      final expected = double.parse(row[2]);
      expect(
        scale.sizeForStep(step, width),
        closeTo(expected, tolerance),
        reason: 'sizeForStep($step, $width)',
      );
    }
  });

  test('line-height.tsv', () {
    final rows = _readFixture(specDir, 'line-height.tsv');
    expect(rows, isNotEmpty);
    for (final row in rows) {
      final fontSize = double.parse(row[0]);
      final expected = double.parse(row[1]);
      expect(
        scale.lineHeightFor(fontSize),
        closeTo(expected, tolerance),
        reason: 'lineHeightFor($fontSize)',
      );
    }
  });

  test('resolved values match the unresolved ones', () {
    final rows = _readFixture(specDir, 'root-size.tsv');
    for (final row in rows) {
      final width = double.parse(row[0]);
      expect(scale.resolve(width).rootSize, double.parse(row[1]));
    }
  });
}

/// Walks up from the current directory to find the repository's `spec/`.
///
/// `flutter test` runs with the package root as the working directory, but
/// tooling and IDEs are not consistent about that, so this does not assume it.
Directory _findSpecDir() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final candidate = Directory('${dir.path}/spec');
    if (File('${candidate.path}/root-size.tsv').existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'Could not find spec/root-size.tsv above ${Directory.current.path}. '
    'Run the fixtures generator with `node spec/generate.mjs`.',
  );
}

/// Parses a fixture into rows of columns, dropping comments and the header.
List<List<String>> _readFixture(Directory specDir, String name) {
  return File('${specDir.path}/$name')
      .readAsLinesSync()
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .skip(1)
      .map((line) => line.split('\t'))
      .toList();
}
