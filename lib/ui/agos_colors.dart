import 'package:material_ui/material_ui.dart';

// Core brand & dark maritime palette matching the AGOS tactical UI.
const agosNavy = Color(0xFF0A1624);
const agosTeal = Color(0xFF2DD49F);

const agosBarBg = Color(0xFF0A1624);
const agosScaffoldBg = Color(0xFF081A2C);
const agosOceanBg = Color(0xFF091F35);
const agosSurface = Color(0xFF0F2235);
const agosSurfaceTranslucent = Color(0xE80D1E30);
const agosButtonGlass = Color(0xDF102337);

const agosBorder = Color(0xFF1C354D);
const agosBorderBright = Color(0xFF284663);
const agosGridLine = Color(0x552B5C82);
const agosCoordLabel = Color(0xFF6B99BC);

const agosTextPrimary = Color(0xFFF2F7FC);
const agosMutedText = Color(0xFF9FB5C8);
const agosSectionTitleColor = Color(0xFF9FB6C8);
const agosLabelMuted = Color(0xFF7D97AD);

const agosAccentOrange = Color(0xFFFF7A1A);
const agosAccentOrangeLight = Color(0xFFC24D08);
const agosOnlineGreen = Color(0xFF2CD49E);
const agosOnlineGreenLight = Color(0xFF0E8F67);
const agosWarningAmber = Color(0xFFF4B63B);
const agosWarningAmberLight = Color(0xFFB37400);
const agosAlertRed = Color(0xFFEF474E);
const agosAlertBg = Color(0xE83D151E);
const agosAlertBorder = Color(0xFFCC444B);
const agosYouBlue = Color(0xFF56A8F5);

class AgosPalette {
  const AgosPalette._({
    required this.isDark,
    required this.barBg,
    required this.scaffoldBg,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceTranslucent,
    required this.buttonGlass,
    required this.inputFill,
    required this.border,
    required this.borderBright,
    required this.textPrimary,
    required this.textMuted,
    required this.textLabel,
    required this.sectionTitle,
    required this.accent,
    required this.online,
    required this.warning,
    required this.danger,
    required this.pillBg,
    required this.pillSelectedBg,
    required this.navUnselected,
    required this.headerTitle,
  });

  final bool isDark;
  final Color barBg;
  final Color scaffoldBg;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceTranslucent;
  final Color buttonGlass;
  final Color inputFill;
  final Color border;
  final Color borderBright;
  final Color textPrimary;
  final Color textMuted;
  final Color textLabel;
  final Color sectionTitle;
  final Color accent;
  final Color online;
  final Color warning;
  final Color danger;
  final Color pillBg;
  final Color pillSelectedBg;
  final Color navUnselected;
  final Color headerTitle;

  static const dark = AgosPalette._(
    isDark: true,
    barBg: agosBarBg,
    scaffoldBg: agosScaffoldBg,
    surface: agosSurface,
    surfaceAlt: Color(0xFF102336),
    surfaceTranslucent: agosSurfaceTranslucent,
    buttonGlass: agosButtonGlass,
    inputFill: agosBarBg,
    border: agosBorder,
    borderBright: agosBorderBright,
    textPrimary: agosTextPrimary,
    textMuted: agosMutedText,
    textLabel: agosLabelMuted,
    sectionTitle: agosSectionTitleColor,
    accent: agosAccentOrange,
    online: agosOnlineGreen,
    warning: agosWarningAmber,
    danger: agosAlertRed,
    pillBg: Color(0xFF102235),
    pillSelectedBg: Color(0xFF1A344D),
    navUnselected: agosMutedText,
    headerTitle: Colors.white,
  );

  static const light = AgosPalette._(
    isDark: false,
    barBg: Color(0xFFFFFFFF),
    scaffoldBg: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF8FAFC),
    surfaceTranslucent: Color(0xF2FFFFFF),
    buttonGlass: Color(0xEBFFFFFF),
    inputFill: Color(0xFFF4F7FA),
    border: Color(0xFFD6E0EA),
    borderBright: Color(0xFFBAC8D6),
    textPrimary: Color(0xFF0D1E2E),
    textMuted: Color(0xFF4B6275),
    textLabel: Color(0xFF60788B),
    sectionTitle: Color(0xFF536C80),
    accent: agosAccentOrangeLight,
    online: agosOnlineGreenLight,
    warning: agosWarningAmberLight,
    danger: Color(0xFFC92A34),
    pillBg: Color(0xFFE9F0F6),
    pillSelectedBg: Color(0xFFFCEEE6),
    navUnselected: Color(0xFF587084),
    headerTitle: Color(0xFF0A1624),
  );

  static AgosPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
