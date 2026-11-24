import { ApiProperty } from '@nestjs/swagger';
import { ParticipantReferenceDto } from '../../groups/dto/participant-reference.dto';

export class SettlementResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  groupId: string;

  @ApiProperty({ type: ParticipantReferenceDto })
  fromParticipant: ParticipantReferenceDto;

  @ApiProperty({ type: ParticipantReferenceDto })
  toParticipant: ParticipantReferenceDto;

  @ApiProperty()
  amountCents: number;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt: Date;
}
