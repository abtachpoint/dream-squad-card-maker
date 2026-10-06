import 'card_template.dart';
import 'element_transform.dart';

class CardProject {
  CardProject({
    required this.id,
    required this.template,
    required this.playerName,
    required this.rating,
    required this.position,
    required this.previewPath,
    this.photoPaths = const [],
    this.logoPath,
    this.flagPath,
    this.customBackgroundPath,
    this.photoTransforms = const [],
    this.photoOpacities = const [],
    this.photoOrder = const [],
    this.nameTransform = const ElementTransform(),
    this.ratingTransform = const ElementTransform(),
  });

  final String id;
  final CardTemplate template;
  final String playerName;
  final int rating;
  final String position;
  final String previewPath;
  final List<String?> photoPaths;
  final String? logoPath;
  final String? flagPath;
  final String? customBackgroundPath;
  final List<ElementTransform> photoTransforms;
  final List<double> photoOpacities;
  final List<int> photoOrder;
  final ElementTransform nameTransform;
  final ElementTransform ratingTransform;
}
