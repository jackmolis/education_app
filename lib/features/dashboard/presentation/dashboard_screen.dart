import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../authentication/presentation/controllers/auth_controller.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import 'widgets/welcome_header.dart';
import 'widgets/daily_goal_card.dart';
import 'widgets/continue_learning_card.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ref.read(authControllerProvider).signOut();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);

    return AppScaffold(
      useSafeArea: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Header
            WelcomeHeader(
              unreadCount: unreadCount,
              isLoading: _isLoading,
              onNotificationTap: () => context.push('/notifications'),
              onLogout: _logout,
            ),
            const SizedBox(height: 20),
            // 2. Daily Goal Card
            const DailyGoalCard(),
            const SizedBox(height: 24),
            // 3. Continue Learning Card
            const ContinueLearningCard(),
            const SizedBox(height: 24),
            // 4. Levels Section
            const LevelsListWidget(),
            const SizedBox(height: 24),
            // 5. Live Session Card
            const LiveSessionCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// LevelsListWidget
// ==========================================

class LevelsListWidget extends StatelessWidget {
  const LevelsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final levels = [
      {
        'title': loc.primarySchool,
        'subtitle': loc.selectLevel,
        'icon': Icons.child_care_rounded,
        'color': Colors.orangeAccent,
      },
      {
        'title': loc.middleSchool,
        'subtitle': loc.selectLevel,
        'icon': Icons.school_rounded,
        'color': Colors.blueAccent,
      },
      {
        'title': loc.highSchool,
        'subtitle': loc.selectLevel,
        'icon': Icons.menu_book_rounded,
        'color': Colors.purpleAccent,
      },
    ];

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.levels,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: levels.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final level = levels[index];
              return _LevelCard(
                title: level['title'] as String,
                subtitle: level['subtitle'] as String,
                icon: level['icon'] as IconData,
                color: level['color'] as Color,
                onTap: () {
                  if (index == 0) {
                    context.push('/dashboard/primary');
                  } else if (index == 1) {
                    context.push('/dashboard/middle');
                  } else if (index == 2) {
                    context.push('/dashboard/high');
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LevelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  bool _isHovering = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isTapped = true),
        onTapUp: (_) {
          setState(() => _isTapped = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isTapped = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isTapped ? 0.98 : (_isHovering ? 1.02 : 1.0)),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isHovering 
                    ? widget.color.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isHovering ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// LiveSessionCard
// ==========================================

class LiveSessionCard extends StatefulWidget {
  const LiveSessionCard({super.key});

  @override
  State<LiveSessionCard> createState() => _LiveSessionCardState();
}

class _LiveSessionCardState extends State<LiveSessionCard> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isHoveringButton = false;
  bool _isTappingButton = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onJoinPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      final loc = AppLocalizations.of(context)!;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.joiningLiveSession),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.primary.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.live_tv_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.joinLive,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.enterEmailToAccess,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    hintText: loc.userExample,
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.pleaseEnterEmail;
                    }
                    final emailRegex = RegExp(
                        r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                    if (!emailRegex.hasMatch(value)) {
                      return loc.pleaseEnterValidEmail;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              MouseRegion(
                onEnter: (_) => setState(() => _isHoveringButton = true),
                onExit: (_) => setState(() => _isHoveringButton = false),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isTappingButton = true),
                  onTapUp: (_) => setState(() => _isTappingButton = false),
                  onTapCancel: () => setState(() => _isTappingButton = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    transform: Matrix4.identity()
                      ..scale(_isTappingButton ? 0.95 : (_isHoveringButton ? 1.02 : 1.0)),
                    child: ElevatedButton(
                      onPressed: _onJoinPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isHoveringButton ? 6 : 2,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        loc.joinNow,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
