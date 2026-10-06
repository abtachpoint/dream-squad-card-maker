import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/squad_project.dart';
import '../widgets/app_notice.dart';
import 'squad_builder_screen.dart';

class MySquadsScreen extends StatelessWidget {
  const MySquadsScreen({super.key});
  static const galleryChannel = MethodChannel('com.soikot.dreamsquad/gallery');

  Future<void> _export(BuildContext context, SquadProject squad) async {
    try {
      final file = File(squad.previewPath);
      if (!file.existsSync()) throw StateError('Missing squad image');
      await galleryChannel.invokeMethod('saveImage', {
        'bytes': await file.readAsBytes(),
        'fileName': 'DreamSquad_Lineup_${DateTime.now().millisecondsSinceEpoch}.png',
      });
      if (context.mounted) {
        await showAppNotice(context, title: 'Squad exported', message: 'Saved to your device gallery.', icon: Icons.check_circle_rounded, accent: Colors.greenAccent);
      }
    } catch (_) {
      if (context.mounted) {
        await showAppNotice(context, title: 'Export failed', message: 'Couldn’t save this squad to the gallery.', icon: Icons.error_outline_rounded, accent: Colors.redAccent);
      }
    }
  }

  Future<void> _delete(BuildContext context, SquadProject squad) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete squad?'),
        content: Text('Remove ${squad.name} from My Squads?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) await appState.deleteSquad(squad);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Squads')),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          if (appState.squads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stadium_outlined, size: 64, color: Colors.white24),
                    const SizedBox(height: 14),
                    const Text('No squads yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('Build and save a squad, then it will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SquadBuilderScreen())), child: const Text('Build Squad')),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: appState.squads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final squad = appState.squads[i];
              final file = File(squad.previewPath);
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF12141B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: file.existsSync()
                          ? Image.file(file, width: 92, height: 122, fit: BoxFit.cover)
                          : Container(width: 92, height: 122, color: Colors.white10, child: const Icon(Icons.image_not_supported_outlined)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(squad.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(squad.formation, style: const TextStyle(color: Colors.white54)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 2,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SquadBuilderScreen(existingSquad: squad),
                                  ),
                                ),
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(onPressed: () => appState.duplicateSquad(squad), tooltip: 'Duplicate', icon: const Icon(Icons.copy_rounded)),
                              IconButton(onPressed: () => _export(context, squad), tooltip: 'Export', icon: const Icon(Icons.download_rounded)),
                              IconButton(onPressed: () => _delete(context, squad), tooltip: 'Delete', icon: const Icon(Icons.delete_outline_rounded)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
