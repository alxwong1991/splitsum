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
import { BillsService } from './bills.service';
import { BillResponseDto } from './dto/bill-response.dto';
import { CreateBillDto } from './dto/create-bill.dto';

@ApiTags('Bills')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Authentication required.' })
@Controller('groups/:groupId/bills')
export class BillsController {
  constructor(private readonly bills: BillsService) {}

  @Post()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Create an equally split HKD bill' })
  @ApiHeader({
    name: 'Idempotency-Key',
    required: true,
    description:
      'Unique retry key, 1-128 letters, digits, or . _ : - characters.',
  })
  @ApiCreatedResponse({ type: BillResponseDto })
  @ApiBadRequestResponse({
    description: 'Invalid bill, participants, or retry key.',
  })
  @ApiNotFoundResponse({ description: 'Group not found.' })
  @ApiConflictResponse({ description: 'Retry key used for different input.' })
  create(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Headers('idempotency-key') key: string | undefined,
    @Body() body: CreateBillDto,
  ) {
    return this.bills.create(user.id, groupId, key, body);
  }

  @Get()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'List a group’s bill history' })
  @ApiOkResponse({ type: BillResponseDto, isArray: true })
  @ApiNotFoundResponse({ description: 'Group not found.' })
  list(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
  ) {
    return this.bills.list(user.id, groupId);
  }

  @Get(':billId')
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'Get bill details and shares' })
  @ApiOkResponse({ type: BillResponseDto })
  @ApiNotFoundResponse({ description: 'Bill not found.' })
  detail(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
    @Param('billId', ParseUUIDPipe) billId: string,
  ) {
    return this.bills.detail(user.id, groupId, billId);
  }
}
