import {
  Body,
  Controller,
  Get,
  Header,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { NameDto } from '../groups/dto/name.dto';
import { UserResponseDto } from '../users/dto/user-response.dto';
import { AcceptedInvitationResponseDto } from './dto/accepted-invitation-response.dto';
import { CreateInvitationDto } from './dto/create-invitation.dto';
import { InvitationResponseDto } from './dto/invitation-response.dto';
import { OwnerInvitationResponseDto } from './dto/owner-invitation-response.dto';
import { InvitationsService } from './invitations.service';

@ApiTags('Invitations')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Authentication required.' })
@Controller('groups/:groupId/invitations')
export class GroupInvitationsController {
  constructor(private readonly invitations: InvitationsService) {}

  @Post()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Invite a registered account by exact email' })
  @ApiCreatedResponse({ type: OwnerInvitationResponseDto })
  @ApiBadRequestResponse({ description: 'Invalid group ID or email.' })
  @ApiNotFoundResponse({ description: 'Group or account not found.' })
  @ApiConflictResponse({
    description: 'Account cannot be invited to this group.',
  })
  @ApiTooManyRequestsResponse({ description: 'Rate limit exceeded.' })
  send(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Body() body: CreateInvitationDto,
  ) {
    return this.invitations.send(user.id, groupId, body.email);
  }

  @Get()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'List invitations sent to a group' })
  @ApiOkResponse({ type: OwnerInvitationResponseDto, isArray: true })
  @ApiNotFoundResponse({ description: 'Group not found.' })
  list(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
  ) {
    return this.invitations.listSent(user.id, groupId);
  }

  @Patch(':invitationId/cancel')
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Cancel a pending invitation' })
  @ApiOkResponse({ type: OwnerInvitationResponseDto })
  @ApiNotFoundResponse({ description: 'Group or invitation not found.' })
  @ApiConflictResponse({ description: 'Invitation is not pending.' })
  cancel(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Param('invitationId', ParseUUIDPipe) invitationId: string,
  ) {
    return this.invitations.cancel(user.id, groupId, invitationId);
  }
}

@ApiTags('Invitations')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Authentication required.' })
@Controller('invitations')
export class InvitationsController {
  constructor(private readonly invitations: InvitationsService) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'List your pending invitations' })
  @ApiOkResponse({ type: InvitationResponseDto, isArray: true })
  list(@CurrentUser() user: UserResponseDto) {
    return this.invitations.listReceived(user.id);
  }

  @Post(':invitationId/accept')
  @HttpCode(200)
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Accept an invitation and choose a group name' })
  @ApiOkResponse({ type: AcceptedInvitationResponseDto })
  @ApiBadRequestResponse({ description: 'Invalid invitation ID or name.' })
  @ApiNotFoundResponse({ description: 'Invitation not found.' })
  @ApiConflictResponse({ description: 'Invitation cannot be accepted.' })
  accept(
    @CurrentUser() user: UserResponseDto,
    @Param('invitationId', ParseUUIDPipe) invitationId: string,
    @Body() body: NameDto,
  ) {
    return this.invitations.accept(user.id, invitationId, body.name);
  }

  @Post(':invitationId/decline')
  @HttpCode(200)
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Decline an invitation' })
  @ApiOkResponse({ type: InvitationResponseDto })
  @ApiNotFoundResponse({ description: 'Invitation not found.' })
  @ApiConflictResponse({ description: 'Invitation is not pending.' })
  decline(
    @CurrentUser() user: UserResponseDto,
    @Param('invitationId', ParseUUIDPipe) invitationId: string,
  ) {
    return this.invitations.decline(user.id, invitationId);
  }
}
