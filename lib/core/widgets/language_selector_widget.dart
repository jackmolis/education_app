import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

class LanguageSelectorWidget extends ConsumerWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLangButton(context, ref, 'en', 'EN', locale.languageCode == 'en'),
        const SizedBox(width: 8),
        _buildLangButton(context, ref, 'fr', 'FR', locale.languageCode == 'fr'),
        const SizedBox(width: 8),
        _buildLangButton(context, ref, 'ar', 'AR', locale.languageCode == 'ar'),
      ],
    );
  }

  Widget _buildLangButton(BuildContext context, WidgetRef ref, String code, String label, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).changeLocale(code);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
          ),
        ),
      ),
    );
  }
}
