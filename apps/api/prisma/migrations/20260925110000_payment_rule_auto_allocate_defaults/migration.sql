ALTER TABLE "GroupPaymentRule"
ADD COLUMN IF NOT EXISTS "autoAllocatePayments" BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE "GroupPaymentRule"
ALTER COLUMN "allowsPartial" SET DEFAULT false;

ALTER TABLE "ContributionPlan"
ALTER COLUMN "allowsPartial" SET DEFAULT false;
