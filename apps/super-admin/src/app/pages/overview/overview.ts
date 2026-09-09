import { Component } from '@angular/core';

import { SuperAdminApi } from '../../core/super-admin-api';
import { GroupTableComponent } from '../../shared/group-table/group-table';
import { sampleGroups, StatCard } from '../../shared/super-admin-data';

@Component({
  selector: 'sa-overview',
  imports: [GroupTableComponent],
  templateUrl: './overview.html',
})
export class OverviewPage {
  constructor(private readonly api: SuperAdminApi) {}

  stats: StatCard[] = [
    {
      label: 'Total vault balance',
      value: 'KES 482.95M',
      delta: '+12.4% this month',
    },
    { label: 'Active groups', value: '1,248', delta: '+34 new this month' },
    { label: 'Total users', value: '42,860', delta: '+8.6% user growth' },
    {
      label: 'Annual recurring revenue',
      value: 'KES 14.8M',
      delta: '+17.9% year over year',
    },
  ];

  groups = sampleGroups.slice(0, 5);
  errorMessage = '';
  isLoading = false;

  async ngOnInit(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const [stats, groups] = await Promise.all([
        this.api.overviewStats(),
        this.api.groups(),
      ]);
      this.stats = stats;
      this.groups = groups.slice(0, 5);
    } catch {
      this.errorMessage = 'Could not load live platform data. Showing sample data.';
    } finally {
      this.isLoading = false;
    }
  }
}
