import {
  PrismaClient,
  BillingInterval,
  ContributionObligationStatus,
  ContributionFrequency,
  ContributionPlanType,
  GroupContributionPaymentStatus,
  PaymentAllocationStatus,
  SubscriptionPlanStatus,
} from "@prisma/client";
import { createHash } from "crypto";

const prisma = new PrismaClient();

const sofiaMembers = [
  ["Aginess Lupili", 0, 0],
  ["Amina Issa", 0, 0],
  ["Anthony Luganda", 0, 0],
  ["Boniphace Lupili", 10000, 10000],
  ["Emmanuel Malekela Madahula", 10000, 60000],
  ["Ester LupilinGeofrey", 0, 0],
  ["Esteria Luganda", 0, 0],
  ["Gervas Luganda", 0, 0],
  ["Hans Lupili", 10000, 5000],
  ["Issa Mbehuzi", 10000, 5000],
  ["Jelaledina Masanja", 10000, 0],
  ["Joseph Marco", 10000, 5000],
  ["Lucas Lupili", 10000, 5000],
  ["Magreth Vililo", 10000, 0],
  ["Mariana Kusagwa", 10000, 10000],
  ["Martina Lupili", 10000, 20000],
  ["Paschal Lupili", 0, 0],
  ["Rachel Lupili", 0, 0],
  ["Regina Kuyela", 10000, 10000],
  ["Simon Madahula", 10000, 10000],
  ["Thomas Bundala", 10000, 5000],
  ["Veronica Marko", 10000, 5000],
  ["Willybard Kazala", 10000, 5000],
] as const;

const monthlyPeriods = [
  ["July 2026", "2026-07-01T00:00:00.000Z", "2026-07-31T23:59:59.999Z"],
  ["August 2026", "2026-08-01T00:00:00.000Z", "2026-08-31T23:59:59.999Z"],
  ["September 2026", "2026-09-01T00:00:00.000Z", "2026-09-30T23:59:59.999Z"],
  ["October 2026", "2026-10-01T00:00:00.000Z", "2026-10-31T23:59:59.999Z"],
  ["November 2026", "2026-11-01T00:00:00.000Z", "2026-11-30T23:59:59.999Z"],
  ["December 2026", "2026-12-01T00:00:00.000Z", "2026-12-31T23:59:59.999Z"],
  ["January 2027", "2027-01-01T00:00:00.000Z", "2027-01-31T23:59:59.999Z"],
  ["February 2027", "2027-02-01T00:00:00.000Z", "2027-02-28T23:59:59.999Z"],
  ["March 2027", "2027-03-01T00:00:00.000Z", "2027-03-31T23:59:59.999Z"],
  ["April 2027", "2027-04-01T00:00:00.000Z", "2027-04-30T23:59:59.999Z"],
  ["May 2027", "2027-05-01T00:00:00.000Z", "2027-05-31T23:59:59.999Z"],
  ["June 2027", "2027-06-01T00:00:00.000Z", "2027-06-30T23:59:59.999Z"],
] as const;

