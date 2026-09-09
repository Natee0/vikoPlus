import { Component } from '@angular/core';

import { SuperAdminApi } from '../../core/super-admin-api';

type Plan = {
  name: string;
  badge: string;
  description: string;
  price: string;
  featured: boolean;
  features: string[];
};

@Component({
  selector: 'sa-packages',
  templateUrl: './packages.html',
})
export class PackagesPage {
  constructor(private readonly api: SuperAdminApi) {}

  plans: Plan[] = [
    {
      name: 'Starter Chama',
      badge: 'Basic community groups',
      description: 'For early-stage table banking groups.',
      price: 'KES 1,500 / month',
      featured: false,
      features: ['Up to 25 members', '1 admin seat', 'M-Pesa STK push', 'CSV exports'],
    },
    {
      name: 'Growth SACCO',
      badge: 'Most popular',
      description: 'For expanding groups that need approvals and reminders.',
      price: 'KES 4,500 / month',
      featured: true,
      features: ['Up to 150 members', '3 admin seats', 'Loan workflows', 'Bulk SMS reminders'],
    },
    {
      name: 'Enterprise SACCO',
      badge: 'Advanced controls',
      description: 'For formally registered SACCOs with audit controls.',
      price: 'KES 12,000 / month',
      featured: false,
      features: ['Unlimited members', 'Multi-signer approvals', 'Audit reports', 'Branch controls'],
    },
    {
      name: 'Custom Institutional',
      badge: 'Platform-level controls',
      description: 'For federations and institutional rollouts.',
      price: 'Custom',
      featured: false,
      features: ['Multi-tenant SACCOs', 'White-label mobile app', 'Dedicated database', '24/7 support SLA'],
    },
  ];
  errorMessage = '';
  isLoading = false;

  async ngOnInit(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const plans = await this.api.plans();
      if (plans.length > 0) {
        this.plans = plans.map((plan, index) => ({
          name: plan.name,
          badge: plan.status,
          description: plan.description ?? 'Subscription access plan',
          price: `${plan.currency} ${new Intl.NumberFormat('en-KE').format(plan.priceMinor)} / ${plan.interval.toLowerCase()}`,
          featured: index === 1,
          features: [
            `${plan.trialDays} trial days`,
            `Code: ${plan.code}`,
            `${plan.interval.toLowerCase()} billing`,
            'Feature entitlements included',
          ],
        }));
      }
    } catch {
      this.errorMessage = 'Could not load live packages. Showing sample plans.';
    } finally {
      this.isLoading = false;
    }
  }
}
