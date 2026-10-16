import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    // Auto-poll every 3.5 seconds to track doctor acceptances in real-time
    _pollTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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

  Future<void> _silentRefresh() async {
    final list = await V2Service.getAppointments();
    if (mounted) {
      setState(() {
        _appointments = list;
      });
    }
  }

  Future<void> _cancelAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Consultation?'),
        content: const Text(
          'Are you sure you want to cancel this appointment request? Refund will be processed as per policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cancel Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await V2Service.cancelAppointment(id);
      _loadAppointments();
    }
  }

  Future<void> _joinCallWithPermissions(String id, Map<String, dynamic> appointment) async {
    final mode = appointment['mode'] ?? 'video';

    // Verify and request hardware permissions before launching call
    if (mode == 'video') {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (statuses[Permission.camera]?.isGranted != true ||
          statuses[Permission.microphone]?.isGranted != true) {
        if (!mounted) return;
        _showPermissionAlert('Camera & Microphone permissions are needed to start the video call.');
        return;
      }
    } else if (mode == 'voice') {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (!mounted) return;
        _showPermissionAlert('Microphone permission is needed to start the voice call.');
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationRoomScreen(
          appointmentId: id,
          appointment: appointment,
        ),
      ),
    );
  }

  void _showPermissionAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Permissions Required'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Consultations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
        ],
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
    final profName = prof['publicName'] ?? a['professionalId']?['name'] ?? 'Clinician';
    final title = prof['title'] ?? 'Specialist';
    final mode = a['mode'] ?? 'video';
    final status = a['status'] ?? 'requested';
    final duration = a['durationMinutes'] ?? 30;
    final total = a['rateSnapshot']?['totalAmount'] ?? 600;
    final scheduledAt = a['scheduledAt'] != null
        ? DateTime.tryParse(a['scheduledAt'])
        : null;

    final isRequested = status == 'requested';
    final isConfirmed = status == 'confirmed' || status == 'paid' || status == 'active' || status == 'ready';

    Color statusColor = Colors.orange;
    String statusLabel = 'REQUESTED';
    if (isRequested) {
      statusColor = const Color(0xFFD97706); // Amber
      statusLabel = 'WAITING FOR DOCTOR';
    } else if (isConfirmed) {
      statusColor = const Color(0xFF059669); // Emerald
      statusLabel = 'CONFIRMED';
    } else if (status == 'completed') {
      statusColor = Colors.blue;
      statusLabel = 'COMPLETED';
    } else if (status == 'cancelled' || status == 'refunded') {
      statusColor = Colors.redAccent;
      statusLabel = 'CANCELLED';
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(modeIcon, color: AppTheme.primaryOrange, size: 24),
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
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Waiting status banner if doctor hasn't accepted yet
          if (isRequested)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Request sent to $profName. Waiting for doctor to accept. Page will unlock automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                  '₹$total',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              if (isConfirmed)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _joinCallWithPermissions(id, a),
                    icon: Icon(
                      mode == 'video'
                          ? Icons.videocam_rounded
                          : (mode == 'voice' ? Icons.phone_in_talk_rounded : Icons.chat_rounded),
                      size: 18,
                    ),
                    label: Text(
                      mode == 'video'
                          ? 'Start Video Call'
                          : (mode == 'voice' ? 'Start Voice Call' : 'Open Live Chat'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else if (isRequested)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null, // Disabled until doctor accepts!
                    icon: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: const Text('Waiting for Doctor Acceptance...'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              if (status != 'cancelled' && status != 'completed')
                OutlinedButton(
                  onPressed: () => _cancelAppointment(id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
