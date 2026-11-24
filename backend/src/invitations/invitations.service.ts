import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { InvitationStatus, Prisma } from '../generated/prisma/client';
import { lockOwnedGroup } from '../groups/group-lock';

const invitationSelect = {
  id: true,
  groupId: true,
  status: true,
  createdAt: true,
  group: { select: { name: true } },
} as const satisfies Prisma.GroupInvitationSelect;

const ownerSelect = {
  ...invitationSelect,
  recipient: { select: { email: true } },
} as const satisfies Prisma.GroupInvitationSelect;

type SelectedInvitation = Prisma.GroupInvitationGetPayload<{
  select: typeof invitationSelect;
}>;
type OwnerInvitation = Prisma.GroupInvitationGetPayload<{
  select: typeof ownerSelect;
}>;

function invitationResponse({ group, ...invitation }: SelectedInvitation) {
  return { ...invitation, groupName: group.name };
}

function ownerResponse({ recipient, ...invitation }: OwnerInvitation) {
  return { ...invitationResponse(invitation), recipientEmail: recipient.email };
}

@Injectable()
export class InvitationsService {
  constructor(private readonly prisma: PrismaService) {}

  async send(ownerId: string, groupId: string, email: string) {
    return this.prisma.$transaction(async (tx) => {
      await lockOwnedGroup(tx, ownerId, groupId);
      const recipient = await tx.account.findUnique({
        where: { email },
        select: { id: true },
      });
      if (!recipient) throw new NotFoundException('Account not found.');
      if (recipient.id === ownerId) {
        throw new ConflictException('You cannot invite yourself.');
      }
      const participant = await tx.participant.findUnique({
        where: { groupId_accountId: { groupId, accountId: recipient.id } },
        select: { archived: true },
      });
      if (participant) {
        throw new ConflictException(
          participant.archived
            ? 'Rejoining an archived member is not supported yet.'
            : 'This account has already joined the group.',
        );
      }
      const pending = await tx.groupInvitation.findFirst({
        where: { groupId, recipientId: recipient.id, status: 'PENDING' },
        select: ownerSelect,
      });
      if (pending) return ownerResponse(pending);
      const invitation = await tx.groupInvitation.create({
        data: { groupId, recipientId: recipient.id },
        select: ownerSelect,
      });
      return ownerResponse(invitation);
    });
  }

  async listSent(ownerId: string, groupId: string) {
    const group = await this.prisma.group.findFirst({
      where: { id: groupId, ownerId },
      select: { id: true },
    });
    if (!group) throw new NotFoundException('Group not found.');
    const invitations = await this.prisma.groupInvitation.findMany({
      where: { groupId, group: { ownerId } },
      select: ownerSelect,
      orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
    });
    return invitations.map(ownerResponse);
  }

  async cancel(ownerId: string, groupId: string, invitationId: string) {
    return this.prisma.$transaction(async (tx) => {
      await lockOwnedGroup(tx, ownerId, groupId);
      const invitation = await tx.groupInvitation.findFirst({
        where: { id: invitationId, groupId },
        select: { id: true, status: true },
      });
      if (!invitation) throw new NotFoundException('Invitation not found.');
      if (invitation.status === 'CANCELLED') {
        const existing = await tx.groupInvitation.findUniqueOrThrow({
          where: { id: invitation.id },
          select: ownerSelect,
        });
        return ownerResponse(existing);
      }
      if (invitation.status !== 'PENDING') {
        throw new ConflictException(
          'Only pending invitations can be cancelled.',
        );
      }
      const updated = await tx.groupInvitation.update({
        where: { id: invitation.id },
        data: { status: 'CANCELLED' },
        select: ownerSelect,
      });
      return ownerResponse(updated);
    });
  }

  async listReceived(accountId: string) {
    const invitations = await this.prisma.groupInvitation.findMany({
      where: { recipientId: accountId, status: 'PENDING' },
      select: invitationSelect,
      orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
    });
    return invitations.map(invitationResponse);
  }

  async accept(accountId: string, invitationId: string, name: string) {
    return this.prisma.$transaction(async (tx) => {
      const groupId = await this.lockInvitationGroup(
        tx,
        accountId,
        invitationId,
      );
      const invitation = await tx.groupInvitation.findFirstOrThrow({
        where: { id: invitationId, recipientId: accountId, groupId },
        select: {
          ...invitationSelect,
          acceptedName: true,
          acceptedParticipant: {
            select: {
              id: true,
              name: true,
              position: true,
              archived: true,
              createdAt: true,
            },
          },
        },
      });
      if (invitation.status === InvitationStatus.ACCEPTED) {
        if (invitation.acceptedName !== name) {
          throw new ConflictException(
            'Invitation was accepted with a different name.',
          );
        }
        if (
          !invitation.acceptedParticipant ||
          invitation.acceptedParticipant.archived
        ) {
          throw new ConflictException('This membership is no longer active.');
        }
        const {
          acceptedName: _name,
          acceptedParticipant,
          ...fields
        } = invitation;
        return {
          ...invitationResponse(fields),
          participant: { ...acceptedParticipant, linkedAccount: true },
        };
      }
      if (invitation.status !== InvitationStatus.PENDING) {
        throw new ConflictException('Invitation is no longer pending.');
      }
      const existing = await tx.participant.findUnique({
        where: { groupId_accountId: { groupId, accountId } },
        select: { id: true },
      });
      if (existing) {
        throw new ConflictException(
          'This account has already joined this group.',
        );
      }
      const group = await tx.group.update({
        where: { id: groupId },
        data: { nextParticipantPosition: { increment: 1 } },
        select: { nextParticipantPosition: true },
      });
      const participant = await tx.participant.create({
        data: {
          groupId,
          accountId,
          name,
          position: group.nextParticipantPosition - 1,
        },
        select: {
          id: true,
          name: true,
          position: true,
          archived: true,
          createdAt: true,
        },
      });
      const accepted = await tx.groupInvitation.update({
        where: { id: invitationId },
        data: {
          status: 'ACCEPTED',
          acceptedParticipantId: participant.id,
          acceptedName: name,
        },
        select: invitationSelect,
      });
      return {
        ...invitationResponse(accepted),
        participant: { ...participant, linkedAccount: true },
      };
    });
  }

  async decline(accountId: string, invitationId: string) {
    return this.prisma.$transaction(async (tx) => {
      const groupId = await this.lockInvitationGroup(
        tx,
        accountId,
        invitationId,
      );
      const invitation = await tx.groupInvitation.findFirstOrThrow({
        where: { id: invitationId, recipientId: accountId, groupId },
        select: invitationSelect,
      });
      if (invitation.status === 'DECLINED')
        return invitationResponse(invitation);
      if (invitation.status !== 'PENDING') {
        throw new ConflictException('Invitation is no longer pending.');
      }
      const declined = await tx.groupInvitation.update({
        where: { id: invitationId },
        data: { status: 'DECLINED' },
        select: invitationSelect,
      });
      return invitationResponse(declined);
    });
  }

  private async lockInvitationGroup(
    tx: Prisma.TransactionClient,
    accountId: string,
    invitationId: string,
  ) {
    const invitation = await tx.groupInvitation.findFirst({
      where: { id: invitationId, recipientId: accountId },
      select: { groupId: true },
    });
    if (!invitation) throw new NotFoundException('Invitation not found.');
    await tx.group.update({
      where: { id: invitation.groupId },
      data: { nextParticipantPosition: { increment: 0 } },
    });
    return invitation.groupId;
  }
}
