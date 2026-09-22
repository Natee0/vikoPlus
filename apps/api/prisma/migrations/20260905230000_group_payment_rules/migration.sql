ALTER TYPE "ContributionPlanType" ADD VALUE IF NOT EXISTS 'PENALTY';
CREATE TABLE IF NOT EXISTS "GroupPaymentRule" (
 "groupId" TEXT PRIMARY KEY REFERENCES "Group"("id") ON DELETE CASCADE,
 "allowsPartial" BOOLEAN NOT NULL DEFAULT true,
 "penaltiesEnabled" BOOLEAN NOT NULL DEFAULT false,
 "penaltyAmountMinor" INTEGER NOT NULL DEFAULT 0,
 "graceDays" INTEGER NOT NULL DEFAULT 0,
 "effectiveAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE "MemberContributionObligation" ADD COLUMN IF NOT EXISTS "penaltySourceId" TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS "MemberContributionObligation_penaltySourceId_key" ON "MemberContributionObligation"("penaltySourceId");
