import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/v2_service.dart';
import 'package:hearme/screens/marketplace/clinician_profile_screen.dart';
import 'package:hearme/screens/safety/crisis_resources_sheet.dart';

class ClinicianDirectoryScreen extends StatefulWidget {
  const ClinicianDirectoryScreen({super.key});

  @override
  State<ClinicianDirectoryScreen> createState() =>
      _ClinicianDirectoryScreenState();
}

class _ClinicianDirectoryScreenState extends State<ClinicianDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _professionals = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Clinical Psychologist',
    'Psychiatrist',
    'Counsellor',
    'Physiotherapist',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfessionals() async {
    setState(() => _isLoading = true);
    final specialtyQuery =
        _selectedCategory == 'All' ? null : _selectedCategory;
    final results = await V2Service.getProfessionals(
      specialty: specialtyQuery,
      query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _professionals = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verified Specialists',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => CrisisResourcesSheet.show(context),
            icon: const Icon(Icons.emergency_outlined, color: Colors.redAccent),
            tooltip: '24/7 Crisis Support',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: 8,
              ),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadProfessionals(),
                  decoration: InputDecoration(
                    hintText: 'Search by specialty, doctor or topic...',
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white60 : AppTheme.textLight,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadProfessionals();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Specialty Category Filter Pills
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppTheme.textDark),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedCategory = cat);
                        _loadProfessionals();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Directory List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _professionals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 54,
                                color: isDark ? Colors.white38 : Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No specialists found',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : AppTheme.textLight,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProfessionals,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppTheme.spacingMedium),
                            itemCount: _professionals.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppTheme.spacingMedium),
                            itemBuilder: (context, index) {
                              final p = _professionals[index];
                              return _buildClinicianCard(context, p, isDark);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicianCard(
      BuildContext context, Map<String, dynamic> p, bool isDark) {
    final title = p['title'] ?? 'Specialist';
    final name = p['publicName'] ?? 'Doctor';
    final specialty = p['specialty'] ?? '';
    final experience = p['experienceYears'] ?? 1;
    final rating = p['rating'] ?? 4.9;
    final reviewCount = p['reviewCount'] ?? 0;
    final ratePerMin = p['rates']?['ratePerMinute'] ?? 20;
    final session30 = p['rates']?['session30Min'] ?? 550;
    final hospital = p['hospitalAffiliation'] ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClinicianProfileScreen(professionalId: p['_id']),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.18),
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : 'D',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Verified badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified,
                                    size: 13, color: Color(0xFF059669)),
                                SizedBox(width: 3),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$title • $specialty',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hospital.isNotEmpty)
                        Text(
                          hospital,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : AppTheme.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rating & Experience chips
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '$rating ($reviewCount)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$experience+ yrs exp',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppTheme.textLight,
                  ),
                ),
                const Spacer(),
                // Transparent price pill
                Text(
                  '₹$ratePerMin/min  •  ₹$session30 / 30m',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
