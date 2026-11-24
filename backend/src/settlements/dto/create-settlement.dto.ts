import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsInt, IsUUID, Max, Min } from 'class-validator';
import { MAX_TOTAL_CENTS } from '../../bills/equal-split';

export class CreateSettlementDto {
  @ApiProperty({
    format: 'uuid',
    description: 'Participant paying an existing debt.',
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase() : value,
  )
  @IsUUID()
  fromParticipantId: string;

  @ApiProperty({
    format: 'uuid',
    description: 'Participant receiving the payment.',
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase() : value,
  )
  @IsUUID()
  toParticipantId: string;

  @ApiProperty({ minimum: 1, maximum: MAX_TOTAL_CENTS, example: 5000 })
  @IsInt()
  @Min(1)
  @Max(MAX_TOTAL_CENTS)
  amountCents: number;
}
