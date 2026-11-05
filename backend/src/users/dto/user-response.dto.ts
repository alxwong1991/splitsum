import { ApiProperty } from '@nestjs/swagger';

export class UserResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'alex@example.invalid' })
  email: string;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;
}
