import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
// STARDUST VAULT — CLAYMORPHISM DESIGN SYSTEM
// Blue & White only. No purple. No violet.
// ─────────────────────────────────────────────────────────────

class AppSpacing {
  static const double tiny = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xlarge = 32.0;
  static const double huge = 48.0;
  static const double edge = 20.0;
}

class AppTheme {
  // ─── Blue & White Palette ───
  static const Color primaryBlue     = Color(0xFF2563EB); // Blue-600
  static const Color primaryLight    = Color(0xFF3B82F6); // Blue-500
  static const Color primaryDark     = Color(0xFF1D4ED8); // Blue-700
  static const Color accentSky       = Color(0xFF60A5FA); // Blue-400
  static const Color accentIce       = Color(0xFFDBEAFE); // Blue-100

  // ─── Neutrals ───
  static const Color white           = Color(0xFFFFFFFF);
  static const Color offWhite        = Color(0xFFFAFCFF);
  static const Color snowGrey        = Color(0xFFF0F4FF);
  static const Color mist            = Color(0xFFE2E8F0);
  static const Color slate           = Color(0xFF64748B);
  static const Color darkSlate       = Color(0xFF1E293B);
  static const Color ink             = Color(0xFF0F172A);

  // ─── Dark Mode ───
  static const Color darkBg          = Color(0xFF0B1120);
  static const Color darkSurface     = Color(0xFF111827);
  static const Color darkCard        = Color(0xFF1A2332);
  static const Color darkBorder      = Color(0xFF1E3A5F);

  // ─── Claymorphism Tokens ───
  static const double cardRadius     = 20.0;
  static const double buttonRadius   = 14.0;
  static const double inputRadius    = 12.0;

