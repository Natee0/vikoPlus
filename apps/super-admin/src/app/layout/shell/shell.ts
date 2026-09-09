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

  signOut(): void {
    this.api.logout();
    void this.router.navigateByUrl('/login');
  }
}
