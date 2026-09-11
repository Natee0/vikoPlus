import { ChangeDetectorRef, Component } from '@angular/core';

import {
  AccessPlan,
  CreateAccessPlanInput,
  CreateReminderPackageInput,
  ReminderPackage,
  SuperAdminApi,
} from '../../core/super-admin-api';
import {
  AdminDialogComponent,
  AdminDialogConfig,
} from '../../shared/admin-dialog/admin-dialog';
import { StatCard } from '../../shared/super-admin-data';

const defaultAccessPlans: CreateAccessPlanInput[] = [
  {
    code: 'viko-starter',
    name: 'Viko Starter',
    description: 'Free starter access for one group during the first month.',
    priceMinor: 0,
    currency: 'TZS',
    interval: 'MONTH',
    intervalCount: 1,
    trialDays: 30,
    status: 'ACTIVE',
    featureEntitlements: { maxGroups: 1, reminders: true, reports: true },
  },
  {
    code: 'vikoplus-monthly',
    name: 'Vikoplus Monthly',
    description: 'TZS 1,000 per group each month after the starter trial.',
    priceMinor: 1000,
    currency: 'TZS',
    interval: 'MONTH',
    intervalCount: 1,
    trialDays: 0,
    status: 'ACTIVE',
    featureEntitlements: { maxGroups: 1, reminders: true, reports: true },
  },
  {
    code: 'vikoplus-pro',
    name: 'Vikoplus Pro',
    description: 'TZS 5,000 for six months, up to 10 groups.',
    priceMinor: 5000,
    currency: 'TZS',
    interval: 'MONTH',
    intervalCount: 6,
    trialDays: 0,
    status: 'ACTIVE',
    featureEntitlements: { maxGroups: 10, reminders: true, reports: true },
  },
  {
    code: 'vikoplus-kabambe',
    name: 'Vikoplus Kabambe',
    description: 'TZS 10,000 per year for unlimited groups.',
    priceMinor: 10000,
    currency: 'TZS',
    interval: 'YEAR',
    intervalCount: 1,
    trialDays: 0,
    status: 'ACTIVE',
    featureEntitlements: { maxGroups: null, reminders: true, reports: true },
  },
];

const defaultReminderPackages: CreateReminderPackageInput[] = [
  {
    code: 'sms-reminder',
    name: 'SMS Reminder',
    description: 'One SMS reminder credit.',
    channel: 'SMS',
    amountMinor: 50,
    currency: 'TZS',
    isActive: true,
  },
  {
    code: 'whatsapp-reminder',
    name: 'WhatsApp Reminder',
    description: 'One WhatsApp reminder credit.',
    channel: 'WHATSAPP',
    amountMinor: 50,
    currency: 'TZS',
    isActive: true,
  },
  {
    code: 'sms-whatsapp-reminder',
    name: 'SMS + WhatsApp Reminder',
    description: 'One combined SMS and WhatsApp reminder credit.',
    channel: 'BOTH',
    amountMinor: 100,
    currency: 'TZS',
    isActive: true,
  },
];

type PackageDialogTarget =
  | { kind: 'access-create' }
  | { kind: 'access-edit'; plan: AccessPlan }
  | { kind: 'access-archive'; plan: AccessPlan }
  | { kind: 'reminder-create' }
  | { kind: 'reminder-edit'; package: ReminderPackage }
  | { kind: 'reminder-toggle'; package: ReminderPackage }
  | { kind: 'defaults' };

@Component({
  selector: 'sa-packages',
  imports: [AdminDialogComponent],
  templateUrl: './packages.html',
})
export class PackagesPage {
  constructor(
    private readonly api: SuperAdminApi,
    private readonly changeDetector: ChangeDetectorRef,
  ) {}

  stats: StatCard[] = [];
  plans: AccessPlan[] = [];
  reminderPackages: ReminderPackage[] = [];
  errorMessage = '';
  isLoading = false;
  isSaving = false;
  dialogOpen = false;
  dialogConfig: AdminDialogConfig | null = null;
  private dialogTarget: PackageDialogTarget | null = null;

  async ngOnInit(): Promise<void> {
    await this.loadPackages();
  }

