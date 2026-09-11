import { HttpClient, HttpErrorResponse, HttpHeaders } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Router } from '@angular/router';
import { firstValueFrom, Observable, timeout } from 'rxjs';

import { GroupRow, StatCard, UserRow } from '../shared/super-admin-data';

const ACCESS_TOKEN_KEY = 'vikoplus.superAdmin.accessToken';
const REFRESH_TOKEN_KEY = 'vikoplus.superAdmin.refreshToken';
const USER_KEY = 'vikoplus.superAdmin.user';
const DEFAULT_API_BASE_URL = 'https://api.vikoplus.co.tz/v1';

type LoginResponse = {
  accessToken: string;
  refreshToken: string;
  user: {
    displayName?: string;
    isPlatformAdmin?: boolean;
  };
};

export type SuperAdminUser = LoginResponse['user'];

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
    id?: string;
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

export type AccessPlan = {
  code: string;
  name: string;
  description?: string | null;
  priceMinor: number;
  currency: string;
  interval: string;
  intervalCount: number;
  status: string;
  trialDays: number;
};

export type ReminderPackage = {
  code: string;
  name: string;
  description?: string | null;
  channel: 'SMS' | 'WHATSAPP' | 'BOTH';
  amountMinor: number;
  quantity: number;
  currency: string;
  isActive: boolean;
};

export type UpsertGroupInput = {
  name: string;
  type?: string;
  location?: string;
  description?: string;
  currency?: string;
};

export type CreateAccessPlanInput = {
  code: string;
  name: string;
  description?: string;
  priceMinor: number;
  currency: string;
  interval: 'MONTH' | 'YEAR';
  intervalCount: number;
  trialDays?: number;
  status?: 'ACTIVE' | 'INACTIVE' | 'ARCHIVED';
  featureEntitlements?: Record<string, unknown>;
};

export type UpdateAccessPlanInput = Partial<Omit<CreateAccessPlanInput, 'code'>>;

export type CreateReminderPackageInput = {
  code: string;
  name: string;
  description?: string;
  channel: 'SMS' | 'WHATSAPP' | 'BOTH';
  amountMinor: number;
  quantity: number;
  currency: string;
  isActive?: boolean;
};

export type UpdateReminderPackageInput = Partial<Omit<CreateReminderPackageInput, 'code'>>;

@Injectable({ providedIn: 'root' })
export class SuperAdminApi {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly baseUrl =
    localStorage.getItem('vikoplus.apiBaseUrl') ?? DEFAULT_API_BASE_URL;
  private refreshPromise: Promise<void> | null = null;

  get isAuthenticated(): boolean {
    return Boolean(this.accessToken || this.refreshToken);
  }

  get accessToken(): string | null {
    return localStorage.getItem(ACCESS_TOKEN_KEY);
  }

  get refreshToken(): string | null {
    return localStorage.getItem(REFRESH_TOKEN_KEY);
  }

  get currentUser(): SuperAdminUser | null {
    const raw = localStorage.getItem(USER_KEY);
    if (!raw) {
      return null;
    }
    try {
      return JSON.parse(raw) as SuperAdminUser;
    } catch {
      localStorage.removeItem(USER_KEY);
      return null;
    }
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
    localStorage.setItem(USER_KEY, JSON.stringify(response.user));
    return response.user;
  }

  logout(): void {
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
  }

  async ensureAuthenticated(): Promise<boolean> {
    if (this.accessToken) {
      return true;
    }
    if (!this.refreshToken) {
      return false;
    }
    try {
      await this.refreshSession();
      return true;
    } catch {
      return false;
    }
  }

