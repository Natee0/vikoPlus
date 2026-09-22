DO $$
BEGIN
    CREATE TYPE "LoanApplicationStatus" AS ENUM ('SUBMITTED', 'APPROVED', 'REJECTED', 'DISBURSED', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE "LoanGuarantorStatus" AS ENUM ('PENDING', 'CONFIRMED', 'DECLINED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE "GroupLoanStatus" AS ENUM ('ACTIVE', 'PAID', 'DEFAULTED', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE "LoanRepaymentStatus" AS ENUM ('SUBMITTED', 'APPROVED', 'REJECTED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'LOAN_APPLICATION_SUBMITTED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'LOAN_APPLICATION_APPROVED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'LOAN_APPLICATION_REJECTED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'LOAN_REPAYMENT_SUBMITTED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'LOAN_REPAYMENT_APPROVED';

CREATE TABLE IF NOT EXISTS "LoanApplication" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "groupMemberId" TEXT NOT NULL,
    "requestedByUserId" TEXT,
    "reviewedByUserId" TEXT,
    "amountMinor" INTEGER NOT NULL,
    "approvedAmountMinor" INTEGER,
    "currency" TEXT NOT NULL DEFAULT 'TZS',
    "purpose" TEXT NOT NULL,
    "termMonths" INTEGER NOT NULL,
    "monthlyInterestRateBps" INTEGER NOT NULL DEFAULT 150,
    "processingFeeMinor" INTEGER NOT NULL DEFAULT 0,
    "status" "LoanApplicationStatus" NOT NULL DEFAULT 'SUBMITTED',
    "reviewNotes" TEXT,
    "rejectionReason" TEXT,
    "approvedAt" TIMESTAMP(3),
    "rejectedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LoanApplication_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "LoanGuarantor" (
    "id" TEXT NOT NULL,
    "applicationId" TEXT NOT NULL,
    "groupMemberId" TEXT NOT NULL,
    "status" "LoanGuarantorStatus" NOT NULL DEFAULT 'PENDING',
    "confirmedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LoanGuarantor_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "GroupLoan" (
    "id" TEXT NOT NULL,
    "applicationId" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "groupMemberId" TEXT NOT NULL,
    "amountMinor" INTEGER NOT NULL,
    "totalPayableMinor" INTEGER NOT NULL,
    "amountPaidMinor" INTEGER NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'TZS',
    "purpose" TEXT NOT NULL,
    "termMonths" INTEGER NOT NULL,
    "monthlyInterestRateBps" INTEGER NOT NULL DEFAULT 150,
    "status" "GroupLoanStatus" NOT NULL DEFAULT 'ACTIVE',
    "disbursedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dueAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "GroupLoan_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "LoanRepayment" (
    "id" TEXT NOT NULL,
    "loanId" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "groupMemberId" TEXT NOT NULL,
    "createdByUserId" TEXT,
    "reviewedByUserId" TEXT,
    "amountMinor" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'TZS',
    "method" TEXT NOT NULL,
    "reference" TEXT,
    "status" "LoanRepaymentStatus" NOT NULL DEFAULT 'SUBMITTED',
    "paidAt" TIMESTAMP(3),
    "reviewedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LoanRepayment_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "LoanApplication_groupId_idx" ON "LoanApplication"("groupId");
CREATE INDEX IF NOT EXISTS "LoanApplication_groupMemberId_idx" ON "LoanApplication"("groupMemberId");
CREATE INDEX IF NOT EXISTS "LoanApplication_status_idx" ON "LoanApplication"("status");

CREATE UNIQUE INDEX IF NOT EXISTS "LoanGuarantor_applicationId_groupMemberId_key" ON "LoanGuarantor"("applicationId", "groupMemberId");
CREATE INDEX IF NOT EXISTS "LoanGuarantor_groupMemberId_idx" ON "LoanGuarantor"("groupMemberId");

CREATE UNIQUE INDEX IF NOT EXISTS "GroupLoan_applicationId_key" ON "GroupLoan"("applicationId");
CREATE INDEX IF NOT EXISTS "GroupLoan_groupId_idx" ON "GroupLoan"("groupId");
CREATE INDEX IF NOT EXISTS "GroupLoan_groupMemberId_idx" ON "GroupLoan"("groupMemberId");
CREATE INDEX IF NOT EXISTS "GroupLoan_status_idx" ON "GroupLoan"("status");

CREATE INDEX IF NOT EXISTS "LoanRepayment_loanId_idx" ON "LoanRepayment"("loanId");
CREATE INDEX IF NOT EXISTS "LoanRepayment_groupId_idx" ON "LoanRepayment"("groupId");
CREATE INDEX IF NOT EXISTS "LoanRepayment_groupMemberId_idx" ON "LoanRepayment"("groupMemberId");

DO $$
BEGIN
    ALTER TABLE "LoanApplication" ADD CONSTRAINT "LoanApplication_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanApplication" ADD CONSTRAINT "LoanApplication_groupMemberId_fkey" FOREIGN KEY ("groupMemberId") REFERENCES "GroupMember"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanApplication" ADD CONSTRAINT "LoanApplication_requestedByUserId_fkey" FOREIGN KEY ("requestedByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanApplication" ADD CONSTRAINT "LoanApplication_reviewedByUserId_fkey" FOREIGN KEY ("reviewedByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanGuarantor" ADD CONSTRAINT "LoanGuarantor_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "LoanApplication"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanGuarantor" ADD CONSTRAINT "LoanGuarantor_groupMemberId_fkey" FOREIGN KEY ("groupMemberId") REFERENCES "GroupMember"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "GroupLoan" ADD CONSTRAINT "GroupLoan_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "LoanApplication"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "GroupLoan" ADD CONSTRAINT "GroupLoan_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "GroupLoan" ADD CONSTRAINT "GroupLoan_groupMemberId_fkey" FOREIGN KEY ("groupMemberId") REFERENCES "GroupMember"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanRepayment" ADD CONSTRAINT "LoanRepayment_loanId_fkey" FOREIGN KEY ("loanId") REFERENCES "GroupLoan"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanRepayment" ADD CONSTRAINT "LoanRepayment_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanRepayment" ADD CONSTRAINT "LoanRepayment_groupMemberId_fkey" FOREIGN KEY ("groupMemberId") REFERENCES "GroupMember"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanRepayment" ADD CONSTRAINT "LoanRepayment_createdByUserId_fkey" FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "LoanRepayment" ADD CONSTRAINT "LoanRepayment_reviewedByUserId_fkey" FOREIGN KEY ("reviewedByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
