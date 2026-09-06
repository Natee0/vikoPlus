import { ForbiddenException, NotFoundException } from "@nestjs/common";
import { GroupsService } from "../src/groups/groups.service";
import { PrismaService } from "../src/prisma/prisma.service";
import { SubscriptionBillingProvider } from "../src/billing/subscription-billing-provider";
import { BriqMessagingService } from "../src/messaging/briq-messaging.service";
import { SmtpEmailService } from "../src/messaging/smtp-email.service";
import { ReminderDispatchService } from "../src/groups/reminder-dispatch.service";

const user = { id: "admin", tokenId: "token", type: "access" as const };
function setup(role = "GROUP_ADMIN", targetRole = "MEMBER", status = "ACTIVE") {
  const target = {
    id: "member",
    groupId: "group",
    userId: "other-user",
    role: targetRole,
    status,
    group: { billingOwnerUserId: "admin" },
  };
  const db = {
    groupMember: {
      findFirst: jest
        .fn()
        .mockResolvedValueOnce({ id: "admin-member", role, status: "ACTIVE" })
        .mockResolvedValueOnce({ id: "admin-member", role, status: "ACTIVE" })
        .mockResolvedValue(target),
      update: jest.fn().mockResolvedValue(target),
    },
    groupInvitation: { updateMany: jest.fn() },
    auditLog: { create: jest.fn() },
    $transaction: jest.fn(),
  };
  db.$transaction.mockImplementation((fn: (tx: typeof db) => unknown) =>
    fn(db),
  );
  const service = new GroupsService(
    db as unknown as PrismaService,
    {} as SubscriptionBillingProvider,
    {} as BriqMessagingService,
    {} as SmtpEmailService,
    {} as ReminderDispatchService,
  );
  return { service, db };
}

describe("member access changes", () => {
  it.each(["SUSPENDED", "REMOVED"] as const)(
    "changes only membership status and retains history for %s",
    async (status) => {
      const { service, db } = setup();
      await service.updateMemberStatus(user, "group", "member", { status });
      expect(db.groupMember.update).toHaveBeenCalledWith({
        where: { id: "member", groupId: "group" },
        data: { status, deactivatedAt: expect.any(Date) },
      });
      expect(db.groupInvitation.updateMany).toHaveBeenCalledWith({
        where: { groupId: "group", groupMemberId: "member", acceptedAt: null },
        data: { expiresAt: expect.any(Date) },
      });
      expect(db.auditLog.create).toHaveBeenCalled();
    },
  );
  it.each(["MEMBER", "TREASURER", "SECRETARY"])(
    "rejects non-admin %s",
    async (role) => {
      const { service, db } = setup(role);
      await expect(
        service.updateMemberStatus(user, "group", "member", {
          status: "REMOVED",
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(db.groupMember.update).not.toHaveBeenCalled();
    },
  );
  it("protects administrator memberships", async () => {
    const { service, db } = setup("GROUP_ADMIN", "GROUP_ADMIN");
    await expect(
      service.updateMemberStatus(user, "group", "member", {
        status: "SUSPENDED",
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(db.groupMember.update).not.toHaveBeenCalled();
  });
  it("requires a target in the same group", async () => {
    const { service, db } = setup();
    db.groupMember.findFirst.mockResolvedValue(null);
    await expect(
      service.updateMemberStatus(user, "group", "member", {
        status: "REMOVED",
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(db.groupMember.findFirst).toHaveBeenLastCalledWith({
      where: { id: "member", groupId: "group" },
      include: { group: true },
    });
  });
  it("restores a linked membership without recreating it", async () => {
    const { service, db } = setup("GROUP_ADMIN", "MEMBER", "SUSPENDED");
    await service.updateMemberStatus(user, "group", "member", {
      status: "ACTIVE",
    });
    expect(db.groupMember.update).toHaveBeenCalledWith({
      where: { id: "member", groupId: "group" },
      data: { status: "ACTIVE", deactivatedAt: null },
    });
  });
});
