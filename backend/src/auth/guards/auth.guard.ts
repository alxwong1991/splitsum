import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { isUUID } from 'class-validator';
import { JsonWebTokenError } from 'jsonwebtoken';
import { UsersService } from '../../users/users.service';
import { AuthenticatedRequest } from '../decorators/current-user.decorator';
import { IS_PUBLIC } from '../decorators/public.decorator';
import { JWT_AUDIENCE, JWT_ISSUER } from '../auth.constants';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwt: JwtService,
    private readonly users: UsersService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (
      this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, [
        context.getHandler(),
        context.getClass(),
      ])
    )
      return true;

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authorization = request.headers.authorization;
    const match = authorization?.match(/^Bearer ([^\s]+)$/i);
    if (!match || match[1].length > 4096) {
      throw new UnauthorizedException('Authentication required.');
    }

    const payload: unknown = await this.jwt
      .verifyAsync(match[1], {
        algorithms: ['HS256'],
        issuer: JWT_ISSUER,
        audience: JWT_AUDIENCE,
      })
      .catch((error: unknown) => {
        if (error instanceof JsonWebTokenError) {
          throw new UnauthorizedException('Invalid or expired access token.');
        }
        throw error;
      });
    if (
      typeof payload !== 'object' ||
      payload === null ||
      !('sub' in payload) ||
      typeof payload.sub !== 'string' ||
      !isUUID(payload.sub) ||
      !('exp' in payload) ||
      typeof payload.exp !== 'number'
    ) {
      throw new UnauthorizedException('Invalid or expired access token.');
    }
    const user = await this.users.findById(payload.sub);
    if (!user)
      throw new UnauthorizedException('Invalid or expired access token.');
    request.user = user;
    return true;
  }
}
