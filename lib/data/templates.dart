import 'package:flutter/material.dart';
import '../models/card_template.dart';

const cardTemplates = <CardTemplate>[
  CardTemplate(id: 'base', name: 'Base Card', pack: CardPack.free, coinCost: 0, photoSlots: 1, backgroundLocked: true, boosterSlots: 0, colors: [Color(0xFF2A2139), Color(0xFF1A3A2A), Color(0xFF7A3D22)]),
  CardTemplate(id: 'potw', name: 'POTW', pack: CardPack.free, coinCost: 0, photoSlots: 1, backgroundLocked: false, boosterSlots: 0, colors: [Color(0xFF061A0D), Color(0xFF00D737), Color(0xFF101010)]),
  CardTemplate(id: 'potm', name: 'POTM', pack: CardPack.free, coinCost: 0, photoSlots: 1, backgroundLocked: false, boosterSlots: 0, colors: [Color(0xFF160A23), Color(0xFF8A2BE2), Color(0xFF111111)]),

  CardTemplate(id: 'epic1', name: 'Epic Type 1', pack: CardPack.premium, coinCost: 15, photoSlots: 2, backgroundLocked: true, boosterSlots: 2, colors: [Color(0xFF013F32), Color(0xFF09A873), Color(0xFF9B7A39)]),
  CardTemplate(id: 'showtime', name: 'Show Time', pack: CardPack.premium, coinCost: 15, photoSlots: 1, backgroundLocked: true, boosterSlots: 2, colors: [Color(0xFF2A0B4F), Color(0xFF16B9D4), Color(0xFF7130D8)]),
  CardTemplate(id: 'epic2a', name: 'Epic Type 2A', pack: CardPack.premium, coinCost: 15, photoSlots: 2, backgroundLocked: true, boosterSlots: 2, colors: [Color(0xFF032D20), Color(0xFF21C66D), Color(0xFF9A7A38)]),
  CardTemplate(id: 'legendary', name: 'Legendary', pack: CardPack.premium, coinCost: 15, photoSlots: 1, backgroundLocked: true, boosterSlots: 0, colors: [Color(0xFF2A2417), Color(0xFFAD8E42), Color(0xFF111111)]),
  CardTemplate(id: 'epic2b', name: 'Epic Type 2B', pack: CardPack.premium, coinCost: 15, photoSlots: 2, backgroundLocked: true, boosterSlots: 1, colors: [Color(0xFF0B2B12), Color(0xFF1E9C45), Color(0xFF8D753E)]),

  CardTemplate(id: 'bt1', name: 'Big Time Type 1', pack: CardPack.bigTime, coinCost: 25, photoSlots: 4, backgroundLocked: true, boosterSlots: 2, colors: [Color(0xFF491309), Color(0xFFFFA000), Color(0xFF9C783E)]),
  CardTemplate(id: 'bt2', name: 'Big Time Type 2', pack: CardPack.bigTime, coinCost: 25, photoSlots: 2, backgroundLocked: true, boosterSlots: 2, colors: [Color(0xFF3D2506), Color(0xFFB88A22), Color(0xFF17110A)]),
  CardTemplate(id: 'bt3', name: 'Big Time Type 3', pack: CardPack.bigTime, coinCost: 25, photoSlots: 2, backgroundLocked: true, boosterSlots: 0, colors: [Color(0xFF051B55), Color(0xFF2875D8), Color(0xFFB89536)]),
  CardTemplate(id: 'bt4', name: 'Big Time Type 4', pack: CardPack.bigTime, coinCost: 25, photoSlots: 2, backgroundLocked: true, boosterSlots: 0, colors: [Color(0xFF1A120B), Color(0xFFA45B17), Color(0xFFD19A44)]),
  CardTemplate(id: 'bt5', name: 'Big Time Type 5', pack: CardPack.bigTime, coinCost: 25, photoSlots: 2, backgroundLocked: true, boosterSlots: 2, colors: [Color(0xFF201003), Color(0xFFD88815), Color(0xFF9E6A2E)]),
  CardTemplate(id: 'oldbt', name: 'Old Big Time', pack: CardPack.bigTime, coinCost: 25, photoSlots: 1, backgroundLocked: true, boosterSlots: 0, colors: [Color(0xFF26180C), Color(0xFF73502D), Color(0xFFB35023)]),
];
