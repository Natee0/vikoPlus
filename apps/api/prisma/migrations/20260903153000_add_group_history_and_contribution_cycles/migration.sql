ALTER TYPE "ContributionFrequency" ADD VALUE 'DAILY';
ALTER TYPE "ContributionFrequency" ADD VALUE 'WEEKLY';

ALTER TABLE "Group" ADD COLUMN "establishedAt" TIMESTAMP(3);
ALTER TABLE "Group" ADD COLUMN "historicalDataStartsAt" TIMESTAMP(3);

ALTER TABLE "ContributionPlan" ADD COLUMN "dueDayOfWeek" INTEGER;
ALTER TABLE "ContributionPlan" ADD COLUMN "dueDayOfMonth" INTEGER;
ALTER TABLE "ContributionPlan" ADD COLUMN "cycleAnchorDate" TIMESTAMP(3);

ALTER TABLE "GroupContributionPayment" ADD COLUMN "paidAt" TIMESTAMP(3);
