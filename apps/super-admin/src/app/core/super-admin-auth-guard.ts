import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { SuperAdminApi } from './super-admin-api';

export const superAdminAuthGuard: CanActivateFn = async () => {
  const api = inject(SuperAdminApi);
  const router = inject(Router);
  if (await api.ensureAuthenticated()) {
    return true;
  }
  return router.createUrlTree(['/login']);
};
