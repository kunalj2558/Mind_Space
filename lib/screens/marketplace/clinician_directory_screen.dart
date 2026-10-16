import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/v2_service.dart';
import 'package:hearme/screens/marketplace/clinician_profile_screen.dart';
import 'package:hearme/screens/safety/crisis_resources_sheet.dart';
import 'package:hearme/screens/wallet/wallet_screen.dart';
import 'package:hearme/screens/consultation/consultation_room_screen.dart';

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
  double _walletBalance = 0.0;
  String _selectedProblem = 'All';

  final List<String> _problemCategories = [
    'All',
    'Stress & Burnout',
    'Anxiety & Panic',
    'Depression',
    'Relationships',
    'Sleep & Insomnia',
    'Psychiatrists (Medication)',
  ];

  @override
  void initState() {
    super.initState();
    _loadWallet();
    _loadProfessionals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    final w = await V2Service.getWalletBalance();
    if (mounted) {
      setState(() => _walletBalance = (w['balance'] as num?)?.toDouble() ?? 0.0);
    }
  }

  Future<void> _loadProfessionals() async {
    setState(() => _isLoading = true);
    String? specQuery;
    if (_selectedProblem == 'Psychiatrists (Medication)') {
      specQuery = 'Psychiatrist';
    } else if (_selectedProblem == 'Depression') {
      specQuery = 'Clinical Psychologist';
    } else if (_selectedProblem == 'Relationships') {
      specQuery = 'Counsellor';
    }

    final results = await V2Service.getProfessionals(
      specialty: specQuery,
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

  String _cleanDoctorName(String raw) {
    var name = raw.trim();
    if (name.toLowerCase().startsWith('dr.') || name.toLowerCase().startsWith('dr ')) {
      name = name.substring(3).trim();
    }
    return 'Dr. $name';
  }

  void _openIntakeSheet() {
    final concernCtrl = TextEditingController(text: 'Work Stress & Burnout');
    double distress = 6;
    String duration = 'Few weeks';
    String lang = 'English / Hindi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: AppTheme.primaryOrange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Clinical Intake Sheet (Astrotalk Profile)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text(
                'Shared with your doctor at consultation start for instant clinical context.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('What is your primary concern?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: concernCtrl.text,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: [
                  'Work Stress & Burnout',
                  'Anxiety & Panic Attacks',
                  'Persistent Depression & Sadness',
                  'Sleep Disorder / Insomnia',
                  'Relationship & Family Conflict',
                  'ADHD / Focus & Concentration',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setSheet(() => concernCtrl.text = v!),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Distress Level:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${distress.toInt()}/10', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
                ],
              ),
              Slider(
                value: distress,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppTheme.primaryOrange,
                onChanged: (val) => setSheet(() => distress = val),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        DropdownButtonFormField<String>(
                          value: duration,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: ['Few days', 'Few weeks', 'Few months', 'Over a year']
                              .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (v) => setSheet(() => duration = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        DropdownButtonFormField<String>(
                          value: lang,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: ['English / Hindi', 'Hindi', 'English', 'Marathi', 'Bengali', 'Tamil']
                              .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (v) => setSheet(() => lang = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await V2Service.saveIntake(
                      primaryConcern: concernCtrl.text,
                      distressLevel: distress.toInt(),
                      duration: duration,
                      preferredLanguage: lang,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Clinical Intake Profile updated & shared with specialists!'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Save Intake Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initiateConsultation(Map<String, dynamic> doctor, String mode) async {
    // Check wallet balance
    if (_walletBalance < 50) {
      final addMoney = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Low Wallet Balance'),
          content: Text(
            'Your current wallet balance is ₹${_walletBalance.toStringAsFixed(2)}. While your first 3 minutes are complimentary, maintaining a minimum ₹100 recharge ensures your session continues seamlessly.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continue Anyway')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
              child: const Text('Recharge Wallet', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (addMoney == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        _loadWallet();
        return;
      }
    }

    // Permissions check
    if (mode == 'video') {
      final statuses = await [Permission.camera, Permission.microphone].request();
      if (statuses[Permission.camera]?.isGranted != true || statuses[Permission.microphone]?.isGranted != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera and microphone permissions are required for video consultations.')),
        );
        return;
      }
    } else if (mode == 'voice') {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice calls.')),
        );
        return;
      }
    }

    // Book appointment & join
    try {
      final res = await V2Service.bookAppointment(
        professionalProfileId: doctor['_id'],
        mode: mode,
        durationMinutes: 30,
        scheduledAt: DateTime.now(),
        serviceType: 'consultation',
        shareSummaryConsent: true,
      );

      final appt = res['appointment'];
      if (appt != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultationRoomScreen(
              appointmentId: appt['_id'],
              appointment: appt,
            ),
          ),
        ).then((_) => _loadWallet());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showCallModePicker(Map<String, dynamic> doctor) {
    final cleanName = _cleanDoctorName(doctor['publicName'] ?? 'Doctor');
    final rates = doctor['rates'] ?? {};
    final vMin = rates['ratePerMinuteVideo'] ?? rates['ratePerMinute'] ?? 25;
    final voMin = rates['ratePerMinuteVoice'] ?? 18;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connect with $cleanName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('First 3 minutes are complimentary • Pay-as-you-go thereafter', style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.videocam_rounded, color: Color(0xFF6366F1)),
              ),
              title: const Text('HD Video Consultation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Face-to-face clinical session • ₹$vMin/min', style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _initiateConsultation(doctor, 'video');
              },
            ),
            const Divider(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.call_rounded, color: Color(0xFF059669)),
              ),
              title: const Text('Direct Voice Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Audio-only private consultation • ₹$voMin/min', style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _initiateConsultation(doctor, 'voice');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Talk & Chat with Doctors',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openIntakeSheet,
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Intake Profile',
          ),
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
            // Pinned Astrotalk Top Wallet Ribbon
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282542) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryOrange, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wallet Balance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(
                        '₹${_walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                      _loadWallet();
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Recharge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium, vertical: 6),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadProfessionals(),
                  decoration: InputDecoration(
                    hintText: 'Search psychiatrist, psychologist, sleep...',
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

            // Astrotalk Problem-First Category Filter Pills
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
                itemCount: _problemCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _problemCategories[index];
                  final isSelected = cat == _selectedProblem;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryOrange,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppTheme.textDark),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedProblem = cat);
                        _loadProfessionals();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

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
                                'No specialists found for $_selectedProblem',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : AppTheme.textLight,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _loadWallet();
                            await _loadProfessionals();
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppTheme.spacingMedium),
                            itemCount: _professionals.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final p = _professionals[index];
                              return _buildAstrotalkDoctorCard(context, p, isDark);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAstrotalkDoctorCard(
      BuildContext context, Map<String, dynamic> p, bool isDark) {
    final title = p['title'] ?? 'Specialist';
    final rawName = p['publicName'] ?? 'Doctor';
    final cleanName = _cleanDoctorName(rawName);
    final specialty = p['specialty'] ?? '';
    final experience = p['experienceYears'] ?? 1;
    final rating = p['rating'] ?? 4.9;
    final reviewCount = p['reviewCount'] ?? 120;
    final hospital = p['hospitalAffiliation'] ?? '';
    final languages = (p['languages'] as List?)?.join(', ') ?? 'English, Hindi';

    final rates = p['rates'] ?? {};
    final vMin = rates['ratePerMinuteVideo'] ?? rates['ratePerMinute'] ?? 25;
    final voMin = rates['ratePerMinuteVoice'] ?? 18;
    final cMin = rates['ratePerMinuteChat'] ?? 10;
    final isAvailable = p['isAvailableNow'] ?? true;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClinicianProfileScreen(professionalId: p['_id'])),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Avatar with Online Green Beacon
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryOrange.withOpacity(0.18),
                    child: Text(
                      rawName.isNotEmpty ? rawName.substring(0, 1).toUpperCase() : 'D',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: isAvailable ? const Color(0xFF059669) : Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cleanName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 15, color: Color(0xFF059669)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$title • $specialty',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hospital.isNotEmpty)
                      Text(
                        hospital,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '🗣️ $languages • $experience+ yrs exp',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

          // Rating & Complimentary Free Tag Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 3),
                Text(
                  '$rating (${reviewCount}+ consultations)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text(
                  '🎁 3 Mins Free Intro',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Rates Row
          Row(
            children: [
              Text('Rates: ', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey)),
              Text('📞 ₹$voMin/m  •  🎥 ₹$vMin/m  •  💬 ₹$cMin/m',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          // Astrotalk Direct Action Buttons: Chat & Call
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _initiateConsultation(p, 'chat'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text('Chat (₹$cMin/m)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCallModePicker(p),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
