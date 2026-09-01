import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { resolve } from "path";
import { BillingModule } from "./billing/billing.module";
import { envValidationSchema } from "./config/env.validation";
import { HealthModule } from "./health/health.module";
import { PrismaModule } from "./prisma/prisma.module";
import { ReportsModule } from "./reports/reports.module";
import { SubscriptionPlansModule } from "./subscription-plans/subscription-plans.module";
import { SubscriptionsModule } from "./subscriptions/subscriptions.module";

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [
        resolve(process.cwd(), ".env"),
        resolve(process.cwd(), "../../.env"),
      ],
      validationSchema: envValidationSchema,
    }),
    PrismaModule,
    HealthModule,
    BillingModule,
    SubscriptionPlansModule,
    SubscriptionsModule,
    ReportsModule,
  ],
})
export class AppModule {}
