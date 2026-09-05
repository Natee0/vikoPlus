import { BadRequestException, ForbiddenException } from "@nestjs/common";
import {
  ContributionFrequency,
  ContributionPlanType,
  GroupRole,
  Prisma,
} from "@prisma/client";
import { GroupsService } from "../src/groups/groups.service";
import { PrismaService } from "../src/prisma/prisma.service";
import { SubscriptionBillingProvider } from "../src/billing/subscription-billing-provider";
import { BriqMessagingService } from "../src/messaging/briq-messaging.service";
import { SmtpEmailService } from "../src/messaging/smtp-email.service";
import { ReminderDispatchService } from "../src/groups/reminder-dispatch.service";

const user = { id: "user", tokenId: "token", type: "access" as const };

function setup(role: GroupRole = GroupRole.MEMBER) {
  const db = {
    groupMember: {
      findFirst: jest
        .fn()
        .mockResolvedValue({ id: "member", role, status: "ACTIVE" }),
    },
    loanApplication: {
      findMany: jest.fn().mockResolvedValue([]),
      findFirst: jest.fn(),
      create: jest.fn(),
    },
    paymentAllocation: {
      findMany: jest.fn().mockResolvedValue([]),
      create: jest.fn(),
    },
    groupContributionPayment: {
      findFirstOrThrow: jest.fn(),
      update: jest.fn(),
    },
    memberContributionObligation: { findMany: jest.fn(), update: jest.fn() },
    groupLoan: { findFirst: jest.fn() },
    loanRepayment: { aggregate: jest.fn(), create: jest.fn() },
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
  return { db, service };
}

describe("group rule enforcement", () => {
  it("blocks approval of the treasurer's payment recorded by another user", async () => {
    const { service, db } = setup(GroupRole.TREASURER);
    db.groupContributionPayment.findFirstOrThrow.mockResolvedValue({
      id: "payment",
      createdByUserId: "another-user",
      groupMemberId: "member",
      status: "SUBMITTED",
    });
    await expect(
      service.approvePayment(user, "group", "payment", {}),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(db.groupContributionPayment.update).not.toHaveBeenCalled();
  });

  it.each([
    GroupRole.GROUP_ADMIN,
    GroupRole.TREASURER,
    GroupRole.SECRETARY,
    GroupRole.MEMBER,
  ])("lets %s view loan applications with appropriate scope", async (role) => {
    const { service, db } = setup(role);
    await service.listLoanApplications(user, "group");
    expect(db.loanApplication.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where:
          role === GroupRole.TREASURER
            ? { groupId: "group" }
            : { groupId: "group", groupMemberId: "member" },
      }),
    );
  });

  it("blocks a group admin from approving loans", async () => {
    const { service, db } = setup(GroupRole.GROUP_ADMIN);
    await expect(
      service.approveLoanApplication(user, "group", "loan", {}),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(db.loanApplication.findFirst).not.toHaveBeenCalled();
  });

  it("blocks a treasurer from approving their own application", async () => {
    const { service, db } = setup(GroupRole.TREASURER);
    db.loanApplication.findFirst.mockResolvedValue({
      requestedByUserId: user.id,
      member: { userId: user.id },
    });
    await expect(
      service.approveLoanApplication(user, "group", "loan", {}),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it("rejects loan repayments beyond the unreserved balance", async () => {
    const { service, db } = setup();
    db.groupLoan.findFirst.mockResolvedValue({
      status: "ACTIVE",
      totalPayableMinor: 100,
      amountPaidMinor: 20,
    });
    db.loanRepayment.aggregate.mockResolvedValue({ _sum: { amountMinor: 60 } });
    await expect(
      service.recordLoanRepayment(user, "group", "loan", {
        amountMinor: 30,
        method: "CASH",
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(db.loanRepayment.create).not.toHaveBeenCalled();
  });

  it("does not accept partial payment when the plan disallows it", async () => {
    const { service, db } = setup();
    db.memberContributionObligation.findMany.mockResolvedValue([
      {
        id: "due",
        amountDueMinor: 100,
        amountPaidMinor: 0,
        plan: { allowsPartial: false },
        allocations: [],
      },
    ]);
    await expect(
      service["allocatePaymentToObligations"](
        "group",
        "payment",
        "member",
        50,
        ["due"],
        false,
        db as unknown as Prisma.TransactionClient,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(db.paymentAllocation.create).not.toHaveBeenCalled();
  });

  it("reserves pending payments so members cannot submit the same amount twice", async () => {
    const { service, db } = setup();
    db.memberContributionObligation.findMany.mockResolvedValue([
      {
        id: "due",
        amountDueMinor: 100,
        amountPaidMinor: 0,
        plan: { allowsPartial: true },
        allocations: [{ amountMinor: 100 }],
      },
    ]);
    await expect(
      service["allocatePaymentToObligations"](
        "group",
        "payment",
        "member",
        100,
        ["due"],
        false,
        db as unknown as Prisma.TransactionClient,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it("uses the configured weekly weekday and cycle anchor", () => {
    const { service } = setup();
    const periods = service["contributionPeriodSpecs"](
      {
        id: "year",
        name: "Year",
        startsAt: new Date("2026-09-01Z"),
        endsAt: new Date("2026-09-30Z"),
      },
      {
        id: "plan",
        name: "Contribution",
        type: ContributionPlanType.RECURRING,
        frequency: ContributionFrequency.WEEKLY,
        dueDayOfWeek: 5,
        dueDayOfMonth: null,
        cycleAnchorDate: new Date("2026-09-07Z"),
        amountMinor: 100,
        currency: "TZS",
      },
    );
    expect(periods[0].startsAt.toISOString().slice(0, 10)).toBe("2026-09-07");
    expect(periods[0].dueAt.getUTCDay()).toBe(5);
  });

  it("creates one annual joining-fee period", () => {
    const { service } = setup();
    const periods = service["contributionPeriodSpecs"](
      {
        id: "year",
        name: "Year",
        startsAt: new Date("2026-09-01Z"),
        endsAt: new Date("2027-08-31Z"),
      },
      {
        id: "plan",
        name: "Joining fee",
        type: ContributionPlanType.JOINING_FEE,
        frequency: ContributionFrequency.ANNUAL,
        dueDayOfWeek: null,
        dueDayOfMonth: null,
        amountMinor: 100,
        currency: "TZS",
      },
    );
    expect(periods).toHaveLength(1);
  });
});
