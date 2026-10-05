import 'dart:io';
import 'package:flutter/material.dart';
import '../app_state.dart';
import 'card_pack_screen.dart';

class MyCardsScreen extends StatelessWidget {
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cards')),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          if (appState.cards.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_card_rounded, size: 64, color: Colors.white24),
                  const SizedBox(height: 14),
                  const Text('No cards yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Create your first card, then it will appear here for squad building.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardPackScreen())), child: const Text('Create Card')),
                ]),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .68, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: appState.cards.length,
            itemBuilder: (context, i) {
              final card = appState.cards[i];
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF12141B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                child: Column(children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(card.previewPath), fit: BoxFit.cover, width: double.infinity))),
                  const SizedBox(height: 7),
                  Text(card.playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${card.rating} • ${card.position} • ${card.template.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                  SizedBox(height: 32, child: TextButton.icon(onPressed: () => appState.deleteCard(card), icon: const Icon(Icons.delete_outline_rounded, size: 18), label: const Text('Delete'))),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
