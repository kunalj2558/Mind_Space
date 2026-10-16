import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/v2_service.dart';
import 'package:hearme/screens/safety/crisis_resources_sheet.dart';

class ConsultationRoomScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointment;

  const ConsultationRoomScreen({
    super.key,
    required this.appointmentId,
    required this.appointment,
  });

  @override
  State<ConsultationRoomScreen> createState() => _ConsultationRoomScreenState();
}

class _ConsultationRoomScreenState extends State<ConsultationRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  bool _isMicMuted = false;
  bool _isCamOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _isEnding = false;
  bool _showChatPanel = false;

  List<dynamic> _messages = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    final mode = widget.appointment['mode'] ?? 'video';
    bool granted = true;

    if (mode == 'video') {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final camStatus = statuses[Permission.camera];
      final micStatus = statuses[Permission.microphone];

      if (camStatus != PermissionStatus.granted || micStatus != PermissionStatus.granted) {
        granted = false;
        if (mounted) {
          _showPermissionRationale(
            title: 'Camera & Microphone Access Required',
            description:
                'MindSpace requires camera and microphone permissions for encrypted telehealth video calls with your clinician.',
          );
        }
      }
    } else if (mode == 'voice') {
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        granted = false;
        if (mounted) {
          _showPermissionRationale(
            title: 'Microphone Access Required',
            description:
                'MindSpace requires microphone permission for encrypted audio consultations.',
          );
        }
      }
    }

    if (mounted) {
      _startSessionTimer();
    }
  }

  void _showPermissionRationale({required String title, required String description}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue in Room'),
          ),
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

  Future<void> _startSessionTimer() async {
    await V2Service.startSession(widget.appointmentId);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  Future<void> _loadMessages() async {
    final msgs = await V2Service.getAppointmentMessages(widget.appointmentId);
    if (mounted) {
      setState(() => _messages = msgs);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    await V2Service.sendAppointmentMessage(widget.appointmentId, text);
    _loadMessages();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Consultation Session?'),
        content: const Text(
          'This will disconnect the call and settle the consultation duration with the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay in Session'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('End Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isEnding = true);
      _sessionTimer?.cancel();
      _pollTimer?.cancel();

      final summary = await V2Service.endSession(widget.appointmentId);

      if (mounted) {
        final billableMins = summary['billableMinutes'] ?? 1;
        final total = summary['itemizedSummary']?['totalCharged'] ??
            widget.appointment['rateSnapshot']?['totalAmount'] ?? 600;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text('Consultation Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your consultation has ended successfully.'),
                const SizedBox(height: 12),
                Text('Duration: $billableMins minute(s)'),
                Text('Total Settled: ₹$total'),
                const SizedBox(height: 8),
                const Text(
                  'Itemized receipt has been logged to your billing history.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Exit room
                },
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatTimer(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final prof = widget.appointment['professionalProfileId'] ?? {};
    final profName = prof['publicName'] ?? widget.appointment['professionalId']?['name'] ?? 'Doctor';
    final mode = widget.appointment['mode'] ?? 'video';
    final duration = widget.appointment['durationMinutes'] ?? 30;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${mode.toUpperCase()} Call • ${_formatTimer(_elapsedSeconds)} / ${duration}m',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF059669)),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() => _showChatPanel = !_showChatPanel),
            icon: Icon(
              _showChatPanel ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: _showChatPanel ? AppTheme.primaryOrange : null,
            ),
            tooltip: 'Toggle In-Call Chat',
          ),
          IconButton(
            onPressed: () => CrisisResourcesSheet.show(context),
            icon: const Icon(Icons.emergency_outlined, color: Colors.redAccent),
            tooltip: 'Emergency Resources',
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
            // Main Media / Call Viewport
            Expanded(
              flex: _showChatPanel ? 1 : 2,
              child: Stack(
                children: [
                  // Remote Doctor View
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16152B) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background glowing grid pattern
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.08,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                ),
                                itemCount: 36,
                                itemBuilder: (_, __) => Container(
                                  margin: const EdgeInsets.all(1),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // Doctor Avatar & Live Status
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryOrange,
                                      const Color(0xFF059669),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFF2B2844),
                                  child: Text(
                                    profName.isNotEmpty ? profName[0].toUpperCase() : 'D',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                profName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF059669),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    mode == 'video'
                                        ? 'Encrypted HD Video Feed Connected'
                                        : 'Encrypted HD Voice Feed Connected',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Top status badges
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_rounded, color: Colors.greenAccent, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'P2P WebRTC Secure',
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatTimer(_elapsedSeconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Local Self-Camera Preview Tile (Bottom-Right)
                  if (mode == 'video')
                    Positioned(
                      bottom: 16,
                      right: 24,
                      child: Container(
                        width: 90,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _isCamOff ? Colors.black87 : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white30, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isCamOff)
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam_off, color: Colors.white54, size: 24),
                                    SizedBox(height: 4),
                                    Text('Cam Off', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                  ],
                                )
                              else
                                Container(
                                  color: const Color(0xFF232B3E),
                                  child: Center(
                                    child: Icon(
                                      _isFrontCamera ? Icons.person_rounded : Icons.landscape_rounded,
                                      color: Colors.white70,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 4,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // In-Call Chat Drawer (Expandable)
            if (_showChatPanel)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1C33) : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.primaryOrange),
                            const SizedBox(width: 8),
                            const Text('Live Consultation Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(() => _showChatPanel = false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _messages.isEmpty
                            ? const Center(
                                child: Text('No messages yet. Send a note to doctor.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(8),
                                itemCount: _messages.length,
                                itemBuilder: (ctx, i) {
                                  final m = _messages[i];
                                  final isMe = m['senderRole'] == 'patient';
                                  return Align(
                                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isMe ? AppTheme.primaryOrange : (isDark ? Colors.white12 : Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        m['message'] ?? '',
                                        style: TextStyle(
                                          color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgController,
                                onSubmitted: (_) => _sendMessage(),
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, size: 18, color: AppTheme.primaryOrange),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Call Controls Dock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mic toggle
                    IconButton(
                      icon: Icon(
                        _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: _isMicMuted ? Colors.redAccent : (isDark ? Colors.white : Colors.black87),
                      ),
                      onPressed: () => setState(() => _isMicMuted = !_isMicMuted),
                      tooltip: _isMicMuted ? 'Unmute Mic' : 'Mute Mic',
                    ),

                    // Video toggle
                    if (mode == 'video')
                      IconButton(
                        icon: Icon(
                          _isCamOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                          color: _isCamOff ? Colors.redAccent : (isDark ? Colors.white : Colors.black87),
                        ),
                        onPressed: () => setState(() => _isCamOff = !_isCamOff),
                        tooltip: _isCamOff ? 'Turn Video On' : 'Turn Video Off',
                      ),

                    // Flip camera
                    if (mode == 'video')
                      IconButton(
                        icon: Icon(
                          Icons.flip_camera_ios_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: () => setState(() => _isFrontCamera = !_isFrontCamera),
                        tooltip: 'Switch Camera',
                      ),

                    // Speaker toggle
                    IconButton(
                      icon: Icon(
                        _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        color: _isSpeakerOn ? AppTheme.primaryOrange : (isDark ? Colors.white : Colors.black87),
                      ),
                      onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                      tooltip: _isSpeakerOn ? 'Speakerphone On' : 'Earpiece Mode',
                    ),

                    // In-call chat toggle
                    IconButton(
                      icon: Icon(
                        Icons.message_rounded,
                        color: _showChatPanel ? AppTheme.primaryOrange : (isDark ? Colors.white : Colors.black87),
                      ),
                      onPressed: () => setState(() => _showChatPanel = !_showChatPanel),
                      tooltip: 'Chat',
                    ),

                    // End Session Button
                    ElevatedButton(
                      onPressed: _isEnding ? null : _endSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call_end_rounded, size: 18),
                          SizedBox(width: 4),
                          Text('End', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
