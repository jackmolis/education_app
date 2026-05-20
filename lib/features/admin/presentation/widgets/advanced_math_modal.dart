import 'package:flutter/material.dart';
import '../../../../core/widgets/smart_math_view.dart';

class AdvancedMathEditorModal extends StatefulWidget {
  final String initialText;

  const AdvancedMathEditorModal({super.key, required this.initialText});

  @override
  State<AdvancedMathEditorModal> createState() => _AdvancedMathEditorModalState();
}

class _AdvancedMathEditorModalState extends State<AdvancedMathEditorModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertAtCursor(String insertion, {int cursorOffsetDelta = 0}) {
    final text = _controller.text;
    final selection = _controller.selection;
    
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, insertion);
    final newSelectionPos = start + insertion.length + cursorOffsetDelta;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionPos),
    );
  }

  Widget _buildToolbarButton(String label, String insertion, {int offset = 0, IconData? icon}) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: icon != null ? Icon(icon, size: 16) : null,
      visualDensity: VisualDensity.compact,
      onPressed: () => _insertAtCursor(insertion, cursorOffsetDelta: offset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Advanced Math Editor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildToolbarButton('Formula (\$)', r'$$', offset: -1, icon: Icons.functions),
              _buildToolbarButton('Fraction', r'\frac{}{}', offset: -3),
              _buildToolbarButton('Power', r'^{}', offset: -1),
              _buildToolbarButton('Square', r'^{2}', offset: 0),
              _buildToolbarButton('Root', r'\sqrt{}', offset: -1),
              _buildToolbarButton('Integral', r'\int_{}^{}', offset: -4),
              _buildToolbarButton('Summation', r'\sum_{}^{}', offset: -4),
              _buildToolbarButton('Pi', r'\pi ', offset: 0),
              _buildToolbarButton('Infinity', r'\infty ', offset: 0),
              _buildToolbarButton('Alpha', r'\alpha ', offset: 0),
              _buildToolbarButton('Beta', r'\beta ', offset: 0),
              _buildToolbarButton('Theta', r'\theta ', offset: 0),
              _buildToolbarButton('Matrix', r'\begin{matrix}  \end{matrix}', offset: -14),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Type your LaTeX here...',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => SmartMathView(
                text: value.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }
}
