ALTER TYPE "AuditAction" ADD VALUE 'PLATFORM_PRICE_CHANGED';
ALTER TYPE "AuditAction" ADD VALUE 'PLATFORM_PACKAGE_PURCHASE_CREATED';

CREATE TYPE "ReminderChannel" AS ENUM ('SMS', 'WHATSAPP', 'BOTH');

CREATE TYPE "ReminderPackagePurchaseStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'CANCELLED');

ALTER TABLE "SubscriptionPlan" ADD COLUMN "intervalCount" INTEGER NOT NULL DEFAULT 1;

CREATE TABLE "PlatformPrice" (
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

CREATE UNIQUE INDEX "PlatformPrice_code_key" ON "PlatformPrice"("code");

CREATE INDEX "PlatformPrice_updatedByUserId_idx" ON "PlatformPrice"("updatedByUserId");

CREATE TABLE "ReminderPackagePurchase" (
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

CREATE INDEX "ReminderPackagePurchase_groupId_idx" ON "ReminderPackagePurchase"("groupId");

CREATE INDEX "ReminderPackagePurchase_platformPriceId_idx" ON "ReminderPackagePurchase"("platformPriceId");

CREATE INDEX "ReminderPackagePurchase_createdByUserId_idx" ON "ReminderPackagePurchase"("createdByUserId");

CREATE INDEX "ReminderPackagePurchase_providerCheckoutId_idx" ON "ReminderPackagePurchase"("providerCheckoutId");

ALTER TABLE "ReminderPackagePurchase" ADD CONSTRAINT "ReminderPackagePurchase_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ReminderPackagePurchase" ADD CONSTRAINT "ReminderPackagePurchase_platformPriceId_fkey" FOREIGN KEY ("platformPriceId") REFERENCES "PlatformPrice"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "ReminderPackagePurchase" ADD CONSTRAINT "ReminderPackagePurchase_createdByUserId_fkey" FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
