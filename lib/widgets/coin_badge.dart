import 'package:flutter/material.dart';
import '../app_state.dart';

class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFF211C08), borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0xFFFFD54F).withOpacity(.4))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on_rounded, size: 18, color: Color(0xFFFFD54F)),
            const SizedBox(width: 5),
            Text('${appState.coins}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
