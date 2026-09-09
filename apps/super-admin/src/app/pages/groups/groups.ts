import { Component } from '@angular/core';

import { SuperAdminApi } from '../../core/super-admin-api';
import { GroupTableComponent } from '../../shared/group-table/group-table';
import { sampleGroups } from '../../shared/super-admin-data';

@Component({
  selector: 'sa-groups',
  imports: [GroupTableComponent],
  templateUrl: './groups.html',
})
export class GroupsPage {
  constructor(private readonly api: SuperAdminApi) {}

  groups = sampleGroups;
  errorMessage = '';
  isLoading = false;

  async ngOnInit(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      this.groups = await this.api.groups();
    } catch {
      this.errorMessage = 'Could not load live groups. Showing sample groups.';
    } finally {
      this.isLoading = false;
    }
  }
}
