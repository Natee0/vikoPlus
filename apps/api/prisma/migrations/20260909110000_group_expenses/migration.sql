DO $$
BEGIN
    CREATE TYPE "GroupExpenseStatus" AS ENUM ('SUBMITTED', 'APPROVED', 'REJECTED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'GROUP_EXPENSE_SUBMITTED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'GROUP_EXPENSE_APPROVED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'GROUP_EXPENSE_REJECTED';

CREATE TABLE IF NOT EXISTS "GroupExpense" (
  "id" TEXT NOT NULL,
  "groupId" TEXT NOT NULL,
  "createdByUserId" TEXT,
  "reviewedByUserId" TEXT,
  "category" TEXT NOT NULL,
  "purpose" TEXT NOT NULL,
  "beneficiary" TEXT,
  "amountMinor" INTEGER NOT NULL,
  "currency" TEXT NOT NULL DEFAULT 'TZS',
  "paymentRail" TEXT,
  "reference" TEXT,
  "status" "GroupExpenseStatus" NOT NULL DEFAULT 'SUBMITTED',
  "spentAt" TIMESTAMP(3),
  "reviewedAt" TIMESTAMP(3),
  "reviewNotes" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "GroupExpense_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "GroupExpense_groupId_idx" ON "GroupExpense"("groupId");
CREATE INDEX IF NOT EXISTS "GroupExpense_status_idx" ON "GroupExpense"("status");
CREATE INDEX IF NOT EXISTS "GroupExpense_createdByUserId_idx" ON "GroupExpense"("createdByUserId");

DO $$
BEGIN
    ALTER TABLE "GroupExpense" ADD CONSTRAINT "GroupExpense_groupId_fkey"
      FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "GroupExpense" ADD CONSTRAINT "GroupExpense_createdByUserId_fkey"
      FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "GroupExpense" ADD CONSTRAINT "GroupExpense_reviewedByUserId_fkey"
      FOREIGN KEY ("reviewedByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
