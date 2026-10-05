import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it } from 'node:test';

import {
  lineHeightFor,
  REFERENCE_SCALE,
  rootSizeFor,
  sizeForStep,
} from '../src/scale.ts';
import { resolveScale } from '../src/resolved.ts';

/**
 * Asserts this port against the fixtures in `spec/`, which are shared with the
 * Flutter, Compose and SwiftUI ports. See `spec/README.md`.
 */
const SPEC_DIR = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'spec');
const TOLERANCE = 1e-9;

/** Parses a fixture into rows of columns, dropping comments and the header. */
function fixture(name: string): string[][] {
  return readFileSync(join(SPEC_DIR, name), 'utf8')
    .split('\n')
    .filter((line) => line.length > 0 && !line.startsWith('#'))
    .slice(1)
    .map((line) => line.split('\t'));
}

const near = (actual: number, expected: number, what: string): void => {
  assert.ok(
    Math.abs(actual - expected) <= TOLERANCE,
    `${what}: expected ${expected}, got ${actual}`,
  );
};

describe('conformance', () => {
  it('matches root-size.tsv', () => {
    const rows = fixture('root-size.tsv');
    assert.ok(rows.length > 0, 'fixture is empty');
    for (const [widthText, expectedText] of rows) {
      const width = Number(widthText);
      near(
        rootSizeFor(REFERENCE_SCALE, width),
        Number(expectedText),
        `rootSizeFor(${width})`,
      );
    }
  });

  it('matches scale-steps.tsv', () => {
    const rows = fixture('scale-steps.tsv');
    assert.ok(rows.length > 0, 'fixture is empty');
    for (const [widthText, stepText, expectedText] of rows) {
      const width = Number(widthText);
      const step = Number(stepText);
      near(
        sizeForStep(REFERENCE_SCALE, step, width),
        Number(expectedText),
        `sizeForStep(${step}, ${width})`,
      );
    }
  });

  it('matches line-height.tsv', () => {
    const rows = fixture('line-height.tsv');
    assert.ok(rows.length > 0, 'fixture is empty');
    for (const [sizeText, expectedText] of rows) {
      const fontSize = Number(sizeText);
      near(
        lineHeightFor(fontSize),
        Number(expectedText),
        `lineHeightFor(${fontSize})`,
      );
    }
  });

  it('resolves to the same numbers it computes directly', () => {
    for (const [widthText, expectedText] of fixture('root-size.tsv')) {
      const width = Number(widthText);
      assert.equal(
        resolveScale(REFERENCE_SCALE, width).rootSize,
        Number(expectedText),
      );
    }
  });
});
