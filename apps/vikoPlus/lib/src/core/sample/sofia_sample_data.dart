class SofiaMember {
  const SofiaMember({
    required this.number,
    required this.name,
    required this.joiningPaid,
    required this.monthlyPaid,
  });

  final String number;
  final String name;
  final int joiningPaid;
  final int monthlyPaid;

  int get totalPaid => joiningPaid + monthlyPaid;
  int get expectedTotal => 70000;
  int get outstanding => expectedTotal - totalPaid;
  int get paidMonths => monthlyPaid ~/ 5000;
  bool get fullyPaid => outstanding <= 0;
  String get initials => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();
}

const sofiaMembers = [
  SofiaMember(
    number: 'SW-001',
    name: 'Aginess Lupili',
    joiningPaid: 0,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-002',
    name: 'Amina Issa',
    joiningPaid: 0,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-003',
    name: 'Anthony Luganda',
    joiningPaid: 0,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-004',
    name: 'Boniphace Lupili',
    joiningPaid: 10000,
    monthlyPaid: 10000,
  ),
  SofiaMember(
    number: 'SW-005',
    name: 'Emmanuel Malekela Madahula',
    joiningPaid: 10000,
    monthlyPaid: 60000,
  ),
  SofiaMember(
    number: 'SW-006',
    name: 'Ester LupilinGeofrey',
    joiningPaid: 0,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-007',
    name: 'Esteria Luganda',
    joiningPaid: 0,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-008',
    name: 'Gervas Luganda',
    joiningPaid: 0,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-009',
    name: 'Hans Lupili',
    joiningPaid: 10000,
    monthlyPaid: 5000,
  ),
  SofiaMember(
    number: 'SW-010',
    name: 'Issa Mbehuzi',
    joiningPaid: 10000,
    monthlyPaid: 5000,
  ),
  SofiaMember(
    number: 'SW-011',
    name: 'Jelaledina Masanja',
    joiningPaid: 10000,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-012',
    name: 'Joseph Marco',
    joiningPaid: 10000,
    monthlyPaid: 5000,
  ),
  SofiaMember(
    number: 'SW-013',
    name: 'Lucas Lupili',
    joiningPaid: 10000,
    monthlyPaid: 5000,
  ),
  SofiaMember(
    number: 'SW-014',
    name: 'Magreth Vililo',
    joiningPaid: 10000,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-015',
    name: 'Mariana Kusagwa',
    joiningPaid: 10000,
    monthlyPaid: 10000,
  ),
  SofiaMember(
    number: 'SW-016',
    name: 'Martina Lupili',
    joiningPaid: 10000,
    monthlyPaid: 20000,
  ),
  SofiaMember(
    number: 'SW-017',
    name: 'Paschal Lupili',
    joiningPaid: 0,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-018',
    name: 'Rachel Lupili',
    joiningPaid: 0,
    monthlyPaid: 0,
  ),
  SofiaMember(
    number: 'SW-019',
    name: 'Regina Kuyela',
    joiningPaid: 10000,
    monthlyPaid: 10000,
  ),
  SofiaMember(
    number: 'SW-020',
    name: 'Simon Madahula',
    joiningPaid: 10000,
    monthlyPaid: 10000,
  ),
  SofiaMember(
    number: 'SW-021',
    name: 'Thomas Bundala',
    joiningPaid: 10000,
    monthlyPaid: 5000,
  ),
  SofiaMember(
    number: 'SW-022',
    name: 'Veronica Marko',
    joiningPaid: 10000,
    monthlyPaid: 5000,
  ),
  SofiaMember(
    number: 'SW-023',
    name: 'Willybard Kazala',
    joiningPaid: 10000,
    monthlyPaid: 5000,
  ),
];

const sofiaMonthTotals = [
  ('Jul', 65000),
  ('Aug', 30000),
  ('Sep', 10000),
  ('Oct', 10000),
  ('Nov', 5000),
  ('Dec', 5000),
  ('Jan', 5000),
  ('Feb', 5000),
  ('Mar', 5000),
  ('Apr', 5000),
  ('May', 5000),
  ('Jun', 5000),
];

const sofiaTotalContributions = 305000;
const sofiaJoiningFees = 150000;
const sofiaMonthlyFees = 155000;
const sofiaOutstanding = 1305000;
const sofiaFinancialYear = 'July 2026 - June 2027';
const vikoplusGroupAccessAnnualPrice = 10000;
const vikoplusSmsReminderPrice = 50;
const vikoplusWhatsAppReminderPrice = 50;
const vikoplusSmsAndWhatsAppReminderPrice = 100;
