import { BadRequestException } from '@nestjs/common';

export const MAX_TOTAL_CENTS = 2_147_483_647;

export interface SplitParticipant {
  id: string;
  position: number;
}

export interface EqualShare {
  participantId: string;
  amountCents: number;
}

export function splitEqually(
  totalCents: number,
  participants: readonly SplitParticipant[],
): EqualShare[] {
  if (
    !Number.isSafeInteger(totalCents) ||
    totalCents <= 0 ||
    totalCents > MAX_TOTAL_CENTS
  ) {
    throw new BadRequestException(
      `Total must be an integer between 1 and ${MAX_TOTAL_CENTS} HKD cents.`,
    );
  }

  if (participants.length === 0) {
    throw new BadRequestException('Select at least one participant.');
  }

  const ids = new Set<string>();
  const positions = new Set<number>();

  for (const participant of participants) {
    if (
      typeof participant.id !== 'string' ||
      participant.id.trim().length === 0 ||
      !Number.isSafeInteger(participant.position) ||
      participant.position < 0
    ) {
      throw new BadRequestException(
        'Participants must have an ID and a non-negative integer position.',
      );
    }
    if (ids.has(participant.id) || positions.has(participant.position)) {
      throw new BadRequestException(
        'Participant IDs and positions must be unique.',
      );
    }
    ids.add(participant.id);
    positions.add(participant.position);
  }

  const ordered = [...participants].sort((a, b) => a.position - b.position);
  const baseCents = Math.floor(totalCents / ordered.length);
  const remainderCents = totalCents % ordered.length;

  return ordered.map((participant, index) => ({
    participantId: participant.id,
    amountCents: baseCents + (index < remainderCents ? 1 : 0),
  }));
}
