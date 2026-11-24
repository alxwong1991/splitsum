import { ApiProperty } from '@nestjs/swagger';

export class BillParticipantDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  archived: boolean;
}
