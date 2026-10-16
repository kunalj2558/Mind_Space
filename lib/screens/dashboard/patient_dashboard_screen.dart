import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/providers/coins_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/core/widgets/theme_toggle_button.dart';
import 'package:hearme/screens/mental_health/mental_health_screen.dart';
import 'package:hearme/screens/chat/chat_bottom_sheet.dart';
import 'package:hearme/screens/linking/my_code_screen.dart';
import 'package:hearme/screens/linking/link_doctor_screen.dart';
import 'package:hearme/screens/rewards/rewards_screen.dart';
import 'package:hearme/screens/rewards/redeemed_rewards_screen.dart';
import 'package:hearme/screens/history/chat_history_screen.dart';
import 'package:hearme/screens/history/mindspace_history_screen.dart';
import 'package:hearme/screens/profile/profile_screen.dart';
import 'package:hearme/screens/welcome/welcome_screen.dart';
import 'package:hearme/screens/marketplace/clinician_directory_screen.dart';
import 'package:hearme/screens/appointments/appointments_list_screen.dart';
import 'package:hearme/screens/safety/crisis_resources_sheet.dart';
import 'package:hearme/screens/wallet/wallet_screen.dart';
import 'package:hearme/services/app_update_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;
    final auth = Provider.of<AuthProvider>(context);
    final coins = Provider.of<CoinsProvider>(context);

    // Silently check for newer app builds from server
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkForUpdatesSilently(context);
    });

    return Scaffold(
      drawer: _buildDrawer(context, isDark, lang, auth),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Builder(
                      builder: (ctx) => GestureDetector(
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.orangeGradient,
                          ),
                          child: Center(
                            child: Text(
                              (auth.user?.name ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppStrings.get('hello', lang)},',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppTheme.darkTextGray
                                  : AppTheme.textGray,
                            ),
                          ),
                          Text(
                            auth.user?.name ?? 'User',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextLight
                                  : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Coins display
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RewardsScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${coins.coins}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Consultation Wallet shortcut
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WalletScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Wallet',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.emergency_outlined, color: Colors.redAccent, size: 22),
                      tooltip: '24/7 Crisis Support',
                      onPressed: () => CrisisResourcesSheet.show(context),
                    ),
                    const ThemeToggleButton(),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: AppTheme.spacingLarge),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Hero: Mind Space
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MentalHealthScreen()),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spacingLarge),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLarge),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C4DFF)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.get('mind_space', lang),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        AppStrings.get('share_your_day', lang),
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.mic_rounded,
                                                color: Colors.white, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              'Start Recording',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Colors.white.withValues(alpha: 0.2),
                                  ),
                                  child: const Icon(
                                    Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideY(begin: 0.15, duration: 400.ms),

                        const SizedBox(height: AppTheme.spacingMedium),

                        // V2 Hero: Verified Specialists & Consultations
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClinicianDirectoryScreen(),
                            ),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spacingLarge),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLarge),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'Verified Specialists',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Psychologists, Psychiatrists & Therapists • Video, Voice & Chat consultations',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'Consult',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, duration: 350.ms),

                        const SizedBox(height: AppTheme.spacingMedium),

                        // Grid of other tiles
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppTheme.spacingMedium,
                          crossAxisSpacing: AppTheme.spacingMedium,
                          childAspectRatio: 1.15,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildTile(
                              context: context,
                              title: AppStrings.get('chat_with_hearme', lang),
                              subtitle: 'AI Medical Assistant',
                              icon: Icons.smart_toy_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4ECDC4),
                                  Color(0xFF44A08D),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => showChatBottomSheet(context),
                              delay: 200,
                            ),
                            _buildTile(
                              context: context,
                              title: 'My Consultations',
                              subtitle: 'Upcoming & Past',
                              icon: Icons.calendar_month_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF4F46E5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AppointmentsListScreen()),
                              ),
                              delay: 250,
                            ),
                            _buildTile(
                              context: context,
                              title: AppStrings.get('mind_rewards', lang),
                              subtitle: '${coins.coins} coins',
                              icon: Icons.stars_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFFA000),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RewardsScreen()),
                              ),
                              delay: 300,
                            ),
                            _buildTile(
                              context: context,
                              title: AppStrings.get('my_code', lang),
                              subtitle: auth.user?.uniqueCode ?? 'HM-XXXX',
                              icon: Icons.qr_code_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF6B35),
                                  Color(0xFFFF8C61),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MyCodeScreen()),
                              ),
                              delay: 400,
                            ),
                            _buildTile(
                              context: context,
                              title: AppStrings.get('link_doctor', lang),
                              subtitle: 'Share health data',
                              icon: Icons.link_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF667EEA),
                                  Color(0xFF764BA2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LinkDoctorScreen()),
                              ),
                              delay: 500,
                            ),
                            _buildTile(
                              context: context,
                              title: 'Consultation Wallet',
                              subtitle: '₹ Balance & Top-up',
                              icon: Icons.account_balance_wallet_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0D9488),
                                  Color(0xFF059669),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const WalletScreen()),
                              ),
                              delay: 550,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spacingMedium),

                        // Emergency Crisis Helpline Ribbon
                        GestureDetector(
                          onTap: () => CrisisResourcesSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.support_agent_rounded, color: Colors.redAccent, size: 22),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Need Immediate Support? 24/7 National Helplines',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Tele-MANAS (14416) • KIRAN (1800-599-0019) • ERSS (112)',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    Provider.of<ThemeProvider>(context).isDarkMode
                        ? AppTheme.darkTextLight
                        : AppTheme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color:
                    Provider.of<ThemeProvider>(context).isDarkMode
                        ? AppTheme.darkTextGray
                        : AppTheme.textGray,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale(
          begin: const Offset(0.9, 0.9),
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildDrawer(
      BuildContext context, bool isDark, String lang, AuthProvider auth) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacingLarge),
            // Profile section
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.orangeGradient,
              ),
              child: Center(
                child: Text(
                  (auth.user?.name ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              auth.user?.name ?? 'User',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
              ),
            ),
            Text(
              auth.user?.email ?? '',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            const Divider(),

            // Profile
            ListTile(
              leading: Icon(
                Icons.person_outline_rounded,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileScreen()),
                );
              },
            ),

            // Language picker
            ListTile(
              leading: Icon(
                Icons.language_rounded,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
              title: Text(
                AppStrings.get('language', lang),
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
              trailing: DropdownButton<String>(
                value: lang,
                underline: const SizedBox.shrink(),
                dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                  fontSize: 14,
                ),
                items: LocaleProvider.supportedLanguages.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (code) {
                  if (code != null) localeProvider.setLanguage(code);
                },
              ),
            ),

            // MindSpace History
            ListTile(
              leading: Icon(
                Icons.psychology_rounded,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
              title: Text(
                'MindSpace History',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MindSpaceHistoryScreen()),
                );
              },
            ),

            // Chat History
            ListTile(
              leading: Icon(
                Icons.chat_bubble_outline_rounded,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
              title: Text(
                'Chat History',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChatHistoryScreen()),
                );
              },
            ),

            // Redeemed Rewards
            ListTile(
              leading: Icon(
                Icons.card_giftcard_rounded,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
              title: Text(
                'My Rewards',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RedeemedRewardsScreen()),
                );
              },
            ),

            // Verified Specialists
            ListTile(
              leading: Icon(
                Icons.verified_user_rounded,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
              title: Text(
                'Verified Specialists',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ClinicianDirectoryScreen()),
                );
              },
            ),

            // My Consultations
            ListTile(
              leading: Icon(
                Icons.calendar_month_rounded,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
              title: Text(
                'My Consultations',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AppointmentsListScreen()),
                );
              },
            ),

            // Consultation Wallet
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF059669),
              ),
              title: Text(
                'Consultation Wallet & Top-Up',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Pay-As-You-Go telehealth balance',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WalletScreen()),
                );
              },
            ),

            // 24/7 Crisis Support
            ListTile(
              leading: const Icon(
                Icons.support_agent_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                '24/7 Crisis Helplines',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                CrisisResourcesSheet.show(context);
              },
            ),

            // Check for Updates
            ListTile(
              leading: const Icon(
                Icons.system_update_rounded,
                color: AppTheme.primaryOrange,
              ),
              title: Text(
                'Check for Updates',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'v${ApiConstants.currentAppVersion} • Instant cloud updates',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                AppUpdateService.checkForUpdatesManually(context);
              },
            ),

            const Spacer(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: Text(
                AppStrings.get('logout', lang),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: AppTheme.spacingMedium),
          ],
        ),
      ),
    );
  }
}
