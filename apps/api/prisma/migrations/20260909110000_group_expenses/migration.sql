CREATE TYPE "GroupExpenseStatus" AS ENUM ('SUBMITTED', 'APPROVED', 'REJECTED');

ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'GROUP_EXPENSE_SUBMITTED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'GROUP_EXPENSE_APPROVED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'GROUP_EXPENSE_REJECTED';

CREATE TABLE "GroupExpense" (
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

CREATE INDEX "GroupExpense_groupId_idx" ON "GroupExpense"("groupId");
CREATE INDEX "GroupExpense_status_idx" ON "GroupExpense"("status");
CREATE INDEX "GroupExpense_createdByUserId_idx" ON "GroupExpense"("createdByUserId");

ALTER TABLE "GroupExpense" ADD CONSTRAINT "GroupExpense_groupId_fkey"
  FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "GroupExpense" ADD CONSTRAINT "GroupExpense_createdByUserId_fkey"
  FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "GroupExpense" ADD CONSTRAINT "GroupExpense_reviewedByUserId_fkey"
  FOREIGN KEY ("reviewedByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
