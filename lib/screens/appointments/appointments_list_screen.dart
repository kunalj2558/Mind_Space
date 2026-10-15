import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/v2_service.dart';
import 'package:hearme/screens/consultation/consultation_room_screen.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final list = await V2Service.getAppointments();
    if (mounted) {
      setState(() {
        _appointments = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Consultation?'),
        content: const Text(
          'Are you sure you want to cancel this appointment? Refund will be processed as per policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cancel & Refund', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await V2Service.cancelAppointment(id);
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Consultations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _appointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 54,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No scheduled consultations yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAppointments,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      itemCount: _appointments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final a = _appointments[index];
                        return _buildAppointmentCard(a, isDark);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> a, bool isDark) {
    final id = a['_id'] ?? '';
    final prof = a['professionalProfileId'] ?? {};
    final profName = prof['publicName'] ?? 'Specialist';
    final title = prof['title'] ?? 'Clinician';
    final mode = a['mode'] ?? 'video';
    final status = a['status'] ?? 'scheduled';
    final duration = a['durationMinutes'] ?? 30;
    final total = a['rateSnapshot']?['totalAmount'] ?? 600;
    final scheduledAt = a['scheduledAt'] != null
        ? DateTime.tryParse(a['scheduledAt'])
        : null;

    final isJoinable = status == 'paid' || status == 'active' || status == 'ready';

    Color statusColor = Colors.orange;
    if (status == 'paid' || status == 'completed') {
      statusColor = const Color(0xFF059669);
    } else if (status == 'cancelled' || status == 'refunded') {
      statusColor = Colors.redAccent;
    }

    IconData modeIcon = Icons.videocam_rounded;
    if (mode == 'voice') modeIcon = Icons.phone_in_talk_rounded;
    if (mode == 'chat') modeIcon = Icons.chat_bubble_rounded;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(modeIcon, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    Text(
                      '$title • $duration min session',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (scheduledAt != null)
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14,
                    color: isDark ? Colors.white54 : AppTheme.textLight),
                const SizedBox(width: 6),
                Text(
                  '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}  ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  'Paid: ₹$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (isJoinable)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConsultationRoomScreen(
                            appointmentId: id,
                            appointment: a,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.meeting_room_rounded, size: 16),
                    label: const Text('Enter Consultation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (isJoinable) const SizedBox(width: 10),
              if (status != 'cancelled' && status != 'completed')
                OutlinedButton(
                  onPressed: () => _cancelAppointment(id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
