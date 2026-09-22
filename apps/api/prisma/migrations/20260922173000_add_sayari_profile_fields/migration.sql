ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "username" TEXT;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "profilePictureUrl" TEXT;
CREATE INDEX IF NOT EXISTS "User_username_idx" ON "User"("username");
