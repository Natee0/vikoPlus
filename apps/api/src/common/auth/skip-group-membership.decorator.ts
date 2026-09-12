import { SetMetadata } from "@nestjs/common";

export const SKIP_GROUP_MEMBERSHIP_CHECK = "skipGroupMembershipCheck";

export const SkipGroupMembershipCheck = () =>
  SetMetadata(SKIP_GROUP_MEMBERSHIP_CHECK, true);
