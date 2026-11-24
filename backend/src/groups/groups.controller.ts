import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
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
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserResponseDto } from '../users/dto/user-response.dto';
import { GroupDetailResponseDto } from './dto/group-detail-response.dto';
import { GroupResponseDto } from './dto/group-response.dto';
import { NameDto } from './dto/name.dto';
import { ParticipantResponseDto } from './dto/participant-response.dto';
import { SelfParticipantDto } from './dto/self-participant.dto';
import { GroupsService } from './groups.service';

@ApiTags('Groups')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Authentication required.' })
@Controller('groups')
export class GroupsController {
  constructor(private readonly groups: GroupsService) {}

  @Post()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Create a group' })
  @ApiCreatedResponse({ type: GroupResponseDto })
  @ApiBadRequestResponse({ description: 'Invalid group name.' })
  create(@CurrentUser() user: UserResponseDto, @Body() body: NameDto) {
    return this.groups.create(user.id, body.name);
  }

  @Get()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'List your groups' })
  @ApiOkResponse({ type: GroupResponseDto, isArray: true })
  list(@CurrentUser() user: UserResponseDto) {
    return this.groups.list(user.id);
  }

  @Get(':groupId')
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Get a group and its participants' })
  @ApiOkResponse({ type: GroupDetailResponseDto })
  @ApiBadRequestResponse({ description: 'Invalid group ID.' })
  @ApiNotFoundResponse({ description: 'Group not found.' })
  detail(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
  ) {
    return this.groups.detail(user.id, groupId);
  }

  @Patch(':groupId')
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Rename a group' })
  @ApiOkResponse({ type: GroupResponseDto })
  @ApiBadRequestResponse({ description: 'Invalid group ID or name.' })
  @ApiNotFoundResponse({ description: 'Group not found.' })
  rename(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Body() body: NameDto,
  ) {
    return this.groups.rename(user.id, groupId, body.name);
  }

  @Post(':groupId/participants')
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Add a named participant' })
  @ApiCreatedResponse({ type: ParticipantResponseDto })
  @ApiBadRequestResponse({ description: 'Invalid group ID or name.' })
  @ApiNotFoundResponse({ description: 'Group not found.' })
  addParticipant(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Body() body: NameDto,
  ) {
    return this.groups.addParticipant(user.id, groupId, body.name);
  }

  @Patch(':groupId/participants/:participantId')
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Rename a participant' })
  @ApiOkResponse({ type: ParticipantResponseDto })
  @ApiBadRequestResponse({ description: 'Invalid ID or name.' })
  @ApiNotFoundResponse({ description: 'Group or participant not found.' })
  @ApiConflictResponse({ description: 'Participant is archived.' })
  renameParticipant(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Param('participantId', ParseUUIDPipe) participantId: string,
    @Body() body: NameDto,
  ) {
    return this.groups.renameParticipant(
      user.id,
      groupId,
      participantId,
      body.name,
    );
  }

  @Patch(':groupId/participants/:participantId/archive')
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Archive a participant' })
  @ApiOkResponse({ type: ParticipantResponseDto })
  @ApiBadRequestResponse({ description: 'Invalid ID.' })
  @ApiNotFoundResponse({ description: 'Group or participant not found.' })
  archiveParticipant(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Param('participantId', ParseUUIDPipe) participantId: string,
  ) {
    return this.groups.archiveParticipant(user.id, groupId, participantId);
  }

  @Put(':groupId/self')
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Set or clear the participant representing you' })
  @ApiOkResponse({ type: GroupResponseDto })
  @ApiBadRequestResponse({
    description: 'Invalid ID or participant selection.',
  })
  @ApiNotFoundResponse({ description: 'Group or participant not found.' })
  @ApiConflictResponse({ description: 'Participant is archived.' })
  setSelf(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Body() body: SelfParticipantDto,
  ) {
    return this.groups.setSelf(user.id, groupId, body.participantId);
  }
}