  // ─── Gradients ───
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF0F4FF), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Clay Shadows (soft, raised look) ───
  static List<BoxShadow> clayShadow({bool elevated = false}) => [
    BoxShadow(
      color: const Color(0xFF2563EB).withValues(alpha: elevated ? 0.12 : 0.06),
      offset: Offset(0, elevated ? 12 : 6),
      blurRadius: elevated ? 32 : 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: elevated ? 0.08 : 0.04),
      offset: Offset(0, elevated ? 4 : 2),
      blurRadius: elevated ? 12 : 6,
      spreadRadius: -1,
    ),
  ];

  // ─── Category Colors (Hierarchical) ───
  static const Map<String, Color> categoryColors = {
    'ids_personal':    primaryBlue,
    'digital':         primaryBlue,
    'home_property':   primaryBlue,
    'financial':       primaryBlue,
    'legal':           primaryBlue,
    'health':          primaryBlue,
    'family':          primaryBlue,
    'aging':           primaryBlue,
    'after_gone':      primaryBlue,
  };

  // ─── Category Icons (Hierarchical Mappings) ───
  static const Map<String, IconData> categoryIcons = {
    // Parents
    'ids_personal':    Icons.person_outline_rounded,
    'digital':         Icons.devices_rounded,
    'home_property':   Icons.home_work_rounded,
    'financial':       Icons.payments_rounded,
    'legal':           Icons.gavel_rounded,
    'health':          Icons.medical_services_rounded,
    'family':          Icons.groups_rounded,
    'aging':           Icons.elderly_rounded,
    'after_gone':      Icons.auto_awesome_rounded,

    // Subcategories - Identity
    'ids_vital':       Icons.badge_rounded,
    'contact_info':    Icons.contact_phone_rounded,
    'charities':       Icons.favorite_rounded,
    'clubs':           Icons.groups_rounded,
    'education':       Icons.school_rounded,
    'military':        Icons.military_tech_rounded,
    'personal_misc':   Icons.more_horiz_rounded,

    // Subcategories - Digital
    'passwords':       Icons.password_rounded,
    'email_accounts':  Icons.email_rounded,
    'devices':         Icons.laptop_rounded,
    'wifi':            Icons.wifi_rounded,
    'social_media':    Icons.share_rounded,
    'shopping':        Icons.shopping_cart_rounded,
    'digital_payment': Icons.wallet_rounded,
    'money_mgmt':      Icons.account_balance_wallet_rounded,
    'streaming':       Icons.movie_rounded,
    'music':           Icons.music_note_rounded,
    'gaming':          Icons.sports_esports_rounded,
    'cloud_storage':   Icons.cloud_rounded,
    'travel':          Icons.flight_rounded,
    'ticketing':       Icons.confirmation_number_rounded,
    'business_net':    Icons.work_rounded,
    'software_licenses': Icons.app_registration_rounded,
    'content_subs':    Icons.subtitles_rounded,
    'conferencing':    Icons.video_chat_rounded,
    'domains_hosting': Icons.public_rounded,
    'other_digital':   Icons.extension_rounded,

    // Subcategories - Property
    'homes':           Icons.home_rounded,
    'vehicles':        Icons.directions_car_rounded,
    'possessions':     Icons.diamond_rounded,
    'storage':         Icons.warehouse_rounded,
    'safe_boxes':      Icons.inventory_2_rounded,
    'home_safes':      Icons.enhanced_encryption_rounded,
    'real_estate':     Icons.home_work_rounded,
    'bank_lockers':    Icons.lock_person_rounded,

    // Subcategories - Finance
    'banking':         Icons.account_balance_rounded,
    'cards':           Icons.credit_card_rounded,
    'loans':           Icons.money_off_rounded,
    'businesses':      Icons.business_rounded,
    'advisors':        Icons.support_agent_rounded,
    'life_insurance':  Icons.volunteer_activism_rounded,
    'disability_ins':  Icons.accessible_rounded,
    'tax_returns':     Icons.description_rounded,
    'social_security': Icons.security_rounded,
    'annuities':       Icons.payments_rounded,
    'pensions':        Icons.savings_rounded,
    'military_benefits': Icons.military_tech_rounded,
    'disability_benefits': Icons.wheelchair_pickup_rounded,
    'govt_schemes':    Icons.account_balance_rounded,

    // Subcategories - Legal
    'attorneys':       Icons.gavel_rounded,
    'wills':           Icons.article_rounded,
    'poa':             Icons.verified_rounded,
    'trusts':          Icons.account_balance_rounded,
    'legal_others':    Icons.source_rounded,

    // Subcategories - Health
    'health_ins':      Icons.health_and_safety_rounded,
    'doctors':         Icons.medical_information_rounded,
    'advance_directive': Icons.note_alt_rounded,
    'medical_records': Icons.receipt_long_rounded,
    'medications':     Icons.medication_rounded,
    'allergies':       Icons.warning_rounded,
    'conditions':      Icons.sick_rounded,
    'med_devices':     Icons.precision_manufacturing_rounded,
    'fitness':         Icons.fitness_center_rounded,

    // Subcategories - Family
    'emergency_contacts': Icons.contact_emergency_rounded,
    'spouse':          Icons.favorite_rounded,
    'children':        Icons.child_care_rounded,
    'parents':         Icons.family_restroom_rounded,
    'pets':            Icons.pets_rounded,
    'other_fam':       Icons.group_rounded,
    'genealogy':       Icons.account_tree_rounded,
    'antique_photos':  Icons.photo_library_rounded,
    'recipes':         Icons.restaurant_menu_rounded,
    'family_tree':     Icons.hub_rounded,

    // Subcategories - Aging
    'care_providers':  Icons.medical_services_rounded,
    'ltc_insurance':   Icons.health_and_safety_rounded,
    'care_prefs':      Icons.handshake_rounded,
    'care_finances':   Icons.savings_rounded,

    // Subcategories - Legacy
    'final_arrangements': Icons.church_rounded,
    'funeral_prefs':   Icons.open_in_new_rounded,
    'legacy_recording': Icons.mic_rounded,
    'obituary':        Icons.notes_rounded,
    'letter_all':      Icons.mail_outline_rounded,
    'letter_family':   Icons.contact_mail_rounded,
    'memorialization': Icons.auto_stories_rounded,
    'about_life':      Icons.history_edu_rounded,
  };

  // ═══════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);
    final displayTheme = GoogleFonts.outfitTextTheme(baseTheme.textTheme);

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: offWhite,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryLight,
        tertiary: accentSky,
        surface: white,
        onPrimary: white,
        onSurface: ink,
        onSurfaceVariant: slate,
        outline: mist,
        surfaceContainerHighest: snowGrey,
      ),
      textTheme: textTheme.copyWith(
        displayLarge:  displayTheme.displayLarge?.copyWith(fontSize: 42, fontWeight: FontWeight.w800, color: ink, letterSpacing: -1.2),
        headlineLarge: displayTheme.headlineLarge?.copyWith(fontSize: 34, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.8),
        headlineMedium: displayTheme.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w700, color: ink),
        headlineSmall: displayTheme.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: ink),
        titleLarge:  textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: darkSlate),
        bodyLarge:   textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: slate),
        bodyMedium:  textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: slate),
        bodySmall:   textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
        labelLarge:  textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: primaryBlue),
        labelSmall:  textTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: slate),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkSlate),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: snowGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(inputRadius), borderSide: BorderSide(color: mist)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(inputRadius), borderSide: BorderSide(color: mist)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(inputRadius), borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(inputRadius), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
        labelStyle: GoogleFonts.inter(color: slate, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: const Color(0xFFA3ACBA), fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: primaryBlue, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: mist, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.outfitTextTheme(baseTheme.textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      primaryColor: accentSky,
      colorScheme: ColorScheme.dark(
        primary: accentSky,
        secondary: primaryLight,
        surface: darkSurface,
        onPrimary: ink,
        onSurface: const Color(0xFFE2E8F0),
        onSurfaceVariant: const Color(0xFF94A3B8),
        outline: darkBorder,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: white, letterSpacing: -1),
        headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: white, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: white),
        headlineSmall: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: white),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: white),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFCBD5E1)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFCBD5E1)),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: accentSky),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(inputRadius), borderSide: BorderSide(color: darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(inputRadius), borderSide: BorderSide(color: darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(inputRadius), borderSide: const BorderSide(color: accentSky, width: 2)),
        labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF475569)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentSky,
        foregroundColor: ink,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
