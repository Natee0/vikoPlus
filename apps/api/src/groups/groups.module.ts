import { Module } from "@nestjs/common";

import { BillingModule } from "../billing/billing.module";
import { MessagingModule } from "../messaging/messaging.module";
import { PrismaModule } from "../prisma/prisma.module";
import { GroupsController } from "./groups.controller";
import { GroupsService } from "./groups.service";

@Module({
  imports: [PrismaModule, BillingModule, MessagingModule],
  controllers: [GroupsController],
  providers: [GroupsService],
})
export class GroupsModule {}
