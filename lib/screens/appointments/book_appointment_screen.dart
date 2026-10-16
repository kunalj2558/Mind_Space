import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/core/widgets/animated_button.dart';
import 'package:hearme/services/v2_service.dart';
import 'package:hearme/screens/appointments/appointments_list_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> professional;

  const BookAppointmentScreen({
    super.key,
    required this.professional,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String _selectedMode = 'video';
  int _selectedDuration = 30;
  bool _shareSummaryConsent = false;
  bool _emergencyAcknowledged = true;
  bool _termsAccepted = true;
  bool _isSubmitting = false;

  int _calculateFee() {
    final rates = widget.professional['rates'] ?? {};
    if (_selectedDuration == 15) return rates['session15Min'] ?? 300;
    if (_selectedDuration == 60) return rates['session60Min'] ?? 999;
    return rates['session30Min'] ?? 550;
  }

  Future<void> _handleBooking() async {
    if (!_emergencyAcknowledged || !_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the informed consent terms to proceed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await V2Service.bookAppointment(
        professionalProfileId: widget.professional['_id'],
        mode: _selectedMode,
        durationMinutes: _selectedDuration,
        shareSummaryConsent: _shareSummaryConsent,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: AppTheme.primaryOrange),
                SizedBox(width: 8),
                Text('Request Sent to Doctor!'),
              ],
            ),
            content: Text(
              'Your request for a $_selectedMode consultation has been sent to ${widget.professional['publicName']}.\n\nThe call session will unlock automatically as soon as the doctor accepts your request.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentsListScreen(),
                    ),
                  );
                },
                child: const Text('Track Request & Waiting Room', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final name = widget.professional['publicName'] ?? 'Doctor';
    final specialty = widget.professional['specialty'] ?? '';
    final sessionFee = _calculateFee();
    const platformFee = 50;
    final total = sessionFee + platformFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Consultation'),
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
              // Specialist Summary
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1) : 'D',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                          Text(
                            specialty,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Consultation Mode Selection
              Text(
                'Select Mode',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildModeCard('video', 'Video Call', Icons.videocam_rounded, isDark),
                  const SizedBox(width: 10),
                  _buildModeCard('voice', 'Voice Call', Icons.phone_in_talk_rounded, isDark),
                  const SizedBox(width: 10),
                  _buildModeCard('chat', 'Live Chat', Icons.chat_bubble_rounded, isDark),
                ],
              ),
              const SizedBox(height: 20),

              // Duration Selection
              Text(
                'Select Duration',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildDurationCard(15, '15 min', isDark),
                  const SizedBox(width: 10),
                  _buildDurationCard(30, '30 min', isDark),
                  const SizedBox(width: 10),
                  _buildDurationCard(60, '60 min', isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Free Session Quota Benefit
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF059669).withOpacity(0.12),
                      const Color(0xFF0D9488).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF059669).withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.card_giftcard_rounded, color: Color(0xFF059669), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complimentary Intro Period Included',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'First 3 mins free for Video/Voice & 5 mins free for Chat. Billing begins only if you choose to continue past the intro.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF047857),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Transparent Itemized Bill
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Itemized Fee Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBillRow('Specialist Consultation Fee', '₹$sessionFee', isDark),
                    const SizedBox(height: 8),
                    _buildBillRow('MindSpace Platform Fee', '₹$platformFee', isDark),
                    const SizedBox(height: 8),
                    _buildBillRow('Applicable Taxes', '₹0', isDark),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payable',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                        Text(
                          '₹$total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Informed Consent & Boundaries
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _emergencyAcknowledged,
                      onChanged: (v) => setState(() => _emergencyAcknowledged = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'I acknowledge that MindSpace is not an emergency response service. In case of immediate danger, I will call 112 or Tele-MANAS (14416).',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _termsAccepted,
                      onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'I agree to the transparent cancellation terms (free cancellation up to 2 hours before session start time).',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _shareSummaryConsent,
                      onChanged: (v) => setState(() => _shareSummaryConsent = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Optional: Share my recent MindSpace wellbeing check-in summary with this specialist to assist the consultation.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Checkout Button
              AnimatedButton(
                text: _isSubmitting ? 'Confirming...' : 'Confirm & Book Consultation (₹$total)',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? () {} : _handleBooking,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(String mode, String label, IconData icon, bool isDark) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMode = mode),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.textDark)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.textDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationCard(int duration, String label, bool isDark) {
    final isSelected = _selectedDuration == duration;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDuration = duration),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.textDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(String item, String amount, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          item,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : AppTheme.textDark,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