  async loadPackages(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const [stats, plans, reminderPackages] = await Promise.all([
        this.api.packageStats(),
        this.api.plans(),
        this.api.reminderPackages(),
      ]);
      this.stats = stats;
      this.plans = plans;
      this.reminderPackages = reminderPackages;
    } catch {
      this.errorMessage = 'Could not load live packages.';
      this.stats = [];
      this.plans = [];
      this.reminderPackages = [];
    } finally {
      this.isLoading = false;
      this.changeDetector.detectChanges();
    }
  }

  addAccessPlan(): void {
    this.dialogTarget = { kind: 'access-create' };
    this.dialogConfig = this.accessPlanDialog();
    this.dialogOpen = true;
  }

  editAccessPlan(plan: AccessPlan): void {
    this.dialogTarget = { kind: 'access-edit', plan };
    this.dialogConfig = this.accessPlanDialog(plan);
    this.dialogOpen = true;
  }

  archiveAccessPlan(plan: AccessPlan): void {
    this.dialogTarget = { kind: 'access-archive', plan };
    this.dialogConfig = {
      title: `Archive ${plan.name}?`,
      message: 'Archived plans will no longer appear in the mobile subscription screen.',
      confirmLabel: 'Archive plan',
      danger: true,
    };
    this.dialogOpen = true;
  }

  addReminderPackage(): void {
    this.dialogTarget = { kind: 'reminder-create' };
    this.dialogConfig = this.reminderPackageDialog();
    this.dialogOpen = true;
  }

  editReminderPackage(item: ReminderPackage): void {
    this.dialogTarget = { kind: 'reminder-edit', package: item };
    this.dialogConfig = this.reminderPackageDialog(item);
    this.dialogOpen = true;
  }

  toggleReminderPackage(item: ReminderPackage): void {
    this.dialogTarget = { kind: 'reminder-toggle', package: item };
    this.dialogConfig = {
      title: `${item.isActive ? 'Disable' : 'Enable'} ${item.name}?`,
      message: item.isActive
        ? 'Disabled reminder packages will not appear in the mobile reminder screen.'
        : 'Enabled reminder packages will appear in the mobile reminder screen.',
      confirmLabel: item.isActive ? 'Disable package' : 'Enable package',
      danger: item.isActive,
    };
    this.dialogOpen = true;
  }

  applyDefaults(): void {
    this.dialogTarget = { kind: 'defaults' };
    this.dialogConfig = {
      title: 'Apply Vikoplus package rules?',
      message:
        'This will create or update Viko Starter, Vikoplus Monthly, Vikoplus Pro, Vikoplus Kabambe, SMS Reminder, WhatsApp Reminder, and SMS + WhatsApp Reminder.',
      confirmLabel: 'Apply rules',
    };
    this.dialogOpen = true;
  }

  closeDialog(): void {
    if (this.isSaving) return;
    this.dialogOpen = false;
    this.dialogConfig = null;
    this.dialogTarget = null;
  }

  async confirmDialog(values: Record<string, string | number | boolean>): Promise<void> {
    const target = this.dialogTarget;
    if (!target) return;
    await this.runPackageAction(async () => {
      if (target.kind === 'defaults') {
        await this.applyDefaultRules();
      } else if (target.kind === 'access-create') {
        await this.api.createPlan(this.accessPlanInput(values));
      } else if (target.kind === 'access-edit') {
        const { code: _code, ...input } = this.accessPlanInput(values, target.plan);
        await this.api.updatePlan(target.plan.code, input);
      } else if (target.kind === 'access-archive') {
        await this.api.updatePlan(target.plan.code, { status: 'ARCHIVED' });
      } else if (target.kind === 'reminder-create') {
        await this.api.createReminderPackage(this.reminderPackageInput(values));
      } else if (target.kind === 'reminder-edit') {
        const { code: _code, ...input } = this.reminderPackageInput(values);
        await this.api.updateReminderPackage(target.package.code, input);
      } else if (target.kind === 'reminder-toggle') {
        await this.api.updateReminderPackage(target.package.code, {
          isActive: !target.package.isActive,
        });
      }
    });
    this.closeDialog();
  }

  money(amountMinor: number, currency = 'TZS'): string {
    return new Intl.NumberFormat('en-TZ', {
      style: 'currency',
      currency,
      maximumFractionDigits: 0,
    }).format(amountMinor);
  }

  accessCadence(plan: AccessPlan): string {
    const interval = plan.interval === 'YEAR' ? 'year' : 'month';
    const count = plan.intervalCount ?? 1;
    return count === 1 ? `Every ${interval}` : `Every ${count} ${interval}s`;
  }

  private async runPackageAction(action: () => Promise<void>): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    this.errorMessage = '';
    try {
      await action();
      await this.loadPackages();
    } catch (error) {
      this.errorMessage =
        error instanceof Error ? error.message : 'Could not save package changes.';
    } finally {
      this.isSaving = false;
      this.changeDetector.detectChanges();
    }
  }

  private async applyDefaultRules(): Promise<void> {
    for (const plan of defaultAccessPlans) {
      await this.createOrUpdateAccessPlan(plan);
    }
    for (const item of defaultReminderPackages) {
      await this.createOrUpdateReminderPackage(item);
    }
  }

  private async createOrUpdateAccessPlan(input: CreateAccessPlanInput): Promise<void> {
    try {
      await this.api.createPlan(input);
    } catch {
      const { code: _code, ...update } = input;
      await this.api.updatePlan(input.code, update);
    }
  }

  private async createOrUpdateReminderPackage(
    input: CreateReminderPackageInput,
  ): Promise<void> {
    try {
      await this.api.createReminderPackage(input);
    } catch {
      const { code: _code, ...update } = input;
      await this.api.updateReminderPackage(input.code, update);
    }
  }

  private accessPlanDialog(plan?: AccessPlan): AdminDialogConfig {
    return {
      title: plan ? 'Edit subscription plan' : 'Add subscription plan',
      confirmLabel: plan ? 'Save changes' : 'Create plan',
      fields: [
        { name: 'code', label: 'Code', value: plan?.code ?? '', required: true },
        { name: 'name', label: 'Name', value: plan?.name ?? '', required: true },
        { name: 'description', label: 'Description', type: 'textarea', value: plan?.description ?? '' },
        { name: 'priceMinor', label: 'Price in TZS', type: 'number', value: plan?.priceMinor ?? 1000, required: true },
        { name: 'currency', label: 'Currency', value: plan?.currency ?? 'TZS', required: true },
        {
          name: 'interval',
          label: 'Billing interval',
          type: 'select',
          value: plan?.interval ?? 'MONTH',
          options: [
            { label: 'Monthly', value: 'MONTH' },
            { label: 'Yearly', value: 'YEAR' },
          ],
        },
        { name: 'intervalCount', label: 'Interval count', type: 'number', value: plan?.intervalCount ?? 1, required: true },
        { name: 'trialDays', label: 'Trial days', type: 'number', value: plan?.trialDays ?? 0 },
      ],
    };
  }

  private reminderPackageDialog(item?: ReminderPackage): AdminDialogConfig {
    return {
      title: item ? 'Edit reminder package' : 'Add reminder package',
      confirmLabel: item ? 'Save changes' : 'Create package',
      fields: [
        { name: 'code', label: 'Code', value: item?.code ?? '', required: true },
        { name: 'name', label: 'Name', value: item?.name ?? '', required: true },
        { name: 'description', label: 'Description', type: 'textarea', value: item?.description ?? '' },
        {
          name: 'channel',
          label: 'Channel',
          type: 'select',
          value: item?.channel ?? 'SMS',
          options: [
            { label: 'SMS only', value: 'SMS' },
            { label: 'WhatsApp only', value: 'WHATSAPP' },
            { label: 'SMS + WhatsApp', value: 'BOTH' },
          ],
        },
        { name: 'amountMinor', label: 'Price per reminder in TZS', type: 'number', value: item?.amountMinor ?? 50, required: true },
        { name: 'currency', label: 'Currency', value: item?.currency ?? 'TZS', required: true },
      ],
    };
  }

  private accessPlanInput(
    values: Record<string, string | number | boolean>,
    original?: AccessPlan,
  ): CreateAccessPlanInput {
    return {
      code: String(values['code'] ?? original?.code ?? '').trim().toLowerCase(),
      name: String(values['name'] ?? '').trim(),
      description: String(values['description'] ?? '').trim() || undefined,
      priceMinor: Number(values['priceMinor'] ?? 0),
      currency: String(values['currency'] ?? 'TZS').trim().toUpperCase(),
      interval: values['interval'] === 'YEAR' ? 'YEAR' : 'MONTH',
      intervalCount: Number(values['intervalCount'] ?? 1),
      trialDays: Number(values['trialDays'] ?? 0),
      status: 'ACTIVE',
    };
  }

  private reminderPackageInput(
    values: Record<string, string | number | boolean>,
  ): CreateReminderPackageInput {
    const channel = String(values['channel'] ?? 'SMS');
    return {
      code: String(values['code'] ?? '').trim().toLowerCase(),
      name: String(values['name'] ?? '').trim(),
      description: String(values['description'] ?? '').trim() || undefined,
      channel: channel === 'WHATSAPP' || channel === 'BOTH' ? channel : 'SMS',
      amountMinor: Number(values['amountMinor'] ?? 0),
      currency: String(values['currency'] ?? 'TZS').trim().toUpperCase(),
      isActive: true,
    };
  }
}
