import {
  ConflictException,
  Injectable,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomBytes } from 'node:crypto';
import * as argon2 from 'argon2';
import { PrismaService } from '../database/prisma.service';
import { Prisma } from '../generated/prisma/client';
import { AuthResponseDto } from './dto/auth-response.dto';
import { CredentialsDto } from './dto/credentials.dto';
import { ACCESS_TOKEN_SECONDS } from './auth.constants';
import { USER_SELECT } from '../users/users.service';

@Injectable()
export class AuthService implements OnModuleInit {
  private dummyHash: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async onModuleInit(): Promise<void> {
    this.dummyHash = await this.hash(randomBytes(32).toString('hex'));
  }

  private hash(password: string): Promise<string> {
    return argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 19456,
      timeCost: 2,
      parallelism: 1,
    });
  }

  async register(credentials: CredentialsDto): Promise<AuthResponseDto> {
    const passwordHash = await this.hash(credentials.password);
    const user = await this.prisma.account
      .create({
        data: { email: credentials.email, passwordHash },
        select: USER_SELECT,
      })
      .catch((error: unknown) => {
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002'
        ) {
          throw new ConflictException('Unable to register with these details.');
        }
        throw error;
      });
    return this.issueToken(user);
  }

  async login(credentials: CredentialsDto): Promise<AuthResponseDto> {
    const account = await this.prisma.account.findUnique({
      where: { email: credentials.email },
    });
    // Unknown accounts still perform an expensive password verification.
    const valid = await argon2.verify(
      account?.passwordHash ?? this.dummyHash,
      credentials.password,
    );
    if (!account || !valid) {
      throw new UnauthorizedException('Invalid email or password.');
    }
    return this.issueToken({
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      createdAt: account.createdAt,
    });
  }

  private async issueToken(
    user: AuthResponseDto['user'],
  ): Promise<AuthResponseDto> {
    return {
      accessToken: await this.jwt.signAsync({ sub: user.id }),
      tokenType: 'Bearer',
      expiresIn: ACCESS_TOKEN_SECONDS,
      user,
    };
  }
}
