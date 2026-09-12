import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { Throttle } from "@nestjs/throttler";
import { CurrentUser } from "../common/auth/auth-user.decorator";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { PlatformAdminGuard } from "../common/auth/platform-admin.guard";
import { SkipGroupMembershipCheck } from "../common/auth/skip-group-membership.decorator";
import { AdminService } from "./admin.service";
import { AdminQueueService } from "./admin-queue.service";
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
@SkipGroupMembershipCheck()
@Controller({ path: "admin", version: "1" })
export class AdminController {
  constructor(
    private readonly admin: AdminService,
    private readonly queues: AdminQueueService,
  ) {}

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

  @Get("queues")
  queuesOverview() {
    return this.queues.list();
  }

  @Get("queues/:queueName/failed")
  queueFailedJobs(
    @Param("queueName") queueName: string,
    @Query("start") start?: string,
    @Query("end") end?: string,
  ) {
    return this.queues.failed(
      queueName,
      parseOptionalNumber(start, 0),
      parseOptionalNumber(end, 49),
    );
  }

  @Post("queues/:queueName/failed/:jobId/retry")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 300000 } })
  retryFailedJob(
    @Param("queueName") queueName: string,
    @Param("jobId") jobId: string,
  ) {
    return this.queues.retryFailed(queueName, jobId);
  }

  @Delete("queues/:queueName/failed")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  cleanFailedJobs(
    @Param("queueName") queueName: string,
    @Query("graceSeconds") graceSeconds?: string,
    @Query("limit") limit?: string,
  ) {
    return this.queues.cleanFailed(
      queueName,
      parseOptionalNumber(graceSeconds, 604800),
      parseOptionalNumber(limit, 1000),
    );
  }
}

function parseOptionalNumber(value: string | undefined, fallback: number) {
  if (value == null || value.trim() === "") return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}
