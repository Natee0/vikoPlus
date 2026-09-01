import { SubscriptionState } from "@prisma/client";

export type SubscriptionAccessInput = {
  state: SubscriptionState;
  currentPeriodEndsAt: Date | null;
  now?: Date;
};

export function hasPaidFeatureAccess(input: SubscriptionAccessInput): boolean {
  const now = input.now ?? new Date();

  if (
    input.state === SubscriptionState.TRIAL ||
    input.state === SubscriptionState.ACTIVE
  ) {
    return true;
  }

  if (input.state === SubscriptionState.GRACE_PERIOD) {
    return true;
  }

  if (
    input.state === SubscriptionState.CANCELLED &&
    input.currentPeriodEndsAt
  ) {
    return input.currentPeriodEndsAt.getTime() > now.getTime();
  }

  return false;
}
