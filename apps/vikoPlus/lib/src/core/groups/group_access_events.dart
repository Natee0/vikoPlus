import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupAccessEventsProvider =
    NotifierProvider<GroupAccessEvents, ({String groupId, int revision})?>(
      GroupAccessEvents.new,
    );

class GroupAccessEvents extends Notifier<({String groupId, int revision})?> {
  @override
  ({String groupId, int revision})? build() => null;

  void denied(String groupId) {
    state = (groupId: groupId, revision: (state?.revision ?? 0) + 1);
  }
}
