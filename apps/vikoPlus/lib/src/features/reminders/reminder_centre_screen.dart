import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class ReminderCentreScreen extends StatelessWidget {
  const ReminderCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Reminder Centre',
      backRoute: '/more',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          InfoCard(
            title: 'Scheduled reminders',
            value: '3',
            icon: Icons.schedule_send_outlined,
          ),
          SizedBox(height: 12),
          InfoCard(
            title: 'Overdue members',
            value: '22',
            icon: Icons.notifications_active_outlined,
            accentColor: AppColors.warning,
          ),
          SizedBox(height: 16),
          ActionTile(
            title: 'Send Reminder',
            subtitle:
                'Compose SMS or WhatsApp for members with outstanding dues',
            icon: Icons.schedule_send_outlined,
            route: '/reminders/new',
            color: AppColors.primaryGreen,
          ),
          SizedBox(height: 16),
          SectionHeader(title: 'Campaigns'),
          SizedBox(height: 12),
          ActionTile(
            title: 'July dues reminder',
            subtitle: 'Review delivery status for the latest sent campaign',
            icon: Icons.sms_outlined,
            route: '/reminders/campaigns/july-dues',
            color: AppColors.secondaryGreen,
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Joining fee follow-up',
            subtitle: 'WhatsApp message template ready for review',
            icon: Icons.chat_outlined,
            route: '/reminders/new',
            color: AppColors.secondaryGreen,
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Message templates',
            subtitle: 'Maintain reusable SMS and WhatsApp copy',
            icon: Icons.article_outlined,
            route: '/reminders/templates',
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }
}
