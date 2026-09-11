import { Component } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

import { SuperAdminApi } from '../../core/super-admin-api';

@Component({
  selector: 'sa-shell',
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  templateUrl: './shell.html',
})
export class ShellPage {
  constructor(
    private readonly api: SuperAdminApi,
    private readonly router: Router,
  ) {}

  get operatorName(): string {
    return this.api.currentUser?.displayName ?? 'Super Admin';
  }

  get operatorInitials(): string {
    return this.operatorName
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase() ?? '')
      .join('') || 'SA';
  }

  signOut(): void {
    this.api.logout();
    void this.router.navigateByUrl('/login');
  }
}
