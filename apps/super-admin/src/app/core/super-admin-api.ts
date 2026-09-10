import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { firstValueFrom, timeout } from 'rxjs';

import { GroupRow, StatCard, UserRow } from '../shared/super-admin-data';

const ACCESS_TOKEN_KEY = 'vikoplus.superAdmin.accessToken';
const REFRESH_TOKEN_KEY = 'vikoplus.superAdmin.refreshToken';
const DEFAULT_API_BASE_URL = 'https://api.vikoplus.co.tz/v1';

type LoginResponse = {
  accessToken: string;
  refreshToken: string;
  user: {
    displayName?: string;
    isPlatformAdmin?: boolean;
  };
};

type MetricsResponse = {
  users?: { total?: number; verifiedIdentities?: number; platformAdmins?: number };
  groups?: { total?: number; activeMembers?: number; pendingInvitations?: number };
  subscriptions?: { total?: number; active?: number; activeAccessPackages?: number };
  contributions?: { approvedPayments?: number; approvedAmountMinor?: number };
  billing?: { successfulTransactions?: number; successfulAmountMinor?: number };
  reminders?: { sentCampaigns?: number; activePackages?: number };
};

type AdminGroupsResponse = {
  groups: Array<{
    name: string;
    type: string;
    country: string;
    primaryContact: string;
    membersCount: number;
    balanceMinor: number;
    currency: string;
    status: 'Active' | 'Pending' | 'Flagged';
  }>;
};

type AdminUsersResponse = {
  users: Array<{
    name: string;
    email?: string | null;
    phone?: string | null;
    role: string;
    groupName: string;
    kycStatus: 'Verified' | 'Pending';
    twoFactorStatus: 'Enabled' | 'Disabled';
    updatedAt: string;
  }>;
};

type AccessPlan = {
  code: string;
  name: string;
  description?: string | null;
  priceMinor: number;
  currency: string;
  interval: string;
  status: string;
  trialDays: number;
};

@Injectable({ providedIn: 'root' })
export class SuperAdminApi {
  private readonly http = inject(HttpClient);
  private readonly baseUrl =
    localStorage.getItem('vikoplus.apiBaseUrl') ?? DEFAULT_API_BASE_URL;

  get isAuthenticated(): boolean {
    return Boolean(this.accessToken);
  }

  get accessToken(): string | null {
    return localStorage.getItem(ACCESS_TOKEN_KEY);
  }

  async login(identifier: string, password: string): Promise<LoginResponse['user']> {
    const response = await firstValueFrom(
      this.http.post<LoginResponse>(`${this.baseUrl}/auth/login`, {
        identifier,
        password,
      }).pipe(timeout(10000)),
    );
    if (!response.user.isPlatformAdmin) {
      throw new Error('Platform admin access is required.');
    }
    localStorage.setItem(ACCESS_TOKEN_KEY, response.accessToken);
    localStorage.setItem(REFRESH_TOKEN_KEY, response.refreshToken);
    return response.user;
  }

  logout(): void {
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
  }

  async overviewStats(): Promise<StatCard[]> {
    const metrics = await firstValueFrom(
      this.http.get<MetricsResponse>(`${this.baseUrl}/admin/metrics`, {
        headers: this.authHeaders(),
      }),
    );
    return [
      {
        label: 'Total vault balance',
        value: this.money(metrics.contributions?.approvedAmountMinor ?? 0),
        delta: `${metrics.contributions?.approvedPayments ?? 0} approved payments`,
      },
      {
        label: 'Active groups',
        value: this.number(metrics.groups?.total ?? 0),
        delta: `${this.number(metrics.groups?.activeMembers ?? 0)} active members`,
      },
      {
        label: 'Total users',
        value: this.number(metrics.users?.total ?? 0),
        delta: `${this.number(metrics.users?.verifiedIdentities ?? 0)} verified identities`,
      },
      {
        label: 'Annual recurring revenue',
        value: this.money(metrics.billing?.successfulAmountMinor ?? 0),
        delta: `${metrics.subscriptions?.active ?? 0} active subscriptions`,
      },
    ];
  }

  async groups(): Promise<GroupRow[]> {
    const response = await firstValueFrom(
      this.http.get<AdminGroupsResponse>(`${this.baseUrl}/admin/groups`, {
        headers: this.authHeaders(),
      }),
    );
    return response.groups.map((group) => ({
      name: group.name,
      type: group.type,
      country: group.country,
      contact: group.primaryContact,
      members: group.membersCount,
      balance: this.money(group.balanceMinor, group.currency),
      status: group.status,
    }));
  }

  async users(): Promise<UserRow[]> {
    const response = await firstValueFrom(
      this.http.get<AdminUsersResponse>(`${this.baseUrl}/admin/users`, {
        headers: this.authHeaders(),
      }),
    );
    return response.users.map((user) => ({
      name: user.name,
      email: user.email ?? user.phone ?? 'No contact',
      role: user.role,
      group: user.groupName,
      kyc: user.kycStatus,
      twoFa: user.twoFactorStatus,
      lastActive: this.date(user.updatedAt),
    }));
  }

  async plans(): Promise<AccessPlan[]> {
    return firstValueFrom(
      this.http.get<AccessPlan[]>(`${this.baseUrl}/admin/access-plans`, {
        headers: this.authHeaders(),
      }),
    );
  }

  private authHeaders(): HttpHeaders {
    const token = this.accessToken;
    return token
      ? new HttpHeaders({ Authorization: `Bearer ${token}` })
      : new HttpHeaders();
  }

  private money(amountMinor: number, currency = 'KES'): string {
    return new Intl.NumberFormat('en-KE', {
      style: 'currency',
      currency,
      maximumFractionDigits: 0,
    }).format(amountMinor);
  }

  private number(value: number): string {
    return new Intl.NumberFormat('en-KE').format(value);
  }

  private date(value: string): string {
    return new Intl.DateTimeFormat('en-KE', {
      month: 'short',
      day: '2-digit',
      year: 'numeric',
    }).format(new Date(value));
  }
}
