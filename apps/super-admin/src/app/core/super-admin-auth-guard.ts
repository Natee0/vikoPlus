import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { SuperAdminApi } from './super-admin-api';

export const superAdminAuthGuard: CanActivateFn = () => {
  const api = inject(SuperAdminApi);
  const router = inject(Router);
  if (api.isAuthenticated) {
    return true;
  }
  return router.createUrlTree(['/login']);
};
