-- Production database optimizations for the main API access patterns.
-- Keep indexes aligned with real filters/orderings used by dashboards, reports,
-- billing webhooks, reminders, and auth guards.

-- Group membership and role checks
CREATE INDEX IF NOT EXISTS "GroupMember_userId_status_updatedAt_idx" ON "GroupMember"("userId", "status", "updatedAt");
CREATE INDEX IF NOT EXISTS "GroupMember_groupId_userId_status_idx" ON "GroupMember"("groupId", "userId", "status");
CREATE INDEX IF NOT EXISTS "GroupMember_groupId_status_role_idx" ON "GroupMember"("groupId", "status", "role");
CREATE INDEX IF NOT EXISTS "GroupMember_groupId_status_fullName_idx" ON "GroupMember"("groupId", "status", "fullName");

-- Loan workflows
CREATE INDEX IF NOT EXISTS "LoanApplication_groupId_status_createdAt_idx" ON "LoanApplication"("groupId", "status", "createdAt");
CREATE INDEX IF NOT EXISTS "LoanApplication_groupMemberId_status_createdAt_idx" ON "LoanApplication"("groupMemberId", "status", "createdAt");
CREATE INDEX IF NOT EXISTS "GroupLoan_groupId_status_dueAt_idx" ON "GroupLoan"("groupId", "status", "dueAt");
CREATE INDEX IF NOT EXISTS "GroupLoan_groupMemberId_status_dueAt_idx" ON "GroupLoan"("groupMemberId", "status", "dueAt");
CREATE INDEX IF NOT EXISTS "LoanRepayment_loanId_status_idx" ON "LoanRepayment"("loanId", "status");
CREATE INDEX IF NOT EXISTS "LoanRepayment_groupId_status_createdAt_idx" ON "LoanRepayment"("groupId", "status", "createdAt");
CREATE INDEX IF NOT EXISTS "LoanRepayment_groupMemberId_status_createdAt_idx" ON "LoanRepayment"("groupMemberId", "status", "createdAt");

-- Expenses and contribution payments
CREATE INDEX IF NOT EXISTS "GroupExpense_groupId_status_createdAt_idx" ON "GroupExpense"("groupId", "status", "createdAt");
CREATE INDEX IF NOT EXISTS "GroupExpense_createdByUserId_status_createdAt_idx" ON "GroupExpense"("createdByUserId", "status", "createdAt");
CREATE INDEX IF NOT EXISTS "MemberContributionObligation_groupMemberId_status_dueAt_idx" ON "MemberContributionObligation"("groupMemberId", "status", "dueAt");
CREATE INDEX IF NOT EXISTS "MemberContributionObligation_planId_status_dueAt_idx" ON "MemberContributionObligation"("planId", "status", "dueAt");
CREATE INDEX IF NOT EXISTS "MemberContributionObligation_periodId_status_idx" ON "MemberContributionObligation"("periodId", "status");
CREATE INDEX IF NOT EXISTS "MemberContributionObligation_dueAt_status_idx" ON "MemberContributionObligation"("dueAt", "status");
CREATE INDEX IF NOT EXISTS "GroupContributionPayment_groupId_status_createdAt_idx" ON "GroupContributionPayment"("groupId", "status", "createdAt");
CREATE INDEX IF NOT EXISTS "GroupContributionPayment_groupMemberId_status_createdAt_idx" ON "GroupContributionPayment"("groupMemberId", "status", "createdAt");
CREATE INDEX IF NOT EXISTS "GroupContributionPayment_createdByUserId_idx" ON "GroupContributionPayment"("createdByUserId");
CREATE INDEX IF NOT EXISTS "GroupContributionPayment_reviewedByUserId_idx" ON "GroupContributionPayment"("reviewedByUserId");
CREATE INDEX IF NOT EXISTS "GroupContributionPayment_status_createdAt_idx" ON "GroupContributionPayment"("status", "createdAt");
CREATE INDEX IF NOT EXISTS "PaymentAllocation_planId_status_idx" ON "PaymentAllocation"("planId", "status");
CREATE INDEX IF NOT EXISTS "PaymentAllocation_obligationId_status_idx" ON "PaymentAllocation"("obligationId", "status");
CREATE INDEX IF NOT EXISTS "PaymentAllocation_status_createdAt_idx" ON "PaymentAllocation"("status", "createdAt");
CREATE INDEX IF NOT EXISTS "Receipt_groupId_issuedAt_idx" ON "Receipt"("groupId", "issuedAt");
CREATE INDEX IF NOT EXISTS "Receipt_status_issuedAt_idx" ON "Receipt"("status", "issuedAt");

