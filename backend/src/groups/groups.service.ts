import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { Prisma } from '../generated/prisma/client';
import { lockOwnedGroup } from './group-lock';

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
} as const;

@Injectable()
export class GroupsService {
  constructor(private readonly prisma: PrismaService) {}

  create(ownerId: string, name: string) {
    return this.prisma.group.create({
      data: { ownerId, name },
      select: groupSelect,
    });
  }

  list(ownerId: string) {
    return this.prisma.group.findMany({
      where: { ownerId },
      select: groupSelect,
      orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
    });
  }

  async detail(ownerId: string, groupId: string) {
    const group = await this.prisma.group.findFirst({
      where: { id: groupId, ownerId },
      select: {
        ...groupSelect,
        participants: {
          select: participantSelect,
          orderBy: { position: 'asc' },
        },
      },
    });
    if (!group) throw new NotFoundException('Group not found.');
    return group;
  }

  async rename(ownerId: string, groupId: string, name: string) {
    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.group.updateMany({
        where: { id: groupId, ownerId },
        data: { name },
      });
      if (!updated.count) throw new NotFoundException('Group not found.');
      return tx.group.findUniqueOrThrow({
        where: { id: groupId },
        select: groupSelect,
      });
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
      return tx.participant.create({
        data: { groupId, name, position: group.nextParticipantPosition - 1 },
        select: participantSelect,
      });
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
      return tx.participant.update({
        where: { id: participantId },
        data: { name },
        select: participantSelect,
      });
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
      return tx.participant.update({
        where: { id: participantId },
        data: { archived: true },
        select: participantSelect,
      });
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
      }
      return tx.group.update({
        where: { id: groupId },
        data: { selfParticipantId: participantId },
        select: groupSelect,
      });
    });
  }

  private async findParticipant(
    tx: Prisma.TransactionClient,
    groupId: string,
    participantId: string,
  ) {
    const participant = await tx.participant.findFirst({
      where: { id: participantId, groupId },
      select: { archived: true },
    });
    if (!participant) throw new NotFoundException('Participant not found.');
    return participant;
  }
}
