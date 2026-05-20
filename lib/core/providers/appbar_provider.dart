import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current AppBar configuration set by the active screen.
class AppBarConfig {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBackButton;

  const AppBarConfig({
    this.title = '',
    this.subtitle,
    this.actions = const [],
    this.showBackButton = false,
  });

  AppBarConfig copyWith({
    String? title,
    String? subtitle,
    List<Widget>? actions,
    bool? showBackButton,
  }) {
    return AppBarConfig(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      actions: actions ?? this.actions,
      showBackButton: showBackButton ?? this.showBackButton,
    );
  }
}

/// Global provider that screens update to control the shell's AppBar.
final appBarConfigProvider = StateProvider<AppBarConfig>(
  (ref) => const AppBarConfig(title: 'Nexora Academy'),
);
