import { Module } from "@nestjs/common";
import { PlatformModule } from "../platform/platform.module";
import { AdminController } from "./admin.controller";
import { AdminService } from "./admin.service";

@Module({
  imports: [PlatformModule],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
