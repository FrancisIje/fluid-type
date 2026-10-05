import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  FLUID_TYPE_ROLES,
  FLUID_TYPE_ROLE_NAMES,
  stepForRole,
  type FluidTypeRole,
} from '../src/roles.ts';
import {
  createScale,
  lineHeightFor,
  REFERENCE_SCALE,
  rem,
  rootSizeFor,
  sizeForRole,
  sizeForStep,
} from '../src/scale.ts';
import { createTextStyles, resolveScale } from '../src/resolved.ts';

const scale = REFERENCE_SCALE;
const near = (actual: number, expected: number, tolerance = 1e-12): void => {
  assert.ok(
    Math.abs(actual - expected) <= tolerance,
    `expected ${actual} to be within ${tolerance} of ${expected}`,
  );
};

describe('rootSizeFor', () => {
  it('holds at minRootSize below and at minWidth', () => {
    assert.equal(rootSizeFor(scale, 0), 12);
    assert.equal(rootSizeFor(scale, 320), 12);
    assert.equal(rootSizeFor(scale, 400), 12);
  });

  it('holds at maxRootSize at and above maxWidth', () => {
    assert.equal(rootSizeFor(scale, 800), 24);
    assert.equal(rootSizeFor(scale, 1280), 24);
    assert.equal(rootSizeFor(scale, Number.MAX_VALUE), 24);
  });

  it('interpolates linearly in between', () => {
    near(rootSizeFor(scale, 500), 15);
    near(rootSizeFor(scale, 600), 18);
    near(rootSizeFor(scale, 700), 21);
  });

  it('is continuous at the breakpoints', () => {
    near(rootSizeFor(scale, 400.0001), 12, 1e-5);
    near(rootSizeFor(scale, 799.9999), 24, 1e-5);
  });

  it('is monotonically non-decreasing', () => {
    let previous = -Infinity;
    for (let w = 0; w <= 1200; w += 0.5) {
      const size = rootSizeFor(scale, w);
      assert.ok(size >= previous, `dipped at width ${w}`);
      previous = size;
    }
  });

  it('treats a zero-width range as a hard breakpoint', () => {
    const step = createScale({
      minWidth: 600,
      maxWidth: 600,
      minRootSize: 12,
      maxRootSize: 24,
    });
    assert.equal(rootSizeFor(step, 599), 12);
    assert.equal(rootSizeFor(step, 600), 24);
    assert.equal(rootSizeFor(step, 601), 24);
    assert.ok(!Number.isNaN(rootSizeFor(step, 600)));
  });

  it('supports a descending scale', () => {
    const descending = createScale({
      minWidth: 400,
      maxWidth: 800,
      minRootSize: 20,
      maxRootSize: 16,
    });
    assert.equal(rootSizeFor(descending, 400), 20);
    near(rootSizeFor(descending, 600), 18);
    assert.equal(rootSizeFor(descending, 800), 16);
  });
});

describe('createScale', () => {
  const bad = {
    'an inverted viewport range': {
      minWidth: 800,
      maxWidth: 400,
      minRootSize: 12,
      maxRootSize: 24,
    },
    'a zero root size': {
      minWidth: 400,
      maxWidth: 800,
      minRootSize: 0,
      maxRootSize: 24,
    },
    'a negative root size': {
      minWidth: 400,
      maxWidth: 800,
      minRootSize: 12,
      maxRootSize: -24,
    },
    'a zero ratio': {
      minWidth: 400,
      maxWidth: 800,
      minRootSize: 12,
      maxRootSize: 24,
      ratio: 0,
    },
    'a non-finite width': {
      minWidth: NaN,
      maxWidth: 800,
      minRootSize: 12,
      maxRootSize: 24,
    },
  };

  for (const [name, options] of Object.entries(bad)) {
    it(`rejects ${name}`, () => {
      assert.throws(() => createScale(options), RangeError);
    });
  }

  it('defaults the ratio to 1.2', () => {
    assert.equal(
      createScale({
        minWidth: 400,
        maxWidth: 800,
        minRootSize: 12,
        maxRootSize: 24,
      }).ratio,
      1.2,
    );
  });
});

