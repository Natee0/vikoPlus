UPDATE "MemberContributionObligation"
SET "status" = 'UPCOMING'
WHERE "status" = 'DUE'
  AND "amountPaidMinor" = 0
  AND "dueAt" > NOW();
