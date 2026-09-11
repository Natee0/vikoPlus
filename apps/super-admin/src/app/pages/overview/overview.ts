import { ChangeDetectorRef, Component } from '@angular/core';

import { SuperAdminApi } from '../../core/super-admin-api';
import { GroupTableComponent } from '../../shared/group-table/group-table';
import { GroupRow, StatCard } from '../../shared/super-admin-data';

@Component({
  selector: 'sa-overview',
  imports: [GroupTableComponent],
  templateUrl: './overview.html',
})
export class OverviewPage {
  constructor(
    private readonly api: SuperAdminApi,
    private readonly changeDetector: ChangeDetectorRef,
  ) {}

  stats: StatCard[] = [];
  groups: GroupRow[] = [];
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
      this.errorMessage = 'Could not load live platform data.';
      this.stats = [];
      this.groups = [];
    } finally {
      this.isLoading = false;
      this.changeDetector.detectChanges();
    }
  }
}
