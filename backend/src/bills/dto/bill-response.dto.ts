import { ApiProperty } from '@nestjs/swagger';
import { ParticipantReferenceDto } from '../../groups/dto/participant-reference.dto';
import { BillShareDto } from './bill-share.dto';

export class BillResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  groupId: string;

  @ApiProperty()
  description: string;

  @ApiProperty({ format: 'date', example: '2026-11-24' })
  billDate: string;

  @ApiProperty()
  totalCents: number;

  @ApiProperty({ enum: ['HKD'] })
  currency: string;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt: Date;

  @ApiProperty({ type: ParticipantReferenceDto })
  payer: ParticipantReferenceDto;

  @ApiProperty({ type: [BillShareDto] })
  shares: BillShareDto[];
}
