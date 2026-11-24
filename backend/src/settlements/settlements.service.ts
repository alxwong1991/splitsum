import {
  BadRequestException,
  ConflictException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import { calculateDirectBalances } from '../balances/direct-balances';
import {
  lockAccountForIdempotency,
  requireIdempotencyKey,
} from '../common/idempotency';
import { PrismaService } from '../database/prisma.service';
import { Prisma } from '../generated/prisma/client';
import { lockOwnedGroup } from '../groups/group-lock';
import { CreateSettlementDto } from './dto/create-settlement.dto';

const operation = 'settlement.create';
const participantSelect = { id: true, name: true, archived: true } as const;
const settlementSelect = {
  id: true,
  groupId: true,
  fromParticipant: { select: participantSelect },
  toParticipant: { select: participantSelect },
  amountCents: true,
  createdAt: true,
} as const satisfies Prisma.SettlementSelect;

@Injectable()
export class SettlementsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    ownerId: string,
    groupId: string,
    key: string | undefined,
    body: CreateSettlementDto,
  ) {
    const retryKey = requireIdempotencyKey(key);
    if (body.fromParticipantId === body.toParticipantId) {
      throw new BadRequestException('Participants must be different.');
    }
    const normalizedGroupId = groupId.toLowerCase();
    const payload = JSON.stringify({
      groupId: normalizedGroupId,
      fromParticipantId: body.fromParticipantId,
      toParticipantId: body.toParticipantId,
      amountCents: body.amountCents,
    });

    return this.prisma.$transaction(async (tx) => {
      await lockAccountForIdempotency(tx, ownerId);
      const previous = await tx.idempotencyRequest.findUnique({
        where: { ownerId_operation_key: { ownerId, operation, key: retryKey } },
        select: { payload: true, settlementId: true },
      });
      if (previous) {
        if (previous.payload !== payload) {
          throw new ConflictException(
            'Idempotency-Key was already used for a different request.',
          );
        }
        if (!previous.settlementId) {
          throw new InternalServerErrorException(
            'Invalid settlement retry record.',
          );
        }
        return tx.settlement.findFirstOrThrow({
          where: {
            id: previous.settlementId,
            groupId: normalizedGroupId,
            group: { ownerId },
          },
          select: settlementSelect,
        });
      }

      await lockOwnedGroup(tx, ownerId, normalizedGroupId);
      const participantCount = await tx.participant.count({
        where: {
          groupId: normalizedGroupId,
          id: { in: [body.fromParticipantId, body.toParticipantId] },
        },
      });
      if (participantCount !== 2) {
        throw new BadRequestException(
          'Both participants must belong to this group.',
        );
      }

      const balances = await calculateDirectBalances(tx, normalizedGroupId);
      const debt = balances.find(
        (balance) =>
          balance.fromParticipant.id === body.fromParticipantId &&
          balance.toParticipant.id === body.toParticipantId,
      );
      if (!debt || body.amountCents > debt.amountCents) {
        throw new BadRequestException(
          'Settlement exceeds the outstanding direct debt.',
        );
      }

      const settlement = await tx.settlement.create({
        data: {
          groupId: normalizedGroupId,
          fromParticipantId: body.fromParticipantId,
          toParticipantId: body.toParticipantId,
          amountCents: body.amountCents,
        },
        select: settlementSelect,
      });
      await tx.group.update({
        where: { id: normalizedGroupId },
        data: { hasEverHadSettlement: true },
      });
      await tx.idempotencyRequest.create({
        data: {
          ownerId,
          operation,
          key: retryKey,
          payload,
          settlementId: settlement.id,
        },
      });
      return settlement;
    });
  }

  async list(ownerId: string, groupId: string) {
    const group = await this.prisma.group.findFirst({
      where: { id: groupId, ownerId },
      select: { id: true },
    });
    if (!group) throw new NotFoundException('Group not found.');
    return this.prisma.settlement.findMany({
      where: { groupId, group: { ownerId } },
      select: settlementSelect,
      orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
    });
  }
}
