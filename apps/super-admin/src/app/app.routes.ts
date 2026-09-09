import { Routes } from '@angular/router';

import { ShellPage } from './layout/shell/shell';
import { superAdminAuthGuard } from './core/super-admin-auth-guard';
import { GroupsPage } from './pages/groups/groups';
import { LoginPage } from './pages/login/login';
import { OverviewPage } from './pages/overview/overview';
import { PackagesPage } from './pages/packages/packages';
import { UsersPage } from './pages/users/users';

export const routes: Routes = [
  { path: 'login', component: LoginPage },
  { path: '', pathMatch: 'full', redirectTo: 'login' },
  {
    path: 'console',
    component: ShellPage,
    canActivate: [superAdminAuthGuard],
    children: [
      { path: 'overview', component: OverviewPage },
      { path: 'groups', component: GroupsPage },
      { path: 'users', component: UsersPage },
      { path: 'packages', component: PackagesPage },
      { path: '', pathMatch: 'full', redirectTo: 'overview' },
    ],
  },
  { path: '**', redirectTo: 'login' },
];
