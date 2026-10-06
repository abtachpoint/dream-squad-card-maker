import 'element_transform.dart';

class SquadProject {
  SquadProject({
    required this.id,
    required this.name,
    required this.formation,
    required this.previewPath,
    this.customFormation = false,
    this.playerCardIds = const [],
    this.playerTransforms = const [],
    this.captainIndex,
    this.fieldStyle = 0,
    this.customBackgroundPath,
    this.teamLogoPath,
    this.managerName = '',
    this.managerPhotoPath,
    this.showBench = false,
    this.benchCardIds = const [],
    this.positionsLocked = false,
  });

  final String id;
  final String name;
  final String formation;
  final String previewPath;
  final bool customFormation;
  final List<String?> playerCardIds;
  final List<ElementTransform> playerTransforms;
  final int? captainIndex;
  final int fieldStyle;
  final String? customBackgroundPath;
  final String? teamLogoPath;
  final String managerName;
  final String? managerPhotoPath;
  final bool showBench;
  final List<String> benchCardIds;
  final bool positionsLocked;
}
