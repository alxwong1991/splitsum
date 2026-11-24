import { ApiProperty } from '@nestjs/swagger';

export class GroupResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty({ type: String, format: 'uuid', nullable: true })
  selfParticipantId: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt: Date;
}
