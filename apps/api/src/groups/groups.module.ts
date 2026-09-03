import { Module } from "@nestjs/common";

import { BillingModule } from "../billing/billing.module";
import { PrismaModule } from "../prisma/prisma.module";
import { GroupsController } from "./groups.controller";
import { GroupsService } from "./groups.service";

@Module({
  imports: [PrismaModule, BillingModule],
  controllers: [GroupsController],
  providers: [GroupsService],
})
export class GroupsModule {}