async function main(): Promise<void> {
  await prisma.subscriptionPlan.upsert({
    where: { code: "starter-monthly" },
    update: {},
    create: {
      code: "starter-monthly",
      name: "Starter Monthly",
      description: "Monthly automatic billing for small groups.",
      priceMinor: 0,
      currency: "TZS",
      interval: BillingInterval.MONTH,
      trialDays: 14,
      status: SubscriptionPlanStatus.ACTIVE,
      featureEntitlements: {
        maxMembers: 50,
        reminders: true,
        reports: true,
      },
    },
  });

  await prisma.subscriptionPlan.upsert({
    where: { code: "growth-annual" },
    update: {},
    create: {
      code: "growth-annual",
      name: "Growth Annual",
      description: "Annual automatic billing for established groups.",
      priceMinor: 0,
      currency: "TZS",
      interval: BillingInterval.YEAR,
      trialDays: 14,
      status: SubscriptionPlanStatus.ACTIVE,
      featureEntitlements: {
        maxMembers: 250,
        reminders: true,
        reports: true,
        auditLog: true,
      },
    },
  });

  const group = await prisma.group.upsert({
    where: { slug: "sofia-wajukuu" },
    update: {},
    create: {
      name: "Sofia Wajukuu",
      slug: "sofia-wajukuu",
      currency: "TZS",
    },
  });

  const financialYear = await prisma.financialYear.upsert({
    where: {
      groupId_startsAt_endsAt: {
        groupId: group.id,
        startsAt: new Date("2026-07-01T00:00:00.000Z"),
        endsAt: new Date("2027-06-30T23:59:59.999Z"),
      },
    },
    update: { isActive: true },
    create: {
      groupId: group.id,
      name: "July 2026 - June 2027",
      startsAt: new Date("2026-07-01T00:00:00.000Z"),
      endsAt: new Date("2027-06-30T23:59:59.999Z"),
      isActive: true,
    },
  });

  const joiningPlan = await prisma.contributionPlan.upsert({
    where: { groupId_name: { groupId: group.id, name: "Kiingilio" } },
    update: {
      type: ContributionPlanType.JOINING_FEE,
      frequency: ContributionFrequency.ONCE,
      amountMinor: 10000,
      currency: "TZS",
      isActive: true,
    },
    create: {
      groupId: group.id,
      name: "Kiingilio",
      type: ContributionPlanType.JOINING_FEE,
      frequency: ContributionFrequency.ONCE,
      amountMinor: 10000,
      currency: "TZS",
    },
  });

  const monthlyPlan = await prisma.contributionPlan.upsert({
    where: { groupId_name: { groupId: group.id, name: "Ada ya kila mwezi" } },
    update: {
      type: ContributionPlanType.RECURRING,
      frequency: ContributionFrequency.MONTHLY,
      amountMinor: 5000,
      currency: "TZS",
      isActive: true,
    },
    create: {
      groupId: group.id,
      name: "Ada ya kila mwezi",
      type: ContributionPlanType.RECURRING,
      frequency: ContributionFrequency.MONTHLY,
      amountMinor: 5000,
      currency: "TZS",
    },
  });

  const joiningPeriod = await prisma.contributionPeriod.upsert({
    where: {
      groupId_planId_startsAt: {
        groupId: group.id,
        planId: joiningPlan.id,
        startsAt: financialYear.startsAt,
      },
    },
    update: {
      financialYearId: financialYear.id,
      label: "Joining fee",
      endsAt: financialYear.startsAt,
      dueAt: financialYear.startsAt,
      sortOrder: 0,
    },
    create: {
      groupId: group.id,
      financialYearId: financialYear.id,
      planId: joiningPlan.id,
      label: "Joining fee",
      startsAt: financialYear.startsAt,
      endsAt: financialYear.startsAt,
      dueAt: financialYear.startsAt,
      sortOrder: 0,
    },
  });

  const periods = await Promise.all(
    monthlyPeriods.map(([label, startsAt, endsAt], index) =>
      prisma.contributionPeriod.upsert({
        where: {
          groupId_planId_startsAt: {
            groupId: group.id,
            planId: monthlyPlan.id,
            startsAt: new Date(startsAt),
          },
        },
        update: {
          financialYearId: financialYear.id,
          label,
          endsAt: new Date(endsAt),
          dueAt: new Date(endsAt),
          sortOrder: index + 1,
        },
        create: {
          groupId: group.id,
          financialYearId: financialYear.id,
          planId: monthlyPlan.id,
          label,
          startsAt: new Date(startsAt),
          endsAt: new Date(endsAt),
          dueAt: new Date(endsAt),
          sortOrder: index + 1,
        },
      }),
    ),
  );

  await prisma.paymentAllocation.deleteMany({
    where: {
      payment: {
        groupId: group.id,
        idempotencyKey: { startsWith: "sofia-seed-" },
      },
    },
  });
  await prisma.receipt.deleteMany({
    where: {
      payment: {
        groupId: group.id,
        idempotencyKey: { startsWith: "sofia-seed-" },
      },
    },
  });
  await prisma.groupContributionPayment.deleteMany({
    where: {
      groupId: group.id,
      idempotencyKey: { startsWith: "sofia-seed-" },
    },
  });

  for (const [index, member] of sofiaMembers.entries()) {
    const [fullName, joiningPaidMinor, monthlyPaidMinor] = member;
    const memberNumber = `SW-${String(index + 1).padStart(3, "0")}`;
    const groupMember = await prisma.groupMember.upsert({
      where: {
        groupId_memberNumber: {
          groupId: group.id,
          memberNumber,
        },
      },
      update: {},
      create: {
        groupId: group.id,
        memberNumber,
        fullName,
        joinedAt: financialYear.startsAt,
      },
    });

    const paidObligations = [];
    const joiningObligation = await prisma.memberContributionObligation.upsert({
      where: {
        groupMemberId_planId_periodId: {
          groupMemberId: groupMember.id,
          planId: joiningPlan.id,
          periodId: joiningPeriod.id,
        },
      },
      update: {
        amountDueMinor: 10000,
        amountPaidMinor: joiningPaidMinor,
        status:
          joiningPaidMinor >= 10000
            ? ContributionObligationStatus.PAID
            : ContributionObligationStatus.DUE,
        dueAt: joiningPeriod.dueAt,
      },
      create: {
        groupMemberId: groupMember.id,
        planId: joiningPlan.id,
        periodId: joiningPeriod.id,
        amountDueMinor: 10000,
        amountPaidMinor: joiningPaidMinor,
        currency: "TZS",
        status:
          joiningPaidMinor >= 10000
            ? ContributionObligationStatus.PAID
            : ContributionObligationStatus.DUE,
        dueAt: joiningPeriod.dueAt,
      },
    });

    if (joiningPaidMinor > 0) {
      paidObligations.push({
        obligation: joiningObligation,
        planId: joiningPlan.id,
        periodId: joiningPeriod.id,
        amountMinor: joiningPaidMinor,
      });
    }

    for (const [periodIndex, period] of periods.entries()) {
      const amountPaidMinor =
        monthlyPaidMinor >= (periodIndex + 1) * 5000 ? 5000 : 0;
      const obligation = await prisma.memberContributionObligation.upsert({
        where: {
          groupMemberId_planId_periodId: {
            groupMemberId: groupMember.id,
            planId: monthlyPlan.id,
            periodId: period.id,
          },
        },
        update: {
          amountDueMinor: 5000,
          amountPaidMinor,
          status:
            amountPaidMinor >= 5000
              ? ContributionObligationStatus.PAID
              : ContributionObligationStatus.DUE,
          dueAt: period.dueAt,
        },
        create: {
          groupMemberId: groupMember.id,
          planId: monthlyPlan.id,
          periodId: period.id,
          amountDueMinor: 5000,
          amountPaidMinor,
          currency: "TZS",
          status:
            amountPaidMinor >= 5000
              ? ContributionObligationStatus.PAID
              : ContributionObligationStatus.DUE,
          dueAt: period.dueAt,
        },
      });

      if (amountPaidMinor > 0) {
        paidObligations.push({
          obligation,
          planId: monthlyPlan.id,
          periodId: period.id,
          amountMinor: amountPaidMinor,
        });
      }
    }

    const totalPaidMinor = joiningPaidMinor + monthlyPaidMinor;
    if (totalPaidMinor === 0) continue;

    const payment = await prisma.groupContributionPayment.create({
      data: {
        groupId: group.id,
        groupMemberId: groupMember.id,
        idempotencyKey: `sofia-seed-${memberNumber}`,
        amountMinor: totalPaidMinor,
        currency: "TZS",
        method: "SOURCE_REPORT",
        reference: "Sofia Wajukuu Michago corrected report",
        status: GroupContributionPaymentStatus.APPROVED,
        submittedAt: new Date("2026-09-01T00:00:00.000Z"),
        reviewedAt: new Date("2026-09-01T00:00:00.000Z"),
      },
    });

    await prisma.paymentAllocation.createMany({
      data: paidObligations.map((allocation) => ({
        paymentId: payment.id,
        planId: allocation.planId,
        periodId: allocation.periodId,
        obligationId: allocation.obligation.id,
        amountMinor: allocation.amountMinor,
        status: PaymentAllocationStatus.APPLIED,
      })),
    });

    const receiptNumber = `SW-2026-${memberNumber}`;
    await prisma.receipt.create({
      data: {
        groupId: group.id,
        paymentId: payment.id,
        receiptNumber,
        verificationHash: createHash("sha256")
          .update(`${payment.id}:${receiptNumber}:${totalPaidMinor}`)
          .digest("hex"),
      },
    });
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error: unknown) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