-- Billing, subscriptions, and reminder packages
CREATE INDEX IF NOT EXISTS "ReminderPackagePurchase_groupId_status_paidAt_idx" ON "ReminderPackagePurchase"("groupId", "status", "paidAt");
CREATE INDEX IF NOT EXISTS "ReminderPackagePurchase_status_createdAt_idx" ON "ReminderPackagePurchase"("status", "createdAt");
CREATE INDEX IF NOT EXISTS "ReminderPackagePurchase_provider_status_createdAt_idx" ON "ReminderPackagePurchase"("provider", "status", "createdAt");
CREATE INDEX IF NOT EXISTS "Subscription_groupId_state_updatedAt_idx" ON "Subscription"("groupId", "state", "updatedAt");
CREATE INDEX IF NOT EXISTS "Subscription_groupId_createdAt_idx" ON "Subscription"("groupId", "createdAt");
CREATE INDEX IF NOT EXISTS "Subscription_state_updatedAt_idx" ON "Subscription"("state", "updatedAt");
CREATE INDEX IF NOT EXISTS "BillingEvent_status_createdAt_idx" ON "BillingEvent"("status", "createdAt");
CREATE INDEX IF NOT EXISTS "BillingEvent_provider_status_createdAt_idx" ON "BillingEvent"("provider", "status", "createdAt");

-- Reminders, notifications, and audit history
CREATE INDEX IF NOT EXISTS "ReminderDelivery_groupId_state_createdAt_idx" ON "ReminderDelivery"("groupId", "state", "createdAt");
CREATE INDEX IF NOT EXISTS "ReminderDelivery_state_createdAt_idx" ON "ReminderDelivery"("state", "createdAt");
CREATE INDEX IF NOT EXISTS "ReminderCampaign_groupId_createdAt_idx" ON "ReminderCampaign"("groupId", "createdAt");
CREATE INDEX IF NOT EXISTS "ReminderCampaign_createdByUserId_createdAt_idx" ON "ReminderCampaign"("createdByUserId", "createdAt");
CREATE INDEX IF NOT EXISTS "Notification_userId_createdAt_idx" ON "Notification"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "Notification_userId_readAt_createdAt_idx" ON "Notification"("userId", "readAt", "createdAt");
CREATE INDEX IF NOT EXISTS "AuditLog_groupId_createdAt_idx" ON "AuditLog"("groupId", "createdAt");
CREATE INDEX IF NOT EXISTS "AuditLog_actorUserId_createdAt_idx" ON "AuditLog"("actorUserId", "createdAt");
CREATE INDEX IF NOT EXISTS "AuditLog_action_createdAt_idx" ON "AuditLog"("action", "createdAt");

-- Smaller partial indexes for the highest-volume open queues.
CREATE INDEX IF NOT EXISTS "GroupContributionPayment_pending_review_idx"
  ON "GroupContributionPayment"("groupId", "createdAt")
  WHERE "status" IN ('SUBMITTED', 'PENDING_VERIFICATION', 'CORRECTION_REQUESTED');

CREATE INDEX IF NOT EXISTS "MemberContributionObligation_open_due_idx"
  ON "MemberContributionObligation"("groupMemberId", "dueAt")
  WHERE "status" IN ('DUE', 'PARTIALLY_PAID', 'OVERDUE');

CREATE INDEX IF NOT EXISTS "GroupExpense_submitted_idx"
  ON "GroupExpense"("groupId", "createdAt")
  WHERE "status" = 'SUBMITTED';

CREATE INDEX IF NOT EXISTS "LoanApplication_submitted_idx"
  ON "LoanApplication"("groupId", "createdAt")
  WHERE "status" = 'SUBMITTED';

CREATE INDEX IF NOT EXISTS "LoanRepayment_submitted_idx"
  ON "LoanRepayment"("groupId", "createdAt")
  WHERE "status" = 'SUBMITTED';

CREATE INDEX IF NOT EXISTS "GroupLoan_active_due_idx"
  ON "GroupLoan"("groupId", "dueAt")
  WHERE "status" = 'ACTIVE';

CREATE INDEX IF NOT EXISTS "Notification_unread_idx"
  ON "Notification"("userId", "createdAt")
  WHERE "readAt" IS NULL;

CREATE INDEX IF NOT EXISTS "BillingEvent_unprocessed_idx"
  ON "BillingEvent"("provider", "createdAt")
  WHERE "status" IN ('RECEIVED', 'FAILED');

CREATE INDEX IF NOT EXISTS "ReminderPackagePurchase_pending_provider_idx"
  ON "ReminderPackagePurchase"("provider", "createdAt")
  WHERE "status" = 'PENDING';

