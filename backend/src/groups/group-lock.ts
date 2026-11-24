import { NotFoundException } from '@nestjs/common';
import { Prisma } from '../generated/prisma/client';

export async function lockOwnedGroup(
  tx: Prisma.TransactionClient,
  ownerId: string,
  groupId: string,
): Promise<void> {
  // Serialize changes to participants, bills, and settlements within a group.
  const updated = await tx.group.updateMany({
    where: { id: groupId, ownerId },
    data: { nextParticipantPosition: { increment: 0 } },
  });
  if (!updated.count) throw new NotFoundException('Group not found.');
}
