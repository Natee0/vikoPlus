-- CreateEnum
DO $$
BEGIN
    CREATE TYPE "GroupDeletionRequestStatus" AS ENUM ('PENDING_INTERNAL_APPROVAL', 'APPROVED_FOR_SUPER_ADMIN', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- AlterEnum
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'GROUP_DELETION_REQUESTED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'GROUP_DELETION_APPROVED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'GROUP_DELETION_CANCELLED';

-- CreateTable
CREATE TABLE IF NOT EXISTS "GroupDeletionRequest" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "requestedByUserId" TEXT NOT NULL,
    "approvedByUserId" TEXT,
    "status" "GroupDeletionRequestStatus" NOT NULL DEFAULT 'PENDING_INTERNAL_APPROVAL',
    "reason" TEXT,
    "approvalNotes" TEXT,
    "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "approvedAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "GroupDeletionRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "GroupDeletionRequest_groupId_idx" ON "GroupDeletionRequest"("groupId");
CREATE INDEX IF NOT EXISTS "GroupDeletionRequest_requestedByUserId_idx" ON "GroupDeletionRequest"("requestedByUserId");
CREATE INDEX IF NOT EXISTS "GroupDeletionRequest_approvedByUserId_idx" ON "GroupDeletionRequest"("approvedByUserId");
CREATE INDEX IF NOT EXISTS "GroupDeletionRequest_status_idx" ON "GroupDeletionRequest"("status");

-- AddForeignKey
DO $$
BEGIN
    ALTER TABLE "GroupDeletionRequest" ADD CONSTRAINT "GroupDeletionRequest_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "GroupDeletionRequest" ADD CONSTRAINT "GroupDeletionRequest_requestedByUserId_fkey" FOREIGN KEY ("requestedByUserId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "GroupDeletionRequest" ADD CONSTRAINT "GroupDeletionRequest_approvedByUserId_fkey" FOREIGN KEY ("approvedByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
