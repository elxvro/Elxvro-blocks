import 'dart:async';

import 'package:flutter/material.dart';

import '../services/audio_service.dart';

class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final dark = Color.lerp(accent, Colors.black, 0.38)!;
    final light = Color.lerp(accent, Colors.white, 0.22)!;
    final foreground =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : const Color(0xFF071014);

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent.withValues(alpha: 0.24),
              blurRadius: 26,
              spreadRadius: 1,
            ),
          ],
          gradient: LinearGradient(
            colors: <Color>[light, dark, accent],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onHighlightChanged: _setPressed,
            onTap: () {
              unawaited(AudioService.instance.playClick());
              widget.onPressed();
            },
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (widget.icon != null) ...<Widget>[
                    Icon(widget.icon, color: foreground),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
