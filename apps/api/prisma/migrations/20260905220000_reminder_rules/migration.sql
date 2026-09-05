ALTER TABLE "ReminderPackagePurchase" ADD COLUMN "usedQuantity" INTEGER NOT NULL DEFAULT 0;
CREATE TABLE "GroupReminderRule" (
  "groupId" TEXT PRIMARY KEY REFERENCES "Group"("id") ON DELETE CASCADE,
  "enabled" BOOLEAN NOT NULL DEFAULT false,
  "offsets" INTEGER[] NOT NULL DEFAULT ARRAY[-3, 0]::INTEGER[],
  "locale" "Locale" NOT NULL DEFAULT 'en',
  "body" TEXT NOT NULL,
  "updatedAt" TIMESTAMP(3) NOT NULL
);
CREATE TABLE "ReminderDelivery" (
  "key" TEXT PRIMARY KEY,
  "groupId" TEXT NOT NULL,
  "state" TEXT NOT NULL DEFAULT 'RESERVED',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX "ReminderDelivery_groupId_idx" ON "ReminderDelivery"("groupId");
