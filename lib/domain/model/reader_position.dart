/// Local reading bookmark. Contains identifiers and geometry, never prose.
class ReaderPosition {
  const ReaderPosition({
    required this.volumeId,
    required this.updatedAt,
    this.sceneId,
    this.sceneOrderKey,
    this.passageId,
    this.passageOrderKey,
    this.passageFraction = 0,
    this.offset = 0,
  });

  final String volumeId;
  final String? sceneId;
  final String? sceneOrderKey;
  final String? passageId;
  final String? passageOrderKey;
  final double passageFraction;
  final double offset;
  final DateTime updatedAt;

  bool get hasValidGeometry =>
      offset.isFinite &&
      offset >= 0 &&
      passageFraction.isFinite &&
      passageFraction >= 0 &&
      passageFraction <= 1;
}
