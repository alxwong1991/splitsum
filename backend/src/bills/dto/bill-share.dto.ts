import { ApiProperty } from '@nestjs/swagger';
import { ParticipantReferenceDto } from '../../groups/dto/participant-reference.dto';

export class BillShareDto {
  @ApiProperty({ type: ParticipantReferenceDto })
  participant: ParticipantReferenceDto;

  @ApiProperty({ minimum: 0 })
  amountCents: number;
}
