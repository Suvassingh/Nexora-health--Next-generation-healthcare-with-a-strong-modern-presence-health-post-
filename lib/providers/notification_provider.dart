

import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
  }) => NotificationState(
    notifications: notifications ?? this.notifications,
    isLoading: isLoading ?? this.isLoading,
  );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    fetchAll();
  }

  final _supabase = Supabase.instance.client;

  Future<void> fetchAll() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final rows = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      state = state.copyWith(
        notifications: (rows as List)
            .map((r) => AppNotification.fromJson(r as Map<String, dynamic>))
            .toList(),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void addNew(AppNotification n) {
    state = state.copyWith(notifications: [n, ...state.notifications]);
  }

  Future<void> markRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
  }

  Future<void> markAllRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(),
    );
  }

  Future<void> deleteNotification(String id) async {
    await _supabase.from('notifications').delete().eq('id', id);
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
      (_) => NotificationNotifier(),
    );
