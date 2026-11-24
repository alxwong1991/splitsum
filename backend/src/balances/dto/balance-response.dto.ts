import { ApiProperty } from '@nestjs/swagger';
import { ParticipantReferenceDto } from '../../groups/dto/participant-reference.dto';

export class BalanceResponseDto {
  @ApiProperty({ type: ParticipantReferenceDto })
  fromParticipant: ParticipantReferenceDto;

  @ApiProperty({ type: ParticipantReferenceDto })
  toParticipant: ParticipantReferenceDto;

  @ApiProperty({ minimum: 1, maximum: Number.MAX_SAFE_INTEGER })
  amountCents: number;
}
