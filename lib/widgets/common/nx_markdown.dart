import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../core/theme/app_theme.dart';

/// Renders the AI answers (coach reply, diet plan, recipe, instructions).
/// The backend sends them as Markdown **strings**, never as lists.
class NxMarkdown extends StatelessWidget {
  final String data;
  final Color? color;
  final double fontSize;

  const NxMarkdown(this.data, {super.key, this.color, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.textMain;
    final body = TextStyle(color: base, fontSize: fontSize, height: 1.5);
    return MarkdownBody(
      data: data,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: body,
        listBullet: body,
        strong: body.copyWith(fontWeight: FontWeight.w800),
        em: body.copyWith(fontStyle: FontStyle.italic),
        h1: body.copyWith(fontSize: fontSize + 6, fontWeight: FontWeight.w800),
        h2: body.copyWith(fontSize: fontSize + 4, fontWeight: FontWeight.w800),
        h3: body.copyWith(fontSize: fontSize + 2, fontWeight: FontWeight.w700),
        blockquote: body.copyWith(color: context.textMuted),
        tableBody: body,
        tableHead: body.copyWith(fontWeight: FontWeight.w800),
        tableBorder: TableBorder.all(color: context.borderColor, width: 1),
        horizontalRuleDecoration: BoxDecoration(border: Border(top: BorderSide(color: context.borderColor))),
      ),
    );
  }
}
