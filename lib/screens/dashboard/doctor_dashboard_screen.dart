import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/core/widgets/theme_toggle_button.dart';
import 'package:hearme/services/v2_service.dart';
import 'package:hearme/screens/notifications/notifications_screen.dart';
import 'package:hearme/screens/doctor/patients_list_screen.dart';
import 'package:hearme/screens/linking/my_code_screen.dart';
import 'package:hearme/screens/profile/profile_screen.dart';
import 'package:hearme/screens/welcome/welcome_screen.dart';
import 'package:hearme/screens/appointments/appointments_list_screen.dart';
import 'package:hearme/screens/consultation/consultation_room_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  List<dynamic> _incomingRequests = [];
  Timer? _requestPoller;

  @override
  void initState() {
    super.initState();
    _loadIncomingRequests();
    _requestPoller = Timer.periodic(const Duration(seconds: 4), (_) => _loadIncomingRequests(silent: true));
  }

  @override
  void dispose() {
    _requestPoller?.cancel();
    super.dispose();
  }

  Future<void> _loadIncomingRequests({bool silent = false}) async {
    try {
      final list = await V2Service.getAppointments();
      if (mounted) {
        setState(() {
          _incomingRequests = list.where((a) => a['status'] == 'requested').toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _acceptRequest(String id, Map<String, dynamic> appointment) async {
    try {
      await V2Service.acceptAppointment(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation request accepted! You can now start the call.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      _loadIncomingRequests();
      
      // Prompt doctor to join the call immediately
      if (mounted) {
        final joinNow = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Start Consultation Now?'),
            content: const Text('The patient is waiting in the room. Would you like to enter now?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                child: const Text('Enter Call Room', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (joinNow == true && mounted) {
          _joinCallWithPermissions(id, appointment);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _rejectRequest(String id) async {
    try {
      await V2Service.rejectAppointment(id);
      _loadIncomingRequests();
    } catch (_) {}
  }

  Future<void> _joinCallWithPermissions(String id, Map<String, dynamic> appointment) async {
    final mode = appointment['mode'] ?? 'video';
    if (mode == 'video') {
      final statuses = await [Permission.camera, Permission.microphone].request();
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
        title: const Text('Permissions Required'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _openRatesManagementSheet(BuildContext context, bool isDark) async {
    final profile = await V2Service.getDoctorProfile();
    if (!mounted) return;

    final rates = profile?['rates'] ?? {};
    final TextEditingController r15 = TextEditingController(text: '${rates['session15Min'] ?? 350}');
    final TextEditingController r30 = TextEditingController(text: '${rates['session30Min'] ?? 650}');
    final TextEditingController r60 = TextEditingController(text: '${rates['session60Min'] ?? 1200}');
    final TextEditingController rPerMin = TextEditingController(text: '${rates['ratePerMinute'] ?? 25}');

    List<String> currentModes = (profile?['consultationModes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        ['video', 'voice', 'chat'];
    bool allowVideo = currentModes.contains('video');
    bool allowVoice = currentModes.contains('voice');
    bool allowChat = currentModes.contains('chat');
    bool isAvailable = profile?['isAvailableNow'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1C33) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Doctor Consultation Rates & Modes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Set your consultation fees and offered modes. These will be charged to patients upon booking.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Offered Consultation Modes', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: const Text('Video Call Consultations'),
                  value: allowVideo,
                  activeColor: AppTheme.primaryOrange,
                  onChanged: (val) => setSheetState(() => allowVideo = val ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Voice Call Consultations'),
                  value: allowVoice,
                  activeColor: AppTheme.primaryOrange,
                  onChanged: (val) => setSheetState(() => allowVoice = val ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Live Chat Consultations'),
                  value: allowChat,
                  activeColor: AppTheme.primaryOrange,
                  onChanged: (val) => setSheetState(() => allowChat = val ?? true),
                ),
                const SizedBox(height: 12),
                const Text('Consultation Fares (INR ₹)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: r15,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '15 Min Fee (₹)', prefixText: '₹'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: r30,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '30 Min Fee (₹)', prefixText: '₹'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: r60,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '60 Min Fee (₹)', prefixText: '₹'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rPerMin,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Per Min Rate (₹)', prefixText: '₹'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  title: const Text('Available for Instant Consultations'),
                  subtitle: const Text('Toggle your online availability badge for patients'),
                  value: isAvailable,
                  activeColor: const Color(0xFF059669),
                  onChanged: (val) => setSheetState(() => isAvailable = val),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final modes = <String>[];
                      if (allowVideo) modes.add('video');
                      if (allowVoice) modes.add('voice');
                      if (allowChat) modes.add('chat');

                      await V2Service.updateDoctorProfile(
                        rates: {
                          'session15Min': int.tryParse(r15.text) ?? 350,
                          'session30Min': int.tryParse(r30.text) ?? 650,
                          'session60Min': int.tryParse(r60.text) ?? 1200,
                          'ratePerMinute': int.tryParse(rPerMin.text) ?? 25,
                        },
                        consultationModes: modes.isNotEmpty ? modes : ['video', 'voice', 'chat'],
                        isAvailableNow: isAvailable,
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Doctor rates and consultation modes updated successfully!'),
                            backgroundColor: Color(0xFF059669),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Consultation Rates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      drawer: _buildDrawer(context, isDark, lang, auth),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (auth.user?.name ?? 'D')[0].toUpperCase(),
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
                            'Dr. ${auth.user?.name ?? 'Doctor'}',
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
                    const ThemeToggleButton(),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 20),

                // Incoming Consultation Requests (Live Notification Section)
                if (_incomingRequests.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.ring_volume_rounded, color: AppTheme.primaryOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Incoming Consultation Requests (${_incomingRequests.length})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._incomingRequests.map((req) {
                    final id = req['_id'];
                    final patient = req['patientId'] ?? {};
                    final patientName = patient['name'] ?? 'Patient';
                    final mode = req['mode'] ?? 'video';
                    final duration = req['durationMinutes'] ?? 30;
                    final fee = req['rateSnapshot']?['totalAmount'] ?? 600;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF2E1C38), const Color(0xFF1E1C33)]
                              : [const Color(0xFFFFF7ED), Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryOrange.withOpacity(0.08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primaryOrange.withOpacity(0.2),
                                child: Text(patientName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patientName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark ? Colors.white : AppTheme.textDark,
                                      ),
                                    ),
                                    Text(
                                      'Requests ${mode.toUpperCase()} session • $duration mins • ₹$fee',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _acceptRequest(id, req),
                                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                                  label: const Text('Accept Request'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: () => _rejectRequest(id),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Decline'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1);
                  }),
                  const SizedBox(height: 10),
                ],

                // Navigation tiles
                _buildTile(
                  context: context,
                  title: 'My Consultation Rates & Modes',
                  subtitle: 'Set your fees for 15m, 30m, 60m & enabled modes',
                  icon: Icons.price_change_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDark: isDark,
                  onTap: () => _openRatesManagementSheet(context, isDark),
                ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),

                const SizedBox(height: AppTheme.spacingMedium),

                _buildTile(
                  context: context,
                  title: 'Scheduled Consultations',
                  subtitle: 'Video, Voice & Live Sessions',
                  icon: Icons.calendar_month_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AppointmentsListScreen()),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),

                const SizedBox(height: AppTheme.spacingMedium),

                _buildTile(
                  context: context,
                  title: AppStrings.get('patient_notifications', lang),
                  subtitle: 'View mental health reports',
                  icon: Icons.notifications_active_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),

                const SizedBox(height: AppTheme.spacingMedium),

                _buildTile(
                  context: context,
                  title: 'My Patients',
                  subtitle: 'View patient health data',
                  icon: Icons.people_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PatientsListScreen()),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                const SizedBox(height: AppTheme.spacingMedium),

                _buildTile(
                  context: context,
                  title: AppStrings.get('my_code', lang),
                  subtitle: auth.user?.uniqueCode ?? 'HM-XXXX',
                  icon: Icons.qr_code_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCodeScreen()),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1),
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
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextLight
                          : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextGray
                          : AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? AppTheme.darkTextGray : AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark, String lang,
      AuthProvider auth) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // User header
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (auth.user?.name ?? 'D')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
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
                            'Dr. ${auth.user?.name ?? 'Doctor'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextLight
                                  : AppTheme.textDark,
                            ),
                          ),
                          Text(
                            auth.user?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextGray
                                  : AppTheme.textGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(AppStrings.get('profile', lang)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.calendar_month_rounded),
                title: const Text('My Consultations'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AppointmentsListScreen()),
                  );
                },
              ),

              const Spacer(),

              // Logout
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: Text(
                  AppStrings.get('logout', lang),
                  style: const TextStyle(color: Colors.red),
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
      ),
    );
  }
}
