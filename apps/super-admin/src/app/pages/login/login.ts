import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import { SuperAdminApi } from '../../core/super-admin-api';

@Component({
  selector: 'sa-login',
  imports: [FormsModule],
  templateUrl: './login.html',
})
export class LoginPage {
  constructor(
    private readonly api: SuperAdminApi,
    private readonly router: Router,
  ) {}

  email = '';
  password = '';
  remember = true;
  errorMessage = '';
  isSubmitting = false;

  async submit(): Promise<void> {
    if (this.isSubmitting) return;
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await this.api.login(this.email, this.password);
      await this.router.navigateByUrl('/dashboard/overview');
    } catch (error) {
      this.errorMessage =
        error instanceof Error
          ? error.message
          : 'Could not sign in. Please check your details and try again.';
    } finally {
      this.isSubmitting = false;
    }
  }
}
