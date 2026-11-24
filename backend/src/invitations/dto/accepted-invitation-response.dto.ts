import { ApiProperty } from '@nestjs/swagger';
import { ParticipantResponseDto } from '../../groups/dto/participant-response.dto';
import { InvitationResponseDto } from './invitation-response.dto';

export class AcceptedInvitationResponseDto extends InvitationResponseDto {
  @ApiProperty({ type: ParticipantResponseDto })
  participant: ParticipantResponseDto;
}
