import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { Prisma } from '../generated/prisma/client';

export function requireIdempotencyKey(key: string | undefined): string {
  if (!key || !/^[A-Za-z0-9._:-]{1,128}$/.test(key)) {
    throw new BadRequestException(
      'Idempotency-Key must be 1-128 letters, digits, or . _ : - characters.',
    );
  }
  return key;
}

export async function lockAccountForIdempotency(
  tx: Prisma.TransactionClient,
  ownerId: string,
): Promise<void> {
  const owner = await tx.$queryRaw<{ id: string }[]>`
    SELECT "id" FROM "Account" WHERE "id" = ${ownerId}::uuid FOR UPDATE
  `;
  if (!owner.length) throw new UnauthorizedException('Account not found.');
}
