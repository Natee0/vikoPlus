import { ChangeDetectorRef, Component } from '@angular/core';

import { SuperAdminApi } from '../../core/super-admin-api';
import { StatCard, UserRow } from '../../shared/super-admin-data';

@Component({
  selector: 'sa-users',
  templateUrl: './users.html',
})
export class UsersPage {
  constructor(
    private readonly api: SuperAdminApi,
    private readonly changeDetector: ChangeDetectorRef,
  ) {}

  stats: StatCard[] = [];
  users: UserRow[] = [];
  errorMessage = '';
  isLoading = false;

  async ngOnInit(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const [stats, users] = await Promise.all([
        this.api.userStats(),
        this.api.users(),
      ]);
      this.stats = stats;
      this.users = users;
    } catch {
      this.errorMessage = 'Could not load live users.';
      this.stats = [];
      this.users = [];
    } finally {
      this.isLoading = false;
      this.changeDetector.detectChanges();
    }
  }
}
