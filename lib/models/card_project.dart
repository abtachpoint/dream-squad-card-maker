import 'card_template.dart';

class CardProject {
  CardProject({
    required this.id,
    required this.template,
    required this.playerName,
    required this.rating,
    required this.position,
    required this.previewPath,
  });

  final String id;
  final CardTemplate template;
  final String playerName;
  final int rating;
  final String position;
  final String previewPath;
}
