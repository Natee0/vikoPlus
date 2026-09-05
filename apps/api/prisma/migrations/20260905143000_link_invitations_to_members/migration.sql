-- Link role-based invitations to manually added members so accepting an invite
-- activates the existing member record instead of creating a duplicate.
ALTER TABLE "GroupInvitation"
ADD COLUMN "groupMemberId" TEXT;

CREATE INDEX "GroupInvitation_groupMemberId_idx"
ON "GroupInvitation"("groupMemberId");

ALTER TABLE "GroupInvitation"
ADD CONSTRAINT "GroupInvitation_groupMemberId_fkey"
FOREIGN KEY ("groupMemberId")
REFERENCES "GroupMember"("id")
ON DELETE CASCADE
ON UPDATE CASCADE;
