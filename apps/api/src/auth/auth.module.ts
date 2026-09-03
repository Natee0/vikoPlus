import { Module } from "@nestjs/common";

import { CommonAuthModule } from "../common/auth/common-auth.module";
import { PrismaModule } from "../prisma/prisma.module";
import { VerificationModule } from "../verification/verification.module";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";

@Module({
  imports: [PrismaModule, CommonAuthModule, VerificationModule],
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}
