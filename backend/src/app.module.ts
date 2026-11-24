import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DatabaseModule } from './database/database.module';
import { HealthController } from './health/health.controller';
import { GroupsModule } from './groups/groups.module';
import { BillsModule } from './bills/bills.module';
import { BalancesModule } from './balances/balances.module';
import { SettlementsModule } from './settlements/settlements.module';

@Module({
  imports: [
    ConfigModule.forRoot(),
    DatabaseModule,
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 60 }]),
    AuthModule,
    GroupsModule,
    BillsModule,
    BalancesModule,
    SettlementsModule,
  ],
  controllers: [AppController, HealthController],
  providers: [
    AppService,
    ThrottlerGuard,
    { provide: APP_GUARD, useExisting: ThrottlerGuard },
  ],
})
export class AppModule {}
