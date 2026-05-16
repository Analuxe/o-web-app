import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationCenter extends StatelessWidget {
  final VoidCallback? onClose;
  const NotificationCenter({super.key, this.onClose});

  IconData _iconForType(String type) {
    switch (type) {
      case 'match_request':
        return Icons.person_add_alt_1;
      case 'match_accepted':
        return Icons.favorite;
      case 'new_message':
        return Icons.chat_bubble;
      case 'date_proposal':
        return Icons.calendar_month;
      case 'system':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'match_request':
        return Colors.purpleAccent;
      case 'match_accepted':
        return OTheme.neonPink;
      case 'new_message':
        return Colors.blueAccent;
      case 'date_proposal':
        return Colors.orangeAccent;
      case 'system':
        return Colors.tealAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: OTheme.neonPink, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => SupabaseService.markAllNotificationsRead(),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: OTheme.neonPink, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

          // Notification List
          Flexible(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService.getNotificationsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: OTheme.neonPink)),
                  );
                }

                final notifications = snapshot.data!
                    .map((json) => AppNotification.fromJson(json))
                    .toList();

                if (notifications.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        const Text(
                          "You're all caught up.",
                          style: TextStyle(color: Colors.white24, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.white.withValues(alpha: 0.04),
                    height: 1,
                    indent: 72,
                  ),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final typeColor = _colorForType(notif.type);

                    return Material(
                      color: notif.isRead
                          ? Colors.transparent
                          : OTheme.neonPink.withValues(alpha: 0.04),
                      child: InkWell(
                        onTap: () {
                          // Mark as read
                          if (!notif.isRead) {
                            SupabaseService.markNotificationRead(notif.id);
                          }
                          // Navigate if there's a route
                          if (notif.targetRoute != null) {
                            onClose?.call(); // Close the overlay
                            context.go(notif.targetRoute!);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar or Icon
                              if (notif.sourceAvatarUrl != null)
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(notif.sourceAvatarUrl!),
                                  backgroundColor: OTheme.deepCharcoal,
                                )
                              else
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: typeColor.withValues(alpha: 0.15),
                                  child: Icon(_iconForType(notif.type), color: typeColor, size: 20),
                                ),
                              const SizedBox(width: 14),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (!notif.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: OTheme.neonPink,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: OTheme.neonPink.withValues(alpha: 0.5),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (notif.body != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.body!,
                                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(_iconForType(notif.type), size: 12, color: typeColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          timeago.format(notif.createdAt),
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