describe('the modular scale', () => {
  it('puts step 0 at the root size', () => {
    near(sizeForStep(scale, 0, 600), 18);
  });

  it('multiplies by the ratio at each step', () => {
    const root = rootSizeFor(scale, 600);
    near(sizeForStep(scale, 1, 600), root * 1.2);
    near(sizeForStep(scale, 2, 600), root * 1.2 * 1.2);
    near(sizeForStep(scale, -1, 600), root / 1.2);
  });

  it('accepts fractional steps', () => {
    const half = sizeForStep(scale, 0.5, 600);
    assert.ok(half > sizeForStep(scale, 0, 600));
    assert.ok(half < sizeForStep(scale, 1, 600));
  });

  it('places roles where the spec says', () => {
    assert.equal(FLUID_TYPE_ROLES.caption, -2);
    assert.equal(FLUID_TYPE_ROLES.body, 0);
    assert.equal(FLUID_TYPE_ROLES.h1, 6);
    assert.equal(stepForRole('h3'), 4);
    near(sizeForRole(scale, 'h1', 600), sizeForStep(scale, 6, 600));
  });

  it('orders roles smallest to largest', () => {
    const sizes = FLUID_TYPE_ROLE_NAMES.map((role) =>
      sizeForRole(scale, role, 600),
    );
    for (let i = 1; i < sizes.length; i++) {
      assert.ok(sizes[i]! > sizes[i - 1]!, `role ${i} is not larger`);
    }
  });

  it('matches rem for whole multipliers', () => {
    near(rem(scale, 2, 600), 36);
    near(rem(scale, 0.5, 800), 12);
  });
});

describe('lineHeightFor', () => {
  it('is loose for small type and tight for display type', () => {
    near(lineHeightFor(8), 1.5);
    near(lineHeightFor(16), 1.5);
    near(lineHeightFor(48), 1.1);
    near(lineHeightFor(96), 1.1);
  });

  it('tightens monotonically in between', () => {
    let previous = Infinity;
    for (let size = 16; size <= 48; size += 0.25) {
      const height = lineHeightFor(size);
      assert.ok(height <= previous, `loosened at size ${size}`);
      previous = height;
    }
  });

  it('is the midpoint at the midpoint', () => {
    near(lineHeightFor(32), 1.3);
  });
});

describe('resolveScale', () => {
  it('caches the root size', () => {
    const fluid = resolveScale(scale, 600);
    near(fluid.rootSize, 18);
    assert.equal(fluid.width, 600);
    assert.equal(fluid.scale, scale);
  });

  it('agrees with the unresolved functions', () => {
    const fluid = resolveScale(scale, 537);
    for (const role of FLUID_TYPE_ROLE_NAMES) {
      near(fluid.size(role), sizeForRole(scale, role, 537));
    }
    near(fluid.rem(3), rem(scale, 3, 537));
    near(fluid.sizeForStep(2.5), sizeForStep(scale, 2.5, 537));
    assert.equal(fluid.lineHeightFor(20), lineHeightFor(20));
  });

  it('returns lineHeight in absolute dp, not as a multiplier', () => {
    const fluid = resolveScale(scale, 800);
    const style = fluid.style('body');
    assert.equal(style.fontSize, 24);
    // 24dp sits a quarter of the way from 16 to 48, so the multiplier is 1.4.
    near(style.lineHeight!, 24 * 1.4);
    assert.ok(style.lineHeight! > style.fontSize!);
  });

  it('gives every role a style', () => {
    const styles = createTextStyles(resolveScale(scale, 640));
    const names = Object.keys(styles) as FluidTypeRole[];
    assert.deepEqual(names.sort(), [...FLUID_TYPE_ROLE_NAMES].sort());
    for (const role of names) {
      assert.ok(styles[role].fontSize! > 0);
      assert.ok(styles[role].lineHeight! > 0);
    }
  });
});
