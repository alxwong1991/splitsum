import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { UserResponseDto } from './dto/user-response.dto';
import { UpdateUserDto } from './dto/update-user.dto';

export const USER_SELECT = {
  id: true,
  email: true,
  displayName: true,
  createdAt: true,
} as const;

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<UserResponseDto | null> {
    return this.prisma.account.findUnique({
      where: { id },
      select: USER_SELECT,
    });
  }

  update(id: string, data: UpdateUserDto): Promise<UserResponseDto> {
    return this.prisma.account.update({
      where: { id },
      data: { displayName: data.displayName },
      select: USER_SELECT,
    });
  }
}
