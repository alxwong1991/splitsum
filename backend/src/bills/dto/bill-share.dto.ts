import { ApiProperty } from '@nestjs/swagger';
import { BillParticipantDto } from './bill-participant.dto';

export class BillShareDto {
  @ApiProperty({ type: BillParticipantDto })
  participant: BillParticipantDto;

  @ApiProperty({ minimum: 0 })
  amountCents: number;
}
