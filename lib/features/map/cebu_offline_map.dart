import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/node_observation.dart';
import '../../ui/agos_colors.dart';
import 'cebu_tile_manifest.dart';

/// Default camera framing Cebu City, Mactan Channel, and Bohol Strait.
const double cebuDefaultLat = 10.285;
const double cebuDefaultLon = 123.955;
const double cebuDefaultZoom = 10.8;

const double cebuMinZoom = 7.5;
const double cebuMaxZoom = 15.5;

const double _minLat = 8.60;
const double _maxLat = 11.90;
const double _minLon = 122.20;
const double _maxLon = 125.80;
const double _tileSize = 256.0;

class CebuMapController extends ChangeNotifier {
  CebuMapController({
    double lat = cebuDefaultLat,
    double lon = cebuDefaultLon,
    double zoom = cebuDefaultZoom,
  }) : _lat = lat.clamp(_minLat, _maxLat),
       _lon = lon.clamp(_minLon, _maxLon),
       _zoom = zoom.clamp(cebuMinZoom, cebuMaxZoom);

  double _lat;
  double _lon;
  double _zoom;

  double get lat => _lat;
  double get lon => _lon;
  double get zoom => _zoom;

  void setCamera({double? lat, double? lon, double? zoom}) {
    final nextLat = (lat ?? _lat).clamp(_minLat, _maxLat);
    final nextLon = (lon ?? _lon).clamp(_minLon, _maxLon);
    final nextZoom = (zoom ?? _zoom).clamp(cebuMinZoom, cebuMaxZoom);
    if (nextLat == _lat && nextLon == _lon && nextZoom == _zoom) return;
    _lat = nextLat;
    _lon = nextLon;
    _zoom = nextZoom;
    notifyListeners();
  }

  void zoomBy(double delta) => setCamera(zoom: _zoom + delta);

  void recenter() => setCamera(
    lat: cebuDefaultLat,
    lon: cebuDefaultLon,
    zoom: cebuDefaultZoom,
  );
}

Offset latLonToWorldPx(double lat, double lon, double zoom) {
  final scale = _tileSize * math.pow(2.0, zoom);
  final clampedLat = lat.clamp(-85.05112878, 85.05112878);
  final latRad = clampedLat * math.pi / 180.0;
  final x = (lon + 180.0) / 360.0 * scale;
  final sinLat = math.sin(latRad);
  final y =
      (0.5 - math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi)) *
      scale;
  return Offset(x, y);
}

({double lat, double lon}) worldPxToLatLon(Offset worldPx, double zoom) {
  final scale = _tileSize * math.pow(2.0, zoom);
  final lon = worldPx.dx / scale * 360.0 - 180.0;
  final n = math.pi - 2.0 * math.pi * worldPx.dy / scale;
  final lat = 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  return (lat: lat, lon: lon);
}

class CebuOfflineMap extends StatefulWidget {
  const CebuOfflineMap({
    super.key,
    required this.controller,
    required this.nodes,
    required this.now,
    this.onNodeTap,
  });

  final CebuMapController controller;
  final List<NodeObservation> nodes;
  final DateTime now;
  final ValueChanged<NodeObservation>? onNodeTap;

  @override
  State<CebuOfflineMap> createState() => _CebuOfflineMapState();
}

class _CebuOfflineMapState extends State<CebuOfflineMap> {
  final Map<String, ui.Image> _tileCache = {};
  final Set<String> _loadingTiles = {};
  final List<String> _lruOrder = [];
  static const int _maxCachedTiles = 180;

