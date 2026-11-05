import { ApiProperty } from '@nestjs/swagger';

export class UserResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'alex@example.invalid' })
  email: string;

  @ApiProperty({ nullable: true, type: String, example: 'Alex', maxLength: 80 })
  displayName: string | null;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;
}
