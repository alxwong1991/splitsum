import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { BalancesController } from './balances.controller';

@Module({
  imports: [DatabaseModule],
  controllers: [BalancesController],
})
export class BalancesModule {}
