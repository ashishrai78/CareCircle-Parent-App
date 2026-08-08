/// 📏 CareCircle — Production Size Constants
///
/// Centralized sizing system for consistent UI across the app.
/// All values in logical pixels (dp).
class USizes {
  USizes._();

  // ============ PADDING & MARGIN ============
  static const double xs = 4.0;       // extra small
  static const double sm = 8.0;       // small
  static const double md = 16.0;      // medium (default)
  static const double lg = 24.0;      // large
  static const double xl = 32.0;      // extra large
  static const double xxl = 48.0;     // 2x extra large

  // ============ ICON SIZES ============
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;  // default Material icon size
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ============ FONT SIZES ============
  static const double fontSizeXs = 10.0;
  static const double fontSizeSm = 12.0;
  static const double fontSizeMd = 14.0;
  static const double fontSizeLg = 16.0;
  static const double fontSizeXl = 18.0;
  static const double fontSizeXxl = 24.0;
  static const double fontSizeDisplay = 32.0;

  // ============ BUTTON SIZES ============
  /// ✅ FIX: Increased from 18.0 → 52.0 (Material Design minimum is 48.0)
  static const double buttonHeight = 52.0;

  /// Button width — used for fixed-width buttons
  static const double buttonWidth = 160.0;

  /// Button corner radius
  static const double buttonRadius = 12.0;

  /// Small button height (for inline actions)
  static const double buttonHeightSm = 36.0;

  /// Large button height (for primary CTAs)
  static const double buttonHeightLg = 56.0;

  /// Search bar height
  static const double searchBarHeight = 52.0;

  // ============ APP BAR ============
  static const double appBarHeight = 56.0;

  // ============ SPACING ============
  /// Default space between sections
  static const double defaultSpace = 16.0;

  /// Space between items in a list
  static const double spaceBtwItems = 12.0;

  /// Space between sections
  static const double spaceBtwSections = 24.0;

  // ============ BORDER RADIUS ============
  static const double borderRadiusXs = 4.0;
  static const double borderRadiusSm = 6.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 12.0;
  static const double borderRadiusXl = 16.0;
  static const double borderRadiusXxl = 24.0;
  static const double borderRadiusCircular = 999.0; // pill shape

  // ============ INPUT FIELD ============
  static const double inputFieldRadius = 12.0;
  static const double inputFieldHeight = 52.0;
  static const double spaceBtwInputFields = 16.0;

  // ============ CARD ============
  static const double cardRadiusXs = 6.0;
  static const double cardRadiusSm = 10.0;
  static const double cardRadiusMd = 12.0;
  static const double cardRadiusLg = 16.0;

  // ============ GRID VIEW ============
  static const double gridViewSpacing = 16.0;

  // ============ HEADER HEIGHTS ============
  /// Home screen primary header height (with gradient)
  static const double homePrimaryHeaderHeight = 280.0;

  /// Profile header height
  static const double profilePrimaryHeaderHeight = 200.0;

  /// Child detail header height
  static const double childDetailHeaderHeight = 240.0;

  // ============ AVATAR ============
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 96.0;

  // ============ STATUS DOT ============
  static const double statusDotSm = 8.0;
  static const double statusDotMd = 12.0;
  static const double statusDotLg = 16.0;

  // ============ MAP / LOCATION ============
  static const double mapHeight = 200.0;
  static const double mapHeightLg = 280.0;

  // ============ PRODUCT / CHILD ITEM ============
  static const double childCardWidth = 170.0;
  static const double childCardHeight = 200.0;
}