-- DB-side updatedAt guard for production/manual maintenance updates.
CREATE OR REPLACE FUNCTION "set_updated_at"()
RETURNS trigger AS $$
BEGIN
  NEW."updatedAt" = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "User_set_updated_at" ON "User";
CREATE TRIGGER "User_set_updated_at" BEFORE UPDATE ON "User"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "UserIdentity_set_updated_at" ON "UserIdentity";
CREATE TRIGGER "UserIdentity_set_updated_at" BEFORE UPDATE ON "UserIdentity"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "Group_set_updated_at" ON "Group";
CREATE TRIGGER "Group_set_updated_at" BEFORE UPDATE ON "Group"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "GroupDeletionRequest_set_updated_at" ON "GroupDeletionRequest";
CREATE TRIGGER "GroupDeletionRequest_set_updated_at" BEFORE UPDATE ON "GroupDeletionRequest"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "GroupMember_set_updated_at" ON "GroupMember";
CREATE TRIGGER "GroupMember_set_updated_at" BEFORE UPDATE ON "GroupMember"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "LoanApplication_set_updated_at" ON "LoanApplication";
CREATE TRIGGER "LoanApplication_set_updated_at" BEFORE UPDATE ON "LoanApplication"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "GroupLoan_set_updated_at" ON "GroupLoan";
CREATE TRIGGER "GroupLoan_set_updated_at" BEFORE UPDATE ON "GroupLoan"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "LoanRepayment_set_updated_at" ON "LoanRepayment";
CREATE TRIGGER "LoanRepayment_set_updated_at" BEFORE UPDATE ON "LoanRepayment"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "GroupExpense_set_updated_at" ON "GroupExpense";
CREATE TRIGGER "GroupExpense_set_updated_at" BEFORE UPDATE ON "GroupExpense"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "FinancialYear_set_updated_at" ON "FinancialYear";
CREATE TRIGGER "FinancialYear_set_updated_at" BEFORE UPDATE ON "FinancialYear"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "ContributionPlan_set_updated_at" ON "ContributionPlan";
CREATE TRIGGER "ContributionPlan_set_updated_at" BEFORE UPDATE ON "ContributionPlan"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "MemberContributionObligation_set_updated_at" ON "MemberContributionObligation";
CREATE TRIGGER "MemberContributionObligation_set_updated_at" BEFORE UPDATE ON "MemberContributionObligation"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "GroupContributionPayment_set_updated_at" ON "GroupContributionPayment";
CREATE TRIGGER "GroupContributionPayment_set_updated_at" BEFORE UPDATE ON "GroupContributionPayment"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "SubscriptionPlan_set_updated_at" ON "SubscriptionPlan";
CREATE TRIGGER "SubscriptionPlan_set_updated_at" BEFORE UPDATE ON "SubscriptionPlan"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "PlatformPrice_set_updated_at" ON "PlatformPrice";
CREATE TRIGGER "PlatformPrice_set_updated_at" BEFORE UPDATE ON "PlatformPrice"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "ReminderPackagePurchase_set_updated_at" ON "ReminderPackagePurchase";
CREATE TRIGGER "ReminderPackagePurchase_set_updated_at" BEFORE UPDATE ON "ReminderPackagePurchase"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "Subscription_set_updated_at" ON "Subscription";
CREATE TRIGGER "Subscription_set_updated_at" BEFORE UPDATE ON "Subscription"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "BillingCustomer_set_updated_at" ON "BillingCustomer";
CREATE TRIGGER "BillingCustomer_set_updated_at" BEFORE UPDATE ON "BillingCustomer"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "BillingPaymentMethod_set_updated_at" ON "BillingPaymentMethod";
CREATE TRIGGER "BillingPaymentMethod_set_updated_at" BEFORE UPDATE ON "BillingPaymentMethod"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "GroupReminderRule_set_updated_at" ON "GroupReminderRule";
CREATE TRIGGER "GroupReminderRule_set_updated_at" BEFORE UPDATE ON "GroupReminderRule"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "ReminderTemplate_set_updated_at" ON "ReminderTemplate";
CREATE TRIGGER "ReminderTemplate_set_updated_at" BEFORE UPDATE ON "ReminderTemplate"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "NotificationPreference_set_updated_at" ON "NotificationPreference";
CREATE TRIGGER "NotificationPreference_set_updated_at" BEFORE UPDATE ON "NotificationPreference"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();

DROP TRIGGER IF EXISTS "PushDeviceToken_set_updated_at" ON "PushDeviceToken";
CREATE TRIGGER "PushDeviceToken_set_updated_at" BEFORE UPDATE ON "PushDeviceToken"
FOR EACH ROW EXECUTE FUNCTION "set_updated_at"();
