import { validateJwtSecret } from './auth.constants';

describe('JWT signing configuration', () => {
  it.each([undefined, '', 'short-secret', 'z'.repeat(64)])(
    'rejects missing, short, or invalid key without revealing it: %#',
    (value) => {
      expect(() => validateJwtSecret(value)).toThrow(
        'JWT_SECRET must be a randomly generated 32-byte hex value.',
      );
    },
  );

  it('accepts the generated-key format', () => {
    const key = 'a'.repeat(64);
    expect(validateJwtSecret(key)).toBe(key);
  });
});
