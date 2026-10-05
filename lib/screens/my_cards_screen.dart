import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/card_project.dart';
import '../widgets/app_notice.dart';
import 'card_editor_screen.dart';
import 'card_pack_screen.dart';
import 'squad_builder_screen.dart';

class MyCardsScreen extends StatelessWidget {
  const MyCardsScreen({super.key});
  static const galleryChannel = MethodChannel('com.soikot.dreamsquad/gallery');

  Future<void> _export(BuildContext context, CardProject card) async {
    try {
      final file = File(card.previewPath);
      if (!file.existsSync()) throw StateError('Missing card image');
      final bytes = await file.readAsBytes();
      await galleryChannel.invokeMethod('saveImage', {
        'bytes': bytes,
        'fileName': 'DreamSquad_${card.playerName.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')}_${DateTime.now().millisecondsSinceEpoch}.png',
      });
      if (context.mounted) {
        await showAppNotice(context, title: 'Card exported', message: 'Saved to your device gallery.', icon: Icons.check_circle_rounded, accent: Colors.greenAccent);
      }
    } catch (_) {
      if (context.mounted) {
        await showAppNotice(context, title: 'Export failed', message: 'Couldn’t save this card to the gallery.', icon: Icons.error_outline_rounded, accent: Colors.redAccent);
      }
    }
  }

  Future<void> _delete(BuildContext context, CardProject card) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('Remove ${card.playerName} from My Cards?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) await appState.deleteCard(card);
  }

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_card_rounded, size: 64, color: Colors.white24),
                    const SizedBox(height: 14),
                    const Text('No cards yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('Create your first card, then it will appear here for squad building.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardPackScreen())), child: const Text('Create Card')),
                  ],
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .60, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: appState.cards.length,
            itemBuilder: (context, i) {
              final card = appState.cards[i];
              final file = File(card.previewPath);
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF12141B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: file.existsSync()
                            ? Image.file(file, fit: BoxFit.cover, width: double.infinity)
                            : Container(color: Colors.white10, alignment: Alignment.center, child: const Icon(Icons.image_not_supported_outlined)),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(card.playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${card.rating} • ${card.position} • ${card.template.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Edit',
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardEditorScreen(template: card.template, existingCard: card))),
                          icon: const Icon(Icons.edit_rounded, size: 19),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Duplicate',
                          onPressed: () => appState.duplicateCard(card),
                          icon: const Icon(Icons.copy_rounded, size: 19),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Export',
                          onPressed: () => _export(context, card),
                          icon: const Icon(Icons.download_rounded, size: 19),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Delete',
                          onPressed: () => _delete(context, card),
                          icon: const Icon(Icons.delete_outline_rounded, size: 19),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: appState.cards.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SquadBuilderScreen())),
              icon: const Icon(Icons.stadium_rounded),
              label: const Text('Build Squad'),
            ),
    );
  }
}
