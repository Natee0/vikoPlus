import { ContributionPlanType } from "@prisma/client";
import {
  calculateContributionReport,
  ContributionReportObligation,
} from "../src/reports/contribution-report.calculator";

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

const monthLabels = [
  "July 2026",
  "August 2026",
  "September 2026",
  "October 2026",
  "November 2026",
  "December 2026",
  "January 2027",
  "February 2027",
  "March 2027",
  "April 2027",
  "May 2027",
  "June 2027",
] as const;

describe("calculateContributionReport", () => {
  it("reproduces the Sofia Wajukuu Michago contribution totals", () => {
    const report = calculateContributionReport(buildSofiaObligations());

    expect(report.membersCount).toBe(23);
    expect(report.totalPaidMinor).toBe(305000);
    expect(report.joiningFeesPaidMinor).toBe(150000);
    expect(report.recurringPaidMinor).toBe(155000);
    expect(report.totalOutstandingMinor).toBe(1305000);
    expect(report.periodTotals.map((period) => period.paidMinor)).toEqual([
      65000, 30000, 10000, 10000, 5000, 5000, 5000, 5000, 5000, 5000, 5000,
      5000,
    ]);
  });

  it("separates member-level joining fees, monthly dues and percentage", () => {
    const report = calculateContributionReport(buildSofiaObligations());

    const emmanuel = report.memberAnalysis.find(
      (member) => member.memberName === "Emmanuel Malekela Madahula",
    );

    expect(emmanuel).toMatchObject({
      joiningFeePaidMinor: 10000,
      recurringPaidMinor: 60000,
      totalPaidMinor: 70000,
      outstandingMinor: 0,
      paidRecurringPeriods: 12,
      percentageOfGroupTotal: 22.95,
    });
  });
});

function buildSofiaObligations(): ContributionReportObligation[] {
  return sofiaMembers.flatMap(
    ([fullName, joiningPaidMinor, monthlyPaidMinor], memberIndex) => {
      const memberId = `member-${memberIndex + 1}`;
      const memberNumber = `SW-${String(memberIndex + 1).padStart(3, "0")}`;
      const obligations: ContributionReportObligation[] = [
        {
          memberId,
          memberNumber,
          memberName: fullName,
          planType: ContributionPlanType.JOINING_FEE,
          periodLabel: "Joining fee",
          periodSortOrder: 0,
          amountDueMinor: 10000,
          amountPaidMinor: joiningPaidMinor,
        },
      ];

      obligations.push(
        ...monthLabels.map((label, monthIndex) => ({
          memberId,
          memberNumber,
          memberName: fullName,
          planType: ContributionPlanType.RECURRING,
          periodLabel: label,
          periodSortOrder: monthIndex + 1,
          amountDueMinor: 5000,
          amountPaidMinor:
            monthlyPaidMinor >= (monthIndex + 1) * 5000 ? 5000 : 0,
        })),
      );

      return obligations;
    },
  );
}