  async metrics(): Promise<MetricsResponse> {
    return this.authenticatedRequest(() =>
      this.http.get<MetricsResponse>(`${this.baseUrl}/admin/metrics`, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  async overviewStats(): Promise<StatCard[]> {
    const metrics = await this.metrics();
    return [
      {
        label: 'Total vault balance',
        value: this.money(metrics.contributions?.approvedAmountMinor ?? 0, 'TZS'),
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
        value: this.money(metrics.billing?.successfulAmountMinor ?? 0, 'TZS'),
        delta: `${metrics.subscriptions?.active ?? 0} active subscriptions`,
      },
    ];
  }

  async groupStats(): Promise<StatCard[]> {
    const metrics = await this.metrics();
    return [
      {
        label: 'Total groups',
        value: this.number(metrics.groups?.total ?? 0),
        delta: `${this.number(metrics.groups?.activeMembers ?? 0)} active members`,
      },
      {
        label: 'Pending invitations',
        value: this.number(metrics.groups?.pendingInvitations ?? 0),
        delta: 'Open group invitations',
      },
      {
        label: 'Approved contribution volume',
        value: this.money(metrics.contributions?.approvedAmountMinor ?? 0, 'TZS'),
        delta: `${this.number(metrics.contributions?.approvedPayments ?? 0)} approved payments`,
      },
      {
        label: 'Active subscriptions',
        value: this.number(metrics.subscriptions?.active ?? 0),
        delta: `${this.number(metrics.subscriptions?.total ?? 0)} total subscriptions`,
      },
    ];
  }

  async userStats(): Promise<StatCard[]> {
    const metrics = await this.metrics();
    return [
      {
        label: 'Total users',
        value: this.number(metrics.users?.total ?? 0),
        delta: `${this.number(metrics.users?.verifiedIdentities ?? 0)} verified identities`,
      },
      {
        label: 'Platform admins',
        value: this.number(metrics.users?.platformAdmins ?? 0),
        delta: 'Super-admin access accounts',
      },
      {
        label: 'Active members',
        value: this.number(metrics.groups?.activeMembers ?? 0),
        delta: 'Across all groups',
      },
      {
        label: 'Pending invitations',
        value: this.number(metrics.groups?.pendingInvitations ?? 0),
        delta: 'Awaiting acceptance',
      },
    ];
  }

  async packageStats(): Promise<StatCard[]> {
    const metrics = await this.metrics();
    return [
      {
        label: 'Active subscriptions',
        value: this.number(metrics.subscriptions?.active ?? 0),
        delta: `${this.number(metrics.subscriptions?.total ?? 0)} total subscriptions`,
      },
      {
        label: 'Active access packages',
        value: this.number(metrics.subscriptions?.activeAccessPackages ?? 0),
        delta: 'Published subscription plans',
      },
      {
        label: 'Successful billing',
        value: this.money(metrics.billing?.successfulAmountMinor ?? 0, 'TZS'),
        delta: `${this.number(metrics.billing?.successfulTransactions ?? 0)} successful transactions`,
      },
      {
        label: 'Reminder packages',
        value: this.number(metrics.reminders?.activePackages ?? 0),
        delta: `${this.number(metrics.reminders?.sentCampaigns ?? 0)} sent campaigns`,
      },
    ];
  }

  async groups(): Promise<GroupRow[]> {
    const response = await this.authenticatedRequest(() =>
      this.http.get<AdminGroupsResponse>(`${this.baseUrl}/admin/groups`, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
    return response.groups.map((group) => ({
      id: group.id,
      name: group.name,
      type: group.type,
      country: group.country,
      contact: group.primaryContact,
      members: group.membersCount,
      balance: this.money(group.balanceMinor, group.currency),
      currency: group.currency,
      status: group.status,
    }));
  }

  async createGroup(input: UpsertGroupInput): Promise<void> {
    await this.authenticatedRequest(() =>
      this.http.post(`${this.baseUrl}/admin/groups`, input, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  async updateGroup(groupId: string, input: UpsertGroupInput): Promise<void> {
    await this.authenticatedRequest(() =>
      this.http.patch(`${this.baseUrl}/admin/groups/${groupId}`, input, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  async deleteGroup(groupId: string): Promise<void> {
    await this.authenticatedRequest(() =>
      this.http.delete(`${this.baseUrl}/admin/groups/${groupId}`, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  async users(): Promise<UserRow[]> {
    const response = await this.authenticatedRequest(() =>
      this.http.get<AdminUsersResponse>(`${this.baseUrl}/admin/users`, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
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
    return this.authenticatedRequest(() =>
      this.http.get<AccessPlan[]>(`${this.baseUrl}/admin/access-plans`, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  async reminderPackages(): Promise<ReminderPackage[]> {
    return this.authenticatedRequest(() =>
      this.http.get<ReminderPackage[]>(`${this.baseUrl}/admin/reminder-packages`, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  async createPlan(input: CreateAccessPlanInput): Promise<void> {
    await this.authenticatedRequest(() =>
      this.http.post(`${this.baseUrl}/admin/access-plans`, input, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  async updatePlan(code: string, input: UpdateAccessPlanInput): Promise<void> {
    await this.authenticatedRequest(() =>
      this.http.patch(`${this.baseUrl}/admin/access-plans/${code}`, input, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  async createReminderPackage(input: CreateReminderPackageInput): Promise<void> {
    await this.authenticatedRequest(() =>
      this.http.post(`${this.baseUrl}/admin/reminder-packages`, input, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  async updateReminderPackage(
    code: string,
    input: UpdateReminderPackageInput,
  ): Promise<void> {
    await this.authenticatedRequest(() =>
      this.http.patch(`${this.baseUrl}/admin/reminder-packages/${code}`, input, {
        headers: this.authHeaders(),
      }).pipe(timeout(15000)),
    );
  }

  private authHeaders(): HttpHeaders {
    const token = this.accessToken;
    return token
      ? new HttpHeaders({ Authorization: `Bearer ${token}` })
      : new HttpHeaders();
  }

  private async authenticatedRequest<T>(
    request: () => Observable<T>,
  ): Promise<T> {
    try {
      return await firstValueFrom(request());
    } catch (error) {
      if (!this.isUnauthorized(error)) {
        throw error;
      }
      try {
        await this.refreshSession();
        return await firstValueFrom(request());
      } catch (refreshError) {
        this.logout();
        void this.router.navigateByUrl('/login');
        throw refreshError;
      }
    }
  }

  private async refreshSession(): Promise<void> {
    if (this.refreshPromise) {
      return this.refreshPromise;
    }
    const refreshToken = this.refreshToken;
    if (!refreshToken) {
      this.logout();
      throw new Error('Session expired. Please sign in again.');
    }
    this.refreshPromise = firstValueFrom(
      this.http.post<LoginResponse>(`${this.baseUrl}/auth/refresh`, {
        refreshToken,
      }).pipe(timeout(10000)),
    )
      .then((response) => {
        if (!response.user.isPlatformAdmin) {
          throw new Error('Platform admin access is required.');
        }
        localStorage.setItem(ACCESS_TOKEN_KEY, response.accessToken);
        localStorage.setItem(REFRESH_TOKEN_KEY, response.refreshToken);
        localStorage.setItem(USER_KEY, JSON.stringify(response.user));
      })
      .catch((error) => {
        this.logout();
        throw error;
      })
      .finally(() => {
        this.refreshPromise = null;
      });
    return this.refreshPromise;
  }

  private isUnauthorized(error: unknown): boolean {
    return error instanceof HttpErrorResponse && error.status === 401;
  }

  private money(amountMinor: number, currency = 'TZS'): string {
    return new Intl.NumberFormat('en-TZ', {
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
