import 'package:flutter/material.dart';

class InlineErrorNotice extends StatelessWidget {
  final String message;
  const InlineErrorNotice(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFFFEDEA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF2C9C4))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.error_outline, color: Color(0xFF9B3028), size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: Color(0xFF652A25), height: 1.5))),
          ])));
}
