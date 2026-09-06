import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../common/vikoplus_screen.dart';

class ReminderCentreScreen extends ConsumerStatefulWidget {
  const ReminderCentreScreen({this.campaignId, super.key});
  final String? campaignId;
  @override
  ConsumerState<ReminderCentreScreen> createState() => _ReminderCentreState();
}

class _ReminderCentreState extends ConsumerState<ReminderCentreScreen> {
  String? _groupId;
  Future<List<Map<String, dynamic>>>? _future;
  Future<void> _refresh() async {
    final id = ref.read(activeGroupProvider)?.id;
    if (id == null) {
      return;
    }
    final future = ref.read(groupsRepositoryProvider).reminderCampaigns(id);
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(activeGroupProvider)?.id;
    if (id != _groupId) {
      _groupId = id;
      _future = id == null
          ? null
          : ref.read(groupsRepositoryProvider).reminderCampaigns(id);
    }
    return VikoplusScreen(
      title: widget.campaignId == null
          ? context.vt('Reminder Centre')
          : context.vt('Campaign Details'),
      backRoute: widget.campaignId == null ? '/more' : '/reminders',
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (id == null) {
            return Text(context.vt('Open a group to view reminders.'));
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                Text(context.vt('Could not load reminders. Please try again.')),
                TextButton(
                  onPressed: _refresh,
                  child: Text(context.vt('Retry')),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final campaigns = snapshot.data!;
          if (widget.campaignId != null) {
            final matches = campaigns.where(
              (item) => item['id'] == widget.campaignId,
            );
            if (matches.isEmpty) {
              return Text(context.vt('Campaign not found in this group.'));
            }
            final campaign = matches.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${campaign['title']}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  context.vtf('Channel: {value}', {
                    'value': campaign['channel'],
                  }),
                ),
                Text(
                  context.vtf('Recipients: {value}', {
                    'value': campaign['recipientCount'],
                  }),
                ),
                const SizedBox(height: 16),
                SelectableText('${campaign['body']}'),
                const SizedBox(height: 16),
                Text(
                  context.vtf('Sent: {value}', {
                    'value': campaign['sentAt'] ?? context.vt('Not sent'),
                  }),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () => context.push('/reminders/new'),
                icon: const Icon(Icons.sms_outlined),
                label: Text(context.vt('Send reminder')),
              ),
              const SizedBox(height: 24),
              Text(
                context.vtf('Campaigns ({count})', {'count': campaigns.length}),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (campaigns.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(context.vt('No campaigns sent yet.')),
                ),
              for (final campaign in campaigns)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(Icons.sms_outlined),
                    title: Text('${campaign['title']}'),
                    subtitle: Text(
                      context.vtf('{channel} - {count} recipients', {
                        'channel': campaign['channel'],
                        'count': campaign['recipientCount'],
                      }),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/reminders/campaigns/${Uri.encodeComponent(campaign['id'] as String)}',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
