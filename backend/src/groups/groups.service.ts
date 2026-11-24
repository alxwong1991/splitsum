import {
  ConflictException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { Prisma } from '../generated/prisma/client';
import { lockOwnedGroup } from './group-lock';
import { accessibleGroup } from './group-access';

const groupSelect = {
  id: true,
  name: true,
  selfParticipantId: true,
  createdAt: true,
} as const;

const participantSelect = {
  id: true,
  name: true,
  position: true,
  archived: true,
  createdAt: true,
  accountId: true,
} as const;

function participantResponse<T extends { accountId: string | null }>(
  participant: T,
) {
  const { accountId, ...rest } = participant;
  return { ...rest, linkedAccount: accountId !== null };
}

@Injectable()
export class GroupsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(ownerId: string, name: string) {
    const group = await this.prisma.group.create({
      data: { ownerId, name },
      select: groupSelect,
    });
    return { ...group, role: 'owner' as const };
  }

  async list(accountId: string) {
    const groups = await this.prisma.$transaction(
      (tx) =>
        tx.group.findMany({
          where: accessibleGroup(accountId),
          select: {
            ...groupSelect,
            ownerId: true,
            participants: {
              where: { accountId, archived: false },
              select: { id: true },
            },
          },
          orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
        }),
      { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead },
    );
    return groups.map(({ ownerId, participants, ...group }) => {
      if (ownerId === accountId) {
        return { ...group, role: 'owner' as const };
      }
      const self = participants[0];
      if (!self) {
        throw new InternalServerErrorException(
          'Unable to verify group membership.',
        );
      }
      return {
        ...group,
        role: 'member' as const,
        selfParticipantId: self.id,
      };
    });
  }

  async detail(accountId: string, groupId: string) {
    const group = await this.prisma.$transaction(
      (tx) =>
        tx.group.findFirst({
          where: { id: groupId, ...accessibleGroup(accountId) },
          select: {
            ...groupSelect,
            ownerId: true,
            participants: {
              select: participantSelect,
              orderBy: { position: 'asc' },
            },
          },
        }),
      { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead },
    );
    if (!group) throw new NotFoundException('Group not found.');
    const { ownerId, participants, ...fields } = group;
    const self = participants.find(
      (participant) =>
        participant.accountId === accountId && !participant.archived,
    );
    if (ownerId !== accountId && !self) {
      throw new NotFoundException('Group not found.');
    }
    return {
      ...fields,
      role: ownerId === accountId ? ('owner' as const) : ('member' as const),
      selfParticipantId:
        ownerId === accountId ? fields.selfParticipantId : (self?.id ?? null),
      participants: participants.map(participantResponse),
    };
  }

  async rename(ownerId: string, groupId: string, name: string) {
    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.group.updateMany({
        where: { id: groupId, ownerId },
        data: { name },
      });
      if (!updated.count) throw new NotFoundException('Group not found.');
      const group = await tx.group.findUniqueOrThrow({
        where: { id: groupId },
        select: groupSelect,
      });
      return { ...group, role: 'owner' as const };
    });
  }

  async addParticipant(ownerId: string, groupId: string, name: string) {
    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.group.updateMany({
        where: { id: groupId, ownerId },
        data: { nextParticipantPosition: { increment: 1 } },
      });
      if (!updated.count) throw new NotFoundException('Group not found.');
      const group = await tx.group.findUniqueOrThrow({
        where: { id: groupId },
        select: { nextParticipantPosition: true },
      });
      const participant = await tx.participant.create({
        data: { groupId, name, position: group.nextParticipantPosition - 1 },
        select: participantSelect,
      });
      return participantResponse(participant);
    });
  }

  async renameParticipant(
    ownerId: string,
    groupId: string,
    participantId: string,
    name: string,
  ) {
    return this.prisma.$transaction(async (tx) => {
      await lockOwnedGroup(tx, ownerId, groupId);
      const participant = await this.findParticipant(
        tx,
        groupId,
        participantId,
      );
      if (participant.archived) {
        throw new ConflictException('Archived participants cannot be renamed.');
      }
      if (participant.accountId !== null) {
        throw new ConflictException(
          'Joined participants choose their own name.',
        );
      }
      const updated = await tx.participant.update({
        where: { id: participantId },
        data: { name },
        select: participantSelect,
      });
      return participantResponse(updated);
    });
  }

  async archiveParticipant(
    ownerId: string,
    groupId: string,
    participantId: string,
  ) {
    return this.prisma.$transaction(async (tx) => {
      await lockOwnedGroup(tx, ownerId, groupId);
      await this.findParticipant(tx, groupId, participantId);
      await tx.group.updateMany({
        where: { id: groupId, selfParticipantId: participantId },
        data: { selfParticipantId: null },
      });
      const updated = await tx.participant.update({
        where: { id: participantId },
        data: { archived: true },
        select: participantSelect,
      });
      return participantResponse(updated);
    });
  }

  async setSelf(
    ownerId: string,
    groupId: string,
    participantId: string | null,
  ) {
    return this.prisma.$transaction(async (tx) => {
      await lockOwnedGroup(tx, ownerId, groupId);
      if (participantId !== null) {
        const participant = await this.findParticipant(
          tx,
          groupId,
          participantId,
        );
        if (participant.archived) {
          throw new ConflictException(
            'An archived participant cannot represent you.',
          );
        }
        if (
          participant.accountId !== null &&
          participant.accountId !== ownerId
        ) {
          throw new ConflictException(
            'A joined participant cannot represent the owner.',
          );
        }
      }
      const updated = await tx.group.update({
        where: { id: groupId },
        data: { selfParticipantId: participantId },
        select: groupSelect,
      });
      return { ...updated, role: 'owner' as const };
    });
  }

  private async findParticipant(
    tx: Prisma.TransactionClient,
    groupId: string,
    participantId: string,
  ) {
    const participant = await tx.participant.findFirst({
      where: { id: participantId, groupId },
      select: { archived: true, accountId: true },
    });
    if (!participant) throw new NotFoundException('Participant not found.');
    return participant;
  }
}
