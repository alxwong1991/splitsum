import { ApiProperty } from '@nestjs/swagger';
import { InvitationResponseDto } from './invitation-response.dto';

export class OwnerInvitationResponseDto extends InvitationResponseDto {
  @ApiProperty({ format: 'email' })
  recipientEmail: string;
}
