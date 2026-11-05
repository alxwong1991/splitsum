import { BadRequestException } from '@nestjs/common';
import { MAX_TOTAL_CENTS, splitEqually } from './equal-split';

describe('splitEqually', () => {
  const participants = [
    { id: 'alex', position: 0 },
    { id: 'bea', position: 1 },
    { id: 'chan', position: 2 },
  ];

  it('splits a divisible total equally', () => {
    expect(splitEqually(9_000, participants)).toEqual([
      { participantId: 'alex', amountCents: 3_000 },
      { participantId: 'bea', amountCents: 3_000 },
      { participantId: 'chan', amountCents: 3_000 },
    ]);
  });

  it('allocates leftover cents by immutable participant position', () => {
    expect(splitEqually(10_000, participants)).toEqual([
      { participantId: 'alex', amountCents: 3_334 },
      { participantId: 'bea', amountCents: 3_333 },
      { participantId: 'chan', amountCents: 3_333 },
    ]);
    expect(splitEqually(10_001, participants)).toEqual([
      { participantId: 'alex', amountCents: 3_334 },
      { participantId: 'bea', amountCents: 3_334 },
      { participantId: 'chan', amountCents: 3_333 },
    ]);
  });

  it('does not depend on selection order or mutate the selection', () => {
    const selected = [participants[2], participants[0], participants[1]];
    const original = [...selected];
    expect(splitEqually(10_000, selected)).toEqual(
      splitEqually(10_000, participants),
    );
    expect(selected).toEqual(original);
  });

  it('supports non-contiguous positions after participants are archived', () => {
    expect(splitEqually(101, [participants[2], participants[0]])).toEqual([
      { participantId: 'alex', amountCents: 51 },
      { participantId: 'chan', amountCents: 50 },
    ]);
  });

  it('does not require the payer to be in the selected participants', () => {
    // Alex can pay a bill split only between Bea and Chan.
    expect(splitEqually(101, participants.slice(1))).toEqual([
      { participantId: 'bea', amountCents: 51 },
      { participantId: 'chan', amountCents: 50 },
    ]);
  });

  it('gives a sole participant the entire total', () => {
    expect(splitEqually(MAX_TOTAL_CENTS, [participants[0]])).toEqual([
      { participantId: 'alex', amountCents: MAX_TOTAL_CENTS },
    ]);
  });

  it('allows zero-cent shares when the positive total is smaller than the selection', () => {
    expect(splitEqually(1, participants)).toEqual([
      { participantId: 'alex', amountCents: 1 },
      { participantId: 'bea', amountCents: 0 },
      { participantId: 'chan', amountCents: 0 },
    ]);
  });

  it.each([
    0,
    -1,
    1.5,
    Number.NaN,
    Number.POSITIVE_INFINITY,
    Number.NEGATIVE_INFINITY,
    MAX_TOTAL_CENTS + 1,
    Number.MAX_SAFE_INTEGER,
  ])('rejects invalid total %s', (total) => {
    expect(() => splitEqually(total, participants)).toThrow(
      BadRequestException,
    );
  });

  it('rejects an empty selection', () => {
    expect(() => splitEqually(100, [])).toThrow(BadRequestException);
  });

  it('rejects duplicate participants', () => {
    expect(() =>
      splitEqually(100, [participants[0], { id: 'alex', position: 1 }]),
    ).toThrow(BadRequestException);
  });

  it('rejects duplicate positions rather than using unstable tie breaking', () => {
    expect(() =>
      splitEqually(100, [participants[0], { id: 'bea', position: 0 }]),
    ).toThrow(BadRequestException);
  });

  it.each([-1, 0.5, Number.NaN, Number.MAX_SAFE_INTEGER + 1])(
    'rejects invalid participant position %s',
    (position) => {
      expect(() => splitEqually(100, [{ id: 'alex', position }])).toThrow(
        BadRequestException,
      );
    },
  );

  it.each(['', '   '])('rejects an empty participant ID', (id) => {
    expect(() => splitEqually(100, [{ id, position: 0 }])).toThrow(
      BadRequestException,
    );
  });

  it('preserves exact totals, integer shares, and a maximum one-cent difference', () => {
    for (let count = 1; count <= 50; count++) {
      const selected = Array.from({ length: count }, (_, position) => ({
        id: `participant-${position}`,
        position,
      }));
      for (const total of [1, count, count + 1, 10_000, MAX_TOTAL_CENTS]) {
        const shares = splitEqually(total, selected);
        const amounts = shares.map((share) => share.amountCents);
        expect(shares).toHaveLength(count);
        expect(amounts.reduce((sum, amount) => sum + amount, 0)).toBe(total);
        expect(amounts.every(Number.isSafeInteger)).toBe(true);
        expect(amounts.every((amount) => amount >= 0)).toBe(true);
        expect(Math.max(...amounts) - Math.min(...amounts)).toBeLessThanOrEqual(
          1,
        );
      }
    }
  });
});
