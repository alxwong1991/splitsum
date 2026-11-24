import { ApiProperty } from '@nestjs/swagger';
import { GroupResponseDto } from './group-response.dto';
import { ParticipantResponseDto } from './participant-response.dto';

export class GroupDetailResponseDto extends GroupResponseDto {
  @ApiProperty({ type: [ParticipantResponseDto] })
  participants: ParticipantResponseDto[];
}
