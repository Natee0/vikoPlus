import { Component } from '@angular/core';

import { SuperAdminApi } from '../../core/super-admin-api';
import { UserRow } from '../../shared/super-admin-data';

@Component({
  selector: 'sa-users',
  templateUrl: './users.html',
})
export class UsersPage {
  constructor(private readonly api: SuperAdminApi) {}

  users: UserRow[] = [
    {
      name: 'Evans Kiprop',
      email: 'evans.kiprop@vikoplus.co.ke',
      role: 'Super Admin',
      group: 'System Platform',
      kyc: 'Verified',
      twoFa: 'Enabled',
      lastActive: 'Today, 08:02',
    },
    {
      name: 'Fatma Ally',
      email: 'fatma.ally@example.com',
      role: 'SACCO Admin',
      group: 'Mshikamano SACCO',
      kyc: 'Verified',
      twoFa: 'Enabled',
      lastActive: 'Yesterday, 17:31',
    },
    {
      name: 'Rehema George',
      email: 'rehema.g@example.com',
      role: 'Member',
      group: 'Mwanzo Women Group',
      kyc: 'Verified',
      twoFa: 'Enabled',
      lastActive: 'Dec 20, 2026',
    },
    {
      name: 'David Ochieng',
      email: 'david@example.com',
      role: 'SACCO Admin',
      group: 'Jipange SACCO',
      kyc: 'Pending',
      twoFa: 'Disabled',
      lastActive: 'Dec 20, 2026',
    },
    {
      name: 'Amina Mwangi',
      email: 'amina@example.com',
      role: 'Secretary',
      group: 'Amani Women Group',
      kyc: 'Verified',
      twoFa: 'Enabled',
      lastActive: 'Dec 19, 2026',
    },
  ];
  errorMessage = '';
  isLoading = false;

  async ngOnInit(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      this.users = await this.api.users();
    } catch {
      this.errorMessage = 'Could not load live users. Showing sample users.';
    } finally {
      this.isLoading = false;
    }
  }
}
