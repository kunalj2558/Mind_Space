import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/core/widgets/animated_button.dart';
import 'package:hearme/services/v2_service.dart';
import 'package:hearme/screens/appointments/book_appointment_screen.dart';

class ClinicianProfileScreen extends StatefulWidget {
  final String professionalId;

  const ClinicianProfileScreen({
    super.key,
    required this.professionalId,
  });

  @override
  State<ClinicianProfileScreen> createState() => _ClinicianProfileScreenState();
}

class _ClinicianProfileScreenState extends State<ClinicianProfileScreen> {
  Map<String, dynamic>? _professional;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await V2Service.getProfessionalDetail(widget.professionalId);
    if (mounted) {
      setState(() {
        _professional = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_professional == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Clinician profile could not be loaded')),
      );
    }

    final p = _professional!;
    final name = p['publicName'] ?? 'Doctor';
    final title = p['title'] ?? 'Specialist';
    final specialty = p['specialty'] ?? '';
    final bio = p['bio'] ?? '';
    final regNo = p['registrationNumber'] ?? '';
    final regBody = p['registrationBody'] ?? '';
    final qualifications = (p['qualifications'] as List<dynamic>?)?.join(', ') ?? '';
    final languages = (p['languages'] as List<dynamic>?)?.join(', ') ?? '';
    final rating = p['rating'] ?? 4.9;
    final reviewCount = p['reviewCount'] ?? 0;
    final rates = p['rates'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1) : 'D',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$title • $specialty',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified,
                              size: 15, color: Color(0xFF059669)),
                          const SizedBox(width: 5),
                          Text(
                            'Reg: $regNo ($regBody)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '$rating ($reviewCount reviews)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Qualifications & Details
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credentials & Background',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (qualifications.isNotEmpty) ...[
                      Text('Education & Qualifications',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.white54 : AppTheme.textLight)),
                      Text(qualifications,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.white : AppTheme.textDark)),
                      const SizedBox(height: 10),
                    ],
                    if (languages.isNotEmpty) ...[
                      Text('Consultation Languages',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.white54 : AppTheme.textLight)),
                      Text(languages,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.white : AppTheme.textDark)),
                      const SizedBox(height: 10),
                    ],
                    if (bio.isNotEmpty) ...[
                      Text('Clinical Approach',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.white54 : AppTheme.textLight)),
                      Text(bio,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color:
                                  isDark ? Colors.white70 : AppTheme.textDark)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transparent Fee Breakdown
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultation Rates & Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRateRow('15-Minute Focus Session',
                        '₹${rates['session15Min'] ?? 300}', isDark),
                    const Divider(height: 16),
                    _buildRateRow('30-Minute Full Consultation',
                        '₹${rates['session30Min'] ?? 550}', isDark),
                    const Divider(height: 16),
                    _buildRateRow('60-Minute Comprehensive Session',
                        '₹${rates['session60Min'] ?? 999}', isDark),
                    const SizedBox(height: 8),
                    Text(
                      'Per-minute rate: ₹${rates['ratePerMinute'] ?? 20}/min • Transparent billing with no hidden fees.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Book Button
              AnimatedButton(
                text: 'Schedule Consultation',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookAppointmentScreen(
                        professional: p,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateRow(String title, String price, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : AppTheme.textDark,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}
