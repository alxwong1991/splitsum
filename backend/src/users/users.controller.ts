import { Body, Controller, Get, Header, Patch } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiBadRequestResponse,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserResponseDto } from './dto/user-response.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';

@ApiTags('Users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  @Header('Cache-Control', 'no-store')
  @ApiOkResponse({ type: UserResponseDto })
  @ApiUnauthorizedResponse({
    description: 'Missing, invalid, or expired token.',
  })
  me(@CurrentUser() user: UserResponseDto): UserResponseDto {
    return user;
  }

  @Patch('me')
  @Header('Cache-Control', 'no-store')
  @ApiOkResponse({ type: UserResponseDto })
  @ApiBadRequestResponse({
    description: 'Display name must be 1-80 characters.',
  })
  @ApiUnauthorizedResponse({ description: 'Authentication required.' })
  update(@CurrentUser() user: UserResponseDto, @Body() body: UpdateUserDto) {
    return this.users.update(user.id, body);
  }
}
