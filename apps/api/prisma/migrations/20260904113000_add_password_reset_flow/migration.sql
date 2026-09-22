-- Add challenge purposes so account verification and password reset codes
-- cannot be used interchangeably.
DO $$
BEGIN
    CREATE TYPE "OtpPurpose" AS ENUM ('ACCOUNT_VERIFICATION', 'PASSWORD_RESET');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE "OtpChallenge"
ADD COLUMN IF NOT EXISTS "purpose" "OtpPurpose" NOT NULL DEFAULT 'ACCOUNT_VERIFICATION';

CREATE INDEX IF NOT EXISTS "OtpChallenge_identifier_purpose_idx" ON "OtpChallenge"("identifier", "purpose");

-- Store short-lived one-time password reset tokens after OTP verification.
CREATE TABLE IF NOT EXISTS "PasswordResetToken" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "usedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PasswordResetToken_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "PasswordResetToken_tokenHash_key" ON "PasswordResetToken"("tokenHash");
CREATE INDEX IF NOT EXISTS "PasswordResetToken_userId_idx" ON "PasswordResetToken"("userId");

DO $$
BEGIN
    ALTER TABLE "PasswordResetToken"
    ADD CONSTRAINT "PasswordResetToken_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'PASSWORD_RESET_REQUESTED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'PASSWORD_RESET_COMPLETED';
