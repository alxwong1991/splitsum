import { Body, Controller, Header, HttpCode, Post } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AuthResponseDto } from './dto/auth-response.dto';
import { CredentialsDto } from './dto/credentials.dto';
import { AuthService } from './auth.service';
import { Public } from './decorators/public.decorator';

@Public()
@ApiTags('Authentication')
@ApiBadRequestResponse({ description: 'Invalid or unexpected fields.' })
@ApiTooManyRequestsResponse({
  description: 'Rate limit exceeded; retry later.',
})
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @Header('Cache-Control', 'no-store')
  @ApiCreatedResponse({ type: AuthResponseDto })
  @ApiConflictResponse({ description: 'Cannot register with these details.' })
  register(@Body() credentials: CredentialsDto): Promise<AuthResponseDto> {
    return this.auth.register(credentials);
  }

  @Post('login')
  @HttpCode(200)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Header('Cache-Control', 'no-store')
  @ApiOkResponse({ type: AuthResponseDto })
  @ApiUnauthorizedResponse({ description: 'Invalid email or password.' })
  login(@Body() credentials: CredentialsDto): Promise<AuthResponseDto> {
    return this.auth.login(credentials);
  }
}
