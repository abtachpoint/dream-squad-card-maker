class ElementTransform {
  const ElementTransform({this.dx = 0, this.dy = 0, this.scale = 1});

  final double dx;
  final double dy;
  final double scale;

  ElementTransform copyWith({double? dx, double? dy, double? scale}) {
    return ElementTransform(
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      scale: scale ?? this.scale,
    );
  }

  Map<String, dynamic> toJson() => {
        'dx': dx,
        'dy': dy,
        'scale': scale,
      };

  factory ElementTransform.fromJson(dynamic raw) {
    if (raw is! Map) return const ElementTransform();
    return ElementTransform(
      dx: (raw['dx'] as num?)?.toDouble() ?? 0,
      dy: (raw['dy'] as num?)?.toDouble() ?? 0,
      scale: ((raw['scale'] as num?)?.toDouble() ?? 1).clamp(.25, 5.0).toDouble(),
    );
  }
}
