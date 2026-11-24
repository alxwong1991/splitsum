import {
  Body,
  Controller,
  Get,
  Header,
  Headers,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiHeader,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserResponseDto } from '../users/dto/user-response.dto';
import { CreateSettlementDto } from './dto/create-settlement.dto';
import { SettlementResponseDto } from './dto/settlement-response.dto';
import { SettlementsService } from './settlements.service';

@ApiTags('Settlements')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Authentication required.' })
@Controller('groups/:groupId/settlements')
export class SettlementsController {
  constructor(private readonly settlements: SettlementsService) {}

  @Post()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Record a payment made outside SplitSum' })
  @ApiHeader({
    name: 'Idempotency-Key',
    required: true,
    description:
      'Unique retry key, 1-128 letters, digits, or . _ : - characters.',
  })
  @ApiCreatedResponse({ type: SettlementResponseDto })
  @ApiBadRequestResponse({
    description:
      'Invalid participants, amount, or retry key; or amount exceeds direct debt.',
  })
  @ApiNotFoundResponse({ description: 'Group not found.' })
  @ApiConflictResponse({ description: 'Retry key used for different input.' })
  create(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Headers('idempotency-key') key: string | undefined,
    @Body() body: CreateSettlementDto,
  ) {
    return this.settlements.create(user.id, groupId, key, body);
  }

  @Get()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'List recorded settlements' })
  @ApiOkResponse({ type: SettlementResponseDto, isArray: true })
  @ApiBadRequestResponse({ description: 'Invalid group ID.' })
  @ApiNotFoundResponse({ description: 'Group not found.' })
  list(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
  ) {
    return this.settlements.list(user.id, groupId);
  }
}
