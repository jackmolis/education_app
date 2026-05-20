import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class SmartMathView extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const SmartMathView({
    super.key,
    required this.text,
    this.style,
  });

  String cleanLatex(String input) {
    if (input.isEmpty) return input;
    
    // Explicitly clamp escaped backslashes dropping them back into literal commands
    var cleaned = input.replaceAll(r'\\', r'\');
    
    // Scrape physical formatting loops
    cleaned = cleaned.replaceAll('\n', ' ').trim();
    
    debugPrint('SmartMathView Processing -> Cleaned Payload: [$cleaned]');
    return cleaned;
  }

  bool _hasLatexIndicators(String input) {
    if (input.contains(r'\')) return true;
    if (input.contains('^')) return true;
    if (input.contains('_')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final sanitizedText = cleanLatex(text);
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    // 1. Detect pure fallback math (No delimiters, but contains calculus signatures)
    if (!sanitizedText.contains('\$')) {
      if (_hasLatexIndicators(sanitizedText)) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Math.tex(
            sanitizedText,
            textStyle: defaultStyle.copyWith(fontFamily: null),
            onErrorFallback: (err) {
              debugPrint('SmartMathView Error: $err | Payload: $sanitizedText');
              return Text(sanitizedText, style: defaultStyle.copyWith(color: Colors.redAccent));
            },
          ),
        );
      } else {
        return Text(sanitizedText, style: defaultStyle);
      }
    }

    // 2. Active Regex to isolate mixed LaTeX encapsulated in `$..$` or `$$..$$`
    final RegExp mathRegex = RegExp(r'(\${1,2})(.*?)\1', dotAll: true);
    final List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in mathRegex.allMatches(sanitizedText)) {
      // Target the leading clean text spans sequentially before reaching the math block
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: sanitizedText.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      // Strip delimiters out natively isolating pure logic bounds
      final mathContent = match.group(2) ?? '';
      
      // Mount the mathematical AST safely into the span sequence dynamically
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Math.tex(
            mathContent,
            textStyle: defaultStyle.copyWith(fontFamily: null),
            onErrorFallback: (err) {
              debugPrint('SmartMathView Error: $err | Payload: $mathContent');
              return Text(mathContent, style: defaultStyle.copyWith(color: Colors.redAccent));
            },
          ),
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Flush any leftover readable parameters appending out at the tail of the block
    if (lastMatchEnd < sanitizedText.length) {
      spans.add(TextSpan(
        text: sanitizedText.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

    // Seamlessly output the unified horizontal array flawlessly!
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
