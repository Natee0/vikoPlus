CREATE TABLE "PushDeviceToken" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "token" TEXT NOT NULL,
  "platform" TEXT NOT NULL,
  "deviceId" TEXT,
  "appVersion" TEXT,
  "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "PushDeviceToken_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "PushDeviceToken_token_key" ON "PushDeviceToken"("token");
CREATE INDEX "PushDeviceToken_userId_idx" ON "PushDeviceToken"("userId");
CREATE INDEX "PushDeviceToken_platform_idx" ON "PushDeviceToken"("platform");

ALTER TABLE "PushDeviceToken"
ADD CONSTRAINT "PushDeviceToken_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
