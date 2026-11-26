// Generated offline tile bounds for Cebu, Philippines (Esri Dark Gray Canvas, AGOS maritime palette).
// Data attribution: Esri, HERE, Garmin, OpenStreetMap contributors, GIS User Community.

class TileZoomBounds {
  const TileZoomBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  bool contains(int x, int y) =>
      x >= minX && x <= maxX && y >= minY && y <= maxY;
}

const int cebuMinNativeZoom = 7;
const int cebuMaxNativeZoom = 13;

const Map<int, TileZoomBounds> cebuTileBounds = {
  7: TileZoomBounds(minX: 107, maxX: 108, minY: 59, maxY: 60),
  8: TileZoomBounds(minX: 215, maxX: 217, minY: 119, maxY: 121),
  9: TileZoomBounds(minX: 431, maxX: 433, minY: 239, maxY: 242),
  10: TileZoomBounds(minX: 862, maxX: 866, minY: 479, maxY: 485),
  11: TileZoomBounds(minX: 1725, maxX: 1732, minY: 959, maxY: 970),
  12: TileZoomBounds(minX: 3454, maxX: 3461, minY: 1926, maxY: 1933),
  13: TileZoomBounds(minX: 6913, maxX: 6919, minY: 3857, maxY: 3862),
};

bool hasCebuTile(int z, int x, int y) {
  final bounds = cebuTileBounds[z];
  return bounds != null && bounds.contains(x, y);
}

String cebuTileAssetPath(int z, int x, int y) =>
    'assets/map_tiles/${z}_${x}_$y.png';
