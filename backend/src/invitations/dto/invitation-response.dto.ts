import { ApiProperty } from '@nestjs/swagger';

export class InvitationResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  groupId: string;

  @ApiProperty()
  groupName: string;

  @ApiProperty({ enum: ['PENDING', 'ACCEPTED', 'DECLINED', 'CANCELLED'] })
  status: string;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt: Date;
}
