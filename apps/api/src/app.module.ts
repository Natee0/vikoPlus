import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { APP_GUARD } from "@nestjs/core";
import { resolve } from "path";
import { BillingModule } from "./billing/billing.module";
import { CommonAuthModule } from "./common/auth/common-auth.module";
import { JwtAuthGuard } from "./common/auth/jwt-auth.guard";
import { envValidationSchema } from "./config/env.validation";
import { AuthModule } from "./auth/auth.module";
import { GroupsModule } from "./groups/groups.module";
import { HealthModule } from "./health/health.module";
import { PlatformModule } from "./platform/platform.module";
import { PrismaModule } from "./prisma/prisma.module";
import { RateLimitModule } from "./common/rate-limit/rate-limit.module";
import { ReportsModule } from "./reports/reports.module";
import { SubscriptionPlansModule } from "./subscription-plans/subscription-plans.module";
import { SubscriptionsModule } from "./subscriptions/subscriptions.module";
import { ThrottlerGuard } from "@nestjs/throttler";
import { AdminModule } from "./admin/admin.module";
import { UploadsModule } from "./uploads/uploads.module";

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
    CommonAuthModule,
    RateLimitModule,
    PrismaModule,
    HealthModule,
    PlatformModule,
    AdminModule,
    AuthModule,
    GroupsModule,
    BillingModule,
    SubscriptionPlansModule,
    SubscriptionsModule,
    ReportsModule,
    UploadsModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
})
export class AppModule {}
