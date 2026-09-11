export type StatCard = {
  label: string;
  value: string;
  delta: string;
};

export type GroupRow = {
  id?: string;
  name: string;
  type: string;
  country: string;
  contact: string;
  members: number;
  balance: string;
  currency?: string;
  status: 'Active' | 'Pending' | 'Flagged';
};

export type UserRow = {
  name: string;
  email: string;
  role: string;
  group: string;
  kyc: 'Verified' | 'Pending';
  twoFa: 'Enabled' | 'Disabled';
  lastActive: string;
};
