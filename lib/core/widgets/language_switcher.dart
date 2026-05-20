import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

class LanguageSwitcher extends ConsumerWidget {
  final Color iconColor;
  final Color textColor;
  
  const LanguageSwitcher({
    super.key,
    this.iconColor = Colors.black87,
    this.textColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentLocale.languageCode,
        icon: Icon(Icons.language, color: iconColor, size: 20),
        dropdownColor: Theme.of(context).cardColor,
        alignment: Alignment.centerRight,
        items: [
          DropdownMenuItem(
            value: 'en',
            child: Text('EN', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          ),
          DropdownMenuItem(
            value: 'fr',
            child: Text('FR', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          ),
          DropdownMenuItem(
            value: 'ar',
            child: Text('AR', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          ),
        ],
        onChanged: (String? newCode) {
          if (newCode != null) {
            ref.read(localeProvider.notifier).setLocale(Locale(newCode));
          }
        },
      ),
    );
  }
}
