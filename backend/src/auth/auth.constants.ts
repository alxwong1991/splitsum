export const ACCESS_TOKEN_SECONDS = 1800;
export const JWT_ISSUER = 'splitsum';
export const JWT_AUDIENCE = 'splitsum-api';

export function validateJwtSecret(value: unknown): string {
  if (typeof value !== 'string' || !/^[a-f0-9]{64}$/i.test(value)) {
    throw new Error(
      'JWT_SECRET must be a randomly generated 32-byte hex value.',
    );
  }
  return value;
}
