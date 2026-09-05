# Vikoplus

Vikoplus is an Android-first group contribution management platform for family, community, welfare, savings, association, club and religious groups.

This repository is a monorepo:

```text
apps/
  api/      NestJS, Prisma, PostgreSQL, Redis
  vikoPlus/ Flutter Android app
docs/
infrastructure/
docker-compose.yml
```

## Foundation Scope

The current foundation includes:

- Provider-neutral subscription billing boundaries with a mock provider for local development and tests.
- Separate data models for Vikoplus platform subscriptions and group contribution payments.
- July-June financial-year support and Sofia Wajukuu seed/reference data.
- English and Swahili localization structure for Flutter.
- Android-only Flutter project setup with Material Design 3 design tokens.

## Local Startup

Create a local `.env` from `.env.example`, then:

```bash
npm install
npm --workspace apps/api run prisma:generate
docker compose up --build
```

For Android:

```bash
cd apps/vikoPlus
flutter pub get
flutter run
```

## Billing Policy

Vikoplus platform access supports automatic payment only. Manual cash, bank transfer, mobile-money evidence upload, and administrator approval flows are not platform subscription mechanisms. Group contribution payments are separate records inside each group and may use group-configured workflows.

## Group Rule Enforcement

- Invited users must accept the invitation using its intended verified identity. Active membership and the role within the selected group control access.
- Active group members, including administrators, treasurers and secretaries, can request loans. Only treasurers review applications and manual repayments; they cannot approve their own payments or loans.
- Contribution schedules use the configured financial year, cycle, amount and membership start date. Joining fees recur annually. Pending payments reserve outstanding dues, and partial payments follow the group's settings.
- Payment-rule changes do not rewrite paid obligations. Late penalties apply prospectively from the saved rule's effective date.
- Enabled reminder rules dispatch SMS through Briq using paid SMS credits. The worker checks every minute; persistent delivery keys prevent duplicate scheduled sends. Uncertain deliveries retain reserved credits and require reconciliation rather than automatic retry. WhatsApp dispatch remains unavailable.
- English and Swahili preferences persist to the signed-in account. Reminder template language is configured separately for the group.

Deploy the committed Prisma migrations before starting the updated API:

```bash
npm exec --workspace apps/api -- prisma migrate deploy
```

The new migrations add repayment rejection auditing, reminder rules and credit usage, financial-year rollover, and payment/penalty rules. Test deployments against a staging PostgreSQL database before production; unit tests do not replace migration and concurrent-request integration checks.