  double _gestureStartZoom = cebuDefaultZoom;
  Offset _gestureAnchorWorld = Offset.zero;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCameraChanged);
  }

  @override
  void didUpdateWidget(covariant CebuOfflineMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onCameraChanged);
      widget.controller.addListener(_onCameraChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCameraChanged);
    for (final img in _tileCache.values) {
      img.dispose();
    }
    _tileCache.clear();
    super.dispose();
  }

  void _onCameraChanged() {
    if (mounted) setState(() {});
  }

  String _tileKey(int z, int x, int y) => '${z}_${x}_$y';

  ui.Image? _getOrRequestTile(int z, int x, int y) {
    final key = _tileKey(z, x, y);
    final existing = _tileCache[key];
    if (existing != null) {
      _lruOrder.remove(key);
      _lruOrder.add(key);
      return existing;
    }
    if (!_loadingTiles.contains(key)) {
      _loadingTiles.add(key);
      unawaited(_loadTile(z, x, y, key));
    }
    return null;
  }

  Future<void> _loadTile(int z, int x, int y, String key) async {
    try {
      final path = cebuTileAssetPath(z, x, y);
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      _tileCache[key] = frame.image;
      _lruOrder.add(key);
      while (_lruOrder.length > _maxCachedTiles) {
        final oldest = _lruOrder.removeAt(0);
        _tileCache.remove(oldest)?.dispose();
      }
      setState(() {});
    } catch (_) {
      // Missing or unbundled tiles gracefully fall back to parent tiles / ocean fill.
    } finally {
      _loadingTiles.remove(key);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _gestureStartZoom = widget.controller.zoom;
    final centerWorld = latLonToWorldPx(
      widget.controller.lat,
      widget.controller.lon,
      _gestureStartZoom,
    );
    final viewportCenter = Offset(
      _viewportSize.width / 2,
      _viewportSize.height / 2,
    );
    _gestureAnchorWorld =
        centerWorld + (details.localFocalPoint - viewportCenter);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_viewportSize.isEmpty) return;
    final scale = details.scale.clamp(0.25, 4.0);
    final nextZoom = (_gestureStartZoom + math.log(scale) / math.ln2).clamp(
      cebuMinZoom,
      cebuMaxZoom,
    );
    final zoomFactor = math.pow(2.0, nextZoom - _gestureStartZoom).toDouble();
    final anchorAtNextZoom = _gestureAnchorWorld * zoomFactor;
    final viewportCenter = Offset(
      _viewportSize.width / 2,
      _viewportSize.height / 2,
    );
    final nextCenterWorld =
        anchorAtNextZoom - (details.localFocalPoint - viewportCenter);
    final nextCenter = worldPxToLatLon(nextCenterWorld, nextZoom);
    widget.controller.setCamera(
      lat: nextCenter.lat,
      lon: nextCenter.lon,
      zoom: nextZoom,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _viewportSize.isEmpty) return;
    final deltaZoom = -event.scrollDelta.dy * 0.0025;
    if (deltaZoom == 0) return;
    final currentZoom = widget.controller.zoom;
    final nextZoom = (currentZoom + deltaZoom).clamp(cebuMinZoom, cebuMaxZoom);
    if (nextZoom == currentZoom) return;

    final centerWorld = latLonToWorldPx(
      widget.controller.lat,
      widget.controller.lon,
      currentZoom,
    );
    final viewportCenter = Offset(
      _viewportSize.width / 2,
      _viewportSize.height / 2,
    );
    final focalWorld = centerWorld + (event.localPosition - viewportCenter);
    final zoomFactor = math.pow(2.0, nextZoom - currentZoom).toDouble();
    final nextCenterWorld =
        focalWorld * zoomFactor - (event.localPosition - viewportCenter);
    final nextCenter = worldPxToLatLon(nextCenterWorld, nextZoom);
    widget.controller.setCamera(
      lat: nextCenter.lat,
      lon: nextCenter.lon,
      zoom: nextZoom,
    );
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    if (_viewportSize.isEmpty) return;
    final currentZoom = widget.controller.zoom;
    final nextZoom = (currentZoom + 1.0).clamp(cebuMinZoom, cebuMaxZoom);
    final centerWorld = latLonToWorldPx(
      widget.controller.lat,
      widget.controller.lon,
      currentZoom,
    );
    final viewportCenter = Offset(
      _viewportSize.width / 2,
      _viewportSize.height / 2,
    );
    final focalWorld = centerWorld + (details.localPosition - viewportCenter);
    final zoomFactor = math.pow(2.0, nextZoom - currentZoom).toDouble();
    final nextCenterWorld =
        focalWorld * zoomFactor - (details.localPosition - viewportCenter);
    final nextCenter = worldPxToLatLon(nextCenterWorld, nextZoom);
    widget.controller.setCamera(
      lat: nextCenter.lat,
      lon: nextCenter.lon,
      zoom: nextZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final zoom = widget.controller.zoom;
        final centerWorld = latLonToWorldPx(
          widget.controller.lat,
          widget.controller.lon,
          zoom,
        );
        final viewportCenter = Offset(
          _viewportSize.width / 2,
          _viewportSize.height / 2,
        );

        final currentNodes = widget.nodes
            .where(
              (n) =>
                  n.hasCurrentFix(widget.now) &&
                  n.packet.latitude != null &&
                  n.packet.longitude != null,
            )
            .toList();

        return Listener(
          onPointerSignal: _handlePointerSignal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onDoubleTapDown: _handleDoubleTapDown,
            onDoubleTap: () {},
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CebuTileAndGridPainter(
                        lat: widget.controller.lat,
                        lon: widget.controller.lon,
                        zoom: zoom,
                        tileLookup: _getOrRequestTile,
                      ),
                    ),
                  ),
                  for (final node in currentNodes) ...[
                    Builder(
                      builder: (context) {
                        final world = latLonToWorldPx(
                          node.packet.latitude!,
                          node.packet.longitude!,
                          zoom,
                        );
                        final screen = world - centerWorld + viewportCenter;
                        if (screen.dx < -40 ||
                            screen.dx > _viewportSize.width + 40 ||
                            screen.dy < -40 ||
                            screen.dy > _viewportSize.height + 40) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                          left: screen.dx - 22,
                          top: screen.dy - 22,
                          child: _NodeMapMarker(
                            nodeId: node.packet.nodeId,
                            onTap: widget.onNodeTap == null
                                ? null
                                : () => widget.onNodeTap!(node),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NodeMapMarker extends StatelessWidget {
  const _NodeMapMarker({required this.nodeId, this.onTap});

  final String nodeId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: agosOnlineGreen,
          shape: BoxShape.circle,
          border: Border.all(color: agosNavy, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          nodeId,
          style: const TextStyle(
            fontFamily: 'Barlow',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: agosNavy,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _CebuTileAndGridPainter extends CustomPainter {
  const _CebuTileAndGridPainter({
    required this.lat,
    required this.lon,
    required this.zoom,
    required this.tileLookup,
  });

  final double lat;
  final double lon;
  final double zoom;
  final ui.Image? Function(int z, int x, int y) tileLookup;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep maritime navy ocean base
    canvas.drawRect(Offset.zero & size, Paint()..color = agosOceanBg);

    final centerWorld = latLonToWorldPx(lat, lon, zoom);
    final viewportCenter = Offset(size.width / 2, size.height / 2);
    final topLeftWorld = centerWorld - viewportCenter;
    final bottomRightWorld = centerWorld + viewportCenter;

    // 2. Draw bundled offline Cebu raster tiles with seamless parent fallback & overzoom
    final targetZ = zoom.floor().clamp(cebuMinNativeZoom, cebuMaxNativeZoom);
    final tileScale = math.pow(2.0, zoom - targetZ).toDouble();
    final tileScreenSize = _tileSize * tileScale;

    final maxTileIndex = (1 << targetZ) - 1;
    final startX = (topLeftWorld.dx / tileScreenSize).floor().clamp(
      0,
      maxTileIndex,
    );
    final endX = (bottomRightWorld.dx / tileScreenSize).floor().clamp(
      0,
      maxTileIndex,
    );
    final startY = (topLeftWorld.dy / tileScreenSize).floor().clamp(
      0,
      maxTileIndex,
    );
    final endY = (bottomRightWorld.dy / tileScreenSize).floor().clamp(
      0,
      maxTileIndex,
    );

    final tilePaint = Paint()..filterQuality = FilterQuality.medium;

    for (var tx = startX; tx <= endX; tx++) {
      for (var ty = startY; ty <= endY; ty++) {
        final dstLeft = tx * tileScreenSize - topLeftWorld.dx;
        final dstTop = ty * tileScreenSize - topLeftWorld.dy;
        final dstRect = Rect.fromLTWH(
          dstLeft,
          dstTop,
          tileScreenSize + 0.6,
          tileScreenSize + 0.6,
        );
        _drawBestAvailableTile(canvas, targetZ, tx, ty, dstRect, tilePaint);
      }
    }

    // 3. Draw maritime coordinate graticule & edge lat/lon labels
    _drawCoordinateGrid(canvas, size, topLeftWorld, bottomRightWorld);
  }

  void _drawBestAvailableTile(
    Canvas canvas,
    int targetZ,
    int tx,
    int ty,
    Rect dstRect,
    Paint paint,
  ) {
    // Find the highest bundled zoom covering (targetZ, tx, ty)
    int? chosenZ;
    int chosenX = tx;
    int chosenY = ty;
    for (var z = targetZ; z >= cebuMinNativeZoom; z--) {
      final shift = targetZ - z;
      final px = tx >> shift;
      final py = ty >> shift;
      if (hasCebuTile(z, px, py)) {
        chosenZ = z;
        chosenX = px;
        chosenY = py;
        break;
      }
    }
    if (chosenZ == null) return;

    final img = tileLookup(chosenZ, chosenX, chosenY);
    if (img != null) {
      final shift = targetZ - chosenZ;
      final srcRect = _subRectForDescendant(img, tx, ty, shift);
      canvas.drawImageRect(img, srcRect, dstRect, paint);
      return;
    }

    // While chosen tile decodes asynchronously, draw any already-cached parent tile
    for (var z = chosenZ - 1; z >= cebuMinNativeZoom; z--) {
      final shift = targetZ - z;
      final px = tx >> shift;
      final py = ty >> shift;
      if (!hasCebuTile(z, px, py)) continue;
      final fallback = tileLookup(z, px, py);
      if (fallback != null) {
        final srcRect = _subRectForDescendant(fallback, tx, ty, shift);
        canvas.drawImageRect(fallback, srcRect, dstRect, paint);
        return;
      }
    }
  }

  Rect _subRectForDescendant(ui.Image img, int tx, int ty, int shift) {
    if (shift <= 0) {
      return Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    }
    final divisions = 1 << shift;
    final subX = tx & (divisions - 1);
    final subY = ty & (divisions - 1);
    final subW = img.width / divisions;
    final subH = img.height / divisions;
    return Rect.fromLTWH(subX * subW, subY * subH, subW, subH);
  }

  double _gridStepDegrees(double z) {
    if (z < 8.5) return 1.0;
    if (z < 9.7) return 0.5;
    if (z < 10.6) return 0.2;
    if (z < 11.7) return 0.1;
    if (z < 13.0) return 0.05;
    if (z < 14.3) return 0.02;
    return 0.01;
  }

  void _drawCoordinateGrid(
    Canvas canvas,
    Size size,
    Offset topLeftWorld,
    Offset bottomRightWorld,
  ) {
    final nw = worldPxToLatLon(topLeftWorld, zoom);
    final se = worldPxToLatLon(bottomRightWorld, zoom);
    final step = _gridStepDegrees(zoom);

    final gridPaint = Paint()
      ..color = agosGridLine
      ..strokeWidth = 0.85;

    final labelStyle = const TextStyle(
      fontFamily: 'Barlow',
      fontWeight: FontWeight.w600,
      fontSize: 10.5,
      color: agosCoordLabel,
      letterSpacing: 0.4,
      shadows: [
        Shadow(color: Color(0xDD071523), blurRadius: 3, offset: Offset(0, 1)),
      ],
    );

    final decimals = step < 0.1 ? 2 : (step < 1.0 ? 2 : 1);

    // Horizontal latitude lines & right-edge labels
    final firstLat = (se.lat / step).ceil() * step;
    for (var curLat = firstLat; curLat <= nw.lat + 1e-6; curLat += step) {
      final wy = latLonToWorldPx(curLat, lon, zoom).dy;
      final sy = wy - topLeftWorld.dy;
      if (sy < 0 || sy > size.height) continue;
      canvas.drawLine(Offset(0, sy), Offset(size.width, sy), gridPaint);

      // Avoid colliding with the very bottom longitude strip or very top edge
      if (sy > 32 && sy < size.height - 32) {
        final text = '${curLat.abs().toStringAsFixed(decimals)}°N';
        final tp = TextPainter(
          text: TextSpan(text: text, style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(size.width - tp.width - 8, sy - tp.height - 3));
      }
    }

    // Vertical longitude lines & bottom-edge labels
    final firstLon = (nw.lon / step).ceil() * step;
    for (var curLon = firstLon; curLon <= se.lon + 1e-6; curLon += step) {
      final wx = latLonToWorldPx(lat, curLon, zoom).dx;
      final sx = wx - topLeftWorld.dx;
      if (sx < 0 || sx > size.width) continue;
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height), gridPaint);

      if (sx > 28 && sx < size.width - 28) {
        final text = '${curLon.abs().toStringAsFixed(decimals)}°E';
        final tp = TextPainter(
          text: TextSpan(text: text, style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(sx - tp.width / 2, size.height - tp.height - 5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CebuTileAndGridPainter oldDelegate) => true;
}
