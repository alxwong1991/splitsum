import { Prisma } from '../generated/prisma/client';

export function accessibleGroup(accountId: string): Prisma.GroupWhereInput {
  return {
    OR: [
      { ownerId: accountId },
      { participants: { some: { accountId, archived: false } } },
    ],
  };
}
