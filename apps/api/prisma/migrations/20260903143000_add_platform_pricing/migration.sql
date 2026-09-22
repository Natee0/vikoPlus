ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'PLATFORM_PRICE_CHANGED';
ALTER TYPE "AuditAction" ADD VALUE IF NOT EXISTS 'PLATFORM_PACKAGE_PURCHASE_CREATED';

DO $$
BEGIN
    CREATE TYPE "ReminderChannel" AS ENUM ('SMS', 'WHATSAPP', 'BOTH');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE "ReminderPackagePurchaseStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE "SubscriptionPlan" ADD COLUMN IF NOT EXISTS "intervalCount" INTEGER NOT NULL DEFAULT 1;

CREATE TABLE IF NOT EXISTS "PlatformPrice" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "channel" "ReminderChannel",
    "amountMinor" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'TZS',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "updatedByUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlatformPrice_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "PlatformPrice_code_key" ON "PlatformPrice"("code");

CREATE INDEX IF NOT EXISTS "PlatformPrice_updatedByUserId_idx" ON "PlatformPrice"("updatedByUserId");

CREATE TABLE IF NOT EXISTS "ReminderPackagePurchase" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "platformPriceId" TEXT NOT NULL,
    "createdByUserId" TEXT NOT NULL,
    "provider" "BillingProvider" NOT NULL DEFAULT 'SAYARI',
    "providerCheckoutId" TEXT,
    "quantity" INTEGER NOT NULL,
    "amountMinor" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'TZS',
    "status" "ReminderPackagePurchaseStatus" NOT NULL DEFAULT 'PENDING',
    "checkoutUrl" TEXT,
    "expiresAt" TIMESTAMP(3),
    "paidAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ReminderPackagePurchase_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "ReminderPackagePurchase_groupId_idx" ON "ReminderPackagePurchase"("groupId");

CREATE INDEX IF NOT EXISTS "ReminderPackagePurchase_platformPriceId_idx" ON "ReminderPackagePurchase"("platformPriceId");

CREATE INDEX IF NOT EXISTS "ReminderPackagePurchase_createdByUserId_idx" ON "ReminderPackagePurchase"("createdByUserId");

CREATE INDEX IF NOT EXISTS "ReminderPackagePurchase_providerCheckoutId_idx" ON "ReminderPackagePurchase"("providerCheckoutId");

DO $$
BEGIN
    ALTER TABLE "ReminderPackagePurchase" ADD CONSTRAINT "ReminderPackagePurchase_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "ReminderPackagePurchase" ADD CONSTRAINT "ReminderPackagePurchase_platformPriceId_fkey" FOREIGN KEY ("platformPriceId") REFERENCES "PlatformPrice"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE "ReminderPackagePurchase" ADD CONSTRAINT "ReminderPackagePurchase_createdByUserId_fkey" FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
