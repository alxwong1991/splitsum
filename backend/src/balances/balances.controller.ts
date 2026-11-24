import {
  Controller,
  Get,
  Header,
  NotFoundException,
  Param,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PrismaService } from '../database/prisma.service';
import { UserResponseDto } from '../users/dto/user-response.dto';
import { calculateDirectBalances } from './direct-balances';
import { BalanceResponseDto } from './dto/balance-response.dto';

@ApiTags('Balances')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Authentication required.' })
@Controller('groups/:groupId/balances')
export class BalancesController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({ summary: 'List outstanding direct debts' })
  @ApiOkResponse({ type: BalanceResponseDto, isArray: true })
  @ApiBadRequestResponse({ description: 'Invalid group ID.' })
  @ApiNotFoundResponse({ description: 'Group not found.' })
  async list(
    @CurrentUser() user: UserResponseDto,
    @Param('groupId', ParseUUIDPipe) groupId: string,
  ) {
    const group = await this.prisma.group.findFirst({
      where: { id: groupId, ownerId: user.id },
      select: { id: true },
    });
    if (!group) throw new NotFoundException('Group not found.');
    return calculateDirectBalances(this.prisma, groupId);
  }
}
