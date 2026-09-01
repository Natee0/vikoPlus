# Vikoplus

Vikoplus is an Android-first group contribution management platform for family, community, welfare, savings, association, club and religious groups.

This repository is a monorepo:

```text
apps/
  api/      NestJS, Prisma, PostgreSQL, Redis
  mobile/   Flutter Android app
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

For mobile:

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Billing Policy

Vikoplus platform access supports automatic payment only. Manual cash, bank transfer, mobile-money evidence upload, and administrator approval flows are not platform subscription mechanisms. Group contribution payments are separate records inside each group and may use group-configured workflows.

