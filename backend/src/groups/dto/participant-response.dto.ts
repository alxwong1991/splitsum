import { ApiProperty } from '@nestjs/swagger';

export class ParticipantResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty({ minimum: 0 })
  position: number;

  @ApiProperty()
  archived: boolean;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt: Date;
}
