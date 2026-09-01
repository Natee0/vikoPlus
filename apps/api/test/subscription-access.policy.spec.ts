import { SubscriptionState } from "@prisma/client";
import { hasPaidFeatureAccess } from "../src/common/subscriptions/subscription-access.policy";

describe("hasPaidFeatureAccess", () => {
  const now = new Date("2026-09-01T00:00:00.000Z");

  it.each([
    SubscriptionState.TRIAL,
    SubscriptionState.ACTIVE,
    SubscriptionState.GRACE_PERIOD,
  ])("allows %s", (state) => {
    expect(
      hasPaidFeatureAccess({ state, currentPeriodEndsAt: null, now }),
    ).toBe(true);
  });

  it("allows cancelled subscriptions until paid period ends", () => {
    expect(
      hasPaidFeatureAccess({
        state: SubscriptionState.CANCELLED,
        currentPeriodEndsAt: new Date("2026-09-10T00:00:00.000Z"),
        now,
      }),
    ).toBe(true);
  });

  it.each([
    SubscriptionState.PAST_DUE,
    SubscriptionState.SUSPENDED,
    SubscriptionState.EXPIRED,
  ])("blocks %s", (state) => {
    expect(
      hasPaidFeatureAccess({ state, currentPeriodEndsAt: null, now }),
    ).toBe(false);
  });
});
