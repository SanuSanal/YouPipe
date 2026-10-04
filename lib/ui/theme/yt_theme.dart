import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// YouTube Android's colour tokens, for both themes (docs/ui.md). Read them with `context.yt`.
@immutable
class YtColors extends ThemeExtension<YtColors> {
  const YtColors({
    required this.background,
    required this.raised,
    required this.chip,
    required this.chipSelected,
    required this.onChipSelected,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.link,
    required this.subscribe,
    required this.onSubscribe,
    required this.navBar,
    required this.skeleton,
  });

  /// Page background.
  final Color background;

  /// Sheets, menus, the description panel.
  final Color raised;

  /// Chips and pill buttons (Like, Share, Subscribed…).
  final Color chip;
  final Color chipSelected;
  final Color onChipSelected;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  /// Links in descriptions and comments, "N replies".
  final Color link;

  /// The Subscribe pill (white on dark, black on light).
  final Color subscribe;
  final Color onSubscribe;
  final Color navBar;

  /// Loading placeholders.
  final Color skeleton;

  static const red = Color(0xFFFF0000);

  /// The seek bar / progress red.
  static const progress = Color(0xFFFF0033);
  static const badge = Color(0xCC000000);
  static const liveRed = Color(0xFFCC0000);

  static const dark = YtColors(
    background: Color(0xFF0F0F0F),
    raised: Color(0xFF212121),
    chip: Color(0xFF272727),
    chipSelected: Color(0xFFF1F1F1),
    onChipSelected: Color(0xFF0F0F0F),
    textPrimary: Color(0xFFF1F1F1),
    textSecondary: Color(0xFFAAAAAA),
    divider: Color(0x1AFFFFFF),
    link: Color(0xFF3EA6FF),
    subscribe: Color(0xFFF1F1F1),
    onSubscribe: Color(0xFF0F0F0F),
    navBar: Color(0xFF0F0F0F),
    skeleton: Color(0xFF272727),
  );

  static const light = YtColors(
    background: Color(0xFFFFFFFF),
    raised: Color(0xFFFFFFFF),
    chip: Color(0xFFF2F2F2),
    chipSelected: Color(0xFF0F0F0F),
    onChipSelected: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0F0F0F),
    textSecondary: Color(0xFF606060),
    divider: Color(0x1A000000),
    link: Color(0xFF065FD4),
    subscribe: Color(0xFF0F0F0F),
    onSubscribe: Color(0xFFFFFFFF),
    navBar: Color(0xFFFFFFFF),
    skeleton: Color(0xFFF2F2F2),
  );

  @override
  YtColors copyWith() => this;

  @override
  YtColors lerp(YtColors? other, double t) => t < 0.5 || other == null ? this : other;
}

/// YouTube Android's sizes, in dp.
abstract final class YtSizes {
  static const topBarHeight = 48.0;
  static const navBarHeight = 48.0;

  /// The floating mini player: a 16:9 card this fraction of the screen width, above the nav bar.
  static const miniPlayerWidthFraction = 0.55;
  static const miniPlayerMargin = 8.0;

  /// The mini player never grows past this on tablets and TVs.
  static const miniPlayerMaxWidth = 360.0;

  /// The left navigation rail on wide screens (landscape tablets, TVs).
  static const navRailWidth = 72.0;

  /// The watch page's video column on wide screens; the related list takes the rest.
  static const watchColumnFraction = 0.64;
  static const miniPlayerRadius = 12.0;
  static const chipHeight = 32.0;
  static const chipRadius = 8.0;
  static const pillHeight = 36.0;
  static const feedAvatar = 36.0;
  static const rowThumbWidth = 160.0;
  static const thumbRadius = 8.0;
  static const sheetRadius = 12.0;
  static const pagePadding = 12.0;
}

/// Text styles matched to YouTube Android (Roboto; YouTube Sans isn't shipped).
abstract final class YtText {
  static const feedTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.3);
  static const rowTitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.3);
  static const meta = TextStyle(fontSize: 12, height: 1.35);
  static const watchTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.25);
  static const sectionTitle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
  static const channelName = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const chip = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const badge = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white);
}

extension YtThemeContext on BuildContext {
  YtColors get yt => Theme.of(this).extension<YtColors>() ?? YtColors.dark;
}

ThemeData buildYtTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final c = dark ? YtColors.dark : YtColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.textPrimary,
    onPrimary: c.background,
    secondary: YtColors.red,
    onSecondary: Colors.white,
    error: YtColors.red,
    onError: Colors.white,
    surface: c.background,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerLowest: c.background,
    surfaceContainerLow: c.raised,
    surfaceContainer: c.raised,
    surfaceContainerHigh: c.raised,
    surfaceContainerHighest: c.chip,
    outline: c.divider,
    outlineVariant: c.divider,
    inverseSurface: c.textPrimary,
    onInverseSurface: c.background,
  );
  final text = TextTheme(
    headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: const TextStyle(fontSize: 16),
    bodyMedium: const TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12, color: c.textSecondary),
    labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  ).apply(fontFamily: 'Roboto', bodyColor: c.textPrimary, displayColor: c.textPrimary);
  final overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: brightness,
    systemNavigationBarColor: c.navBar,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [c],
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    fontFamily: 'Roboto',
    textTheme: text,
    splashFactory: InkRipple.splashFactory,
    highlightColor: c.divider,
    // List rows, menus and settings show where the TV remote's focus is (cards use FocusHighlight).
    focusColor: c.textPrimary.withValues(alpha: 0.22),
    // Icon buttons (search, ⋮, player controls) get the same ring as cards when the remote focuses them.
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused) ? BorderSide(color: c.textPrimary, width: 2.5) : null,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      toolbarHeight: YtSizes.topBarHeight + 8,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: c.textPrimary),
      systemOverlayStyle: overlay,
    ),
    dividerTheme: DividerThemeData(color: c.divider, space: 1, thickness: 1),
    iconTheme: IconThemeData(color: c.textPrimary, size: 24),
    listTileTheme: ListTileThemeData(
      iconColor: c.textPrimary,
      textColor: c.textPrimary,
      subtitleTextStyle: TextStyle(fontSize: 12, color: c.textSecondary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.raised,
      modalBackgroundColor: c.raised,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.textSecondary.withValues(alpha: 0.5),
      dragHandleSize: const Size(40, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(YtSizes.sheetRadius)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    popupMenuTheme: PopupMenuThemeData(color: c.raised, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? const Color(0xFFF1F1F1) : const Color(0xFF212121),
      contentTextStyle: TextStyle(color: dark ? const Color(0xFF0F0F0F) : Colors.white, fontSize: 14),
      actionTextColor: c.link,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.textPrimary, linearTrackColor: c.divider),
    sliderTheme: SliderThemeData(
      activeTrackColor: YtColors.progress,
      inactiveTrackColor: c.divider,
      thumbColor: YtColors.progress,
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: SliderComponentShape.noOverlay,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.link : null),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.link.withValues(alpha: 0.5) : null,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: InputBorder.none,
      hintStyle: TextStyle(color: c.textSecondary),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.link,
      selectionColor: c.link.withValues(alpha: 0.3),
      selectionHandleColor: c.link,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.textPrimary,
      unselectedLabelColor: c.textSecondary,
      indicatorColor: c.textPrimary,
      dividerColor: c.divider,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      tabAlignment: TabAlignment.start,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}
