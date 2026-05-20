import 'package:flutter/material.dart';
import '../../../../core/widgets/smart_math_view.dart';
import 'advanced_math_modal.dart';

class MathEditor extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;

  const MathEditor({
    super.key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator,
    this.prefixIcon,
  });

  void _insertAtCursor(String insertion, {int cursorOffsetDelta = 0}) {
    final text = controller.text;
    final selection = controller.selection;
    
    // Default to the end if no explicit selection is found
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, insertion);
    final newSelectionPos = start + insertion.length + cursorOffsetDelta;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionPos),
    );
  }

  Widget _buildToolbarButton(String label, String insertion, {int offset = 0, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        avatar: icon != null ? Icon(icon, size: 16) : null,
        visualDensity: VisualDensity.compact,
        onPressed: () => _insertAtCursor(insertion, cursorOffsetDelta: offset),
      ),
    );
  }

  void _openAdvancedEditor(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AdvancedMathEditorModal(initialText: controller.text),
    );

    if (result != null) {
      controller.text = result;
      // Move cursor securely to the end
      controller.selection = TextSelection.collapsed(offset: result.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // MS Word Style Math Toolbar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildToolbarButton('Formula (\$)', r'$$', offset: -1, icon: Icons.functions),
              _buildToolbarButton('Fraction', r'\frac{}{}', offset: -3),
              _buildToolbarButton('Power', r'^{}', offset: -1),
              _buildToolbarButton('Square', r'^{2}', offset: 0),
              _buildToolbarButton('Root', r'\sqrt{}', offset: -1),
              _buildToolbarButton('Pi', r'\pi ', offset: 0),
              _buildToolbarButton('Infinity', r'\infty ', offset: 0),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                tooltip: 'Advanced Editor',
                onPressed: () => _openAdvancedEditor(context),
              ),
            ],
          ),
        ),
        // Interactive Text Field
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: prefixIcon,
          ),
          validator: validator,
        ),
        // Live Compilation Engine
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => SmartMathView(
            text: value.text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
