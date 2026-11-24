import { ApiProperty } from '@nestjs/swagger';
import { IsUUID, ValidateIf } from 'class-validator';

export class SelfParticipantDto {
  @ApiProperty({
    type: String,
    format: 'uuid',
    nullable: true,
    description: 'Active participant ID, or null to clear the selection.',
  })
  @ValidateIf((_object, value: unknown) => value !== null)
  @IsUUID()
  participantId: string | null;
}
