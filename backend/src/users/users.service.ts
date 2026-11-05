import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { UserResponseDto } from './dto/user-response.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<UserResponseDto | null> {
    return this.prisma.account.findUnique({
      where: { id },
      select: { id: true, email: true, createdAt: true },
    });
  }
}
