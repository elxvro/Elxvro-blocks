import 'package:flutter/material.dart';

class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, required this.coins, this.compact = false});

  final int coins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFFFC86E).withValues(alpha: 0.10),
        border: Border.all(
          color: const Color(0xFFFFC86E).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.monetization_on_rounded,
            color: Color(0xFFFFD06E),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(
              color: const Color(0xFFFFD98B),
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
