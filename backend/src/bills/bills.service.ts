import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { Prisma } from '../generated/prisma/client';
import { CreateBillDto } from './dto/create-bill.dto';
import { splitEqually } from './equal-split';

const operation = 'bill.create';
const personSelect = { id: true, name: true, archived: true } as const;
const billSelect = {
  id: true,
  groupId: true,
  description: true,
  billDate: true,
  totalCents: true,
  currency: true,
  createdAt: true,
  payer: { select: personSelect },
  shares: {
    select: { amountCents: true, participant: { select: personSelect } },
    orderBy: { participant: { position: 'asc' } },
  },
} as const satisfies Prisma.BillSelect;

type SelectedBill = Prisma.BillGetPayload<{ select: typeof billSelect }>;

function response(bill: SelectedBill) {
  return { ...bill, billDate: bill.billDate.toISOString().slice(0, 10) };
}

@Injectable()
export class BillsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    ownerId: string,
    groupId: string,
    key: string | undefined,
    body: CreateBillDto,
  ) {
    if (!key || !/^[A-Za-z0-9._:-]{1,128}$/.test(key)) {
      throw new BadRequestException(
        'Idempotency-Key must be 1-128 letters, digits, or . _ : - characters.',
      );
    }

    const billDate = new Date(`${body.billDate}T00:00:00.000Z`);
    if (
      body.billDate.startsWith('0000-') ||
      Number.isNaN(billDate.getTime()) ||
      billDate.toISOString().slice(0, 10) !== body.billDate
    ) {
      throw new BadRequestException('Bill date must be a valid calendar date.');
    }

    const normalizedGroupId = groupId.toLowerCase();
    const participantIds = [...body.participantIds].sort();
    const payload = JSON.stringify({
      groupId: normalizedGroupId,
      description: body.description,
      billDate: body.billDate,
      totalCents: body.totalCents,
      payerId: body.payerId,
      participantIds,
    });

    const result = await this.prisma.$transaction(async (tx) => {
      // Serialize retries for this account, even when they target different groups.
      const owner = await tx.$queryRaw<{ id: string }[]>`
        SELECT "id" FROM "Account" WHERE "id" = ${ownerId}::uuid FOR UPDATE
      `;
      if (!owner.length) throw new UnauthorizedException('Account not found.');

      const previous = await tx.idempotencyRequest.findUnique({
        where: { ownerId_operation_key: { ownerId, operation, key } },
        select: { payload: true, billId: true },
      });
      if (previous) {
        if (previous.payload !== payload) {
          throw new ConflictException(
            'Idempotency-Key was already used for a different request.',
          );
        }
        return tx.bill.findFirstOrThrow({
          where: {
            id: previous.billId,
            groupId: normalizedGroupId,
            group: { ownerId },
          },
          select: billSelect,
        });
      }

      // Participant changes take the same group lock.
      const group = await tx.group.updateMany({
        where: { id: normalizedGroupId, ownerId },
        data: { nextParticipantPosition: { increment: 0 } },
      });
      if (!group.count) throw new NotFoundException('Group not found.');

      const requiredIds = [...new Set([body.payerId, ...participantIds])];
      const participants = await tx.participant.findMany({
        where: {
          groupId: normalizedGroupId,
          id: { in: requiredIds },
          archived: false,
        },
        select: { id: true, position: true },
      });
      if (participants.length !== requiredIds.length) {
        throw new BadRequestException(
          'Payer and split participants must be active members of this group.',
        );
      }
      const selectedIds = new Set(participantIds);
      const shares = splitEqually(
        body.totalCents,
        participants.filter((participant) => selectedIds.has(participant.id)),
      );
      const bill = await tx.bill.create({
        data: {
          groupId: normalizedGroupId,
          payerId: body.payerId,
          description: body.description,
          billDate,
          totalCents: body.totalCents,
        },
        select: { id: true },
      });
      await tx.billShare.createMany({
        data: shares.map((share) => ({
          billId: bill.id,
          groupId: normalizedGroupId,
          participantId: share.participantId,
          amountCents: share.amountCents,
        })),
      });
      await tx.idempotencyRequest.create({
        data: { ownerId, operation, key, payload, billId: bill.id },
      });
      return tx.bill.findUniqueOrThrow({
        where: { id: bill.id },
        select: billSelect,
      });
    });
    return response(result);
  }

  async list(ownerId: string, groupId: string) {
    const group = await this.prisma.group.findFirst({
      where: { id: groupId, ownerId },
      select: { id: true },
    });
    if (!group) throw new NotFoundException('Group not found.');
    const bills = await this.prisma.bill.findMany({
      where: { groupId, group: { ownerId } },
      select: billSelect,
      orderBy: [{ billDate: 'desc' }, { createdAt: 'desc' }, { id: 'asc' }],
    });
    return bills.map(response);
  }

  async detail(ownerId: string, groupId: string, billId: string) {
    const bill = await this.prisma.bill.findFirst({
      where: { id: billId, groupId, group: { ownerId } },
      select: billSelect,
    });
    if (!bill) throw new NotFoundException('Bill not found.');
    return response(bill);
  }
}
