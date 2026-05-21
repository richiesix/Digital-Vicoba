import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/nav_icons.dart';
import '../../../l10n/app_localizations.dart';

class _NotifItem {
  _NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String type;
  bool isRead;
  final DateTime? createdAt;

  factory _NotifItem.fromJson(Map<String, dynamic> json) {
    return _NotifItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Color get accentColor => switch (type) {
        'meeting' => AppColors.savings,
        'payment' => AppColors.pending,
        'loan' => AppColors.overdue,
        'alert' => const Color(0xFF1565C0),
        _ => AppColors.primary,
      };

  IconData get icon => switch (type) {
        'meeting' => Icons.event,
        'payment' => Icons.payments,
        'loan' => Icons.request_quote,
        _ => Icons.notifications_outlined,
      };
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<_NotifItem> _items = [];
  bool _loading = true;
  bool _showOld = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _unreadCount => _items.where((n) => !n.isRead).length;

  List<_NotifItem> get _unreadItems {
    final list = _items.where((n) => !n.isRead).toList();
    list.sort((a, b) => _compareDate(b.createdAt, a.createdAt));
    return list;
  }

  List<_NotifItem> get _readItems {
    final list = _items.where((n) => n.isRead).toList();
    list.sort((a, b) => _compareDate(b.createdAt, a.createdAt));
    return list;
  }

  int _compareDate(DateTime? a, DateTime? b) {
    final ad = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ad.compareTo(bd);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).get('/notifications');
      final data = res.data;
      final list = (data is Map && data['data'] is List)
          ? data['data'] as List
          : (data is List ? data : <dynamic>[]);

      setState(() {
        _items = list.map((e) => _NotifItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (_items.isEmpty) _items = _demoItems(context.l10n);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = _demoItems(context.l10n);
        _loading = false;
      });
    }
  }

  List<_NotifItem> _demoItems(AppLocalizations l10n) => [
        _NotifItem(
          id: 1,
          title: l10n.meetingReminder,
          body: 'Mkutano wa wiki unaanza saa 5:00 leo.',
          type: 'meeting',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        _NotifItem(
          id: 2,
          title: l10n.paymentReminder,
          body: 'Malipo ya hisa yanatarajiwa leo.',
          type: 'payment',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        _NotifItem(
          id: 3,
          title: l10n.applyLoan,
          body: 'Ombi lako la mkopo limeidhinishwa na kamati.',
          type: 'loan',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

  Future<void> _markRead(_NotifItem item) async {
    if (item.isRead) return;
    try {
      if (item.id > 0) {
        await ref.read(apiClientProvider).patch('/notifications/${item.id}/read');
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => item.isRead = true);
    HapticFeedback.lightImpact();
  }

  Future<void> _markAllRead() async {
    final unread = _unreadItems;
    if (unread.isEmpty) return;

    for (final item in unread) {
      try {
        if (item.id > 0) {
          await ref.read(apiClientProvider).patch('/notifications/${item.id}/read');
        }
      } catch (_) {}
      item.isRead = true;
    }

    if (!mounted) return;
    setState(() {});
    HapticFeedback.lightImpact();
  }

  String _formatTime(_NotifItem item, AppLocalizations l10n) {
    final dt = item.createdAt?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return l10n.todayAt(DateFormat('HH:mm').format(dt));
    }
    return DateFormat('d MMM, HH:mm').format(dt);
  }

  Future<void> _showDetail(_NotifItem item) async {
    HapticFeedback.lightImpact();
    if (!item.isRead) await _markRead(item);
    if (!mounted) return;
    final l10n = context.l10n;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          blur: 18,
          opacity: 0.75,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _NotifIconBubble(item: item, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (item.isRead) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: AppColors.savings),
                              const SizedBox(width: 4),
                              Text(
                                l10n.notificationOpened,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.savings,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(item.body, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
              const SizedBox(height: 8),
              Text(_formatTime(item, l10n), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNotificationSections(AppLocalizations l10n) {
    final unread = _unreadItems;
    final read = _readItems;
    final widgets = <Widget>[];

    if (unread.isEmpty && read.isEmpty) {
      return widgets;
    }

    if (unread.isNotEmpty) {
      widgets.add(_SectionLabel(title: l10n.newNotifications, count: unread.length));
      for (final item in unread) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NotificationGlassTile(
              item: item,
              timeLabel: _formatTime(item, l10n),
              openedLabel: l10n.notificationOpened,
              onTap: () => _showDetail(item),
            ),
          ),
        );
      }
    } else if (read.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            opacity: 0.4,
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.grey.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.noNewNotifications,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (read.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        GlassCard(
          onTap: () {
            setState(() => _showOld = !_showOld);
            HapticFeedback.selectionClick();
          },
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          opacity: 0.4,
          child: Row(
            children: [
              Icon(
                _showOld ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _showOld ? l10n.hideOldNotifications : l10n.showOldNotifications(read.length),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (_showOld) {
        widgets.add(const SizedBox(height: 12));
        widgets.add(_SectionLabel(title: l10n.oldNotifications, count: read.length, dimmed: true));
        for (final item in read) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NotificationGlassTile(
                item: item,
                timeLabel: _formatTime(item, l10n),
                openedLabel: l10n.notificationOpened,
                onTap: () => _showDetail(item),
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = _buildNotificationSections(l10n);
    final hasContent = _items.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          const _GlassBackground(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: Colors.white,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _NotificationsHeader(l10n: l10n, unread: _unreadCount)),
                        if (_unreadCount > 0)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _markAllRead,
                                  child: Text(
                                    l10n.markAllRead,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!hasContent)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 220,
                              child: Center(
                                child: GlassCard(
                                  margin: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade500),
                                      const SizedBox(height: 12),
                                      Text(l10n.noNotifications),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate(sections),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GlassBackground extends StatelessWidget {
  const _GlassBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({required this.l10n, required this.unread});

  final AppLocalizations l10n;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(10),
            borderRadius: 14,
            blur: 8,
            opacity: 0.35,
            child: SvgPicture.asset(
              NavIcons.notifications,
              width: 28,
              height: 28,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notifications,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.notificationsSubtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          if (unread > 0)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: 20,
              blur: 6,
              opacity: 0.4,
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.count,
    this.dimmed = false,
  });

  final String title;
  final int count;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: dimmed ? Colors.white.withValues(alpha: 0.75) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: dimmed ? 0.15 : 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.white.withValues(alpha: dimmed ? 0.85 : 1),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifIconBubble extends StatelessWidget {
  const _NotifIconBubble({required this.item, this.size = 44});

  final _NotifItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            item.accentColor.withValues(alpha: 0.35),
            item.accentColor.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Icon(item.icon, color: item.accentColor, size: size * 0.45),
    );
  }
}

class _NotificationGlassTile extends StatelessWidget {
  const _NotificationGlassTile({
    required this.item,
    required this.timeLabel,
    required this.openedLabel,
    required this.onTap,
  });

  final _NotifItem item;
  final String timeLabel;
  final String openedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      opacity: item.isRead ? 0.45 : 0.62,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotifIconBubble(item: item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.savings,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      timeLabel,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    if (item.isRead) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.done_all, size: 14, color: AppColors.savings),
                      const SizedBox(width: 4),
                      Text(
                        openedLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.savings,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            item.isRead ? Icons.check_circle_outline : Icons.chevron_right,
            color: item.isRead ? AppColors.savings : Colors.grey.shade500,
          ),
        ],
      ),
    );
  }
}
