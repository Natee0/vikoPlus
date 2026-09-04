ALTER TABLE "ReminderCampaign" ADD COLUMN "body" TEXT NOT NULL DEFAULT '';
ALTER TABLE "ReminderCampaign" ADD COLUMN "recipientCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "ReminderCampaign" ADD COLUMN "createdByUserId" TEXT;
