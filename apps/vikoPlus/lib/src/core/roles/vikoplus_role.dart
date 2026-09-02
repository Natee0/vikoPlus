import 'package:flutter/material.dart';

enum VikoplusRole { newUser, chairperson, treasurer, secretary, member }

extension VikoplusRoleDetails on VikoplusRole {
  String get label {
    switch (this) {
      case VikoplusRole.newUser:
        return 'New user';
      case VikoplusRole.chairperson:
        return 'Chairperson / Admin';
      case VikoplusRole.treasurer:
        return 'Treasurer';
      case VikoplusRole.secretary:
        return 'Secretary';
      case VikoplusRole.member:
        return 'Member';
    }
  }

  String get description {
    switch (this) {
      case VikoplusRole.newUser:
        return 'No group yet. Create a group or join one with an invitation.';
      case VikoplusRole.chairperson:
        return 'Full group setup, billing, reports, and member management.';
      case VikoplusRole.treasurer:
        return 'Contribution register, payment recording, receipts, and dues.';
      case VikoplusRole.secretary:
        return 'Member list, invitations, reminders, and group records.';
      case VikoplusRole.member:
        return 'Personal dashboard, dues, receipts, and own contributions.';
    }
  }

  String get verifyDestination {
    switch (this) {
      case VikoplusRole.newUser:
        return '/create-or-join-group';
      case VikoplusRole.chairperson:
      case VikoplusRole.treasurer:
      case VikoplusRole.secretary:
      case VikoplusRole.member:
        return '/groups';
    }
  }

  IconData get icon {
    switch (this) {
      case VikoplusRole.newUser:
        return Icons.person_add_alt_outlined;
      case VikoplusRole.chairperson:
        return Icons.admin_panel_settings_outlined;
      case VikoplusRole.treasurer:
        return Icons.account_balance_wallet_outlined;
      case VikoplusRole.secretary:
        return Icons.assignment_ind_outlined;
      case VikoplusRole.member:
        return Icons.person_outline;
    }
  }
}
