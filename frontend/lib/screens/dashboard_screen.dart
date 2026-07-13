import 'dart:ui';
import 'package:flutter/material.dart';

import '../main.dart';

import '../widgets/clay_card.dart';
import '../theme.dart';
import '../models/category_schema.dart';
import '../services/vault_service.dart';
import 'features/category_dashboard_screen.dart';
import 'features/parent_dashboard_screen.dart';
import 'features/security_log_screen.dart';
import 'features/nominees_screen.dart';
import 'appointed_vaults_screen.dart';
import 'settings_screen.dart';
import 'features/assets_screen.dart';
import 'features/insurance_screen.dart';
import 'features/legal_center_screen.dart';
import 'features/contacts_screen.dart';
import 'features/others_screen.dart';
import 'features/passwords_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/category_wheel_selector.dart';
import '../widgets/schema_driven_form.dart';
import '../widgets/login_prompt.dart';
import '../widgets/guided_tour.dart';
import '../widgets/intro_modal.dart';
import '../widgets/vault_health_widget.dart';
import '../widgets/bento_category_card.dart';
import '../widgets/ai_insights_row.dart';
import 'account_screen.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/scanner_selection_modal.dart';

class DashboardScreen extends StatefulWidget {
  final bool isGuest;
  final bool isLogin;

  const DashboardScreen({
    super.key,
    this.isGuest = true,
    this.isLogin = true,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final VaultService _vaultService = VaultService();
  final AuthService _auth = AuthService();

  VaultSchemaResponse? _schemaResponse;
  Map<String, int> _parentCounts = {};
  Map<String, int> _subcategoryCounts = {};
  bool _isLoadingSchemas = true;
  bool _showIntro = false;
  bool _showTour = false;
  bool _isProfileComplete = true;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _showIntro = widget.isGuest;
    if (!widget.isGuest && !widget.isLogin) _showTour = true;
    _loadSchemas();
  }

  int _calculateCompletion() {
    if (_schemaResponse == null || _schemaResponse!.categories.isEmpty) return 0;
    final filled = _subcategoryCounts.values.where((v) => v > 0).length;
    final total = _schemaResponse!.categories.length;
    if (total == 0) return 0;
    double percentage = (filled / total) * 100;
    if (filled > 0 && percentage < 10) percentage = 10;
    return percentage.round().clamp(0, 100);
  }

  Future<void> _loadSchemas() async {
    try {
      final response = await _vaultService.getSchemas();
      Map<String, int> pCounts = {};
      Map<String, int> sCounts = {};
      bool isComplete = true;
      String currentName = 'User';

      try {
        final summary = await _vaultService.getSummary();
        pCounts = Map<String, int>.from(summary['parent_counts'] ?? {});
        sCounts = Map<String, int>.from(summary['subcategory_counts'] ?? {});
        
        if (!widget.isGuest) {
          final profile = await _auth.getProfile();
          currentName = profile['full_name'] ?? 'User';
          
          final completion = await _auth.getProfileCompletion();
          isComplete = completion['is_complete'] == true;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _schemaResponse = response;
          _parentCounts = pCounts;
          _subcategoryCounts = sCounts;
          _isProfileComplete = isComplete;
          _userName = currentName;
          _isLoadingSchemas = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSchemas = false);
    }
  }

  String? _selectedParentKey;
  String? _selectedSubcategoryKey;
  int _selectedIndex = 0; // 0 = Dashboard, 12 = Security

  void _selectParent(String key) {
    setState(() {
      _selectedParentKey = key;
      _selectedSubcategoryKey = null;
      _selectedIndex = -1;
    });
  }

  void _selectSubcategory(String key) {
    if (_schemaResponse == null) return;
    final schema = _schemaResponse!.categories[key];
    if (schema == null) return;

    final isWide = MediaQuery.of(context).size.width >= _kTabletBreak;
    if (isWide) {
      setState(() {
        _selectedSubcategoryKey = key;
        _selectedIndex = -1;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoryDashboardScreen(schema: schema)),
      ).then((_) {
        // Clear locally if needed, though on mobile it doesn't matter much as it was pushed
        if (mounted) setState(() => _selectedSubcategoryKey = null);
      });
    }
  }

  void _goHome() => setState(() { 
    _selectedIndex = 0; 
    _selectedParentKey = null; 
    _selectedSubcategoryKey = null; 
  });

  void _showScannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScannerSelectionModal(schemaResponse: _schemaResponse, vaultService: _vaultService),
    ).then((_) => _loadSchemas()); // Refresh counts when modal is closed
  }
  
