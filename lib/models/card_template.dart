import 'package:flutter/material.dart';

enum CardPack { free, premium, bigTime }

class CardTemplate {
  const CardTemplate({
    required this.id,
    required this.name,
    required this.pack,
    required this.coinCost,
    required this.photoSlots,
    required this.backgroundLocked,
    required this.boosterSlots,
    required this.colors,
  });

  final String id;
  final String name;
  final CardPack pack;
  final int coinCost;
  final int photoSlots;
  final bool backgroundLocked;
  final int boosterSlots;
  final List<Color> colors;

  String get packLabel => switch (pack) {
        CardPack.free => 'Free Pack',
        CardPack.premium => 'Premium Pack',
        CardPack.bigTime => 'Big Time Pack',
      };
}
