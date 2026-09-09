export type StatCard = {
  label: string;
  value: string;
  delta: string;
};

export type GroupRow = {
  name: string;
  type: string;
  country: string;
  contact: string;
  members: number;
  balance: string;
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

export const sampleGroups: GroupRow[] = [
  {
    name: 'Markaz SACCO',
    type: 'Regional SACCO',
    country: 'Kenya',
    contact: 'Fatma Ally',
    members: 34,
    balance: 'KES 2,120,000',
    status: 'Active',
  },
  {
    name: 'Nuru Self Help Chama',
    type: 'Welfare Chama',
    country: 'Tanzania',
    contact: 'Michael Otieno',
    members: 48,
    balance: 'KES 178,000',
    status: 'Active',
  },
  {
    name: 'Pamoja Youth Club',
    type: 'Investment Club',
    country: 'Tanzania',
    contact: 'Grace Wanjiru',
    members: 19,
    balance: 'KES 54,200',
    status: 'Active',
  },
  {
    name: 'Beta Harvest Enterprise Chama',
    type: 'Commercial Chama',
    country: 'Kenya',
    contact: 'Ochieng Okumu',
    members: 24,
    balance: 'KES 430,000',
    status: 'Active',
  },
  {
    name: 'Nature Agri Cooperative',
    type: 'Agricultural Coop',
    country: 'Tanzania',
    contact: 'Peter Kimani',
    members: 128,
    balance: 'KES 4,520,000',
    status: 'Active',
  },
  {
    name: 'Mombasa Coast Traders Fund',
    type: 'Trade Chama',
    country: 'Kenya',
    contact: 'Salim Rashid',
    members: 89,
    balance: 'KES 890,000',
    status: 'Pending',
  },
  {
    name: 'Rafiki Lights Youth Chama',
    type: 'Youth Fund',
    country: 'Kenya',
    contact: 'Brian Kamau',
    members: 13,
    balance: 'KES 220,000',
    status: 'Flagged',
  },
];
