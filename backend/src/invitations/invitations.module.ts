import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import {
  GroupInvitationsController,
  InvitationsController,
} from './invitations.controller';
import { InvitationsService } from './invitations.service';

@Module({
  imports: [DatabaseModule],
  controllers: [GroupInvitationsController, InvitationsController],
  providers: [InvitationsService],
})
export class InvitationsModule {}
