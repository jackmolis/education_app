import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notifications_provider.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when screen opens
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    final repo = ref.read(notificationsRepositoryProvider);
    await repo.markAllAsRead(user.id);
    if (mounted) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to load notifications.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (notifications) {
          // Filter out notifications that don't have a valid lesson_id or subject_id
          final validNotifications = notifications.where((n) => n.lessonId != null && n.subjectId != null).toList();

          if (validNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 72,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: validNotifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final notification = validNotifications[index];
                final isUnread = !notification.isRead;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isUnread
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    child: Icon(
                      isUnread
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_outlined,
                      color: isUnread
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.body != null && notification.body!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.body!,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(notification.createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  trailing: isUnread
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                  onTap: () async {
                    if (isUnread) {
                      final repo = ref.read(notificationsRepositoryProvider);
                      await repo.markAsRead(notification.id);
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadCountProvider);
                    }
                    final subjectId = notification.subjectId;
                    final lessonId = notification.lessonId;
                    if (subjectId != null && lessonId != null) {
                      if (!context.mounted) return;
                      context.push('/subjects/$subjectId/lesson/$lessonId');
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $ampm';
  }
}
