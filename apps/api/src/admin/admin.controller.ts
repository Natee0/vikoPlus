import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { Throttle } from "@nestjs/throttler";
import { CurrentUser } from "../common/auth/auth-user.decorator";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { PlatformAdminGuard } from "../common/auth/platform-admin.guard";
import { AdminService } from "./admin.service";
import {
  CreateAdminGroupDto,
  CreateAccessPlanDto,
  CreateReminderPackageDto,
  UpdateAdminGroupDto,
  UpdateAccessPlanDto,
  UpdateReminderPackageDto,
} from "./dto/admin-platform.dto";

@ApiBearerAuth()
@ApiTags("admin")
@UseGuards(PlatformAdminGuard)
@Controller({ path: "admin", version: "1" })
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get("metrics")
  metrics() {
    return this.admin.metrics();
  }

  @Get("groups")
  groups() {
    return this.admin.groups();
  }

  @Post("groups")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 300000 } })
  createGroup(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: CreateAdminGroupDto,
  ) {
    return this.admin.createGroup(user, body);
  }

  @Patch("groups/:groupId")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 300000 } })
  updateGroup(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: UpdateAdminGroupDto,
  ) {
    return this.admin.updateGroup(user, groupId, body);
  }

  @Delete("groups/:groupId")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  deleteGroup(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.admin.deleteGroup(user, groupId);
  }

  @Get("users")
  users() {
    return this.admin.users();
  }

  @Get("pricing")
  pricing() {
    return this.admin.packageSettings();
  }

  @Get("access-plans")
  accessPlans() {
    return this.admin.listAccessPlans();
  }

  @Post("access-plans")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 300000 } })
  createAccessPlan(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: CreateAccessPlanDto,
  ) {
    return this.admin.createAccessPlan(user, body);
  }

  @Patch("access-plans/:code")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 300000 } })
  updateAccessPlan(
    @CurrentUser() user: AuthenticatedUser,
    @Param("code") code: string,
    @Body() body: UpdateAccessPlanDto,
  ) {
    return this.admin.updateAccessPlan(user, code, body);
  }

  @Get("reminder-packages")
  reminderPackages() {
    return this.admin.listReminderPackages();
  }

  @Post("reminder-packages")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 300000 } })
  createReminderPackage(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: CreateReminderPackageDto,
  ) {
    return this.admin.createReminderPackage(user, body);
  }

  @Patch("reminder-packages/:code")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 300000 } })
  updateReminderPackage(
    @CurrentUser() user: AuthenticatedUser,
    @Param("code") code: string,
    @Body() body: UpdateReminderPackageDto,
  ) {
    return this.admin.updateReminderPackage(user, code, body);
  }
}