  void _goSecurity() => setState(() { 
    _selectedIndex = 12; 
    _selectedParentKey = null; 
    _selectedSubcategoryKey = null; 
  });

  CategorySchema? get _selectedSubSchema {
    if (_selectedSubcategoryKey == null) return null;
    return _schemaResponse?.categories[_selectedSubcategoryKey];
  }

  // ─── Menu items for sidebar (Hierarchical) ───
  List<Map<String, dynamic>> get _menuItems {
    final items = <Map<String, dynamic>>[
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'key': '__home__', 'color': AppTheme.primaryBlue},
      {'icon': Icons.people_outline_rounded, 'label': 'My Nominees', 'key': '__nominees__', 'color': Colors.orangeAccent},
      {'icon': Icons.verified_user_rounded, 'label': 'Appointed Vaults', 'key': '__appointed__', 'color': Colors.greenAccent},
    ];

    if (_schemaResponse != null) {
      _schemaResponse!.parents.forEach((key, p) {
        items.add({
          'icon': AppTheme.categoryIcons[key] ?? Icons.folder_rounded,
          'label': p.label,
          'key': key,
          'color': p.parsedColor,
        });
      });
    }

    items.add({'icon': Icons.security_rounded, 'label': 'Security Log', 'key': '__security__', 'color': Colors.redAccent});
    items.add({'icon': Icons.settings_suggest_rounded, 'label': 'Settings', 'key': '__settings__', 'color': Colors.blueGrey});
    items.add({'icon': Icons.account_circle_rounded, 'label': 'Account Dossier', 'key': '__account__', 'color': AppTheme.primaryBlue});
    return items;
  }

  /// Responsive breakpoints
  static const double _kTabletBreak = 768;
  static const double _kDesktopBreak = 1024;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= _kTabletBreak;
    final isDesktop = screenWidth >= _kDesktopBreak;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(child: _sidebarContent()),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              if (isDesktop) _sidebar(),
              Expanded(
                child: Column(
                  children: [
                    _appBar(isDesktop),
                    Expanded(child: _mainContentArea(context, isDesktop)),
                  ],
                ),
              ),
            ],
          ),
          // Floating capsule bottom bar on phones/tablets
          if (!isDesktop)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _floatingCapsuleBar(),
            ),
          // Floating Scanner FAB — bottom right, above the bar
          if (!isDesktop)
            Positioned(
              right: 16,
              bottom: 78,
              child: _PulseScannerFab(
                isGuest: widget.isGuest,
                onPressed: () => widget.isGuest ? _showLoginRequiredPrompt() : _showScannerModal(),
              ),
            ),

          if (_showIntro)
            IntroModal(onFinish: () => setState(() { _showIntro = false; _showTour = true; })),
          if (_showTour && _schemaResponse != null)
            GuidedTour(
              onStepChange: (index) {
                if (index == 0) _goHome();
                else if (index <= _schemaResponse!.parents.length) {
                  final k = _schemaResponse!.parents.keys.elementAt(index - 1);
                  _selectParent(k);
                }
              },
              steps: [
                TourStep(title: 'Welcome to your Dashboard', description: 'Your central command center for all secure information.', icon: Icons.dashboard_rounded),
                ..._schemaResponse!.parents.entries.map((e) => TourStep(
                  title: e.value.label,
                  description: 'Manage all ${e.value.label} related assets.',
                  icon: AppTheme.categoryIcons[e.key] ?? Icons.folder_rounded,
                )),
                TourStep(title: 'Security Log', description: 'Monitor all access attempts and security events.', icon: Icons.security_rounded),
              ],
              onFinish: () => setState(() { _showTour = false; _goHome(); }),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FLOATING CAPSULE BAR (Liquid Glass)
  // ═══════════════════════════════════════════════════════════
  Widget _floatingCapsuleBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380; // iPhone SE / mini

    return Padding(
      padding: EdgeInsets.only(
        left: 4,
        right: 4,
        bottom: 0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: isCompact ? 60 : 66,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F1A2E).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppTheme.primaryBlue.withValues(alpha: 0.12),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : AppTheme.primaryBlue.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _capsuleTab(Icons.home_rounded, 'Home', _selectedIndex == 0, _goHome, isCompact),
                _capsuleTab(Icons.grid_view_rounded, 'Vault', _selectedParentKey != null, _showVaultNavigation, isCompact),
                // Center AI Guide button
                _capsuleFab(isCompact),
                _capsuleTab(Icons.add_rounded, 'Add', false, () => widget.isGuest ? _showLoginRequiredPrompt() : _showCategoryWheel(), isCompact),
                _capsuleTab(Icons.security_rounded, 'Security', _selectedIndex == 12, _goSecurity, isCompact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _capsuleTab(IconData icon, String label, bool isActive, VoidCallback onTap, bool isCompact) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = AppTheme.primaryBlue;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? (isCompact ? 10 : 14) : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
              size: isCompact ? 20 : 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: isCompact ? 9 : 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
              letterSpacing: 0.2,
            )),
          ],
        ),
      ),
    );
  }

  Widget _capsuleFab(bool isCompact) {
    final size = isCompact ? 44.0 : 50.0;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/guide'),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: isCompact ? 22 : 24),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SIDEBAR (iPad/Desktop)
  // ═══════════════════════════════════════════════════════════
  Widget _sidebar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFF),
        border: Border(right: BorderSide(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.15 : 1.0))),
      ),
      child: _sidebarContent(),
    );
  }

  Widget _sidebarContent() {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: AppSpacing.huge),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: AppSpacing.medium),
              Text('STARDUST', style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 2)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xlarge),
        _sectionLabel('VAULT'),
        const SizedBox(height: AppSpacing.small),
        Expanded(
          child: _isLoadingSchemas
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    final key = item['key'] as String;
                    final isSelected = key == '__home__'
                        ? _selectedIndex == 0
                        : key == '__security__'
                            ? _selectedIndex == 12
                            : _selectedParentKey == key;

                    return _SidebarTile(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                      selected: isSelected,
                      accentColor: item['color'] as Color? ?? AppTheme.primaryBlue,
                      count: _parentCounts[key],
                      onTap: () {
                        if (key == '__home__') _goHome();
                        else if (key == '__security__') _goSecurity();
                        else if (key == '__account__') setState(() { _selectedIndex = 7; _selectedParentKey = null; _selectedSubcategoryKey = null; });
                        else _selectParent(key);
                        // Close drawer on mobile
                        final scaffoldState = Scaffold.maybeOf(context);
                        if (scaffoldState?.isDrawerOpen == true) Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        if (widget.isGuest) ...[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _authButton(icon: Icons.login_rounded, label: 'Sign In', onPressed: () => Navigator.pushNamed(context, '/auth'), isPrimary: false),
                const SizedBox(height: 8),
                _authButton(icon: Icons.person_add_rounded, label: 'Create Account', onPressed: () => Navigator.pushNamed(context, '/signup'), isPrimary: true),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // APP BAR (with SafeArea)
  // ═══════════════════════════════════════════════════════════
  Widget _appBar(bool isWide) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 400;
    final isMedium = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.primaryBlue.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : AppSpacing.edge,
            vertical: 8,
          ),
          child: Row(
            children: [
              if (!isWide)
                IconButton(
                  icon: Icon(Icons.menu_rounded, color: theme.colorScheme.onSurface, size: 24),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              if (!isWide) const SizedBox(width: 8),
              // App title on mobile
              if (!isWide && !isNarrow)
                Text('Stardust', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                )),
              const Spacer(),
              _userProfile(isMedium),
              SizedBox(width: isNarrow ? 8 : 12),
              _actionButton(
                label: isNarrow ? '' : (isMedium ? 'Add' : 'Add Resource'),
                icon: Icons.add_rounded,
                onPressed: () => widget.isGuest ? _showLoginRequiredPrompt() : _showCategoryWheel(),
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _userProfile(bool isNarrow) {
    final theme = Theme.of(context);
    final firstLetter = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () {
        if (!widget.isGuest) {
          setState(() {
            _selectedIndex = 7; // Account Screen
            _selectedParentKey = null;
            _selectedSubcategoryKey = null;
          });
        }
      },
      child: Row(
        children: [
          if (!isNarrow) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(widget.isGuest ? 'Guest' : _userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface)),
                Text(widget.isGuest ? 'GUEST' : 'PREMIUM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 1)),
              ],
            ),
            const SizedBox(width: 12),
          ],
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(widget.isGuest ? 'G' : firstLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MAIN CONTENT ROUTER
  // ═══════════════════════════════════════════════════════════
  Widget _mainContentArea(BuildContext context, bool isDesktop) {
    final isWide = MediaQuery.of(context).size.width >= _kTabletBreak;

    // Security Log
    if (_selectedIndex == 12) return SecurityLogScreen(onBack: _goHome);

    // Selected Index mappings: 0=Home, 1=Assets, 3=Insurance, 4=Legal, 5=Health, 6=Family, 12=Security
    if (_selectedIndex == 1) return AssetsScreen(onBack: _goHome);
    if (_selectedIndex == 3) return InsuranceScreen(onBack: _goHome);
    if (_selectedIndex == 4) return LegalCenterScreen(onBack: _goHome);
    if (_selectedIndex == 5) return ContactsScreen(onBack: _goHome);
    if (_selectedIndex == 6) return OthersScreen(onBack: _goHome);
    if (_selectedIndex == 7) return AccountScreen(onBack: _goHome);

    // Nominees (Deputies)
    if (_selectedParentKey == '__nominees__') {
      return NomineesScreen(onBack: _goHome, isGuest: widget.isGuest);
    }

    // Appointed Vaults (Succession Discovery)
    if (_selectedParentKey == '__appointed__') {
      return AppointedVaultsScreen(onBack: _goHome);
    }

    // Settings (Vault Governance)
    if (_selectedParentKey == '__settings__') {
      return SettingsScreen(onBack: _goHome);
    }

    // Category view (Desktop: inline)
    if (_selectedSubcategoryKey != null && _selectedSubSchema != null) {
      if (isDesktop) {
        return CategoryDashboardScreen(
          schema: _selectedSubSchema!,
          onBack: _goHome,
        );
      } else {
        // Correcting navigation bug: Navigator was pushed multiple times here.
        // Pushing is now handled in _selectSubcategory.
        return const SizedBox.shrink();
      }
    }

    // Parent Dashboard view
    if (_selectedParentKey != null && _schemaResponse != null) {
      final parent = _schemaResponse!.parents[_selectedParentKey!];
      if (parent != null) {
        final subs = _schemaResponse!.categories.values
            .where((c) => c.parent == _selectedParentKey)
            .toList();
        
        return ParentDashboardScreen(
          parent: parent,
          subcategories: subs,
          counts: _subcategoryCounts,
          onSelectSubcategory: _selectSubcategory,
          onBack: _goHome,
        );
      }
    }

    // Dashboard home
    return _dashboardHome(context, isWide);
  }

  // ═══════════════════════════════════════════════════════════
  // DASHBOARD HOME — Responsive
  // ═══════════════════════════════════════════════════════════
  Widget _dashboardHome(BuildContext context, bool isWide) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final welcomeMsg = widget.isGuest ? 'Welcome' : (widget.isLogin ? 'Welcome back 👋' : 'Welcome 👋');

    // Responsive padding
    final edgePad = screenWidth < 380 ? 14.0 : (isWide ? 32.0 : 18.0);
    
    // Hardcoded insights for V2 demo
    final insights = [
      AIInsight(text: 'Visa Platinum expiring in 43 days. Update now?', icon: Icons.credit_card_rounded, color: Colors.orange),
      AIInsight(text: 'Security log shows login from new device.', icon: Icons.warning_amber_rounded, color: Colors.red),
      AIInsight(text: 'Identity docs folder is 80% complete.', icon: Icons.badge_rounded, color: AppTheme.primaryBlue),
    ];

    return RefreshIndicator(
      onRefresh: _loadSchemas,
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: edgePad, right: edgePad, top: edgePad, bottom: isWide ? 40.0 : 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Text(welcomeMsg, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ),
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Global Asset Integrity Monitor',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                ),
                if (widget.isGuest)
                  _actionButton(
                    label: 'Sync',
                    icon: Icons.sync_rounded,
                    onPressed: () => Navigator.pushNamed(context, '/auth'),
                    isPrimary: true,
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Health Widget (V2 Premium Spotlight)
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: VaultHealthWidget(
                percentage: _calculateCompletion(),
                status: _calculateCompletion() > 70 ? 'Excellent Status' : 'Incomplete Vault',
                onTap: () => _goSecurity(),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // AI Insights Row
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              child: AIInsightsRow(insights: insights),
            ),

            const SizedBox(height: 40),

            // Bento Grid
            Row(
              children: [
                const SizedBox(width: 4),
                Text(
                  'MISSION CONTROL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (!widget.isGuest && !_isProfileComplete) ...[
              _profileCompletionReminder(),
              const SizedBox(height: 24),
            ],

            _isLoadingSchemas || _schemaResponse == null
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final parents = _schemaResponse!.parents.values.toList();
                      
                      // Custom Bento Layout logic
                      // Financial (0) is large, IDs (1) is large, others small
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: List.generate(parents.length, (index) {
                          final p = parents[index];
                          final count = _parentCounts[p.key] ?? 0;
                          final isLarge = index < 2; // Make first two (Personal/Financial) take more space
                          
                          double width;
                          if (screenWidth > 800) {
                             width = isLarge ? (constraints.maxWidth * 0.6) - 8 : (constraints.maxWidth * 0.3);
                          } else {
                             width = isLarge ? constraints.maxWidth : (constraints.maxWidth / 2) - 8;
                          }

                          return FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: Duration(milliseconds: 400 + (index * 100)),
                            child: SizedBox(
                              width: width,
                              height: isLarge ? 200 : 140,
                              child: BentoCategoryCard(
                                parent: p,
                                count: count,
                                isLarge: isLarge,
                                onTap: () => _selectParent(p.key),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ═══════════════════════════════════════════════════════════
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
        letterSpacing: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900,
      )),
    );
  }

  Widget _authButton({required IconData icon, required String label, required VoidCallback onPressed, required bool isPrimary}) {
    final color = isPrimary ? AppTheme.primaryBlue : Colors.white;
    final onColor = isPrimary ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: isPrimary ? null : Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: isPrimary ? [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onColor, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: onColor, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required String label, IconData? icon, required VoidCallback onPressed, required bool isPrimary, double? width}) {
    final theme = Theme.of(context);
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.primaryBlue : Colors.white,
        foregroundColor: isPrimary ? Colors.white : theme.colorScheme.onSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: isPrimary ? BorderSide.none : BorderSide(color: theme.colorScheme.outline)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 16),
          if (label.isNotEmpty) ...[const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))],
        ],
      ),
    );
    return width != null ? SizedBox(width: width, child: button) : button;
  }

  Widget _profileCompletionReminder() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.privacy_tip_rounded, color: Colors.orangeAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Setup Incomplete',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Complete your dossier to ensure full succession coverage.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => setState(() {
                  _selectedIndex = 7;
                  _selectedParentKey = null;
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Finish Setup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroButton({required String label, IconData? icon, required VoidCallback onPressed, required bool isPrimary}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isPrimary ? Colors.transparent : Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: isPrimary ? AppTheme.primaryBlue : Colors.white), const SizedBox(width: 8)],
            Text(label, style: TextStyle(color: isPrimary ? AppTheme.primaryBlue : Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── Quick Actions & Navigation ───
  void _showQuickAddMenu() {
    _showCategoryWheel();
  }

  void _showCategoryWheel() {
    if (_schemaResponse == null) return;
    final allCategories = _schemaResponse!.categories.values.toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CategoryWheelSelector(
        schemas: allCategories,
        onSelect: (schema) {
          Navigator.pop(ctx);
          _showAddForm(schema);
        },
      ),
    );
  }

  void _showAddForm(CategorySchema schema) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => SchemaDrivenForm(
          schema: schema,
          onSubmit: (data) async {
            try {
              await _vaultService.addItem(schema.key, data);
              if (mounted) {
                Navigator.pop(context);
                _loadSchemas(); // Refresh dashboard counts
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${schema.label} added to vault'),
                    backgroundColor: schema.parsedColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save: $e'),
                    backgroundColor: Colors.red.shade400,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showVaultNavigation() {
    _showParentPicker((key) => _selectParent(key), 'Navigate Vault');
  }

  void _showParentPicker(Function(String) onSelect, String title) {
    if (_schemaResponse == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(title, style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _schemaResponse!.parents.length,
                  itemBuilder: (context, index) {
                    final key = _schemaResponse!.parents.keys.elementAt(index);
                    final p = _schemaResponse!.parents[key]!;
                    final color = p.parsedColor;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelect(key);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(AppTheme.categoryIcons[key] ?? Icons.folder, color: color),
                          ),
                          const SizedBox(height: 8),
                          Text(p.label, 
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredPrompt() => LoginRequiredPrompt.show(context);
}

// ═══════════════════════════════════════════════════════════
// SIDEBAR TILE
// ═══════════════════════════════════════════════════════════
class _SidebarTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  final int? count;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentColor = AppTheme.primaryBlue,
    this.count,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = widget.accentColor;
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF697386);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? activeColor.withValues(alpha: isDark ? 0.15 : 0.08)
                  : (_isHovering ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: widget.selected
                  ? Border.all(color: activeColor.withValues(alpha: 0.2))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.selected ? activeColor : inactiveColor, size: 18),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(widget.label, style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.selected ? activeColor : inactiveColor,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                  )),
                ),
                if (widget.count != null && widget.count! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${widget.count}', style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseScannerFab extends StatefulWidget {
  final bool isGuest;
  final VoidCallback onPressed;

  const _PulseScannerFab({required this.isGuest, required this.onPressed});

  @override
  State<_PulseScannerFab> createState() => _PulseScannerFabState();
}

class _PulseScannerFabState extends State<_PulseScannerFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Pulse circles (positioned absolutely, won't affect layout)
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = (_controller.value + (index / 3)) % 1.0;
                return Opacity(
                  opacity: (1.0 - progress) * 0.25,
                  child: Container(
                    width: 56 + (progress * 40),
                    height: 56 + (progress * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                );
              },
            );
          }),
          FloatingActionButton.extended(
            onPressed: widget.onPressed,
            backgroundColor: AppTheme.primaryBlue,
            icon: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20),
            label: const Text(
              'SCAN', 
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.5,
                fontSize: 13,
              )
            ),
            elevation: 8,
          ),
        ],
      ),
    );
  }
}


