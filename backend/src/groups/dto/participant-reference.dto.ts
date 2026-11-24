import { ApiProperty } from '@nestjs/swagger';

export class ParticipantReferenceDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  archived: boolean;
}
