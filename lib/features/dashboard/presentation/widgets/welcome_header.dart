import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/language_switcher.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

class WelcomeHeader extends ConsumerStatefulWidget {
  final int unreadCount;
  final bool isLoading;
  final VoidCallback onNotificationTap;
  final VoidCallback onLogout;

  const WelcomeHeader({
    super.key,
    required this.unreadCount,
    required this.isLoading,
    required this.onNotificationTap,
    required this.onLogout,
  });

  @override
  ConsumerState<WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends ConsumerState<WelcomeHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final loc = AppLocalizations.of(context)!;
    if (hour < 12) return loc.goodMorning;
    if (hour < 17) return loc.goodAfternoon;
    return loc.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final userState = ref.watch(authStateChangesProvider);
    final email = userState.value?.email ?? 'Student';
    final displayName =
        email.contains('@') ? email.split('@').first : email;
    final locale = ref.watch(localeProvider);
    final now = DateTime.now();
    final dateStr = DateFormat.yMMMMEEEEd(locale.languageCode).format(now);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + action buttons
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👋 ${_greeting(context)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF1F5F9).withValues(alpha: 0.8)
                                : const Color(0xFF1E293B).withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          loc.helloUser(displayName),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Language Switcher
                  LanguageSwitcher(
                    iconColor: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1E293B),
                    textColor: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1E293B),
                  ),
                  const SizedBox(width: 8),
                  // Notification bell
                  _ActionButton(
                    isDark: isDark,
                    onTap: widget.onNotificationTap,
                    child: Badge(
                      isLabelVisible: widget.unreadCount > 0,
                      label: Text(
                        '${widget.unreadCount}',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: const Color(0xFFFF8A00),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Logout
                  if (widget.isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    _ActionButton(
                      isDark: isDark,
                      onTap: widget.onLogout,
                      child: Icon(
                        Icons.logout_rounded,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                        size: 22,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Date row (streak removed)
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small reusable icon button container used in the header.
class _ActionButton extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final VoidCallback onTap;

  const _ActionButton({
    required this.isDark,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
